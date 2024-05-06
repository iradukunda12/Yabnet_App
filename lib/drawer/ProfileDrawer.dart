import 'dart:async';

import 'package:flutter/material.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/pages/common_pages/ProfilePage.dart';

import '../../components/CustomProject.dart';
import '../../main.dart';
import '../collections/common_collection/ProfileImage.dart';
import '../components/CustomOnClickContainer.dart';
import '../data/UserData.dart';
import '../data_notifiers/ProfileNotifier.dart';
import '../operations/MembersOperation.dart';
import '../pages/common_pages/SettingsPage.dart';

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    void goToSetting() {
      Navigator.pop(context);
      Future.delayed(const Duration(milliseconds: 200), () {
        Navigator.push(context,
                MaterialPageRoute(builder: (context) => const SettingsPage()))
            .then((value) {
          setNormalUiViewOverlay();
        });
      });
    }

    void viewProfile() {
      Navigator.pop(context);
      Future.delayed(const Duration(milliseconds: 200), () {
        Navigator.push(context,
                MaterialPageRoute(builder: (context) => const ProfilePage()))
            .then((value) {
          setNormalUiViewOverlay();
        });
      });
    }

    return Drawer(
        backgroundColor: Colors.white,
        width: getScreenWidth(context) - (getScreenWidth(context) * 0.2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 16,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomOnClickContainer(
                    onTap: goToSetting,
                    defaultColor: Colors.transparent,
                    clickedColor: Colors.grey.shade200,
                    child: const Icon(
                      Icons.settings,
                      color: Color(getDarkGreyColor),
                      size: 30,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 24,
              ),
              CustomOnClickContainer(
                onTap: viewProfile,
                defaultColor: Colors.grey.shade200,
                clickedColor: Colors.grey.shade300,
                height: 70,
                width: 70,
                clipBehavior: Clip.hardEdge,
                shape: BoxShape.circle,
                child: WidgetStateConsumer(
                    widgetStateNotifier: ProfileNotifier().state,
                    widgetStateBuilder: (context, snapshot) {
                      return ProfileImage(
                        fullName: snapshot?.fullName ?? '',
                        iconSize: 45,
                        imageUri: MembersOperation().getMemberProfileBucketPath(
                            snapshot?.userId ?? '', snapshot?.profileIndex),
                        imageUrl: (imageAddress) {},
                      );
                    }),
              ),
              const SizedBox(
                height: 8,
              ),
              StreamBuilder(
                  initialData: ProfileNotifier().state.currentValue,
                  stream: ProfileNotifier().state.stream,
                  builder: (context, snapshot) {
                    UserData? userData = snapshot.data;
                    String fullname = "${userData?.fullName}";
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                fullname,
                                style: TextStyle(
                                    color: Colors.black.withOpacity(0.9),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 4,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: viewProfile,
                                child: Text(
                                  "View profile",
                                  style: TextStyle(
                                      color: Colors.grey.shade800,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
            ],
          ),
        ));
  }
}
