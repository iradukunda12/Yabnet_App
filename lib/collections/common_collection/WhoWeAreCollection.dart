import 'package:flutter/material.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/components/CustomOnClickContainer.dart';
import 'package:yabnet/operations/MembersOperation.dart';
import 'package:yabnet/supabase/SupabaseConfig.dart';

import '../../components/CustomCircularButton.dart';
import '../../components/CustomProject.dart';
import '../../components/EllipsisText.dart';
import '../../db_references/AppFile.dart';
import '../../db_references/Members.dart';
import '../../main.dart';
import '../../pages/common_pages/PdfVieverPage.dart';
import '../../services/AppFileService.dart';

class WhoWeAreCollection extends StatefulWidget {
  const WhoWeAreCollection({super.key});

  @override
  State<WhoWeAreCollection> createState() => _WhoWeAreCollectionState();
}

class _WhoWeAreCollectionState extends State<WhoWeAreCollection> {
  WidgetStateNotifier<bool> knowUsNotifier =
      WidgetStateNotifier(currentValue: false);

  @override
  void initState() {
    super.initState();
    getKnowUs();
  }

  void getKnowUs() {
    MembersOperation()
        .getUserRecord(field: dbReference(Members.knows_us))
        .then((value) {
      if (value == false || value == null) {
        knowUsNotifier.sendNewState(true);
      }
    });
  }

  void onTapAboutUs() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => PdfViewerPage(
                  localIdentity: dbReference(AppFile.abus),
                  pdfTitle: 'About Us',
                  appFileNotifier: AppFileService().aboutUsNotifier,
                ))).then((value) {
      setNormalUiViewOverlay();
    });
  }

  void handleUserKnowsUs() {
    String? userId = SupabaseConfig.client.auth.currentUser?.id;

    knowUsNotifier.sendNewState(false);
    if (userId != null) {
      MembersOperation.updateTheValue(dbReference(Members.knows_us), true)
          .then((value) {
        knowUsNotifier.sendNewState(false);
      });
      MembersOperation().updateUserKnowsAboutUs(userId, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WidgetStateConsumer(
        widgetStateNotifier: knowUsNotifier,
        widgetStateBuilder: (context, knowsUs) {
          if (knowsUs == null || knowsUs == false) return SizedBox();
          return Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: CustomOnClickContainer(
                      defaultColor: Colors.grey.shade100,
                      clickedColor: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(15),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        height: 5,
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                              child: Text(
                                            "Who we are?",
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 24),
                                          )),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                CustomCircularButton(
                                  imagePath: null,
                                  mainAlignment: Alignment.center,
                                  iconColor: Colors.black,
                                  onPressed: handleUserKnowsUs,
                                  icon: Icons.clear,
                                  gap: 8,
                                  width: 30,
                                  height: 30,
                                  iconSize: 24,
                                  defaultBackgroundColor: Colors.transparent,
                                  colorImage: true,
                                  showShadow: false,
                                  clickedBackgroundColor:
                                      const Color(getDarkGreyColor)
                                          .withOpacity(0.4),
                                ),
                              ],
                            ),
                            EllipsisText(
                              text: 'We are YABNET – the Young Adventist'
                                  ' Professionals and Business Network!. At YABNET, '
                                  'we are committed to fostering a vibrant and '
                                  'supportive community for professionals, '
                                  'entrepreneurs, and businesses within the'
                                  ' Adventist community and beyond.',
                              maxLength: 120,
                              onMorePressed: () {},
                              textStyle:
                                  TextStyle(color: Colors.black, fontSize: 14),
                              moreText: 'more',
                            ),
                            SizedBox(
                              height: 4,
                            ),
                            Row(
                              children: [
                                Expanded(
                                    child: Divider(
                                  color: Colors.black.withOpacity(0.7),
                                )),
                              ],
                            ),
                            CustomOnClickContainer(
                              defaultColor: Colors.transparent,
                              clickedColor: Colors.grey.shade200,
                              padding: EdgeInsets.all(4),
                              borderRadius: BorderRadius.circular(8),
                              onTap: onTapAboutUs,
                              child: Row(
                                children: [
                                  Text(
                                    "Learn more",
                                    textScaler: TextScaler.noScaling,
                                    style: TextStyle(
                                        color: Colors.black.withOpacity(0.7),
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(
                                    width: 4,
                                  ),
                                  Icon(Icons.link_rounded,
                                      color: Colors.black.withOpacity(0.7))
                                ],
                              ),
                            )
                          ],
                        ),
                      )),
                ),
              ],
            ),
          );
        });
  }
}
