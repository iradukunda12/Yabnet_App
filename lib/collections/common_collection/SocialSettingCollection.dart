import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/src/url_launcher_uri.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/services/AppFileService.dart';

import '../../components/CustomClickableCard.dart';
import '../../components/CustomProject.dart';
import '../../data_notifiers/AppFileServiceData.dart';
import '../../db_references/AppFile.dart';
import '../../operations/CacheOperation.dart';
import 'ResourceCollection.dart';

class SocialData {
  final String? imageAsset;
  final String linkName;
  final String linkAddress;

  SocialData(this.imageAsset, this.linkName, this.linkAddress);
}

class SocialSettingCollection extends StatefulWidget {
  const SocialSettingCollection({super.key});

  @override
  State<SocialSettingCollection> createState() =>
      _SocialSettingCollectionState();
}

class _SocialSettingCollectionState extends State<SocialSettingCollection> {
  double socialSize = 45;
  StreamSubscription? socialSubscription;
  WidgetStateNotifier<List<SocialData>> socialsNotifier = WidgetStateNotifier();

  Map<String, String> socialsMediaFile = {
    dbReference(AppFile.whatsapp): ResourceCollection.whatsappImage,
    dbReference(AppFile.facebook): ResourceCollection.facebookImage,
    dbReference(AppFile.instagram): ResourceCollection.instagramImage,
    dbReference(AppFile.x): ResourceCollection.xImage,
  };

  Map<String, String> socialsMediaName = {
    dbReference(AppFile.whatsapp): "Whatsapp",
    dbReference(AppFile.facebook): "Facebook",
    dbReference(AppFile.instagram): "Instagram",
    dbReference(AppFile.youtube): "Youtube",
    dbReference(AppFile.linkedin): "LinkedIn",
    dbReference(AppFile.pinterest): "Pinterest",
    dbReference(AppFile.x): "X",
  };

  @override
  void initState() {
    super.initState();
    getSocials(AppFileService().socialsNotifier.currentValue);
    socialSubscription ??=
        AppFileService().socialsNotifier.stream.listen((event) {
      getSocials(event);
    });
  }

  @override
  void dispose() {
    super.dispose();
    socialSubscription?.cancel();
    socialSubscription = null;
  }

  void getSocials(AppFileServiceData? appFileServiceData) {
    try {
      CacheOperation()
          .getCacheData(
              dbReference(AppFile.database), dbReference(AppFile.app_socials))
          .then((savedData) {
        if (savedData is Map) {
          final savedAppFileServiceData =
              AppFileServiceData.fromJson(savedData);
          if (appFileServiceData != null) {
            showSocials(appFileServiceData);
          } else {
            showSocials(savedAppFileServiceData);
          }
        } else {
          if (appFileServiceData != null) {
            showSocials(appFileServiceData);
          }
        }
      }).onError((error, stackTrace) {
        if (appFileServiceData != null) {
          showSocials(appFileServiceData);
        }
      });
    } catch (e) {
      if (appFileServiceData != null) {
        showSocials(appFileServiceData);
      }
    }
  }

  void showSocials(AppFileServiceData appFileServiceData) {
    List<SocialData> socials = [];
    Map? socialData = appFileServiceData.collectionData;

    if (socialData != null) {
      socialData.forEach((key, value) {
        String? name = socialsMediaName[key];
        String? file = socialsMediaFile[key];

        if (name != null &&
            key != null &&
            value != null &&
            value.toString().isNotEmpty) {
          socials.add(SocialData(file, name, value));
        }
      });
      socials.sort((a, b) {
        return b.linkName.compareTo(a.linkName);
      });
      socialsNotifier.sendNewState(socials);
    }
  }

  void handleThisSocialLink(String linkAddress) async {
    try {
      Uri linkUrl = Uri.parse(linkAddress);
      if (await canLaunchUrl(linkUrl)) {
        await launchUrl(linkUrl);
      } else {
        showToastMobile(msg: "An error occurred");
      }
    } catch (e) {
      showToastMobile(msg: "An error occurred");
    }
  }

