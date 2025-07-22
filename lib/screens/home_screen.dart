import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart%20';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:we_chat/helper/dialogs.dart';
import 'package:we_chat/main.dart';
import 'package:we_chat/models/chat_user.dart';
import 'package:we_chat/network/apis.dart';
import 'package:we_chat/screens/profile_screen.dart';
import 'package:we_chat/widgets/chat_user_card.dart';

class HomeScreen extends StatefulWidget {
  /// Firebase User object to hold user details
  final User user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// for storing users
  final List<ChatUser> _list = [];

  /// for storing searched item
  final List<ChatUser> _searchList = [];

  /// for storing search status
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    APIs.getSelfInfo();

    /// for setting user status according to lifecycle events
    /// resume -- user is online
    /// pause -- user is offline
    SystemChannels.lifecycle.setMessageHandler((message) {
      debugPrint('Message: $message');

      /// only if the user is logged into the application then only to update the status
      if (APIs.auth.currentUser != null) {
        if (message.toString().contains('resume')) {
          APIs.updateActiveStatus(true);
        }
        if (message.toString().contains('pause')) {
          APIs.updateActiveStatus(false);
        }
      }
      return Future.value(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      /// for hiding keyboard when a tap is detected on the screen
      onTap: () => FocusScope.of(context).unfocus(),
      child: PopScope(
        /// if search is on & back button is pressed then close search
        /// or else simple close current screen on back button click
        canPop: false,
        onPopInvokedWithResult: (_, __) {
          if (_isSearching) {
            setState(() => _isSearching = !_isSearching);
            return;
          }

          // some delay before pop
          Future.delayed(
            const Duration(milliseconds: 300),
            SystemNavigator.pop,
          );
        },
        child: Scaffold(
          /// App Bar
          appBar: AppBar(
            leading: Icon(Icons.home_outlined, size: 30),
            title:
                _isSearching
                    ? TextField(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Name, Email...',
                      ),
                      autofocus: true,
                      style: const TextStyle(fontSize: 17, letterSpacing: 0.5),

                      /// when search changes then update search list
                      onChanged: (val) {
                        /// search logic
                        _searchList.clear();

                        for (var i in _list) {
                          if (i.name.toLowerCase().contains(
                                val.toLowerCase(),
                              ) ||
                              i.email.toLowerCase().contains(
                                val.toLowerCase(),
                              )) {
                            _searchList.add(i);
                          }
                          setState(() {
                            _searchList;
                          });
                        }
                      },
                    )
                    : Text('We Chat'),
            actions: [
              /// search user button
              IconButton(
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                  });
                },
                icon: Icon(
                  _isSearching
                      ? CupertinoIcons.clear_circled_solid
                      : Icons.search_outlined,
                  size: 30,
                ),
              ),

              /// more features button
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(user: APIs.me),
                    ),
                  );
                },
                icon: Icon(Icons.more_vert, size: 30),
              ),
            ],
          ),

          ///floating button to add new user
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: FloatingActionButton(
              onPressed: () {
                _addChatUserDialog(context);
              },
              child: const Icon(Icons.person_add),
            ),
          ),

          ///Showing Chats
          body: StreamBuilder(
            stream: APIs.getMyUsersId(),

            /// get id of only known users
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                ///if data is loading
                case ConnectionState.waiting:
                case ConnectionState.none:
                  return Center(child: const CircularProgressIndicator());

                /// if all or some data is loaded then show
                case ConnectionState.active:
                case ConnectionState.done:
                  final docList = snapshot.data?.docs;

                  if (docList == null || docList.isEmpty) {
                    return const Center(
                      child: Text(
                        'No Connections Found',
                        style: TextStyle(fontSize: 20),
                      ),
                    );
                  }
                  return StreamBuilder(
                    stream: APIs.getAllUsers(
                      snapshot.data?.docs.map((e) => e.id).toList() ?? [],
                    ),

                    /// get only those users. whose ids are provided
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        ///if data is loading
                        case ConnectionState.waiting:
                        case ConnectionState.none:
                        // return Center(
                        //   child: const CircularProgressIndicator(),
                        // );

                        /// if all or some data is loaded then show
                        case ConnectionState.active:
                        case ConnectionState.done:
                          final data = snapshot.data?.docs;

                          /// Clear list before adding new data to avoid duplicates
                          _list.clear();

                          /// Convert each document to ChatUser and add to list
                          _list.addAll(
                            data!
                                .map((e) => ChatUser.fromJson(e.data()))
                                .toList(),
                            //e is each document
                            //map() applies this conversion to every document in the list.
                            //chatuser.fromjson : converts JSON to a Dart object.
                            // It returns an Iterable<ChatUser>.
                            //list.addAll(...): Adds all the converted ChatUser objects into your local list
                          );

                          if (_list.isNotEmpty) {
                            return ListView.builder(
                              padding: EdgeInsets.only(top: mq.height * .01),
                              physics: BouncingScrollPhysics(),
                              itemCount:
                                  _isSearching
                                      ? _searchList.length
                                      : _list.length,
                              itemBuilder: (context, index) {
                                return ChatUserCard(
                                  user:
                                      _isSearching
                                          ? _searchList[index]
                                          : _list[index],
                                );
                              },
                            );
                          } else {
                            return Center(
                              child: const Text(
                                'No Connections Found',
                                style: TextStyle(fontSize: 20),
                              ),
                            );
                          }
                      }
                    },
                  );
              }
              return Center(child: CircularProgressIndicator(strokeWidth: 2));
            },
          ),
        ),
      ),
    );
  }

  void _addChatUserDialog(BuildContext parentContext) {
    String email = '';

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
                Icon(Icons.person_add, color: Colors.blue, size: 28),
                Text('  Add User'),
              ],
            ),

            /// content
            content: TextFormField(
              maxLines: null,
              onChanged: (value) => email = value,
              decoration: const InputDecoration(
                hintText: 'Email Id',
                prefixIcon: const Icon(Icons.email, color: Colors.blue),
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
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),

              /// add button
              MaterialButton(
                onPressed: () async {
                  /// Close the dialog only after all updates
                  Navigator.of(dialogContext).pop();
                  if (email.isNotEmpty) {
                    APIs.addChatuser(email).then((value) {
                      if (!value) {
                        Dialogs.showSnackBar(context, 'User does not exists!!');
                      } else {
                        Dialogs.showSnackBar(
                          context,
                          'Email added successfully',
                        );
                      }
                    });
                  } else {
                    Dialogs.showSnackBar(context, 'Email cannot be empty');
                  }
                },
                child: const Text(
                  'Add',
                  style: TextStyle(color: Colors.blue, fontSize: 16),
                ),
              ),
            ],
          ),
    );
  }
}
