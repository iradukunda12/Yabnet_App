import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ChannelData {
  final String? androidChannelId;
  final String? androidChannelName;
  final AndroidNotificationVisibility androidVisibility;
  final AndroidNotificationPriority androidPriority;
  final Importance localImportance;
  final Priority localPriority;
  final String? androidSmallIcon;

  final String? androidSound;

  final String? androidTicker;

  final String? androidTag;

  final String? androidClickAction;

  final String? androidColor;

  final int? androidCount;

  final String? imageUrl;

  final String? link;

  final String? appleBadge;

  final AppleNotificationSound? appleSound;

  final String? appleSubtitle;

  final List<String> appleSubtitleLocArgs;

  final String? appleSubtitleLocKey;

  final String? webAnalyticsLabel;

  final AndroidBitmap<Object>? androidLargeIcon;

  ChannelData(
      {this.androidChannelId,
      this.androidLargeIcon,
      this.localImportance = Importance.max,
      this.localPriority = Priority.max,
      this.androidChannelName,
      this.androidSmallIcon,
      this.androidSound,
      this.androidTicker,
      this.androidTag,
      this.androidClickAction,
      this.androidColor,
      this.androidCount,
      this.imageUrl,
      this.link,
      this.appleBadge,
      this.appleSound,
      this.appleSubtitle,
      this.appleSubtitleLocArgs = const [],
      this.appleSubtitleLocKey,
      this.webAnalyticsLabel,
      this.androidVisibility = AndroidNotificationVisibility.public,
      this.androidPriority = AndroidNotificationPriority.highPriority});

  static ChannelData extractData(RemoteNotification? notification) {
    return ChannelData(
        androidChannelId: notification?.android?.channelId,
        androidChannelName: "",
        // edit
        androidClickAction: notification?.android?.clickAction,
        androidVisibility: notification?.android?.visibility ??
            AndroidNotificationVisibility.public,
        androidPriority: notification?.android?.priority ??
            AndroidNotificationPriority.highPriority,
        androidTicker: notification?.android?.ticker,
        androidTag: notification?.android?.tag,
        androidSound: notification?.android?.sound,
        androidSmallIcon: notification?.android?.smallIcon,
        androidCount: notification?.android?.count,
        androidColor: notification?.android?.color,
        appleBadge: notification?.apple?.badge,
        appleSubtitleLocKey: notification?.apple?.subtitleLocKey,
        appleSubtitle: notification?.apple?.subtitle,
        appleSound: notification?.apple?.sound,
        appleSubtitleLocArgs: notification?.apple?.subtitleLocArgs ?? [],
        webAnalyticsLabel: notification?.web?.analyticsLabel,
        link: notification?.android?.link);
  }
}