  void shareThisApp() async {
    showCustomProgressBar(context);
    CacheOperation()
        .getCacheData(
            dbReference(AppFile.database), dbReference(AppFile.app_link))
        .then((savedData) {
      if (savedData is Map) {
        final savedAppFileServiceData = AppFileServiceData.fromJson(savedData);
        String? iosLink = savedAppFileServiceData.iosData;
        String? androidLink = savedAppFileServiceData.androidData;
        if (Platform.isAndroid) {
          handleAndroidShare(androidLink);
        } else if (Platform.isIOS) {
          handleIosShare(iosLink);
        }
      } else {
        if (Platform.isAndroid) {
          handleAndroidShare(null);
        } else if (Platform.isIOS) {
          handleIosShare(null);
        }
      }
      closeCustomProgressBar(context);
    }).onError((error, stackTrace) {
      closeCustomProgressBar(context);
      showDebug(msg: "$error $stackTrace");
      if (Platform.isAndroid) {
        handleAndroidShare(null);
      } else if (Platform.isIOS) {
        handleIosShare(null);
      }
    });
  }

  void handleAndroidShare(String? androidLink) {
    late String subject;
    if (androidLink != null) {
      subject = "Download our app form Play Store with the link: $androidLink";
    } else {
      subject = "Check out Yabnet on Play Store!. Enjoy the App!!!";
    }
    shareApp("YABNET", subject);
  }

  void handleIosShare(String? iosLink) {
    late String subject;
    if (iosLink != null) {
      subject = "Download our app form App Store with the link: $iosLink";
    } else {
      subject = "Check out Yabnet on App Store!. Enjoy the App!!!";
    }
    shareApp("YABNET", subject);
  }

  void shareApp(String title, String text) {
    Share.shareWithResult(text, subject: title).then((value) {
      if (value.status == ShareResultStatus.success) {
        showToastMobile(msg: "Thank you for sharing!");
      } else if (value.status == ShareResultStatus.dismissed) {
        showToastMobile(msg: "You can always share later. Thank you!");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Social
        WidgetStateConsumer(
            widgetStateNotifier: socialsNotifier,
            widgetStateBuilder: (context, socials) {
              if ((socials?.isEmpty ?? true)) return SizedBox();
              return Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            for (var index = 0;
                                index < socials!.length;
                                index++)
                              Padding(
                                padding: EdgeInsets.only(
                                    left: index == 0 ? 24 : 0,
                                    right: (index + 1) == socials.length
                                        ? 26
                                        : 24),
                                child: Row(
                                  children: [
                                    // Image
                                    GestureDetector(
                                      onTap: () {
                                        handleThisSocialLink(
                                            socials[index].linkAddress);
                                      },
                                      child: Column(
                                        children: [
                                          // Image
                                          Builder(builder: (context) {
                                            String? asset =
                                                socials[index].imageAsset;
                                            return asset != null
                                                ? ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    child: Image.asset(
                                                      asset,
                                                      height: socialSize,
                                                    ),
                                                  )
                                                : Container(
                                                    clipBehavior: Clip.hardEdge,
                                                    height: socialSize,
                                                    width: socialSize,
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withOpacity(0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Icon(
                                                      Icons.link,
                                                      size: socialSize - 8,
                                                      color: Colors.black
                                                          .withOpacity(0.7),
                                                    ),
                                                  );
                                          }),

                                          SizedBox(
                                            height: 5,
                                          ),

                                          Text(
                                            socials[index].linkName,
                                            textScaler: TextScaler.noScaling,
                                            style: TextStyle(
                                                color: Colors.black
                                                    .withOpacity(0.7),
                                                fontSize: 16),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: CustomClickableCard(
                  onTap: shareThisApp,
                  defaultColor: Colors.white,
                  clickedColor: Colors.grey.shade200,
                  text: 'Share this app',
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
