import 'dart:io';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:smart_talk/allConstants/all_constants.dart';
import 'package:smart_talk/allConstants/app_constants.dart';
import 'package:smart_talk/allWidgets/common_widgets.dart';
import 'package:smart_talk/models/user_chat.dart';
import 'package:smart_talk/providers/settings_provider.dart';


class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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
  late SettingsProvider settingsProvider;

  final FocusNode focusNodeNickname = FocusNode();

  @override
  void initState() {
    super.initState();
    settingsProvider = context.read<SettingsProvider>();
    readLocal();
  }

  void readLocal() {
    setState(() {
      id = settingsProvider.getPrefs(FirestoreConstants.id) ?? "";
      displayName = settingsProvider.getPrefs(FirestoreConstants.displayName) ?? "";

      photoUrl = settingsProvider.getPrefs(FirestoreConstants.photoUrl) ?? "";
      phoneNumber =
          settingsProvider.getPrefs(FirestoreConstants.phoneNumber) ?? "";
      aboutMe = settingsProvider.getPrefs(FirestoreConstants.aboutMe) ?? "";
    });
    displayNameController = TextEditingController(text: displayName);
    aboutMeController = TextEditingController(text: aboutMe);
  }

  Future getImage() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? pickedFile = await imagePicker
        .pickImage(source: ImageSource.gallery)
        .catchError((onError) {
      Fluttertoast.showToast(msg: onError.toString())
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
    UploadTask uploadTask = settingsProvider.uploadFile(
        avatarImageFile!, fileName);
    try {
      TaskSnapshot snapshot = await uploadTask;
      photoUrl = await snapshot.ref.getDownloadURL();
      UserChat updateInfo = UserChat(id: id,
          photoUrl: photoUrl,
          displayName: displayName,
          phoneNumber: phoneNumber,
          aboutMe: aboutMe);
      settingsProvider.updateFirestoreData(
          FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
          .then((value) async {
        await settingsProvider.setPrefs(FirestoreConstants.photoUrl, photoUrl);
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

  void handleUpdateData() {
    focusNodeNickname.unfocus();
    setState(() {
      isLoading = true;
      if (dialCodeDigits != "+00" && _phoneController.text != "") {
        phoneNumber = dialCodeDigits + _phoneController.text.toString();
      }
    });
    UserChat updateInfo = UserChat(id: id,
        photoUrl: photoUrl,
        displayName: displayName,
        phoneNumber: phoneNumber,
        aboutMe: aboutMe);
    settingsProvider.updateFirestoreData(
        FirestoreConstants.pathUserCollection, id, updateInfo.toJson())
        .then((value) async {
      await settingsProvider.setPrefs(
          FirestoreConstants.displayName, displayName);
      await settingsProvider.setPrefs(
          FirestoreConstants.phoneNumber, phoneNumber);
      await settingsProvider.setPrefs(
        FirestoreConstants.photoUrl, photoUrl,);
      await settingsProvider.setPrefs(
          FirestoreConstants.aboutMe,aboutMe );

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
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text(
              AppConstants.settingsTitle,
            ),
          ),
          body: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: getImage,
                    child: Container(
                      alignment: Alignment.center,
                      child: avatarImageFile == null ? photoUrl.isNotEmpty ?
                      ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: Image.network(photoUrl,
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                          errorBuilder: (context, object, stackTrace) {
                            return const Icon(Icons.account_circle, size: 90,
                              color: AppColors.greyColor,);
                          },
                          loadingBuilder: (BuildContext context, Widget child,
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
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes! : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ) : const Icon(Icons.account_circle,
                        size: 90,
                        color: AppColors.greyColor,)
                          : ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: Image.file(avatarImageFile!, width: 120,
                          height: 120,
                          fit: BoxFit.cover,),),
                      margin: const EdgeInsets.all(20),
                    ),),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Name', style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        color: AppColors.spaceCadet,
                      ),),
                      TextField(
                        decoration: kTextInputDecoration.copyWith(
                            hintText: 'Write your Name'),
                        controller: displayNameController,
                        onChanged: (value) {
                          displayName = value;
                        },
                        focusNode: focusNodeNickname,
                      ),
                      vertical15,
                      const Text('About Me...', style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        color: AppColors.spaceCadet
                      ),),
                      TextField(
                        decoration: kTextInputDecoration.copyWith(
                            hintText: 'Write about yourself...'),
                        onChanged: (value) {
                          aboutMe = value;
                        },
                      ),
                      vertical15,
                      const Text('Select Country Code', style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        color: AppColors.spaceCadet,
                      ),),
                      Container(
                        width: double.infinity,
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 1.5),
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
                      vertical15,
                      const Text('Phone Number', style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        color: AppColors.spaceCadet,
                      ),),
                      TextField(
                        decoration: kTextInputDecoration.copyWith(
                          hintText: 'Phone Number',
                          prefix: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(dialCodeDigits,
                              style: const TextStyle(color: Colors.grey),),
                          ),
                        ),
                        controller: _phoneController,
                        maxLength: 12,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                  ElevatedButton(onPressed: handleUpdateData, child:const Padding(
                    padding:  EdgeInsets.all(8.0),
                    child:  Text('Update Info'),
                  )),

                ],
              ),
            ),

        ),
        Center(child: buildLoading(isLoading? const CircularProgressIndicator() : const SizedBox.shrink())),
      ],
    );
  }
}