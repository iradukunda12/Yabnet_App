import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yabnet/collections/common_collection/ResourceCollection.dart';
import 'package:yabnet/components/CustomOnClickContainer.dart';
import 'package:yabnet/components/EllipsisText.dart';
import 'package:yabnet/data/UpdateInfo.dart';

import '../../components/CustomCircularButton.dart';
import '../../components/CustomProject.dart';
import '../../main.dart';

class UpdatePage extends StatefulWidget {
  final Function() onOpened;
  final UpdateInfo updateInfo;

  const UpdatePage(
      {super.key, required this.updateInfo, required this.onOpened});

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  @override
  void initState() {
    super.initState();
    setLightUiViewOverlay();
    widget.onOpened();
  }

  @override
  Widget build(BuildContext context) {
    void performBackPressed() {
      setNormalUiViewOverlay();
      try {
        if (KeyboardVisibilityProvider.isKeyboardVisible(context)) {
          hideKeyboard(context);
        } else {
          Navigator.pop(context);
          setNormalUiViewOverlay();
        }
      } catch (e) {
        Navigator.pop(context);
        setNormalUiViewOverlay();
      }
    }

    Future<bool> googleUpdateOperation(String appId) {
      final uri =
          Uri.https("play.google.com", "/store/apps/details", {"id": appId});
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    Future<bool> iosUpdateOperation(String appId) {
      var uri = Uri.https("itunes.apple.com", "/lookup", {"bundleId": appId});
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    void onTapLater() => performBackPressed();
    void onTapUpdate() async {
      showCustomProgressBar(context);

      try {
        final packageInfo = await PackageInfo.fromPlatform();
        closeCustomProgressBar(context);

        String appId = packageInfo.packageName;

        if (Platform.isAndroid) {
          googleUpdateOperation(appId);
        } else if (Platform.isIOS) {
          iosUpdateOperation(appId);
        } else {
          showToastMobile(msg: "An error occurred");
        }
      } catch (e, s) {
        closeCustomProgressBar(context);
        showDebug(msg: "$e $s");
        showToastMobile(msg: "An error occurred");
      }
    }

    return Builder(builder: (context) {
      final updateInfo = widget.updateInfo;
      bool iosIsCritical = updateInfo.criticalIOSUpdate ?? false;
      bool androidIsCritical = updateInfo.criticalAndroidUpdate ?? false;

      String versionText = "Unknown";
      if (Platform.isAndroid && updateInfo.androidVersion != null) {
        versionText = updateInfo.androidVersion!;
      } else if (Platform.isIOS && updateInfo.iosVersion != null) {
        versionText = updateInfo.iosVersion!;
      }

      String installedVersion = "Unknown";
      if (Platform.isAndroid && updateInfo.androidInstalledVersion != null) {
        installedVersion = updateInfo.androidInstalledVersion!;
      } else if (Platform.isIOS && updateInfo.iosInstalledVersion != null) {
        installedVersion = updateInfo.iosInstalledVersion!;
      }

      String releaseNote = "New Update features.";
      if (Platform.isAndroid && updateInfo.releaseAndroidNote != null) {
        releaseNote = updateInfo.releaseAndroidNote!;
      } else if (Platform.isIOS && updateInfo.releaseIOSNote != null) {
        releaseNote = updateInfo.releaseIOSNote!;
      }

      DateTime? updatedWhen = null;
      if (Platform.isAndroid && updateInfo.lastAndroidUpdated != null) {
        updatedWhen = updateInfo.lastAndroidUpdated!;
      } else if (Platform.isIOS && updateInfo.lastIOSUpdated != null) {
        updatedWhen = updateInfo.lastIOSUpdated!;
      }

      TextStyle updateTextStyle =
          TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 14);

      return Stack(
        children: [
          Positioned.fill(
            child: Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 40, right: 40, top: 110),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                      child: Text(
                                    "New Update !!!",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 28),
                                  )),
                                ],
                              ),
                              SizedBox(
                                height: 8,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        children: <TextSpan>[
                                          TextSpan(
                                            text: "A new updated version ",
                                            style: updateTextStyle,
                                          ),
                                          TextSpan(
                                            text: versionText,
                                            style: updateTextStyle.copyWith(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text:
                                                " is available on ${Platform.isIOS ? "App Store" : "Play Store"} to download. The version you have installed is ",
                                            style: updateTextStyle,
                                          ),
                                          TextSpan(
                                            text: installedVersion,
                                            style: updateTextStyle.copyWith(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                            text: " on your device.",
                                            style: updateTextStyle,
                                          ),
                                        ],
                                      ),
                                      // overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 24,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                      child: Text(
                                    "Release Note",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24),
                                  )),
                                ],
                              ),
                              SizedBox(
                                height: 4,
                              ),
                              if (updatedWhen != null)
                                Row(
                                  children: [
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          children: <TextSpan>[
                                            TextSpan(
                                              text: "Updated on ",
                                              style: updateTextStyle,
                                            ),
                                            TextSpan(
                                              text: DateFormat("MMM d, yyyy")
                                                  .format(updatedWhen),
                                              style: updateTextStyle.copyWith(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        // overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              SizedBox(
                                height: 16,
                              ),
                              EllipsisText(
                                  text: releaseNote,
                                  maxLength: 500,
                                  textStyle: TextStyle(
                                      color: Colors.black.withOpacity(0.8),
                                      fontSize: 14)),
                              SizedBox(
                                height: 32,
                              ),
                              Row(
                                children: [
                                  ((iosIsCritical && Platform.isIOS) ||
                                          (androidIsCritical &&
                                              Platform.isAndroid))
                                      ? SizedBox()
                                      : Expanded(
                                          child: CustomOnClickContainer(
                                              onTap: onTapLater,
                                              defaultColor: Colors.transparent,
                                              clickedColor:
                                                  Colors.grey.shade200,
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 12),
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                              border: Border.all(
                                                  color: Colors.black
                                                      .withOpacity(0.8)),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                      child: Text(
                                                    "Later",
                                                    textAlign: TextAlign.center,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 17,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  )),
                                                ],
                                              )),
                                        ),
                                  SizedBox(
                                    width: 16,
                                  ),
                                  Expanded(
                                    child: CustomOnClickContainer(
                                        onTap: onTapUpdate,
                                        defaultColor: Color(getMainPinkColor),
                                        clickedColor: Color(getMainPinkColor)
                                            .withOpacity(0.4),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        borderRadius: BorderRadius.circular(50),
                                        // border: Border.all(color: Colors.black.withOpacity(0.8)),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "Update",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        )),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //   Image
                  Image.asset(
                    ResourceCollection.yabnetImage,
                    height: 140,
                    width: 160,
                    alignment: Alignment.topLeft,
                    fit: BoxFit.fill,
                  ),

                  Expanded(child: SizedBox()),
                  ((iosIsCritical && Platform.isIOS) ||
                          (androidIsCritical && Platform.isAndroid))
                      ? SizedBox()
                      : Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: CustomCircularButton(
                            imagePath: null,
                            mainAlignment: Alignment.center,
                            iconColor: Color(getDarkGreyColor),
                            onPressed: performBackPressed,
                            icon: Icons.cancel,
                            gap: 8,
                            width: getSpanLimiter(
                                45, getScreenHeight(context) * 0.1),
                            height: getSpanLimiter(
                                45, getScreenHeight(context) * 0.1),
                            iconSize: getSpanLimiter(
                                35, getScreenHeight(context) * 0.075),
                            defaultBackgroundColor: Colors.transparent,
                            colorImage: true,
                            showShadow: false,
                            clickedBackgroundColor:
                                const Color(getDarkGreyColor).withOpacity(0.4),
                          ),
                        ),

                  SizedBox(
                    width: 40,
                  )
                ],
              )),
        ],
      );
    });
  }
}
