import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:we_chat/main.dart';
import 'package:we_chat/models/chat_user.dart';
import 'package:we_chat/screens/view_profile_screen.dart';

class ProfileDialog extends StatelessWidget {
  const ProfileDialog({super.key, required this.user});

  final ChatUser user;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        height: mq.height * .35,
        width: mq.width * .6,
        child: Stack(
          children: [
            /// user profile picture
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Align(
                alignment: Alignment.center,
                child: CachedNetworkImage(
                  width: mq.width * 0.5,
                  fit: BoxFit.cover,
                  imageUrl: user.image,
                  errorWidget:
                      (context, url, error) =>
                          const CircleAvatar(child: Icon(Icons.person)),
                ),
              ),
            ),

            /// user name
            Positioned(
              left: mq.width * 0.04,
              top: mq.height * 0.02,
              width: mq.width * 0.55,
              child: Text(
                user.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            /// info button
            Positioned(
              top: 6,
              right: 8,
              child: MaterialButton(
                onPressed: () {
                  /// to remove the current dialog box
                  Navigator.pop(context);

                  /// to move user to user profile screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ViewProfileScreen(user: user),
                    ),
                  );
                },
                minWidth: 0,
                padding: EdgeInsets.all(0),
                shape: CircleBorder(),
                child: Icon(Icons.info_outline, color: Colors.blue, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
