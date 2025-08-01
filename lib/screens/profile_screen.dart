import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:we_chat/helper/dialogs.dart';
import 'package:we_chat/main.dart';
import 'package:we_chat/models/chat_user.dart';
import 'package:we_chat/network/apis.dart';
import 'package:we_chat/screens/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final ChatUser user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _image;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      /// to hide keyboard
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: Text('Profile Screen')),

        /// floating button to logout from the application
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: FloatingActionButton.extended(
            backgroundColor: Colors.redAccent,
            onPressed: () async {
              /// showing progress dialog
              Dialogs.showProgressIndicator(context);

              /// to show user status as offline when he logs out
              await APIs.updateActiveStatus(false);

              /// sign out from app
              await APIs.auth.signOut().then((value) async {
                await GoogleSignIn().signOut().then((value) {
                  /// for hiding progress dialog
                  Navigator.pop(context);

                  /// for moving to home screen
                  Navigator.pop(context);

                  /// to make the app not store the instance of old auth
                  APIs.auth = FirebaseAuth.instance;

                  /// for moving to login screen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  );
                });
              });
            },
            icon: const Icon(Icons.logout, color: Colors.white, size: 25),
            label: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontSize: 21),
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: mq.width * 0.05),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  /// for adding some space ///max width
                  SizedBox(height: mq.height * .03, width: mq.width),

                  Stack(
                    children: [
                      _image != null
                          /// selected profile picture
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(mq.height * .1),
                            child: Image.file(
                              File(_image!),
                              height: mq.height * 0.2,
                              width: mq.height * 0.2,
                              fit: BoxFit.cover,
                            ),
                          )
                          :
                          /// user profile picture
                          ClipRRect(
                            borderRadius: BorderRadius.circular(mq.height * .1),
                            child: CachedNetworkImage(
                              height: mq.height * 0.2,
                              width: mq.height * 0.2,
                              fit: BoxFit.cover,
                              imageUrl: widget.user.image,
                              errorWidget:
                                  (context, url, error) => const CircleAvatar(
                                    child: Icon(Icons.person),
                                  ),
                            ),
                          ),

                      /// edit image button
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: MaterialButton(
                          elevation: 1,
                          onPressed: () {
                            _showBottomSheet();
                          },
                          shape: const CircleBorder(),
                          color: Colors.white,
                          child: const Icon(
                            Icons.edit,
                            size: 30,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: mq.height * .03),

                  /// User email label
                  Text(
                    widget.user.email,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),

                  /// for adding some space
                  SizedBox(height: mq.height * .05),

                  /// User Name Input field
                  TextFormField(
                    initialValue: widget.user.name,
                    onSaved: (val) => widget.user.name = val ?? '',
                    validator:
                        (val) =>
                            val != null && val.isNotEmpty
                                ? null
                                : 'Required Field',
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      label: Text('Name'),
                      hintText: 'eg. Happy Singh',
                    ),
                  ),

                  /// for adding some space
                  SizedBox(height: mq.height * .02),

                  ///User About field
                  TextFormField(
                    initialValue: widget.user.about,
                    onSaved: (val) => widget.user.about = val ?? '',
                    validator:
                        (val) =>
                            val != null && val.isNotEmpty
                                ? null
                                : 'Required Field',
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.info_outline, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      label: Text('About'),
                      hintText: 'eg. Happy Singh',
                    ),
                  ),

                  /// for adding some space
                  SizedBox(height: mq.height * .05),

                  /// User Details Update button
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        APIs.updateUserInfo().then((value) {
                          Dialogs.showSnackBar(
                            context,
                            'Details Updated Successfully',
                          );
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: StadiumBorder(),
                      minimumSize: Size(mq.width * 0.5, mq.height * 0.06),
                    ),
                    icon: Icon(Icons.edit, color: Colors.white, size: 28),
                    label: Text(
                      'UPDATE',
                      style: TextStyle(fontSize: 25, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// bottom sheet for picking profile pic for user
  void _showBottomSheet() {
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
          padding: EdgeInsets.only(
            top: mq.height * .03,
            bottom: mq.height * .05,
          ),
          children: [
            /// pick profile picture label
            const Text(
              'Pick Profile Picture',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),

            /// for adding some space
            SizedBox(height: mq.height * .02),

            /// buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                /// pick from gallery button
                ElevatedButton(
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();

                    /// Pick an image.
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );
                    if (image != null) {
                      /// setting selected image path
                      setState(() {
                        _image = image.path;
                      });

                      /// updating the profile in realtime database
                      APIs.updateProfilePicture(File(_image!));

                      /// for hiding bottom sheet
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                    fixedSize: Size(mq.width * 0.3, mq.height * 0.15),
                  ),
                  child: Image.asset('images/add_image.png'),
                ),

                /// pick image from camera button
                ElevatedButton(
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();

                    /// Pick an image.
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                      imageQuality: 80,
                    );
                    if (image != null) {
                      /// setting selected image path
                      setState(() {
                        _image = image.path;
                      });

                      /// updating the profile in realtime database
                      APIs.updateProfilePicture(File(_image!)).then((value) {
                        Dialogs.showSnackBar(
                          context,
                          'Profile Updated Successfully, Wait for a while',
                        );
                      });

                      /// for hiding bottom sheet
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                    fixedSize: Size(mq.width * 0.3, mq.height * 0.15),
                  ),
                  child: Image.asset('images/camera.png'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
