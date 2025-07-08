import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:we_chat/helper/my_date_util.dart';
import 'package:we_chat/main.dart';
import 'package:we_chat/models/chat_user.dart';
import 'package:we_chat/network/apis.dart';
import 'package:we_chat/screens/chat_screen.dart';
import 'package:we_chat/widgets/dialogs/profile_dialog.dart';

import '../models/message.dart';

class ChatUserCard extends StatefulWidget {
  final ChatUser user;
  const ChatUserCard({super.key, required this.user});

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

/// card to represent a single user in chatscreen
class _ChatUserCardState extends State<ChatUserCard> {
  /// last message info (if no msg -> null)
  Message? _message;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: mq.width * .04, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: .5,
      child: InkWell(
        /// for navigating to chat screen
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ChatScreen(user: widget.user)),
          );
        },
        child: StreamBuilder(
          stream: APIs.getLastMessage(widget.user),
          builder: (context, snapshot) {
            /// showing the last message in the main chat screen
            final data = snapshot.data?.docs;
            final list =
                data?.map((e) => Message.fromJson(e.data())).toList() ?? [];
            if (list.isNotEmpty) _message = list[0];

            return ListTile(
              /// User Profile picture
              leading: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => ProfileDialog(user: widget.user),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(mq.height * .08),
                  child: CachedNetworkImage(
                    height: mq.height * 0.05,
                    width: mq.height * 0.05,
                    imageUrl: widget.user.image,
                    errorWidget:
                        (context, url, error) =>
                            const CircleAvatar(child: Icon(Icons.person)),
                  ),
                ),
              ),

              ///User Name
              title: Text(widget.user.name),

              ///User Last Message
              subtitle: Text(
                _message != null
                    ? _message!.type != Type.image
                        ? 'image'
                        : _message!.msg
                    : widget.user.about,
                maxLines: 1,
              ),

              ///User Last message time
              //trailing: Text('12:00 PM', style: TextStyle(color: Colors.black54)),
              trailing:
                  _message == null
                      ? null
                      /// show nothing when no msg is sent
                      : _message!.read.isEmpty &&
                          _message!.fromId != APIs.user.uid
                      ? Container(
                        /// show for unread msgs
                        height: 15,
                        width: 15,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      )
                      : Text(
                        /// message sent time
                        MyDateUtil.getLastMessageTime(
                          context: context,
                          time: _message!.sent,
                        ),
                        style: TextStyle(fontSize: 13, color: Colors.black54),
                      ),
            );
          },
        ),
      ),
    );
  }
}
