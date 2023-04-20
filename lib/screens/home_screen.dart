import 'dart:async';
// import 'dart:html';

import 'package:chatapp/constants/firebase_constants.dart';
import 'package:chatapp/models/chat_user.dart';
import 'package:chatapp/providers/home_provider.dart';
import 'package:chatapp/screens/chat_page.dart';
import 'package:chatapp/screens/login_screen.dart';
import 'package:chatapp/screens/profile_page.dart';
import 'package:chatapp/utils/keyboard_utils.dart';
import 'package:chatapp/widgets/loading_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chatapp/providers/auth_provider.dart';
import 'package:flutter/rendering.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final ScrollController scrollController = ScrollController();

  String _textSearch = "";
  int _limit = 20;
  final _limitIncrement = 20;
  bool isLoading = false;

  late AuthProvider authProvider;
  late String currentUserId;
  late HomeProvider homeProvider;

  // final firebaseFirestore = FirebaseFirestore.instance;

  Future<void> googleSignOut() async {
    authProvider.googleSignOut();
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }

  void scrollListener() {
    if (scrollController.offset >= scrollController.position.maxScrollExtent &&
        !scrollController.position.outOfRange) {
      setState(() {
        _limit += _limitIncrement;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    authProvider = context.read<AuthProvider>();
    homeProvider = context.read<HomeProvider>();

    if (authProvider.getFirebaseUserId()!.isNotEmpty == true) {
      currentUserId = authProvider.getFirebaseUserId()!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }

    scrollController.addListener(scrollListener);
  }

  @override
  void dispose() {
    super.dispose();
    buttonClearController.close();
  }

  StreamController<bool> buttonClearController = StreamController<bool>();
  TextEditingController searchTextEditingController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 6, 53, 91),
        centerTitle: true,
        elevation: 0,
        title: Text("Smart Talk"),
        actions: [
          IconButton(
            onPressed: () => googleSignOut(),
            icon: Icon(Icons.logout),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()));
            },
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: Container(
        child: Column(
          children: [
            buildSearchBar(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    HomeProvider(firebaseFirestore: FirebaseFirestore.instance)
                        .getFirestoreData(FirestoreConstants.pathUserCollection,
                            _limit, _textSearch),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasData) {
                    if ((snapshot.data?.docs.length ?? 0) > 0) {
                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) =>
                            buildItem(context, snapshot.data?.docs[index]),
                        controller: scrollController,
                        separatorBuilder: (BuildContext context, int index) =>
                            const Divider(),
                      );
                    } else {
                      return Center(
                        child: Text("No user found..."),
                      );
                    }
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            ),
            Positioned(
              child: isLoading ? const LoadingView() : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: TextFormField(
        textInputAction: TextInputAction.search,
        controller: searchTextEditingController,
        onChanged: (value) {
          if (value.isEmpty) {
            buttonClearController.add(true);
            setState(() {
              _textSearch = value;
            });
          } else {
            buttonClearController.add(false);
            setState(() {
              _textSearch = "";
            });
          }
        },
        decoration: InputDecoration(
          // labelText: "Search",
          hintText: "Search hare...",
          prefixIcon: Icon(Icons.person_search),
          suffixIcon: IconButton(
            onPressed: () {
              searchTextEditingController.clear();
              buttonClearController.add(false);
              setState(() {
                _textSearch = '';
              });
            },
            icon: Icon(
              Icons.clear,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(25.0),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildItem(BuildContext context, DocumentSnapshot? documentSnapshot) {
    final firebaseAuth = FirebaseAuth.instance;
    if (documentSnapshot != null) {
      ChatUser userChat = ChatUser.fromDocument(documentSnapshot);
      if (userChat.id == currentUserId) {
        return SizedBox.shrink();
      } else {
        return TextButton(
          onPressed: () {
            if (KeyboardUtils.isKeyboardShowing()) {
              KeyboardUtils.closeKeyboard(context);
            }
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    peerId: userChat.id,
                    peerAvatar: userChat.photoUrl,
                    peerNickname: userChat.displayName,
                    userAvatar: firebaseAuth.currentUser!.photoURL!,
                  ),
                ));
          },
          child: ListTile(
            leading: userChat.photoUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Image.network(
                      userChat.photoUrl,
                      fit: BoxFit.cover,
                      width: 50,
                      height: 50,
                      loadingBuilder: (BuildContext context, Widget child,
                          ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        } else {
                          return SizedBox(
                            height: 50,
                            width: 50,
                            child: CircularProgressIndicator(
                              color: Colors.grey,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        }
                      },
                      errorBuilder: (context, object, StackTrace) {
                        return Icon(Icons.account_circle, size: 50);
                      },
                    ),
                  )
                : const Icon(
                    Icons.account_circle,
                    size: 50,
                  ),
            title: Text(
              userChat.displayName,
              style: const TextStyle(color: Colors.black),
            ),
          ),
        );
      }
    } else {
      return SizedBox.shrink();
    }
  }
}

  // Widget buildSearchBar() {
  //   return Container(
  //     margin: const EdgeInsets.all(8),
  //     height: 50,
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(30),
  //       color: Colors.white,
  //       border: Border.all(
  //         color: Colors.black,
  //         style: BorderStyle.solid,
  //         width: 1.0,
  //       ),
  //     ),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.center,
  //       children: [
  //         const SizedBox(
  //           width: 10,
  //         ),
  //         const Icon(
  //           Icons.person_search,
  //           // color: AppColors.white,
  //           size: 24,
  //         ),
  //         const SizedBox(
  //           width: 5,
  //         ),
  //         Expanded(
  //           child: TextFormField(
  //             textInputAction: TextInputAction.search,
  //             controller: searchTextEditingController,
  //             onChanged: (value) {
  //               if (value.isNotEmpty) {
  //                 buttonClearController.add(true);
  //                 setState(() {
  //                   _textSearch = value;
  //                 });
  //               } else {
  //                 buttonClearController.add(false);
  //                 setState(() {
  //                   _textSearch = "";
  //                 });
  //               }
  //             },
  //             decoration: const InputDecoration.collapsed(
  //               hintText: 'Search here...',
  //               // hintStyle: TextStyle(color: Colors.amber),
  //             ),
  //           ),
  //         ),
  //         StreamBuilder(
  //           stream: buttonClearController.stream,
  //           builder: (context, snapshot) {
  //             return snapshot.data == true
  //                 ? GestureDetector(
  //                     onTap: () {
  //                       searchTextEditingController.clear();
  //                       buttonClearController.add(false);
  //                       setState(() {
  //                         _textSearch = "";
  //                       });
  //                     },
  //                     child: Icon(Icons.clear_rounded),
  //                   )
  //                 : SizedBox.shrink();
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }