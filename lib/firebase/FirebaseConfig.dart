import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_in_app_messaging/firebase_in_app_messaging.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart';
import 'package:yabnet/operations/NotificationOperation.dart';

import '../components/CustomProject.dart';
import '../data/ChannelData.dart';
import '../local_notification.dart';
import '../main.dart';
import 'FirebaseOptions.dart';

class FirebaseConfig {
  static final FirebaseConfig firebaseConfigInstance =
      FirebaseConfig.internal();

  factory FirebaseConfig() => firebaseConfigInstance;

  FirebaseConfig.internal();

  Uri fcmPostUri = Uri.parse("https://fcm.googleapis.com/fcm/send");
  String fcmServerKey =
      "AAAAU3knAa4:APA91bGTPiCDGp80XEAwjVhuhxNhfM4fqWskBpfqP5V4aYx4piQQBLk9vjQHkM50rlP2Nkw2e1jN4s64zoVKoDeVuod5DXNuZf6qUrCrvX3bDqoKHO7C4MEJKqLXfIr04XlyQTc9Q0NX";

  String? getFcmToken;

  Future initialize({bool fromBackground = true}) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (fromBackground) {
      return;
    }
    try {
      await initNotification();
    } catch (e, s) {
      showDebug(msg: "$e $s");
    }
  }

  Future initNotification() async {
    final firebaseMessaging = FirebaseMessaging.instance;

    final fcmToken = await firebaseMessaging.getToken();
    getFcmToken = fcmToken;
    showDebug(msg: fcmToken);
  }

  Future<AuthorizationStatus> askNotificationPermission() async {
    final firebaseMessaging = FirebaseMessaging.instance;
    final setting = await firebaseMessaging.requestPermission(
        carPlay: true,
        criticalAlert: true,
        provisional: true,
        announcement: true);
    await NotificationOperation()
        .changeNotificationStatus(setting.authorizationStatus);
    return setting.authorizationStatus;
  }

  Future initPushNotification() async {
    final firebaseMessaging = FirebaseMessaging.instance;

    await askNotificationPermission();
    // Set Notification Options
    await firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true, badge: true, sound: true);

    RemoteMessage? initialMessage = await firebaseMessaging.getInitialMessage();

    if (initialMessage != null) {
      //   Handle when notification is clicked
      LocalNotification().handleNotificationPressed(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => LocalNotification().handleNotificationPressed(message));

    FirebaseMessaging.onMessage.listen((message) async {
      if (message.notification == null) return;

      sendFCMNotificationToLocal(message);
    });

    FirebaseMessaging.onBackgroundMessage(performActionOnBackGroundMessage);
  }

  void sendFCMNotificationToLocal(RemoteMessage message) {
    final notification = message.notification;
    // Get the Type of Notification Here to get the channel data
    LocalNotification().showLocalNotification(
        notification!.hashCode,
        notification.title,
        notification.body,
        ChannelData.extractData(notification),
        payload: jsonEncode(message.toMap()));
  }

  Future initInAppMessaging() async {
    FirebaseInAppMessaging.instance;
  }

  AndroidNotification androidNotification(ChannelData channelData) {
    return AndroidNotification(
        priority: channelData.androidPriority,
        visibility: channelData.androidVisibility,
        link: channelData.link,
        channelId: channelData.androidChannelId,
        color: channelData.androidColor,
        count: channelData.androidCount,
        imageUrl: channelData.imageUrl,
        smallIcon: channelData.androidSmallIcon,
        sound: channelData.androidSound,
        tag: channelData.androidTag,
        ticker: channelData.androidTicker,
        clickAction: channelData.androidClickAction);
  }

  AppleNotification appleNotification(ChannelData channelData) {
    return AppleNotification(
        badge: channelData.appleBadge,
        sound: channelData.appleSound,
        imageUrl: channelData.imageUrl,
        subtitle: channelData.appleSubtitle,
        subtitleLocArgs: channelData.appleSubtitleLocArgs,
        subtitleLocKey: channelData.appleSubtitleLocKey);
  }

  WebNotification webNotification(ChannelData channelData) {
    return WebNotification(
        link: channelData.link,
        image: channelData.imageUrl,
        analyticsLabel: channelData.webAnalyticsLabel);
  }

  Future<Response?> sendNotification(String fcmToken, String title, String body,
      Map<String, dynamic> data, ChannelData channelData) async {
    // Remote Notification
    RemoteNotification remoteNotification = RemoteNotification(
        android: androidNotification(channelData),
        apple: appleNotification(channelData),
        web: webNotification(channelData),
        title: title,
        body: body);

    // Create payload
    final fcmPayload = jsonEncode({
      // To Token
      "to": fcmToken,

      // Notification
      "notification": remoteNotification.toMap(),

      //   data
      "data": data,
    });

    //  check token is no empty

    if (fcmToken.isEmpty) {
      showDebug(msg: "The token does not exists");
      return null;
    }

    // Send a post Request
    Response response = await post(fcmPostUri,
        headers: {
          "Content-Type": 'application/json',
          "Authorization": "key=$fcmServerKey"
        },
        body: fcmPayload);

    return response;
  }
}
