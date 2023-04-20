import 'dart:ffi';
import 'dart:io';

import 'package:chatapp/constants/app_constant.dart';
import 'package:chatapp/constants/firebase_constants.dart';
import 'package:chatapp/models/chat_user.dart';
import 'package:chatapp/providers/profile_provider.dart';
import 'package:chatapp/widgets/loading_view.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  TextEditingController? displayNameController;
  TextEditingController? aboutMeController;
  final TextEditingController _phoneController = TextEditingController();

  late String currentUserId;
  String dialCodeDigits = '+00';
  String id = '';
  String displayName = '';
  String photoUrl = '';
  String phoneNumber = '';
  String aboutMe = '';

  bool isLoading = false;
  File? avatarImageFile;
  late ProfileProvider profileProvider;

  final FocusNode focusNodeNickname = FocusNode();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    profileProvider = context.read<ProfileProvider>();
    readLocal();
  }

  void readLocal() {
    setState(() {
      id = profileProvider.getPrefs(FirestoreConstants.id) ?? "";
      displayName =
          profileProvider.getPrefs(FirestoreConstants.displayName) ?? "";

      photoUrl = profileProvider.getPrefs(FirestoreConstants.photoUrl) ?? "";
      phoneNumber =
          profileProvider.getPrefs(FirestoreConstants.phoneNumber) ?? "";
      aboutMe = profileProvider.getPrefs(FirestoreConstants.aboutMe) ?? "";
    });
    displayNameController = TextEditingController(text: displayName);
    aboutMeController = TextEditingController(text: aboutMe);
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();

    XFile? pickedFile = await imagePicker
        .pickImage(source: ImageSource.gallery)
        .catchError((onError) {
      Fluttertoast.showToast(msg: onError.toString());
    });

    File? image;
    if (pickedFile != null) {
      image = File(pickedFile.path);
    }

    if (image != null) {
      setState(() {
        avatarImageFile = image;
        isLoading = true;
      });
      uploadFile();
    }
  }

  Future uploadFile() async {
    String fileName = id;
    UploadTask uploadTask =
        profileProvider.uploadImageFile(avatarImageFile!, fileName);

    try {
      TaskSnapshot snapshot = await uploadTask;
      photoUrl = await snapshot.ref.getDownloadURL();
      ChatUser updateInfo = ChatUser(
          id: id,
          photoUrl: photoUrl,
          displayName: displayName,
          phoneNumber: phoneNumber,
          aboutMe: aboutMe);
      profileProvider
          .updateFirestoreData(
              FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
          .then((value) async {
        await profileProvider.setPrefs(FirestoreConstants.photoUrl, photoUrl);
        setState(() {
          isLoading = false;
        });
      });
    } on FirebaseException catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  void updateFirestoreData() {
    focusNodeNickname.unfocus();
    setState(() {
      isLoading = true;
      if (dialCodeDigits != "+00" && _phoneController.text != "") {
        phoneNumber = dialCodeDigits + _phoneController.text.toString();
      }
    });
    ChatUser updateInfo = ChatUser(
        id: id,
        photoUrl: photoUrl,
        displayName: displayName,
        phoneNumber: phoneNumber,
        aboutMe: aboutMe);
    profileProvider
        .updateFirestoreData(
            FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
        .then((value) async {
      await profileProvider.setPrefs(
          FirestoreConstants.displayName, displayName);
      await profileProvider.setPrefs(
          FirestoreConstants.phoneNumber, phoneNumber);
      await profileProvider.setPrefs(
        FirestoreConstants.photoUrl,
        photoUrl,
      );
      await profileProvider.setPrefs(FirestoreConstants.aboutMe, aboutMe);

      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: 'UpdateSuccess');
    }).catchError((onError) {
      Fluttertoast.showToast(msg: onError.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
        AppConstants.profileTitle,
      )),
      body: Stack(
        children: [
          SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              GestureDetector(
                onTap: getImage,
                child: Container(
                  alignment: Alignment.center,
                  child: avatarImageFile == null
                      ? photoUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                width: 120,
                                height: 120,
                                errorBuilder: (context, object, StackTrace) {
                                  return const Icon(
                                    Icons.account_circle,
                                    size: 90,
                                    color: Colors.grey,
                                  );
                                },
                                loadingBuilder: (BuildContext context,
                                    Widget child,
                                    ImageChunkEvent? loadingProgress) {
                                  if (loadingProgress == null) {
                                    return child;
                                  }
                                  return SizedBox(
                                    width: 90,
                                    height: 90,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.grey,
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.account_circle,
                              size: 90,
                              color: Colors.grey,
                            )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: Image.file(
                            avatarImageFile!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                  margin: EdgeInsets.all(20),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Name",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2a2d43),
                    ),
                  ),
                  TextField(
                    decoration:
                        const InputDecoration(hintText: "Write your name"),
                    controller: displayNameController,
                    onChanged: (value) {
                      displayName = value;
                    },
                    focusNode: focusNodeNickname,
                  ),
                  SizedBox(height: 15),
                  const Text(
                    "About Me...",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2a2d43),
                    ),
                  ),
                  TextField(
                    decoration: const InputDecoration(
                        hintText: "Write about yourself..."),
                    controller: displayNameController,
                    onChanged: (value) {
                      displayName = value;
                    },
                    focusNode: focusNodeNickname,
                  ),
                  SizedBox(height: 15),
                  const Text(
                    "Select Country Code",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2a2d43),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Color.fromARGB(255, 136, 114, 114),
                          width: 1.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CountryCodePicker(
                      onChanged: (country) {
                        setState(() {
                          dialCodeDigits = country.dialCode!;
                        });
                      },
                      initialSelection: 'IN',
                      showCountryOnly: false,
                      showOnlyCountryWhenClosed: false,
                      favorite: const ["+1", "US", "+91", "IN"],
                    ),
                  ),
                  SizedBox(height: 15),
                  const Text(
                    'Phone Number',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2a2d43),
                    ),
                  ),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Phone Number',
                      prefix: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          dialCodeDigits,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    controller: _phoneController,
                    maxLength: 12,
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              ElevatedButton(
                  onPressed: updateFirestoreData,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Update Info"),
                  ))
            ]),
          ),
          Positioned(child: isLoading ? LoadingView() : SizedBox.shrink()),
        ],
      ),
    );
  }
}
