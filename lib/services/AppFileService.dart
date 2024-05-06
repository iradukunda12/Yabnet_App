import 'dart:async';
import 'dart:ui';

import 'package:connectivity/connectivity.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/components/CustomProject.dart';
import 'package:yabnet/data_notifiers/AppFileServiceData.dart';
import 'package:yabnet/db_references/AppFile.dart';
import 'package:yabnet/operations/AppFileOperation.dart';
import 'package:yabnet/operations/CacheOperation.dart';

class AppFileService {
  static final AppFileService instance = AppFileService.internal();

  factory AppFileService() => instance;

  AppFileService.internal();

  StreamSubscription? appFileStreamSubscription;
  StreamSubscription? connectionAppFile;
  WidgetStateNotifier<AppLifecycleState> lifeCycleNotifier =
      WidgetStateNotifier(currentValue: AppLifecycleState.resumed);

  // Term and Condition
  WidgetStateNotifier<AppFileServiceData> termAndConditionNotifier =
      WidgetStateNotifier();

  // Privacy Policy
  WidgetStateNotifier<AppFileServiceData> privacyPolicyNotifier =
      WidgetStateNotifier();

  // Acknowledgements
  WidgetStateNotifier<AppFileServiceData> acknowledgementsNotifier =
      WidgetStateNotifier();

  // FAQ
  WidgetStateNotifier<AppFileServiceData> faqNotifier = WidgetStateNotifier();

  // About us
  WidgetStateNotifier<AppFileServiceData> aboutUsNotifier =
      WidgetStateNotifier();

  // Update
  WidgetStateNotifier<AppFileServiceData> updateNotifier =
      WidgetStateNotifier();

  // Socials
  WidgetStateNotifier<AppFileServiceData> socialsNotifier =
      WidgetStateNotifier();

  bool fetchUpdate = false;

  List<AppFileServiceData> appFileServiceDataList = [];

  // Flag For services
  bool beginCheckAppFileTable = true;

  bool lifeCycleListening = false;

  void beginService() {
    // Check Company Table
    if (beginCheckAppFileTable) {
      checkAppFileTable();
      beginCheckAppFileTable = false;
    }

    registerConnectionSubscription();
    listenToLifeCycle();
  }

  Future<void> endService() async {
    await appFileStreamSubscription?.cancel();
    appFileStreamSubscription = null;
    await connectionAppFile?.cancel();
    connectionAppFile = null;

    // Flag For services
    beginCheckAppFileTable = false;
  }

  void registerConnectionSubscription() {
    if (connectionAppFile == null) {
      connectionAppFile = Connectivity()
          .onConnectivityChanged
          .listen((ConnectivityResult event) {
        if (event != ConnectivityResult.none) {
          beginService();
        }
      });

      connectionAppFile?.onError((error, stackTrace) {
        connectionAppFile?.cancel();
        connectionAppFile = null;
      });
    }
  }

  void listenToLifeCycle() {
    if (!lifeCycleListening) {
      lifeCycleListening = true;
      lifeCycleNotifier.stream.listen((event) {
        if ((beginCheckAppFileTable ||
                appFileStreamSubscription?.isPaused == true) &&
            event == AppLifecycleState.resumed) {
          beginService();
        }
      });
    }
  }

  void checkAppFileTable() {
    appFileStreamSubscription?.cancel();
    appFileStreamSubscription = null;
    appFileStreamSubscription =
        AppFileOperation().fetchAppDataStream().listen((event) {
      appFileServiceDataList.clear();
      fetchUpdate = false;
      event.forEach((element) {
        appFileServiceDataList.add(AppFileServiceData.fromOnline(element));
        fetchUpdate = appFileServiceDataList.isNotEmpty;
      });
      if (fetchUpdate) {
        handleAppFiles();
      }
    });

    appFileStreamSubscription?.onError((error, stackTrace) {
      beginCheckAppFileTable = true;
    });
    appFileStreamSubscription?.onDone(() {
      beginCheckAppFileTable = true;
    });
  }

  Future<void> fetchAppFiles() async {
    await AppFileOperation().fetchAppData().then((value) {
      appFileServiceDataList.clear();
      fetchUpdate = false;
      value.forEach((element) {
        appFileServiceDataList.add(AppFileServiceData.fromOnline(element));
        fetchUpdate = appFileServiceDataList.isNotEmpty;
      });
      if (fetchUpdate) {
        handleAppFiles();
      }
    });
  }

