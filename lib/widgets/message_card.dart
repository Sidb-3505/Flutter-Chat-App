import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart%20';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:we_chat/helper/dialogs.dart';
import 'package:we_chat/helper/my_date_util.dart';
import 'package:we_chat/main.dart';
import 'package:we_chat/models/message.dart';
import 'package:we_chat/network/apis.dart';

class MessageCard extends StatefulWidget {
  final Message message;
  const MessageCard({super.key, required this.message});

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  @override
  Widget build(BuildContext context) {
    bool isMe = APIs.user.uid == widget.message.fromId;
    return InkWell(
      onLongPress: () {
        _showBottomSheet(isMe);
      },
      child: isMe ? _greenMessage() : _blueMessage(),
    );
  }

  /// sender or another user message
  Widget _blueMessage() {
    /// update last read message if sender and receiver are different
    if (widget.message.read.isEmpty) {
      APIs.updateMessageReadStatus(widget.message);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        /// text message
        Flexible(
          child: Container(
            padding: EdgeInsets.all(mq.width * 0.04),
            margin: EdgeInsets.symmetric(
              horizontal: mq.width * 0.04,
              vertical: mq.height * 0.01,
            ),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 225, 245, 255),
              border: Border.all(color: Colors.lightBlue),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(30),
                topLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child:
                widget.message.type == Type.text
                    /// show text
                    ? Text(
                      widget.message.msg,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    )
                    /// show image
                    : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        fit: BoxFit.cover,
                        imageUrl: widget.message.msg,
                        placeholder:
                            (context, url) => const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        errorWidget:
                            (context, url, error) =>
                                const Icon(Icons.image, size: 70),
                      ),
                    ),
          ),
        ),

        /// message time
        Padding(
          padding: EdgeInsets.all(
            widget.message.type == Type.image
                ? mq.width * 0.03
                : mq.width * 0.04,
          ),
          child: Text(
            MyDateUtil.getFormattedTime(
              context: context,
              time: widget.message.sent,
            ),
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  ///our or user message
  Widget _greenMessage() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        /// message time
        Row(
          children: [
            /// for adding some space
            SizedBox(width: mq.width * .04),

            /// double tick blue icon for message read
            if (widget.message.read.isNotEmpty)
              Icon(Icons.done_all_rounded, color: Colors.blue, size: 20),

            /// for adding some space
            SizedBox(width: 2),

            /// sent time
            Text(
              MyDateUtil.getFormattedTime(
                context: context,
                time: widget.message.sent,
              ),
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),

        /// text message
        Flexible(
          child: Container(
            padding: EdgeInsets.all(
              widget.message.type == Type.image
                  ? mq.width * 0.03
                  : mq.width * 0.04,
            ),
            margin: EdgeInsets.symmetric(
              horizontal: mq.width * 0.04,
              vertical: mq.height * 0.01,
            ),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 218, 255, 176),
              border: Border.all(color: Colors.lightGreen),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(30),
                topLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child:
                widget.message.type == Type.text
                    /// show text
                    ? Text(
                      widget.message.msg,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    )
                    /// show image
                    : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        fit: BoxFit.cover,
                        imageUrl: widget.message.msg,
                        placeholder:
                            (context, url) => const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        errorWidget:
                            (context, url, error) =>
                                const Icon(Icons.image, size: 70),
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  /// bottom sheet for modifying message details
  void _showBottomSheet(bool isMe) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return ListView(
          shrinkWrap: true,
          children: [
            /// black divider
            Container(
              height: 4,
              margin: EdgeInsets.symmetric(
                vertical: mq.height * 0.015,
                horizontal: mq.width * 0.4,
              ),
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            widget.message.type == Type.text
                ?
                /// copy
                _OptionItem(
                  icon: Icon(
                    Icons.copy_all_rounded,
                    size: 26,
                    color: Colors.blue,
                  ),
                  name: 'Copy Text',
                  onTap: () async {
                    Clipboard.setData(
                      ClipboardData(text: widget.message.msg),
                    ).then((value) {
                      /// for hiding bottom sheet
                      Navigator.pop(context);
                      Dialogs.showSnackBar(context, 'Text Copied');
                    });
                  },
                )
                : _OptionItem(
                  icon: Icon(
                    Icons.download_rounded,
                    size: 26,
                    color: Colors.blue,
                  ),
                  name: 'Save Image',
                  onTap: () async {
                    try {
                      await GallerySaver.saveImage(
                        widget.message.msg,
                        albumName: 'We Chat',
                      ).then((success) {
                        /// for hiding bottom sheet
                        Navigator.pop(context);
                        if (success != null && success) {
                          Dialogs.showSnackBar(
                            context,
                            'Image downloaded successfully',
                          );
                        }
                      });
                    } catch (err) {
                      print(err);
                    }
                  },
                ),

            /// seperator / divider
            if (isMe)
              Divider(
                color: Colors.black54,
                endIndent: mq.width * .04,
                indent: mq.width * .04,
              ),

            /// edit
            if (widget.message.type == Type.text && isMe)
              _OptionItem(
                icon: Icon(Icons.edit, size: 26, color: Colors.blue),
                name: 'Edit Message',
                onTap: () {
                  Navigator.pop(context);

                  /// close bottom sheet
                  _showMessageUpdateDialog(context);
                },
              ),

            /// delete
            if (isMe)
              _OptionItem(
                icon: Icon(Icons.delete_forever, size: 26, color: Colors.red),
                name: 'Delete Message',
                onTap: () {
                  APIs.deleteMessage(widget.message).then((value) {
                    /// for hiding bottom sheet
                    Navigator.pop(context);
                  });
                },
              ),

            /// seperator / divider
            Divider(
              color: Colors.black54,
              endIndent: mq.width * .04,
              indent: mq.width * .04,
            ),

            /// sent
            _OptionItem(
              icon: Icon(Icons.remove_red_eye, color: Colors.blue),
              name:
                  'Sent At: ${MyDateUtil.getMessageTime(time: widget.message.sent)}',
              onTap: () {},
            ),

            /// read
            _OptionItem(
              icon: Icon(Icons.remove_red_eye, color: Colors.green),
              name:
                  widget.message.read.isEmpty
                      ? 'Read At: Not seen yet'
                      : 'Read At: ${MyDateUtil.getMessageTime(time: widget.message.read)}',
              onTap: () {},
            ),
          ],
        );
      },
    );
  }

  /// dialog for updating message content
  void _showMessageUpdateDialog(BuildContext parentContext) {
    String updatedMsg = widget.message.msg;

    showDialog(
      context: parentContext,
      builder:
          (dialogContext) => AlertDialog(
            contentPadding: const EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: 10,
            ),

            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),

            /// title
            title: const Row(
              children: [
                Icon(Icons.message, color: Colors.blue, size: 28),
                Text(' Update Message'),
              ],
            ),

            /// content
            content: TextFormField(
              initialValue: updatedMsg,
              maxLines: null,
              onChanged: (value) => updatedMsg = value,
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
              ),
            ),

            /// actions
            actions: [
              /// cancel button
              MaterialButton(
                onPressed: () {
                  /// hide alert dialog
                  Navigator.pop(dialogContext);
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                ),
              ),

              /// update button
              MaterialButton(
                onPressed: () async {
                  await APIs.updateMessage(widget.message, updatedMsg);

                  /// Close the dialog only after all updates
                  Navigator.of(dialogContext).pop();

                  if (mounted) {
                    setState(() {
                      widget.message.msg = updatedMsg;
                    });
                  }
                },
                child: const Text(
                  'Update',
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                ),
              ),
            ],
          ),
    );
  }
}

class _OptionItem extends StatelessWidget {
  final Icon icon;
  final String name;
  final VoidCallback onTap;

  const _OptionItem({
    required this.icon,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(),
      child: Padding(
        padding: EdgeInsets.only(
          left: mq.width * 0.05,
          top: mq.width * 0.015,
          bottom: mq.width * 0.02,
        ),
        child: Row(
          children: [
            icon,
            Flexible(
              child: Text(
                '   $name',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
