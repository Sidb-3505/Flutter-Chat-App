import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
    return APIs.user.uid == widget.message.fromId
        ? _greenMessage()
        : _blueMessage();
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
}
