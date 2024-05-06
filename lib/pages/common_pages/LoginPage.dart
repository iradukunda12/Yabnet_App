import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yabnet/collections/common_collection/ResourceCollection.dart';
import 'package:yabnet/components/CustomOnClickContainer.dart';
import 'package:yabnet/firebase/FirebaseConfig.dart';
import 'package:yabnet/services/AppFileService.dart';
import 'package:yabnet/services/UserProfileService.dart';
import 'package:yabnet/supabase/SupabaseConfig.dart';

import '../../components/CustomEditTextField.dart';
import '../../components/CustomImageSquareTile.dart';
import '../../components/CustomPrimaryButton.dart';
import '../../components/CustomProject.dart';
import '../../data_notifiers/AppFileServiceData.dart';
import '../../db_references/AppFile.dart';
import '../../db_references/Members.dart';
import '../../main.dart';
import '../../operations/AuthenticationOperation.dart';
import '../../operations/MembersOperation.dart';
import 'ChoosePlanPage.dart';
import 'InformationPage.dart';
import 'InitialPage.dart';
import 'ResetDetailsPage.dart';
import 'SignUpPage.dart';
import 'VerificationPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  bool userNameAvail = false;
  bool passwordAvail = false;
  final userNameController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    userNameController.dispose();
    passwordController.dispose();
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
        passwordAvail = passwordController.text.isNotEmpty &&
            CustomEditTextFormatter(CustomEditTextFieldFormatOptions(
                    hasUpperCase: true,
                    hasLowerCase: true,
                    hasLengthOf: 6,
                    hasNumbers: true,
                    hasSpecialCharacter: true))
                .validatePassword(passwordController.text);
      });
    });
  }

  void backPressed(bool something) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const CheckAuth()),
      (Route<dynamic> route) => false,
    );
  }

  bool enableButtonOnValidateCheck() {
    return userNameAvail && passwordAvail;
  }

  void onUnsuccessful(Object error) {
    closeCustomProgressBar(context);
    if (error is AuthException) {
      String errorMessage = (error).message.toLowerCase();

      switch (errorMessage) {
        case "email not confirmed":
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => VerificationPage(
                        email: userNameController.text.trim(),
                        otpType: OtpType.signup,
                        verificationType: VerificationType.signUp,
                      )));
          break;

        default:
          showToastMobile(msg: errorMessage);
      }
    } else if (error is TimeoutException) {
      showToastMobile(
          msg:
              "You were timeout under 1 minute due to something that occurred.");
    } else {
      showDebug(msg: "$error");
      showToastMobile(msg: "No internet connection.");
    }
  }

  void proceedToInformationPage(String uuid, AppFileServiceData privacyPolicy) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (context) => InformationPage(
                uuid: uuid,
                privacyPolicy: privacyPolicy,
              )),
      (Route<dynamic> route) => false,
    ).then((value) {
      setTransparentUIViewOverlay();
      setFullScreenMode();
    });
  }

  void goToPlanPage() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => ChoosePlanPage()),
      (Route<dynamic> route) => false,
    );
  }

  void onSignInComplete(AuthResponse response) async {
    showCustomProgressBar(context);
    // Check online record and update to local database
    String sessionCode = MembersOperation().getSessionCode();

    String? fcmToken = FirebaseConfig().getFcmToken;

    if (Platform.isIOS) {
      fcmToken = "ios";
    }

    // if (fcmToken == null) {
    //   closeCustomProgressBar(context);
    //   showToastMobile(msg: "An error occurred");
    //   SupabaseConfig.client.auth.signOut();
    //   return;
    // }

    MembersOperation()
        .userNewSessionAndOnlineRecord(
            SupabaseConfig.client.auth.currentUser?.id ?? '',
            sessionCode,
            fcmToken!)
        .then((userData) async {
      showDebug(msg: userData);
      handleUserData(response, userData);
    }).onError((error, stackTrace) {
      showDebug(msg: "$error $stackTrace");
      handleUserData(response, null);
    });
  }

  void handleUserData(AuthResponse response, dynamic userData) {
    String? uuid = response.user?.id;

    // User data not null
    if (userData != null) {
      // Retrieve the uuid
      // Check if there is a value

      if (userData[dbReference(Members.restricted)] == true) {
        closeCustomProgressBar(context);
        userNameController.clear();
        passwordController.clear();
        UserProfileService().handleRestriction(true, fromLogin: true);
      } else {
        if (uuid != null) {
          // Fetch AppFiles

          AppFileService().fetchAppFiles().then((value) {
            // Clear any saved entries for the new user
            MembersOperation().removeExistedUserRecord().then((removed) {
              // Check if operation was successful
              // Save the user data to storage
              MembersOperation()
                  .saveOnlineUserRecordToLocal(userData, useOther: true)
                  .then((saved) async {
                //  Check if saving operation was success

                if (saved) {
                  // Set this user to be verified to storage
                  MembersOperation()
                      .setUserLocalVerification(uuid)
                      .then((setVerification) {
                    // If user is verified to storage
                    if (setVerification) {
                      // Return to the secondary page.
                      closeCustomProgressBar(context);
                      goToPlanPage();
                    } else {
                      // Verification to storage failed
                      onSignInError(1);
                    }
                  }).onError((error, stackTrace) {
                    onSignInError(2);
                  });
                } else {
                  // Unable to save data
                  onSignInError(3);
                }
              }).onError((error, stackTrace) {
                showDebug(msg: "$error $stackTrace");
                onSignInError(4);
              });
            }).onError((error, stackTrace) => onSignInError(6));
          }).onError((error, stackTrace) => onSignInError(18));
        } else {
          // Retrieving uuid failed
          onSignInError(9);
        }
      }
    } else if (uuid != null) {
      // User data is null
      AppFileServiceData appFileServiceData = AppFileServiceData(
          "appFileId",
          dbReference(AppFile.pp),
          "onlineDirectory",
          null,
          "iosLink",
          "androidLink",
          "fileType", {});
      proceedToInformationPage(uuid, appFileServiceData);
    } else {
      // Retrieving uuid failed
      onSignInError(16);
    }
  }

  Future<Null>? onSignInError(int n) async {
    closeCustomProgressBar(context);
    showToastMobile(msg: "Unable to Sign in at the moment. Code $n");
    AuthenticationOperation().signOut(context);
  }

  void signInUsers() {
    hideKeyboard(context);
    showCustomProgressBar(context, cancelTouch: true);

    var isEmail = userNameController.text.contains("@");

    if (isEmail) {
      String email = userNameController.text.trim();
      String password = passwordController.text.trim();
      AuthenticationOperation().signInWithEmail(email, password).listen(
          (event) {
        closeCustomProgressBar(context);
        if (event.user != null) {
          onSignInComplete(event);
        } else {
          showToastMobile(msg: "Try again!!!");
        }
      }, onError: onUnsuccessful);
    } else {
      showToastMobile(msg: "Check your email address or username.");
      closeCustomProgressBar(context);
    }
  }

  void goToSignUpPage() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignUpPage()),
      (Route<dynamic> route) => false,
    );
  }

  void clickForgetPassword() {
    userNameController.clear();
    passwordController.clear();
    Navigator.push(context,
            MaterialPageRoute(builder: (context) => ResetDetailsPage()))
        .then((value) {
      setTransparentUIViewOverlay();
      setFullScreenMode();
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
                        child: Text("Login",
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
                                    useShadow: false,
                                    textSize: 16),
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
                                          buttonText: "Sign In",
                                          onTap: signInUsers,
                                          isEnabled:
                                              enableButtonOnValidateCheck()),
                                    ),
                                  ),
                                ],
                              ),

                              // Forgot password
                              const SizedBox(height: 12),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24),
                                child: CustomOnClickContainer(
                                  onTap: clickForgetPassword,
                                  defaultColor: Colors.transparent,
                                  clickedColor:
                                      Color(getMainPinkColor).withOpacity(0.1),
                                  padding: EdgeInsets.all(8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Forgot password?",
                                        style: TextStyle(
                                            color: Color(getMainPinkColor)
                                                .withOpacity(0.9)),
                                      )
                                    ],
                                  ),
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
                        onTap: goToSignUpPage,
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
                                        text: "Not a member yet? ",
                                        style: TextStyle(
                                            color: Color(
                                              getDarkGreyColor,
                                            ),
                                            fontSize: 16),
                                      ),
                                      TextSpan(
                                        text: "Register here",
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
