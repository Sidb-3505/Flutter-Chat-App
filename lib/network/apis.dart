import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart';
import 'package:we_chat/models/chat_user.dart';
import 'package:we_chat/models/message.dart';
import 'package:we_chat/screens/auth/sign_in_with_google.dart';

class APIs {
  /// for firebase authentication
  static FirebaseAuth auth = FirebaseAuth.instance;

  /// for google authentication
  static GoogleAuthService authService = GoogleAuthService();

  /// for accessing cloud firestore database
  static FirebaseFirestore firestore = FirebaseFirestore.instance;

  /// for accessing storage
  static FirebaseStorage storage = FirebaseStorage.instance;

  /// to return self info
  static late ChatUser me;

  /// for accessing firebase messaging (push notification)
  static FirebaseMessaging fMessaging = FirebaseMessaging.instance;

  /// for getting firebase message token
  // static Future<void> getFirebaseMessagingToken() async {
  //   await fMessaging.requestPermission();
  //
  //   await fMessaging.getToken().then((t) {
  //     if (t != null) {
  //       me.pushToken = t;
  //       print('Push token: $t');
  //     }
  //   });
  // }

  /// for sending push notification
  // static Future<void> sendPushNotification(
  //   ChatUser chatUser,
  //   String msg,
  // ) async {
  //   try {
  //     final body = {
  //       "to": chatUser.pushToken,
  //       "notification": {"title": chatUser.name, "body": msg},
  //     };
  //
  //     var response = await post(
  //       Uri.parse('https://fcm.googleapis.com/fcm/send'),
  //       headers: {HttpHeaders.contentTypeHeader: 'application/json'},
  //       body: jsonEncode(body),
  //     );
  //   } catch (err) {
  //     print('Error: $err');
  //   }
  // }

  /// to return current user
  static User get user => auth.currentUser!;

  /// for checking is user exists or not
  static Future<bool> userExists() async {
    return (await firestore.collection('users').doc(user.uid).get()).exists;
  }

  /// for checking is user exists or not
  static Future<bool> addChatuser(String email) async {
    final data =
        await firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .get();
    if (data.docs.isNotEmpty && data.docs.first.id != user.uid) {
      /// user exits
      firestore
          .collection('users')
          .doc(user.uid)
          .collection('my_users')
          .doc(data.docs.first.id)
          .set({});
      return true;
    } else {
      return false;
    }
  }

  /// for getting current user info
  static Future<void> getSelfInfo() async {
    await firestore.collection('users').doc(user.uid).get().then((user) async {
      if (user.exists) {
        me = ChatUser.fromJson(user.data()!);
        // await getFirebaseMessagingToken();

        /// for setting user status to active
        APIs.updateActiveStatus(true);
      } else {
        await createUser().then((value) => getSelfInfo());
      }
    });
  }

  /// for creating new user
  static Future<void> createUser() async {
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    final chatUser = ChatUser(
      image: user.photoURL.toString(),
      about: "Hey i am using We Chat!",
      name: user.displayName.toString(),
      createdAt: time,
      isOnline: false,
      id: user.uid,
      lastActive: time,
      email: user.email.toString(),
      pushToken: "",
    );

    return await firestore
        .collection('users')
        .doc(user.uid)
        .set(chatUser.toJson());
  }

  /// for getting id's of known users from firebase
  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyUsersId() {
    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('my_users')
        .snapshots();
  }

  /// for getting all users from firebase
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllUsers(
    List<String> userIds,
  ) {
    return firestore
        .collection('users')
        .where('id', whereIn: userIds)
        //where('id', isNotEqualTo: user.uid)
        .snapshots();
  }

  /// for adding an user to my user when first message is send
  static Future<void> sendFirstMessage(
    ChatUser chatUser,
    String msg,
    Type type,
  ) async {
    await firestore
        .collection('users')
        .doc(chatUser.id)
        .collection('my_users')
        .doc(user.uid)
        .set({})
        .then((value) => sendMessage(chatUser, msg, type));
  }

