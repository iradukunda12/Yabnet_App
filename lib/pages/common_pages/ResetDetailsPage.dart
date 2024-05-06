import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/CustomCircularButton.dart';
import '../../components/CustomEditTextField.dart';
import '../../components/CustomPrimaryButton.dart';
import '../../components/CustomProject.dart';
import '../../supabase/SupabaseConfig.dart';
import 'VerificationPage.dart';

class ResetDetailsPage extends StatefulWidget {
  const ResetDetailsPage({Key? key}) : super(key: key);

  @override
  State<ResetDetailsPage> createState() => _ResetDetailsPageState();
}

class _ResetDetailsPageState extends State<ResetDetailsPage> {
  bool userNameAvail = false;
  TextEditingController userNameController = TextEditingController();

  @override
  void dispose() {
    userNameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    setLightUiViewOverlay();

    userNameController.addListener(() {
      setState(() {
        userNameAvail = userNameController.text.isNotEmpty &&
            CustomEditTextFormatter(null)
                .isEmail(userNameController.text.trim());
      });
    });
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
    String email = userNameController.text.trim();
    showCustomProgressBar(context);
    SupabaseConfig.client.auth.resetPasswordForEmail(email).then((value) {
      closeCustomProgressBar(context);
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => VerificationPage(
                  email: email,
                  otpType: OtpType.recovery,
                  verificationType: VerificationType.forget_password,
                )),
      );
    }).onError((error, stackTrace) {
      showToastMobile(msg: "Email rate limit exceeded. Try again later!");

      showDebug(msg: "$error $stackTrace");

      closeCustomProgressBar(context);
    });
  }

  bool enableButtonOnValidateCheck() {
    return userNameAvail;
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
          child: Column(children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Back Button
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                            "Confirm Email",
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
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                                "You will get a code, if the email address is an valid account details to Yabnet members."),
                          ),
                        ),
                      ],
                    ),

                    //  Password TextField
                    const SizedBox(height: 24),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: CustomEditTextField(
                          controller: userNameController,
                          hintText: "Email",
                          obscureText: false,
                          useShadow: false,
                          textSize: 16),
                    ),

                    //  Save Button
                    const SizedBox(
                      height: 50,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: CustomPrimaryButton(
                                buttonText: "Continue",
                                onTap: handleUserInfo,
                                isEnabled: enableButtonOnValidateCheck()),
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
          ]),
        ),
      ),
    );
  }
}
