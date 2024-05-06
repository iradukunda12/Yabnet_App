import 'dart:async';
import 'dart:io';

import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/operations/MembersOperation.dart';

import '../components/CustomProject.dart';
import '../data/UpdateInfo.dart';
import '../data_notifiers/AppFileServiceData.dart';
import '../db_references/AppFile.dart';
import '../db_references/Members.dart';
import '../firebase/FirebaseConfig.dart';
import '../operations/CacheOperation.dart';
import 'AppFileService.dart';

enum ServiceType { update, privacyPolicy, notification, nothing }

class MainService {
  static final MainService instance = MainService.internal();

  factory MainService() => instance;

  MainService.internal();

  StreamSubscription? updateStream;
  StreamSubscription? privacyStream;

  Duration notificationDuration = const Duration(hours: 12);
  Duration privacyPolicyDuration = const Duration(days: 3);
  Duration updateDuration = const Duration(days: 1);

  ServiceType serviceType = ServiceType.nothing;

  WidgetStateNotifier<UpdateInfo> updateAppInfoNotifier = WidgetStateNotifier();
  WidgetStateNotifier<AppFileServiceData> changedPrivacyNotifier =
      WidgetStateNotifier();

  bool checkDateTimeDifference(
      String? dateTimeString, DateTime parameterDateTime, Duration duration) {
    // Try parsing the datetime string
    DateTime? parsedDateTime;
    try {
      parsedDateTime = DateTime.tryParse((dateTimeString ?? ''));
    } catch (e) {
      // Parsing failed, return true
      return true;
    }

    // If parsedDateTime is null, return true
    if (parsedDateTime == null) {
      return true;
    }

    // Calculate the difference between parsedDateTime and parameterDateTime
    Duration difference = parameterDateTime.difference(parsedDateTime);

    // Check if the difference is more than or equal the duration parameter

    if (difference.abs().inSeconds >= duration.inSeconds) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> canHandleThisServiceDateTime(
      String database, String key, Duration duration) async {
    final saveDatTime = await CacheOperation().getCacheData(database, key);
    final dateTime = DateTime.now();
    final difference =
        checkDateTimeDifference(saveDatTime.toString(), dateTime, duration);

    if (difference) {
      await CacheOperation().saveCacheData(database, key, dateTime.toString());
      return true;
    }
    return false;
  }

  void startService() {
    handleUpdate();
    handlePushNotification();
    handlePrivacyPolicy();
  }

  void handlePushNotification() async {
    final check = await canHandleThisServiceDateTime(
        dbReference(AppFile.database),
        dbReference(AppFile.notification_time),
        notificationDuration);
    if (check && serviceType != ServiceType.update) {
      serviceType = ServiceType.notification;
      await FirebaseConfig().initPushNotification();
    }
  }

  void handlePrivacyPolicy() async {
    Future<void> processThePrivacyPolicy(
        AppFileServiceData? appFileServiceData) async {
      if (appFileServiceData != null) {
        bool changed = false;

        // Change here
        final privacyPolicy = await MembersOperation()
            .getUserRecord(field: dbReference(Members.privacy_policy));

        if (privacyPolicy != null && privacyPolicy.toString().isNotEmpty) {
          changed = privacyPolicy != appFileServiceData.onlineIndex &&
              appFileServiceData.onlineIndex?.isNotEmpty == true;
        } else {
          changed = true;
        }

        final check = await canHandleThisServiceDateTime(
            dbReference(AppFile.database),
            dbReference(AppFile.pp_time),
            privacyPolicyDuration);
        if (changed && check && serviceType != ServiceType.update) {
          serviceType = ServiceType.privacyPolicy;
          changedPrivacyNotifier.sendNewState(appFileServiceData);
        }
      }
    }

    processThePrivacyPolicy(
        AppFileService().privacyPolicyNotifier.currentValue);

    privacyStream ??= AppFileService()
        .privacyPolicyNotifier
        .stream
        .listen(processThePrivacyPolicy);
  }

  Future<void> handleUpdate() async {
    Future<void> processTheUpdate(
        AppFileServiceData? appFileServiceData) async {
      //   Update Service is Returned
      if (appFileServiceData != null) {
        String? iosVersion = appFileServiceData.iosData;
        String? androidVersion = appFileServiceData.androidData;

        UpdateInfo updateInfo = UpdateInfo.fromOnline(
            appFileServiceData.collectionData ?? {},
            iosVersion,
            androidVersion);

        final check = await canHandleThisServiceDateTime(
            dbReference(AppFile.database),
            dbReference(AppFile.update_time),
            updateDuration);

        if (Platform.isAndroid &&
            updateInfo.androidVersion != null &&
            (check || updateInfo.criticalAndroidUpdate == true)) {
          serviceType = ServiceType.update;
          updateAppInfoNotifier.sendNewState(updateInfo);
        } else if (Platform.isIOS &&
            updateInfo.iosVersion != null &&
            (check || updateInfo.criticalIOSUpdate == true)) {
          serviceType = ServiceType.update;
          updateAppInfoNotifier.sendNewState(updateInfo);
        }
      }
    }

    final savedData = await CacheOperation().getCacheData(
        dbReference(AppFile.database), dbReference(AppFile.update));

    if (savedData is Map) {
      final savedAppFileServiceData = AppFileServiceData.fromJson(savedData);
      processTheUpdate(savedAppFileServiceData);
    } else {
      processTheUpdate(AppFileService().updateNotifier.currentValue);
    }
    updateStream ??=
        AppFileService().updateNotifier.stream.listen(processTheUpdate);
  }
}
