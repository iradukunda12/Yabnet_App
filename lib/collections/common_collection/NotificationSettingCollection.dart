import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:yabnet/components/CustomProject.dart';
import 'package:yabnet/db_references/Notification.dart' as not;
import 'package:yabnet/firebase/FirebaseConfig.dart';
import 'package:yabnet/operations/CacheOperation.dart';

import '../../main.dart';

class NotificationSettingCollection extends StatefulWidget {
  const NotificationSettingCollection({super.key});

  @override
  State<NotificationSettingCollection> createState() =>
      _NotificationSettingCollectionState();
}

class _NotificationSettingCollectionState
    extends State<NotificationSettingCollection> {
  bool acceptPushNotification = false;

  @override
  void initState() {
    super.initState();
    fetchNotificationSetting();
  }

  void fetchNotificationSetting() async {
    final settings = await CacheOperation().getCacheData(
        dbReference(not.Notification.database),
        dbReference(not.Notification.status));
    setState(() {
      acceptPushNotification =
          settings == dbReference(dbReference(AuthorizationStatus.authorized));
    });
  }

  void onChangePushNotification(onChanged) {
    if (!acceptPushNotification) {
      FirebaseConfig().askNotificationPermission().then((settings) {
        fetchNotificationSetting();
      });
    } else {
      openAppSettings().then((value) {
        fetchNotificationSetting();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        //   Push Notification

        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Switch Text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          //   Push Text
                          const Expanded(
                            child: Text(
                              "Accept push notifications",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                          ),

                          // Switch
                          const SizedBox(
                            width: 5,
                          ),
                          SizedBox(
                            height: 35,
                            child: Switch(
                                value: acceptPushNotification,
                                activeColor: const Color(getMainPinkColor),
                                inactiveThumbColor:
                                    const Color(getDarkGreyColor),
                                activeTrackColor: const Color(getMainPinkColor)
                                    .withOpacity(0.5),
                                inactiveTrackColor:
                                    const Color(getDarkGreyColor)
                                        .withOpacity(0.5),
                                onChanged: onChangePushNotification),
                          )
                        ],
                      ),

                      //   Description
                      const SizedBox(
                        height: 8,
                      ),
                      const Text(
                        "We may send you notification about newly added features and personalized experiences and more.",
                        style: TextStyle(fontSize: 14),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }
}
