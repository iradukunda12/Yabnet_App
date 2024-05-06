import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/db_references/Members.dart';
import 'package:yabnet/operations/MembersOperation.dart';

import '../../components/CustomProject.dart';
import '../../operations/AuthenticationOperation.dart';
import '../../supabase/SupabaseConfig.dart';
import '../db_references/Profile.dart';
import '../local_navigation_controller.dart';

class UserProfileService {
  static final UserProfileService instance = UserProfileService.internal();

  factory UserProfileService() => instance;

  UserProfileService.internal();

  StreamSubscription? userProfileStreamSubscription;
  StreamSubscription? connectionProfile;
  WidgetStateNotifier<AppLifecycleState> lifeCycleNotifier =
      WidgetStateNotifier(currentValue: AppLifecycleState.resumed);

  String userId = SupabaseConfig.client.auth.currentUser?.id ?? "";

  // Flag For services
  bool beginCheckUserTable = true;

  bool subscriptionValidityIsConfirmed = true;

  bool profilePictureUploading = true;

  bool lifeCycleListening = false;

  void beginService() {
    // Check Company Table
    if (beginCheckUserTable) {
      checkUserTable();
      beginCheckUserTable = false;
    }

    registerConnectionSubscription();
    listenToLifeCycle();
  }

  Future<void> endService() async {
    await userProfileStreamSubscription?.cancel();
    userProfileStreamSubscription = null;
    await connectionProfile?.cancel();
    connectionProfile = null;

    // Flag For services
    beginCheckUserTable = false;
    userId = "";
    subscriptionValidityIsConfirmed = false;

    profilePictureUploading = false;
  }

  void registerConnectionSubscription() {
    if (connectionProfile == null) {
      connectionProfile = Connectivity()
          .onConnectivityChanged
          .listen((ConnectivityResult event) {
        if (event != ConnectivityResult.none) {
          beginService();
        }
      });

      connectionProfile?.onError((error, stackTrace) {
        connectionProfile?.cancel();
        connectionProfile = null;
      });
    }
  }

  void listenToLifeCycle() {
    if (!lifeCycleListening) {
      lifeCycleListening = true;
      lifeCycleNotifier.stream.listen((event) {
        if ((beginCheckUserTable ||
                userProfileStreamSubscription?.isPaused == true) &&
            event == AppLifecycleState.resumed) {
          beginService();
        }
      });
    }
  }

  void checkUserTable() {
    userProfileStreamSubscription?.cancel();
    userProfileStreamSubscription = null;
    userProfileStreamSubscription = SupabaseConfig.client
        .from(dbReference(Members.table))
        .stream(primaryKey: [dbReference(Members.id)])
        .eq(dbReference(Members.id), userId)
        .listen((event) {
          dynamic userDetails = event.singleOrNull;

          if (userDetails != null) {
            String lastname = userDetails[dbReference(Members.lastname)];
            String firstname = userDetails[dbReference(Members.firstname)];
            handleFullNameChanged(lastname, firstname);

            String? pictureIndex =
                userDetails[dbReference(Profile.image_index)];
            handlePictureChange(pictureIndex);

            String? phoneNumber = userDetails[dbReference(Members.phone_no)];
            handlePhoneChanged(phoneNumber);

            String? sessionCode =
                userDetails[dbReference(Members.session_code)];
            handleSessionCodeChanged(sessionCode);

            String? phoneCode = userDetails[dbReference(Members.phone_code)];
            handlePhoneCodeChanged(phoneCode);

            bool? aboutUs = userDetails[dbReference(Members.knows_us)];
            handleKnowsUs(aboutUs);

            bool restricted = userDetails[dbReference(Members.restricted)];
            handleRestriction(restricted);
          }
        });

    userProfileStreamSubscription?.onError((error, stackTrace) {
      beginCheckUserTable = true;
    });
    userProfileStreamSubscription?.onDone(() {
      beginCheckUserTable = true;
    });
  }

  void handleFullNameChanged(
    String lastname,
    String firstname,
  ) {
    MembersOperation.updateTheValue(dbReference(Members.lastname), lastname);
    MembersOperation.updateTheValue(dbReference(Members.firstname), firstname);
  }

  void handlePhoneChanged(String? phoneNumber) {
    MembersOperation.updateTheValue(dbReference(Members.phone_no), phoneNumber);
  }

  void handleSessionCodeChanged(String? sessionCode) async {
    String? oldSessionCode = await MembersOperation()
        .getUserRecord(field: dbReference(Members.session_code));
    bool sessionChanged = oldSessionCode == null ||
        sessionCode == null ||
        oldSessionCode != sessionCode;

    if (sessionChanged) {
      LocalNavigationController().onUseNavigatorKey((navigatorState) {
        if (navigatorState?.context != null) {
          BuildContext context = navigatorState!.context;
          openDialog(
              context,
              const Text(
                "Session Changed",
                style: TextStyle(color: Colors.black, fontSize: 17),
              ),
              const Text(
                  "You have logged into another device. You will be signed out from this device."),
              [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      AuthenticationOperation().signOut(context);
                    },
                    child: const Text("Okay", style: TextStyle(fontSize: 15))),
              ],
              cancelTouch: false);
        }
      });
    }
  }

  void handlePhoneCodeChanged(String? phoneCode) {
    MembersOperation.updateTheValue(dbReference(Members.phone_code), phoneCode);
  }

  void handleKnowsUs(bool? aboutUs) async {
    final saved = await MembersOperation()
        .getUserRecord(field: dbReference(dbReference(Members.knows_us)));
    if (saved != aboutUs) {
      MembersOperation.updateTheValue(dbReference(Members.knows_us), aboutUs);
    }
  }

  void handlePictureChange(String? pictureIndex) {
    if (!profilePictureUploading) {
      MembersOperation.updateTheValue(
          dbReference(Profile.image_index), pictureIndex);
    }
  }

  void handleRestriction(bool restricted, {bool fromLogin = false}) {
    if (!fromLogin) {
      MembersOperation.updateTheValue(
          dbReference(Members.restricted), restricted);
    }

    if (restricted) {
      LocalNavigationController().onUseNavigatorKey((navigatorState) {
        BuildContext context = navigatorState!.context;
        if (fromLogin) {
          SupabaseConfig.client.auth.signOut();
        } else {
          AuthenticationOperation().signOut(context);
        }
        openDialog(
            context,
            const Text(
              "Restricted Access",
              style: TextStyle(color: Colors.black, fontSize: 17),
            ),
            const Text(
                "You have been restricted from Yabnet. You will be logged out."),
            [
              TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                  child: const Text("Okay", style: TextStyle(fontSize: 15))),
            ],
            cancelTouch: false);
      });
    }
  }
}
