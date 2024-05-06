import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as online_db;
import 'package:yabnet/data_notifiers/AppFileServiceData.dart';
import 'package:yabnet/pages/common_pages/ResetPasswordPage.dart';

import '../../components/CustomCircularButton.dart';
import '../../components/CustomEditTextField.dart';
import '../../components/CustomPrimaryButton.dart';
import '../../components/CustomProject.dart';
import '../../main.dart';
import '../../operations/MembersOperation.dart';
import '../../supabase/SupabaseConfig.dart';
import 'InformationPage.dart';
import 'LoginPage.dart';

enum VerificationType { signUp, forget_password }

class VerificationPage extends StatefulWidget {
  final String email;
  final VerificationType verificationType;
  final online_db.OtpType otpType;
  final AppFileServiceData? privacyPolicy;

  const VerificationPage(
      {Key? key,
      required this.email,
      required this.otpType,
      required this.verificationType,
      this.privacyPolicy = null})
      : super(key: key);

  static const expireIn = 299;

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  TextEditingController otpController = TextEditingController();
  bool enableVerifyButton = false;
  bool hideTimer = false;
  int expiringTime = VerificationPage.expireIn;
  Timer? expiringTimer;

  @override
  void initState() {
    super.initState();

    // Set The navigator and title bar color
    setLightUiViewOverlay();

    startExpiringTimer();
    otpController.addListener(() {
      setState(() {
        enableVerifyButton = otpController.text.length == 6;
      });
    });
  }

  @override
  void dispose() {
    otpController.dispose();
    expiringTimer?.cancel();
    super.dispose();
  }

