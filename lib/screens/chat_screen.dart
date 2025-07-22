import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart%20';
import 'package:image_picker/image_picker.dart';
import 'package:we_chat/helper/my_date_util.dart';
import 'package:we_chat/main.dart';
import 'package:we_chat/models/chat_user.dart';
import 'package:we_chat/network/apis.dart';
import 'package:we_chat/screens/view_profile_screen.dart';
import 'package:we_chat/widgets/message_card.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> _list = [];

  /// _showEmoji --> for showing whether to show emoji or not
  /// _isUploading --> for showing whether the image is uploading or not
  bool _showEmoji = false, _isUploading = false;

  /// for handling messages
  final _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: PopScope(
          /// if emojis are shown & back button is pressed then close emojis
          /// or else simple close current screen on back button click
          canPop: false,
          onPopInvokedWithResult: (_, __) {
            if (_showEmoji) {
              setState(() => _showEmoji = !_showEmoji);
              return;
            }

            // some delay before pop
            Future.delayed(
              const Duration(milliseconds: 300),
              SystemNavigator.pop,
            );
          },
          child: Scaffold(
            /// app bar
            appBar: AppBar(
              automaticallyImplyLeading: false,
              flexibleSpace: _appBar(),
            ),
            backgroundColor: Color.fromARGB(255, 234, 248, 255),

            /// body
            body: Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                    stream: APIs.getAllMessages(widget.user),
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        ///if data is loading
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                          return const SizedBox();

                        /// if all or some data is loaded then show
                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;

                          /// Clear list before adding new data to avoid duplicates
                          _list.clear();

                          /// Convert each document to ChatUser and add to list
                          _list.addAll(
                            data!
                                .map((e) => Message.fromJson(e.data()))
                                .toList(),
                          );

                          // Scroll to bottom after build
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_scrollController.hasClients) {
                              _scrollController.jumpTo(
                                _scrollController.position.maxScrollExtent,
                              );
                            }
                          });

                          if (_list.isNotEmpty) {
                            return ListView.builder(
                              controller: _scrollController,
                              itemCount: _list.length,
                              padding: EdgeInsets.only(top: mq.height * .01),
                              physics: BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                return MessageCard(message: _list[index]);
                              },
                            );
                          } else {
                            return Center(
                              child: const Text(
                                'Say Hi!! 👋',
                                style: TextStyle(fontSize: 20),
                              ),
                            );
                          }
                      }
                    },
                  ),
                ),

                /// progress indicator for showing uploading
                if (_isUploading)
                  const Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),

                /// chat input field
                _chatInput(),

                /// show emoji on emoji keyboard button click and vice versa
                if (_showEmoji)
                  SizedBox(
                    height: mq.height * 0.35,
                    child: EmojiPicker(
                      textEditingController: _textController,
                      config: Config(
                        height: 256,
                        checkPlatformCompatibility: true,
                        emojiViewConfig: EmojiViewConfig(
                          emojiSizeMax:
                              28 *
                              (foundation.defaultTargetPlatform ==
                                      TargetPlatform.iOS
                                  ? 1.20
                                  : 1.0),
                        ),
                        viewOrderConfig: const ViewOrderConfig(
                          top: EmojiPickerItem.categoryBar,
                          middle: EmojiPickerItem.emojiView,
                          bottom: EmojiPickerItem.searchBar,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// app bar widget
  Widget _appBar() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ViewProfileScreen(user: widget.user),
          ),
        );
      },
      child: StreamBuilder(
        stream: APIs.getUserInfo(widget.user),
        builder: (context, snapshot) {
          final data = snapshot.data?.docs;
          final list =
              data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];

          return Row(
            children: [
              /// back button
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.arrow_back, color: Colors.black87),
              ),

              /// user profile picture
              ClipRRect(
                borderRadius: BorderRadius.circular(mq.height * .08),
                child: CachedNetworkImage(
                  height: mq.height * 0.04,
                  width: mq.height * 0.04,
                  imageUrl: list.isNotEmpty ? list[0].image : widget.user.image,
                  errorWidget:
                      (context, url, error) =>
                          const CircleAvatar(child: Icon(Icons.person)),
                ),
              ),

              /// to add some space
              const SizedBox(width: 10),

              /// to show user's name and last seen
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// to show user's name
                  Text(
                    list.isNotEmpty ? list[0].name : widget.user.name,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  /// to add some space
                  const SizedBox(height: 2),

                  /// to show user's last seen
                  Text(
                    list.isNotEmpty
                        ? list[0].isOnline
                            ? 'Online'
                            : MyDateUtil.getLastActiveTime(
                              context: context,
                              lastActive: list[0].lastActive,
                            )
                        : MyDateUtil.getLastActiveTime(
                          context: context,
                          lastActive: widget.user.lastActive,
                        ),
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  /// bottom chat input field
  Widget _chatInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        children: [
          /// input field and buttons
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  /// emoji button
                  IconButton(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      setState(() => _showEmoji = !_showEmoji);
                    },
                    icon: Icon(
                      Icons.emoji_emotions,
                      color: Colors.blueAccent,
                      size: 25,
                    ),
                  ),

                  /// text input field
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      onTap: () {
                        if (_showEmoji) {
                          setState(() => _showEmoji = !_showEmoji);
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: 'Type Something...',
                        hintStyle: TextStyle(color: Colors.blueAccent),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  /// pick an image from gallery button
                  IconButton(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();

                      /// Picking multiple images.
                      final List<XFile> images = await picker.pickMultiImage(
                        imageQuality: 70,
                      );

                      /// updating the images one by one
                      for (var i in images) {
                        setState(() => _isUploading = true);
                        await APIs.sendChatImage(widget.user, File(i.path));
                        setState(() => _isUploading = false);
                      }
                    },
                    icon: Icon(Icons.image, color: Colors.blueAccent, size: 26),
                  ),

                  /// pick an image from camera button
                  IconButton(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();

                      /// Pick an image.
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 70,
                      );
                      if (image != null) {
                        /// updating the profile in realtime database
                        setState(() => _isUploading = true);
                        await APIs.sendChatImage(widget.user, File(image.path));
                        setState(() => _isUploading = false);
                      }
                    },
                    icon: Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.blueAccent,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// send message button
          MaterialButton(
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                if (_list.isEmpty) {
                  /// for sending first message (add user to my user collection of chatUser(frnd))
                  APIs.sendFirstMessage(
                    widget.user,
                    _textController.text,
                    Type.text,
                  );
                  _textController.text = '';
                } else {
                  APIs.sendMessage(
                    widget.user,
                    _textController.text,
                    Type.text,
                  );
                  _textController.text = '';
                }
              }
            },
            minWidth: 0,
            padding: const EdgeInsets.only(
              top: 10,
              bottom: 10,
              right: 5,
              left: 10,
            ),
            shape: const CircleBorder(),
            color: Colors.green,
            child: Icon(Icons.send, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}