  void handleAppFiles() {
    //   Term and Condition
    int foundTC = appFileServiceDataList.indexWhere(
        (element) => element.localIdentity == dbReference(AppFile.tc));
    if (foundTC != -1) {
      handleTermsAndCondition(appFileServiceDataList[foundTC]);
    }

    //   Privacy and Policy
    int foundPP = appFileServiceDataList.indexWhere(
        (element) => element.localIdentity == dbReference(AppFile.pp));
    if (foundPP != -1) {
      handlePrivacyAndPolicy(appFileServiceDataList[foundPP]);
    }

    //   Acknowledgements
    int foundAK = appFileServiceDataList.indexWhere(
        (element) => element.localIdentity == dbReference(AppFile.ak));
    if (foundAK != -1) {
      handleAcknowledgements(appFileServiceDataList[foundAK]);
    }

    //   About Us
    int foundAboutUs = appFileServiceDataList.indexWhere(
        (element) => element.localIdentity == dbReference(AppFile.abus));
    if (foundAboutUs != -1) {
      handleAboutUs(appFileServiceDataList[foundAboutUs]);
    }

    //   About Us
    int foundUpdate = appFileServiceDataList.indexWhere(
        (element) => element.localIdentity == dbReference(AppFile.update));
    if (foundUpdate != -1) {
      handleUpdate(appFileServiceDataList[foundUpdate]);
    }

    //   FAQ
    int foundFAQ = appFileServiceDataList.indexWhere(
        (element) => element.localIdentity == dbReference(AppFile.faq));
    if (foundFAQ != -1) {
      handleFAQ(appFileServiceDataList[foundFAQ]);
    }

    //   AppLink
    int foundAppLink = appFileServiceDataList.indexWhere(
        (element) => element.localIdentity == dbReference(AppFile.app_link));
    if (foundAppLink != -1) {
      handleAppLink(appFileServiceDataList[foundAppLink]);
    }

    //   AppSocials
    int foundAppSocials = appFileServiceDataList.indexWhere(
        (element) => element.localIdentity == dbReference(AppFile.app_socials));
    if (foundAppSocials != -1) {
      handleAppSocials(appFileServiceDataList[foundAppSocials]);
    }
  }

  void saveFileFromPath(AppFileServiceData appFileServiceData) async {
    final fileByte =
        await AppFileOperation().downloadAppFile(appFileServiceData);
    if (fileByte != null) {
      final file = await AppFileOperation().saveFile(
          appFileServiceData.localIdentity!,
          "APP_FILE",
          appFileServiceData.fileType!,
          fileByte);

      showDebug(msg: "Path -> ${file.path}");
    }
  }

  Future<void> handleAppFileOperation(AppFileServiceData appFileServiceData,
      String database, String key, WidgetStateNotifier notifier,
      {bool sendCachedUpdate = false}) async {
    // final savedData = await CacheOperation().getCacheData(database, key);
    //
    // if (savedData is Map) {
    //   final savedAppFileServiceData = AppFileServiceData.fromJson(savedData);
    //
    //   if ((savedAppFileServiceData.onlineDirectory !=
    //           appFileServiceData.onlineDirectory ||
    //       savedAppFileServiceData.onlineIndex !=
    //           appFileServiceData.onlineIndex ||
    //       appFileServiceData.fileType != savedAppFileServiceData.fileType || savedAppFileServiceData.iosData != appFileServiceData.iosData || savedAppFileServiceData.androidData != savedAppFileServiceData.androidData)) {
    //     showToastMobile(msg: true);
    //     await CacheOperation()
    //         .saveCacheData(database, key, appFileServiceData.toJson());
    //     // saveFileFromPath(appFileServiceData);
    //     notifier.sendNewState(appFileServiceData);
    //   }else if(sendCachedUpdate){
    //     notifier.sendNewState(savedAppFileServiceData);
    //   }
    // } else {
    await CacheOperation()
        .saveCacheData(database, key, appFileServiceData.toJson());
    // saveFileFromPath(appFileServiceData);
    notifier.sendNewState(appFileServiceData);
    // }
  }

  void handleTermsAndCondition(AppFileServiceData appFileServiceData) async {
    await handleAppFileOperation(
        appFileServiceData,
        dbReference(AppFile.database),
        dbReference(AppFile.tc),
        termAndConditionNotifier);
  }

  void handlePrivacyAndPolicy(AppFileServiceData appFileServiceData) async {
    await handleAppFileOperation(
        appFileServiceData,
        dbReference(AppFile.database),
        dbReference(AppFile.pp),
        privacyPolicyNotifier);
  }

  void handleAcknowledgements(AppFileServiceData appFileServiceData) async {
    await handleAppFileOperation(
        appFileServiceData,
        dbReference(AppFile.database),
        dbReference(AppFile.ak),
        acknowledgementsNotifier);
  }

  void handleFAQ(AppFileServiceData appFileServiceData) async {
    await handleAppFileOperation(appFileServiceData,
        dbReference(AppFile.database), dbReference(AppFile.faq), faqNotifier);
  }

  void handleAppLink(AppFileServiceData appFileServiceData) async {
    await handleAppFileOperation(
        appFileServiceData,
        dbReference(AppFile.database),
        dbReference(AppFile.app_link),
        WidgetStateNotifier());
  }

  void handleAppSocials(AppFileServiceData appFileServiceData) async {
    await handleAppFileOperation(
        appFileServiceData,
        dbReference(AppFile.database),
        dbReference(AppFile.app_socials),
        socialsNotifier);
  }

  void handleAboutUs(AppFileServiceData appFileServiceData) async {
    await handleAppFileOperation(
        appFileServiceData,
        dbReference(AppFile.database),
        dbReference(AppFile.abus),
        aboutUsNotifier);
  }

  void handleUpdate(AppFileServiceData appFileServiceData) async {
    await handleAppFileOperation(
        appFileServiceData,
        dbReference(AppFile.database),
        dbReference(AppFile.update),
        updateNotifier,
        sendCachedUpdate: true);
  }
}
