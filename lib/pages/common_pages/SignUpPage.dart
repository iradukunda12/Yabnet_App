import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/data_notifiers/AppFileServiceData.dart';
import 'package:yabnet/operations/AppFileOperation.dart';

import '../../collections/common_collection/ResourceCollection.dart';
import '../../components/CustomEditTextField.dart';
import '../../components/CustomImageSquareTile.dart';
import '../../components/CustomPrimaryButton.dart';
import '../../components/CustomProject.dart';
import '../../db_references/AppFile.dart';
import '../../main.dart';
import '../../operations/AuthenticationOperation.dart';
import 'InitialPage.dart';
import 'LoginPage.dart';
import 'PdfVieverPage.dart';
import 'VerificationPage.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State createState() {
    return SignUpPageState();
  }
}

class SignUpPageState extends State<SignUpPage> {
  bool userNameAvail = false;
  bool passwordAvail = false;
  bool passwordChecked = false;
  bool accepted = false;
  bool confirmPasswordAvail = false;
  final userNameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  WidgetStateNotifier<String> textNotifier =
      WidgetStateNotifier(currentValue: "");
  WidgetStateNotifier<String> secondTextNotifier =
      WidgetStateNotifier(currentValue: "");

  @override
  void dispose() {
    userNameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    setTransparentUIViewOverlay();
    setFullScreenMode();

    userNameController.addListener(() {
      setState(() {
        userNameAvail = userNameController.text.isNotEmpty &&
            CustomEditTextFormatter(null)
                .isEmail(userNameController.text.trim());
      });
    });

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

  void backPressed(bool something) async {
    hideKeyboard(context);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const CheckAuth()),
      (Route<dynamic> route) => false,
    );
  }

  void onUnsuccessful(Object error) {
    closeCustomProgressBar(context);
    if (error.runtimeType == AuthException) {
      var errorCode = (error as AuthException).message;
      showToastMobile(msg: errorCode);
    } else if (error.runtimeType == TimeoutException) {
      showToastMobile(
          msg:
              "You were timeout under 1 minutes due to something that occurred.");
    } else {
      showToastMobile(msg: "No internet connection");
    }
  }

  void onSignUpComplete(
      AuthResponse response, AppFileServiceData appFileServiceData) {
    closeCustomProgressBar(context);
    if (response.user != null && response.session != null) {
      userNameController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
      backPressed(true);
    } else if ((response.user?.identities?.isNotEmpty ?? false) &&
        response.session == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => VerificationPage(
                  email: userNameController.text.trim(),
                  otpType: OtpType.signup,
                  verificationType: VerificationType.signUp,
                  privacyPolicy: appFileServiceData,
                )),
        (Route<dynamic> route) => false,
      ).then((value) {
        setTransparentUIViewOverlay();
        setFullScreenMode();
      });
    } else {
      showToastMobile(msg: "Accounts exists. Sign in instead.");
    }
  }

  void signUpUsers() async {
    hideKeyboard(context);
    showCustomProgressBar(context, cancelTouch: true);

    var isEmail = userNameController.text.contains("@");
    var passwordMatch =
        passwordController.text.trim() == confirmPasswordController.text.trim();

    // Making sure it is an email
    if (isEmail && passwordMatch) {
      var email = userNameController.text.trim();
      var password = passwordController.text.trim();

      AppFileOperation().fetchParticularAppFile(AppFile.pp).then((value) {
        if (value != null) {
          AppFileServiceData appFileServiceData =
              AppFileServiceData.fromOnline(value);
          AuthenticationOperation().signUpWithEmail(email, password).listen(
              (event) {
            onSignUpComplete(event, appFileServiceData);
          }, onError: onUnsuccessful);
        } else {
          showToastMobile(msg: "An error has occurred");
        }
      }).onError((error, stackTrace) {
        closeCustomProgressBar(context);
        showToastMobile(msg: "An error has occurred");
        showDebug(msg: "$error $stackTrace");
      });
    } else if (!passwordMatch && isEmail) {
      // Display Password Match Problem
      closeCustomProgressBar(context);
      showToastMobile(msg: "Passwords don't match");
    } else if (!isEmail && passwordMatch) {
      //  Display UnRecognized Email
      closeCustomProgressBar(context);
      showToastMobile(msg: "You have entered a wrong email format");
    } else {
      closeCustomProgressBar(context);
      showToastMobile(msg: "Please check your details.");
    }
  }

  bool enableButtonOnValidateCheck() {
    return userNameAvail &&
        passwordAvail &&
        confirmPasswordAvail &&
        passwordChecked &&
        accepted &&
        passwordController.text == confirmPasswordController.text;
  }

  void goToLoginPage() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  void onTapPrivacyAndPolicy() {
    showCustomProgressBar(context);
    AppFileOperation().fetchParticularAppFile(AppFile.pp).then((value) {
      closeCustomProgressBar(context);

      if (value != null) {
        AppFileServiceData appFileServiceData =
            AppFileServiceData.fromOnline(value);

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PdfViewerPage(
                      localIdentity: dbReference(AppFile.pp),
                      pdfTitle: 'Privacy Policy',
                      appFileNotifier:
                          WidgetStateNotifier(currentValue: appFileServiceData),
                    ))).then((value) {
          setTransparentUIViewOverlay();
          setFullScreenMode();
        });
      } else {
        showToastMobile(msg: "An error has occurred");
      }
    }).onError((error, stackTrace) {
      closeCustomProgressBar(context);
      showToastMobile(msg: "An error has occurred");
      showDebug(msg: "$error $stackTrace");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.grey.shade200,
      body: PopScope(
        onPopInvoked: backPressed,
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    height: getScreenHeight(context) * 0.5,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            ResourceCollection.logonImage,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned.fill(
                            child: Container(
                          color: Colors.black.withOpacity(0.6),
                        ))
                      ],
                    ),
                  ),
                  SizedBox(
                    height: getScreenHeight(context) * 0.5,
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: getScreenHeight(context) * 0.2,
                        alignment: Alignment.bottomCenter,
                        child: Image.asset(
                          ResourceCollection.textImage,
                          fit: BoxFit.cover,
                          height: 65,
                        ),
                      ),

                      SizedBox(
                        height: 4,
                      ),
                      Row(
                        children: [
                          Expanded(
                              child: Text(
                            "Connect, Elevate, Travel",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          )),
                        ],
                      ),

                      //  Hello Text
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text("Register",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold)),
                      ),

                      // Welcome Text
                      const SizedBox(height: 48),

                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: getScreenWidth(context) * 0.05),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: CustomEditTextField(
                                    controller: userNameController,
                                    hintText: "Email",
                                    obscureText: false,
                                    useShadow: false,
                                    textSize: 16),
                              ),

                              //  Password TextField
                              const SizedBox(height: 16),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                      vertical: 6),
                                              child: Text(
                                                "Password does not match",
                                                style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 14),
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
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

                              //  SignIn Button
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24),
                                      child: CustomPrimaryButton(
                                          buttonText: "Sign Up",
                                          onTap: signUpUsers,
                                          isEnabled:
                                              enableButtonOnValidateCheck()),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(
                                height: 16,
                              ),

                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: accepted,
                                      onChanged: (newValue) {
                                        setState(() {
                                          accepted = newValue!;
                                        });
                                      },
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: onTapPrivacyAndPolicy,
                                        child: Text(
                                          "I read and accepted the Privacy Policy",
                                          style: TextStyle(
                                            decoration:
                                                TextDecoration.underline,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      //  Or Continue with Text
                      const SizedBox(height: 36),
                      if (2 == 4)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              //  First Divider

                              Expanded(
                                  child: Divider(
                                      thickness: 0.5,
                                      color: Color(getGreyTextColor))),

                              //  Text

                              SizedBox(width: 4),
                              Text(
                                "Or continue using",
                                style: TextStyle(
                                  color: Color(getGreyTextColor),
                                ),
                              ),
                              SizedBox(width: 4),
                              //  First Divider

                              Expanded(
                                  child: Divider(
                                      thickness: 0.5,
                                      color: Color(getGreyTextColor)))
                            ],
                          ),
                        ),

                      //  Google and Apple Continued

                      const SizedBox(height: 40),
                      if (2 == 4)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                color: Colors.white),
                            padding: EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Google Continued
                                CustomImageSquareTile(
                                    onTap: () {},
                                    defaultColor: const Color(getGridGreyColor),
                                    clickedColor: const Color(getGridGreyColor)
                                        .withOpacity(0.4),
                                    imagePath:
                                        ResourceCollection.facebookImage),
                                const SizedBox(width: 25),

                                // Apple Continued
                                CustomImageSquareTile(
                                    onTap: () {},
                                    defaultColor: const Color(getGridGreyColor),
                                    clickedColor: const Color(getGridGreyColor)
                                        .withOpacity(0.4),
                                    imagePath: ResourceCollection.xImage),
                              ],
                            ),
                          ),
                        ),

                      //  Sign up
                      const SizedBox(height: 40),

                      GestureDetector(
                        onTap: goToLoginPage,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: RichText(
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    text: const TextSpan(children: [
                                      TextSpan(
                                        text: "Already a member? ",
                                        style: TextStyle(
                                            color: Color(
                                              getDarkGreyColor,
                                            ),
                                            fontSize: 16),
                                      ),
                                      TextSpan(
                                        text: "Login here",
                                        style: TextStyle(
                                            color: Color(
                                              getTextLightBlueColor,
                                            ),
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ])),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Bottom Padding
                      const SizedBox(height: 70),

                      // const Spacer()
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
