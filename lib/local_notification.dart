import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'collections/common_collection/LocalNotificationCollections.dart';
import 'data/ChannelData.dart';
import 'operations/NotificationTypeOperation.dart';

class LocalNotification {
  static final LocalNotification localNotificationInstance =
      LocalNotification.internal();

  factory LocalNotification() => localNotificationInstance;

  LocalNotification.internal();

  FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
  bool flutterLocalNotificationsPluginInitialized = false;

  Future<void> setup() async {
    if (flutterLocalNotificationsPluginInitialized) {
      return;
    }
    const androidInitializationSetting =
        AndroidInitializationSettings('@drawable/ic_launcher_foreground');
    const iosInitializationSetting = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
        android: androidInitializationSetting, iOS: iosInitializationSetting);

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin?.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final message =
            RemoteMessage.fromMap(jsonDecode(response.payload ?? ""));
        handleNotificationPressed(message);
      },
    );

    await createAndroidChannels();
    flutterLocalNotificationsPluginInitialized = true;
  }

  Future<void> createAndroidChannels() async {
    Iterable<Future<void>> creatingChannel =
        LocalNotificationCollection().listOfChannelData.map((e) {
      return flutterLocalNotificationsPlugin
              ?.resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.createNotificationChannel(AndroidNotificationChannel(
                e.androidChannelId ?? "notification",
                e.androidChannelName ?? "Notifications",
                importance: e.localImportance,
              )) ??
          Future.value();
    });

    await Future.wait((creatingChannel));
  }

  void handleNotificationPressed(RemoteMessage? message) async {
    RemoteMessage? readMessage;
    if (message == null) {
      readMessage = await FirebaseMessaging.instance.getInitialMessage();
    } else {
      readMessage = message;
    }

    if (readMessage != null) {
      NotificationTypeOperation().handleTheNotificationMessage(readMessage);
    }
  }

  void showLocalNotification(
      int hashCode, String? title, String? body, ChannelData channelData,
      {String? payload,
      StyleInformation? styleInformation,
      List<DarwinNotificationAttachment>? darwinNotificationAttachment}) {
    final androidNotificationDetail = AndroidNotificationDetails(
        channelData.androidChannelId ?? '0', // channel Id
        channelData.androidChannelName ?? 'Zero', // channel Name
        importance: channelData.localImportance,
        icon: channelData.androidSmallIcon,
        largeIcon: channelData.androidLargeIcon,
        priority: channelData.localPriority,
        styleInformation: styleInformation);
    final iosNotificationDetail =
        DarwinNotificationDetails(attachments: darwinNotificationAttachment);
    final notificationDetails = NotificationDetails(
      iOS: iosNotificationDetail,
      android: androidNotificationDetail,
    );
    flutterLocalNotificationsPlugin
        ?.show(hashCode, title, body, notificationDetails, payload: payload);
  }
}
