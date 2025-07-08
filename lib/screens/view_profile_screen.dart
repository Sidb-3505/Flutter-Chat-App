import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:we_chat/helper/dialogs.dart';
import 'package:we_chat/helper/my_date_util.dart';
import 'package:we_chat/main.dart';
import 'package:we_chat/models/chat_user.dart';
import 'package:we_chat/network/apis.dart';
import 'package:we_chat/screens/auth/login_screen.dart';

/// view profile screen --> to view profile of a user
class ViewProfileScreen extends StatefulWidget {
  final ChatUser user;
  const ViewProfileScreen({super.key, required this.user});

  @override
  State<ViewProfileScreen> createState() => _ViewProfileScreenState();
}

class _ViewProfileScreenState extends State<ViewProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      /// to hide keyboard
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.user.name,
            style: const TextStyle(
              fontSize: 28,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        /// floating button to show
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Joined On: ',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              MyDateUtil.getLastMessageTime(
                context: context,
                time: widget.user.createdAt,
                showYear: true,
              ),
              style: const TextStyle(fontSize: 18, color: Colors.black87),
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: mq.width * 0.05),
          child: SingleChildScrollView(
            child: Column(
              children: [
                /// for adding some space ///max width
                SizedBox(height: mq.height * .03, width: mq.width),

                ClipRRect(
                  borderRadius: BorderRadius.circular(mq.height * .1),
                  child: CachedNetworkImage(
                    height: mq.height * 0.2,
                    width: mq.height * 0.2,
                    fit: BoxFit.cover,
                    imageUrl: widget.user.image,
                    errorWidget:
                        (context, url, error) =>
                            const CircleAvatar(child: Icon(Icons.person)),
                  ),
                ),
                SizedBox(height: mq.height * .03),

                /// User email label
                Text(
                  widget.user.email,
                  style: const TextStyle(fontSize: 18, color: Colors.black87),
                ),

                /// for adding some space
                SizedBox(height: mq.height * .02),

                ///User About field
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'About: ',
                      style: const TextStyle(
                        fontSize: 17,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      widget.user.about,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),

                /// for adding some space
                SizedBox(height: mq.height * .05),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