  void proceedToInformationPage(String uuid) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (context) => InformationPage(
                uuid: uuid,
                privacyPolicy: widget.privacyPolicy!,
              )),
      (Route<dynamic> route) => false,
    );
  }

  void proceedToLoginInPage() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  void verifyTheCodeForChangePassword(String emailAddress) {
    showCustomProgressBar(context);
    String code = otpController.text.trim();

    // Verify OTP and sign in
    SupabaseConfig.client.auth
        .verifyOTP(token: code, type: widget.otpType, email: emailAddress)
        .then((value) async {
      expiringTimer?.cancel();
      expiringTimer = null;
      hideTimer = true;
      expiringTime = VerificationPage.expireIn;

      // Retrieve the user uuid
      String? uuid = SupabaseConfig.client.auth.currentSession?.user.id;
      closeCustomProgressBar(context);
      otpController.clear();
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ResetPasswordPage(email: emailAddress)));
    }).onError((error, stackTrace) {
      if (error is online_db.AuthException && error.statusCode == 403) {
        showToastMobile(msg: "Token is expired, Request a new token!");
      } else {
        showToastMobile(msg: "An error occurred. Try again later!");
        showDebug(msg: "$error $stackTrace");
      }
      closeCustomProgressBar(context);
    });
  }

  void verifyTheCodeForSignUp(String emailAddress) {
    showCustomProgressBar(context);
    String code = otpController.text.trim();

    // Verify OTP and sign in
    SupabaseConfig.client.auth
        .verifyOTP(token: code, type: widget.otpType, email: emailAddress)
        .then((value) async {
      expiringTimer?.cancel();
      expiringTimer = null;
      hideTimer = true;
      expiringTime = VerificationPage.expireIn;

      // Retrieve the user uuid
      String? uuid = SupabaseConfig.client.auth.currentSession?.user.id;

      // Check is there is value
      if (uuid != null) {
        // Check if this user is the verified user to storage or null
        if (!await MembersOperation().userLocalVerificationData(uuid)) {
          // Remove any saved entries for previous user
          MembersOperation().removeExistedUserRecord().then((value) async {
            // Set this user to be the verified user to storage
            await MembersOperation()
                .setUserLocalVerification(uuid)
                .then((value) {
              closeCustomProgressBar(context);
              proceedToInformationPage(uuid);
            }).onError((error, stackTrace) => onContinueVerification());
          }).onError((error, stackTrace) => onContinueVerification());
        } else {
          // Already verified to storage
          closeCustomProgressBar(context);
          proceedToInformationPage(uuid);
        }
      } else {
        // Retrieving uuid failed
        onContinueVerification();
      }
    }).onError((error, stackTrace) {
      closeCustomProgressBar(context);
      otpController.clear();
      if (error is online_db.AuthException) {
        showDebug(msg: error.message);
        showToastMobile(msg: error.message);
      }
    });
  }

  onContinueVerification() async {
    closeCustomProgressBar(context);
    showToastMobile(msg: "Unable to proceed at the moment.");
    proceedToLoginInPage();
  }

  String formatSeconds(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;

    String minutesStr = minutes.toString().padLeft(2, '0');
    String secondsStr = remainingSeconds.toString().padLeft(2, '0');

    return '$minutesStr:$secondsStr';
  }

  void startExpiringTimer() {
    expiringTimer ??= Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        expiringTime--;
      });

      if (expiringTime == 0) {
        hideTimer = true;
        expiringTimer?.cancel();
        expiringTimer = null;
      }
    });
  }

  void handleResendTokenForSignUp() {
    showCustomProgressBar(context);
    if (expiringTime == 0 && expiringTimer == null) {
      SupabaseConfig.client.auth
          .resend(email: widget.email, type: widget.otpType)
          .then((value) {
        otpController.clear();
        closeCustomProgressBar(context);
        showToastMobile(msg: "Resent a new OTP.");
        hideTimer = false;
        expiringTime = VerificationPage.expireIn;
        startExpiringTimer();
      }, onError: (error) {
        closeCustomProgressBar(context);
        showToastMobile(msg: error);
      });
    }
  }

  void handleResendTokenForPasswordReset() {
    showCustomProgressBar(context);
    if (expiringTime == 0 && expiringTimer == null) {
      SupabaseConfig.client.auth.resetPasswordForEmail(widget.email).then(
          (value) {
        otpController.clear();
        closeCustomProgressBar(context);
        showToastMobile(msg: "Resent a new OTP.");
        hideTimer = false;
        expiringTime = VerificationPage.expireIn;
        startExpiringTimer();
      }, onError: (error) {
        closeCustomProgressBar(context);
        showToastMobile(msg: error);
      });
    }
  }

  void performBackPressed() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (widget.verificationType == VerificationType.forget_password)
                  Padding(
                    padding: const EdgeInsets.only(top: 16, left: 24),
                    child: Row(
                      children: [
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
                      ],
                    ),
                  ),
                const SizedBox(
                  width: 8,
                ),
                //  Confirm Text
                const SizedBox(height: 50),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text("Verify your email!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      )),
                ),

                // Confirming Text
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    "Check your email inbox.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(getGreyTextColor),
                      fontSize: 16,
                    ),
                  ),
                ),

                //  Code TextField
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: CustomEditTextField(
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      controller: otpController,
                      hintText: "6-digit numeric code",
                      obscureText: false,
                      useShadow: false,
                      textSize: 16),
                ),

                //  Verify Button
                const SizedBox(
                  height: 32,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: CustomPrimaryButton(
                            buttonText: "Verify",
                            onTap: () {
                              if (widget.verificationType ==
                                  VerificationType.signUp) {
                                verifyTheCodeForSignUp(widget.email);
                              } else if (widget.verificationType ==
                                  VerificationType.forget_password) {
                                verifyTheCodeForChangePassword(widget.email);
                              }
                            },
                            isEnabled: enableVerifyButton),
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    children: [
                      !hideTimer
                          ? Row(
                              children: [
                                Text(
                                  "Expires in ${formatSeconds(expiringTime)}",
                                  style: const TextStyle(
                                      color: Colors.black, fontSize: 15),
                                ),
                              ],
                            )
                          : GestureDetector(
                              onTap: () {
                                if (widget.verificationType ==
                                    VerificationType.signUp) {
                                  handleResendTokenForSignUp();
                                } else if (widget.verificationType ==
                                    VerificationType.forget_password) {
                                  handleResendTokenForPasswordReset();
                                }
                              },
                              child: const Text(
                                "Resend code",
                                style: TextStyle(
                                    color: Color(getTextLightBlueColor),
                                    fontSize: 15),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
