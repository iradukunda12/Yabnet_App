import 'package:flutter/material.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/components/CustomOnClickContainer.dart';
import 'package:yabnet/data/NotificationData.dart';
import 'package:yabnet/operations/MembersOperation.dart';
import 'package:yabnet/operations/NotificationOperation.dart';

import '../collections/common_collection/ProfileImage.dart';

class NotificationWidget extends StatelessWidget {
  final NotificationData notification;
  final Function() onTap;

  const NotificationWidget(
      {Key? key, required this.notification, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool read = notification.notificationId != null ||
        notification.notificationIsOtherPost != null;
    return CustomOnClickContainer(
      onTap: onTap,
      padding: EdgeInsets.only(top: 12, bottom: 12, right: 16, left: 16 - 5),
      defaultColor:
          (read ? null : Colors.blue.withOpacity(0.1)) ?? Colors.transparent,
      clickedColor: read ? Colors.grey.shade200 : Colors.blue.withOpacity(0.19),
      borderRadius: BorderRadius.circular(1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Read/Unread Indicator
          Padding(
            padding: const EdgeInsets.only(top: 0),
            child: Icon(
              size: 10,
              read ? null : Icons.circle,
              color: read ? null : Colors.blue,
            ),
          ),

          SizedBox(
            width: 8,
          ),

          Container(
              height: 50,
              width: 50,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade300,
              ),
              child: WidgetStateConsumer(
                  widgetStateNotifier:
                      notification.postProfileNotifier?.state ??
                          WidgetStateNotifier(currentValue: null),
                  widgetStateBuilder: (context, data) {
                    return ProfileImage(
                      iconSize: 40,
                      textSize: 16,
                      canDisplayImage: true,
                      fromHome: true,
                      imageUri: MembersOperation().getMemberProfileBucketPath(
                          data?.userId ?? '', data?.profileIndex),
                      fullName: data?.fullName ?? "Error",
                    );
                  })),
          SizedBox(
            width: 8,
          ),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: NotificationOperation().getNotificationText(notification),
          )),
          Column(
            children: [
              Text(
                NotificationOperation().formatTimeAgo(
                    NotificationOperation().getNotificationTime(notification)),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              SizedBox(
                height: 2,
              ),
              CustomOnClickContainer(
                onTap: () {},
                defaultColor: Colors.transparent,
                clickedColor: Colors.grey.shade200,
                child: Icon(
                  Icons.more_vert,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
