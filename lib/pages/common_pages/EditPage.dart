import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/data/UserData.dart';
import 'package:yabnet/data_notifiers/ProfileNotifier.dart';

import '../../components/CustomCircularButton.dart';
import '../../components/CustomEditTextField.dart';
import '../../components/CustomPrimaryButton.dart';
import '../../components/CustomProject.dart';
import '../../data/ProfessionData.dart';
import '../../operations/MembersOperation.dart';

class EditPage extends StatefulWidget {
  const EditPage({Key? key}) : super(key: key);

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  bool firstNameAvail = false;
  bool lastNameAvail = false;
  String bioAvail = "";
  bool addressAvail = false;
  bool churchChange = false;
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final bioController = TextEditingController();
  final addressController = TextEditingController();
  final churchController = TextEditingController();
  TextEditingController locationSearchController = TextEditingController();
  TextEditingController countryCodeSearchController = TextEditingController();
  List<ProfessionData> cachedProfessionField = [];
  WidgetStateNotifier<UserData> dataNotifier = WidgetStateNotifier();
  StreamSubscription? streamSubscription;

  @override
  void dispose() {
    streamSubscription?.cancel;
    streamSubscription == null;
    firstNameController.dispose();
    lastNameController.dispose();
    addressController.dispose();
    churchController.dispose();
    locationSearchController.dispose();
    countryCodeSearchController.dispose();
    super.dispose();
  }

  UserData? userData;

  @override
  void initState() {
    super.initState();

    handleUserData(ProfileNotifier().state.currentValue);

    streamSubscription ??=
        ProfileNotifier().state.stream.listen(handleUserData);

    firstNameController.addListener(() {
      setState(() {
        firstNameAvail = firstNameController.text.trim() !=
            userData?.fullName.split(" ").last;
      });
    });
    lastNameController.addListener(() {
      setState(() {
        lastNameAvail = lastNameController.text.trim() !=
            userData?.fullName.split(" ").first;
      });
    });
    addressController.addListener(() {
      setState(() {
        addressAvail = addressController.text.trim() != userData?.location;
      });
    });
    bioController.addListener(() {
      setState(() {
        bioAvail = bioController.text;
      });
    });
    churchController.addListener(() {
      setState(() {
        churchChange = churchController.text.trim() != userData?.church;
      });
    });
  }

  void handleUserData(UserData? currentValue) {
    userData = currentValue;
    if (userData != null && mounted) {
      dataNotifier.sendNewState(userData);
      lastNameController.text = userData!.fullName.split(" ").first.trim();
      firstNameController.text = userData!.fullName.split(" ").last.trim();
      addressController.text = userData!.location;
      churchController.text = userData!.church;
      bioController.text = userData!.bio ?? '';
      bioAvail = bioController.text;
    }
  }

  void backPressed(bool isSomething) async {}

  String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('dd - MM - yyyy');
    return formatter.format(dateTime);
  }

  String capitalizeString(String value) {
    if (value.isEmpty) {
      return "";
    }

    String firstChar = value[0].toUpperCase();
    String restOfString = "";

    if (value.length > 2) {
      restOfString = value.substring(1, value.length);
    } else if (value.length == 2) {
      restOfString = value.substring(1);
    }

    return (firstChar + restOfString).trim();
  }

  void handleUserInfo() async {
    hideKeyboard(context);
    showCustomProgressBar(context);
    String firstName = capitalizeString(firstNameController.text);
    String lastName = capitalizeString(lastNameController.text);
    String address = addressController.text;
    String church = churchController.text;
    String bio = bioController.text;
    String? id = userData?.userId;

    if (id == null) {
      showToastMobile(msg: "An error occurred.");
      return;
    }
    MembersOperation()
        .updateUserRecordBothOnlineAndLocal(
      id,
      lastName,
      firstName,
      bio,
      address,
      church,
      address,
    )
        .then((saved) {
      closeCustomProgressBar(context);

      showToastMobile(msg: "Successfully saved your information.");
    }).onError((error, stackTrace) {
      closeCustomProgressBar(context);
      showToastMobile(msg: "Unable to save information at the moment.");
    });
  }

  bool enableButtonOnValidateCheck() {
    return firstNameAvail ||
        lastNameAvail ||
        addressAvail ||
        churchChange ||
        bioAvail.isNotEmpty;
  }

  void performBackPressed() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PopScope(
        onPopInvoked: backPressed,
        child: SafeArea(
          child: WidgetStateConsumer(
              widgetStateNotifier: dataNotifier,
              widgetStateBuilder: (context, data) {
                UserData? userData = data;

                if (userData == null) {
                  return SizedBox();
                }

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // Back Button
                            const SizedBox(height: 20),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(children: [
                                CustomCircularButton(
                                  imagePath: null,
                                  iconColor: Colors.black,
                                  onPressed: performBackPressed,
                                  icon: Icons.arrow_back,
                                  width: 40,
                                  height: 40,
                                  iconSize: 30,
                                  mainAlignment: Alignment.center,
                                  defaultBackgroundColor: Colors.transparent,
                                  clickedBackgroundColor: Colors.white,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                const Expanded(
                                  child: Text(
                                    "Edit Profile",
                                    textScaleFactor: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ]),
                            ),

                            const SizedBox(
                              height: 16,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: CustomEditTextField(
                                  capitalization: TextCapitalization.words,
                                  keyboardType: TextInputType.text,
                                  controller: firstNameController,
                                  hintText: "Firstname",
                                  obscureText: false,
                                  useShadow: false,
                                  textSize: 16),
                            ),

                            //  Last Name Text
                            const SizedBox(
                              height: 16,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: CustomEditTextField(
                                  capitalization: TextCapitalization.words,
                                  keyboardType: TextInputType.text,
                                  controller: lastNameController,
                                  hintText: "Lastname",
                                  obscureText: false,
                                  useShadow: false,
                                  textSize: 16),
                            ),

                            //  Bio Text
                            const SizedBox(
                              height: 16,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: CustomEditTextField(
                                  capitalization: TextCapitalization.words,
                                  keyboardType: TextInputType.text,
                                  controller: bioController,
                                  hintText: "Bio",
                                  maxLength: 80,
                                  minLine: 3,
                                  obscureText: false,
                                  useShadow: false,
                                  textSize: 16),
                            ),

                            //  Address Text
                            const SizedBox(
                              height: 16,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: CustomEditTextField(
                                  controller: addressController,
                                  hintText: "Address",
                                  useShadow: false,
                                  obscureText: false,
                                  textSize: 16),
                            ),

                            //  Church
                            const SizedBox(
                              height: 16,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: CustomEditTextField(
                                  capitalization: TextCapitalization.words,
                                  controller: churchController,
                                  hintText: "Church",
                                  obscureText: false,
                                  useShadow: false,
                                  textSize: 16),
                            ),

                            // Profession Field

                            SizedBox(
                              height: 16,
                            ),

                            //  Save Button
                            const SizedBox(
                              height: 50,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24),
                                    child: CustomPrimaryButton(
                                        buttonText: "Save",
                                        onTap: handleUserInfo,
                                        isEnabled:
                                            enableButtonOnValidateCheck()),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 50,
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                );
              }),
        ),
      ),
    );
  }
}