  /// for updating user info
  static Future<void> updateUserInfo() async {
    await firestore.collection('users').doc(user.uid).update({
      'name': me.name,
      'about': me.about,
    });
  }

  /// for updating user profile picture
  static Future<void> updateProfilePicture(File file) async {
    /// getting image file extension
    final ext = file.path.split('.').last;

    /// storage file ref with path
    final ref = storage.ref().child('profile_pictures/${user.uid}.$ext');

    /// uploading the image
    await ref.putFile(file, SettableMetadata(contentType: 'images/$ext'));

    /// updating the image in firestore database
    me.image = await ref.getDownloadURL();
    await firestore.collection('users').doc(user.uid).update({
      'image': me.image,
    });
  }

  /// for getting specific user info
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserInfo(
    ChatUser chatUser,
  ) {
    return firestore
        .collection('users')
        .where('id', isEqualTo: chatUser.id)
        .snapshots();
  }

  /// update online or last active status of the user
  static Future<void> updateActiveStatus(bool isOnline) async {
    firestore.collection('users').doc(user.uid).update({
      'is_online': isOnline,
      'last_active': DateTime.now().millisecondsSinceEpoch.toString(),
      'push_token': me.pushToken,
    });
  }

  ///******************* Chat Screen Related APIs ********************///

  /// chats (collection) -> conversation_id (doc) -> messages (collection) -> message (doc)

  /// Useful for getting Conversation id
  static String getConversationId(String id) =>
      user.uid.hashCode <= id.hashCode
          ? '${user.uid}_$id'
          : '${id}_${user.uid}';

  /// for getting all messages from specific conversation from firebase database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getAllMessages(
    ChatUser user,
  ) {
    return firestore
        .collection('chats/${getConversationId(user.id)}/messages')
        .snapshots();
  }

  /// for sending messages
  static Future<void> sendMessage(
    ChatUser chatUser,
    String msg,
    Type type,
  ) async {
    /// message sending time (used as id)
    final time = DateTime.now().millisecondsSinceEpoch.toString();

    /// message to send
    final Message message = Message(
      toId: chatUser.id,
      msg: msg,
      read: '',
      type: type,
      fromId: user.uid,
      sent: time,
    );

    final ref = firestore.collection(
      'chats/${getConversationId(chatUser.id)}/messages',
    );
    await ref.doc(time).set(message.toJson());
  }

  /// update read status of message
  static Future<void> updateMessageReadStatus(Message message) async {
    firestore
        .collection('chats/${getConversationId(message.fromId)}/messages')
        .doc(message.sent)
        .update({'read': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  /// get only last message from specific conversation from firebase database
  static Stream<QuerySnapshot<Map<String, dynamic>>> getLastMessage(
    ChatUser user,
  ) {
    return firestore
        .collection('chats/${getConversationId(user.id)}/messages')
        .orderBy('sent', descending: true)
        .limit(1)
        .snapshots();
  }

  /// send chat image
  static Future<void> sendChatImage(ChatUser chatUser, File file) async {
    try {
      /// getting image file extension
      final ext = file.path.split('.').last;

      /// storage file ref with path
      final ref = storage.ref().child(
        'images/${getConversationId(chatUser.id)}/${DateTime.now().millisecondsSinceEpoch}.$ext',
      );

      /// uploading the image
      await ref.putFile(file, SettableMetadata(contentType: 'images/$ext'));

      /// updating the image in firestore database
      final imageUrl = await ref.getDownloadURL();
      await sendMessage(chatUser, imageUrl, Type.image);
    } catch (err) {
      print("Image upload failed");
    }
  }

  /// delete message
  static Future<void> deleteMessage(Message message) async {
    await firestore
        .collection('chats/${getConversationId(message.toId)}/messages')
        .doc(message.sent)
        .delete();

    if (message.type == Type.image) {
      await storage.refFromURL(message.msg).delete();
    }
  }

  /// update message
  static Future<void> updateMessage(Message message, String updatedMsg) async {
    await firestore
        .collection('chats/${getConversationId(message.toId)}/messages/')
        .doc(message.sent)
        .update({'msg': updatedMsg});
  }
}
