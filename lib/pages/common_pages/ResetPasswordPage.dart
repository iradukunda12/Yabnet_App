import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/supabase/SupabaseConfig.dart';

import '../../components/CustomCircularButton.dart';
import '../../components/CustomEditTextField.dart';
import '../../components/CustomPrimaryButton.dart';
import '../../components/CustomProject.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;

  const ResetPasswordPage({Key? key, required this.email}) : super(key: key);

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  bool passwordAvail = false;
  bool confirmPasswordAvail = false;
  bool passwordChecked = false;
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  WidgetStateNotifier<String> textNotifier =
      WidgetStateNotifier(currentValue: "");
  WidgetStateNotifier<String> secondTextNotifier =
      WidgetStateNotifier(currentValue: "");

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    setLightUiViewOverlay();

    passwordController.addListener(() {
      setState(() {
        passwordAvail = passwordController.text.isNotEmpty;
      });
    });
    confirmPasswordController.addListener(() {
      setState(() {
        confirmPasswordAvail = confirmPasswordController.text.isNotEmpty;
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
    showCustomProgressBar(context);
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;

    if (password != confirmPassword) {
      closeCustomProgressBar(context);
      showToastMobile(msg: "Password does not match");
      return;
    }
    SupabaseConfig.client.auth
        .updateUser(
            UserAttributes(email: widget.email, password: confirmPassword))
        .then((value) {
      showToastMobile(msg: "Password changed. Login again!");
      closeCustomProgressBar(context);
      Navigator.pop(context);
      Navigator.pop(context);
      Navigator.pop(context);
    }).onError((error, stackTrace) {
      showToastMobile(msg: "Password cannot be your last password");
      showDebug(msg: "$error $stackTrace");

      closeCustomProgressBar(context);
    });
  }

  bool enableButtonOnValidateCheck() {
    return passwordAvail &&
        confirmPasswordAvail &&
        passwordChecked &&
        passwordController.text == confirmPasswordController.text;
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
                            "Change Password",
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

                    //  Password TextField
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: CustomEditTextField(
                          controller: passwordController,
                          hintText: "Password",
                          obscureText: true,
                          textNotifier: textNotifier,
                          useShadow: false,
                          textSize: 16),
                    ),

                    //  Confirm Password TextField
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: CustomEditTextField(
                          controller: confirmPasswordController,
                          hintText: "Confirm password",
                          obscureText: true,
                          useShadow: false,
                          textNotifier: secondTextNotifier,
                          textSize: 16),
                    ),

                    WidgetStateConsumer(
                        widgetStateNotifier: secondTextNotifier,
                        widgetStateBuilder: (context, text) {
                          if ((secondTextNotifier.currentValue !=
                                  textNotifier.currentValue) &&
                              text?.isNotEmpty == true) {
                            return Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 6),
                                    child: Text(
                                      "Password does not match",
                                      style: TextStyle(
                                          color: Colors.red, fontSize: 14),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return SizedBox();
                          }
                        }),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: PasswordCheckWidget(
                        customEditTextFieldFormatter:
                            CustomEditTextFieldFormatOptions(
                                hasUpperCase: true,
                                hasLowerCase: true,
                                hasLengthOf: 6,
                                hasNumbers: true,
                                hasSpecialCharacter: true),
                        textNotifier: textNotifier,
                        validated: (bool value) {
                          passwordChecked = value;
                        },
                      ),
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
                                buttonText: "Change Password",
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
