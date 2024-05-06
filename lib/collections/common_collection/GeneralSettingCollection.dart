import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yabnet/services/AppFileService.dart';

import '../../builders/AutoReconnectFutureBuilder.dart';
import '../../components/CustomClickableCard.dart';
import '../../components/CustomProject.dart';
import '../../db_references/AppFile.dart';
import '../../operations/AuthenticationOperation.dart';
import '../../pages/common_pages/PdfVieverPage.dart';

class GeneralSettingCollection extends StatefulWidget {
  const GeneralSettingCollection({super.key});

  @override
  State<GeneralSettingCollection> createState() =>
      _GeneralSettingCollectionState();
}

class _GeneralSettingCollectionState extends State<GeneralSettingCollection> {
  String currentThemeMode = "Light Mode";
  String? version;

  void changeTheme() {}

  void clickTermAndCondition() async {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PdfViewerPage(
                  localIdentity: dbReference(AppFile.tc),
                  pdfTitle: 'Terms And Condition',
                  appFileNotifier: AppFileService().termAndConditionNotifier,
                )));
  }

  void clickAboutUs() async {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PdfViewerPage(
                  localIdentity: dbReference(AppFile.abus),
                  pdfTitle: 'About Us',
                  appFileNotifier: AppFileService().aboutUsNotifier,
                )));
  }

  void clickPrivacyPolicy() async {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PdfViewerPage(
                  localIdentity: dbReference(AppFile.pp),
                  pdfTitle: 'Privacy Policy',
                  appFileNotifier: AppFileService().privacyPolicyNotifier,
                )));
  }

  void clickAcknowledgements() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PdfViewerPage(
                  localIdentity: dbReference(AppFile.ak),
                  pdfTitle: 'Acknowledgements',
                  appFileNotifier: AppFileService().acknowledgementsNotifier,
                )));
  }

  void clickFAQ() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PdfViewerPage(
                  localIdentity: dbReference(AppFile.faq),
                  pdfTitle: 'FAQs',
                  appFileNotifier: AppFileService().faqNotifier,
                )));
  }

  void clickLogOut() {
    openDialog(
      context,
      color: Colors.grey.shade200,
      const Text(
        "Log Out",
        style: TextStyle(color: Colors.red, fontSize: 17),
      ),
      const Text("Are you sure you want to log out?"),
      [
        TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel",
                style: TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                    fontWeight: FontWeight.bold))),
        TextButton(
            onPressed: () {
              Navigator.pop(context);
              AuthenticationOperation().signOut(context);
            },
            child: const Text("Yes",
                style: TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                    fontWeight: FontWeight.bold))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          children: [
            // Theme Mode
            Row(
              children: [
                Expanded(
                  child: CustomClickableCard(
                    showClickable: false,
                    onTap: changeTheme,
                    borderRadius: 0,
                    defaultColor: Colors.white,
                    clickedColor: Colors.grey.shade200,
                    text: currentThemeMode,
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),

            //Version
            Row(
              children: [
                Expanded(
                  child: AutoReconnectFutureBuilder(
                      autoFuture: PackageInfo.fromPlatform(),
                      builder: (context, autoFuture) {
                        String versionText = "Error checking version";
                        if (!autoFuture.hasData && version == null) {
                          version = "Checking";
                        }
                        version = autoFuture.data?.version;
                        versionText = "Version $version";
                        return CustomClickableCard(
                          onTap: changeTheme,
                          borderRadius: 0,
                          defaultColor: Colors.white,
                          clickedColor: Colors.grey.shade200,
                          text: versionText,
                          textStyle: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w500),
                        );
                      }),
                ),
              ],
            ),
            //About us
            Row(
              children: [
                Expanded(
                  child: CustomClickableCard(
                    onTap: clickAboutUs,
                    borderRadius: 0,
                    defaultColor: Colors.white,
                    clickedColor: Colors.grey.shade200,
                    text: "About Us",
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            //Terms and Condition
            Row(
              children: [
                Expanded(
                  child: CustomClickableCard(
                    onTap: clickTermAndCondition,
                    borderRadius: 0,
                    defaultColor: Colors.white,
                    clickedColor: Colors.grey.shade200,
                    text: "Terms and Condition",
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            //Privacy Policy
            Row(
              children: [
                Expanded(
                  child: CustomClickableCard(
                    onTap: clickPrivacyPolicy,
                    borderRadius: 0,
                    defaultColor: Colors.white,
                    clickedColor: Colors.grey.shade200,
                    text: "Privacy Policy",
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            //Acknowledgements
            Row(
              children: [
                Expanded(
                  child: CustomClickableCard(
                    onTap: clickAcknowledgements,
                    borderRadius: 0,
                    defaultColor: Colors.white,
                    clickedColor: Colors.grey.shade200,
                    text: "Acknowledgements",
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            //FAQ
            Row(
              children: [
                Expanded(
                  child: CustomClickableCard(
                    onTap: clickFAQ,
                    borderRadius: 0,
                    defaultColor: Colors.white,
                    clickedColor: Colors.grey.shade200,
                    text: "FAQ",
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            //FAQ
            Row(
              children: [
                Expanded(
                  child: CustomClickableCard(
                    onTap: clickLogOut,
                    borderRadius: 0,
                    defaultColor: Colors.white,
                    clickedColor: Colors.grey.shade200,
                    text: "Log out",
                    showClickable: true,
                    textStyle: const TextStyle(
                        color: Colors.red,
                        fontSize: 15,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
