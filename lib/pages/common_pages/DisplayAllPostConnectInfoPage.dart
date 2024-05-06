import 'package:flutter/material.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/components/CustomProject.dart';

import '../../builders/CustomWrapListBuilder.dart';
import '../../collections/common_collection/ProfileImage.dart';
import '../../components/CustomCircularButton.dart';
import '../../components/CustomOnClickContainer.dart';
import '../../data/ConnectInfo.dart';
import '../../main.dart';
import '../../operations/MembersOperation.dart';
import '../../supabase/SupabaseConfig.dart';
import 'MemberProfilePage.dart';
import 'ProfilePage.dart';

class DisplayAllPostConnectInfoPage extends StatefulWidget {
  final String forMember;
  final List<ConnectInfo> allMentions;

  const DisplayAllPostConnectInfoPage({
    super.key,
    required this.forMember,
    required this.allMentions,
  });

  @override
  State<DisplayAllPostConnectInfoPage> createState() =>
      _DisplayAllPostConnectInfoPageState();
}

class _DisplayAllPostConnectInfoPageState
    extends State<DisplayAllPostConnectInfoPage> {
  TextEditingController searchResultController = TextEditingController();
  WidgetStateNotifier<String> searchNotifier = WidgetStateNotifier();

  void performBackPressed() {
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    setLightUiViewOverlay();
    searchNotifier.addController(searchResultController, (stateNotifier) {
      stateNotifier.sendNewState(searchResultController.text.trim());
    });
  }

  @override
  void dispose() {
    super.dispose();
    searchResultController.dispose();
  }

  void viewUserProfile(ConnectInfo connectInfo) {
    String membersId = connectInfo.membersId;
    String? thisUser = SupabaseConfig.client.auth.currentUser?.id;

    if (thisUser == membersId) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => ProfilePage()));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MembersProfilePage(
                    membersId: membersId,
                  )));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Back Button
            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              child: Row(children: [
                CustomCircularButton(
                  imagePath: null,
                  iconColor: Colors.black,
                  onPressed: performBackPressed,
                  icon: Icons.arrow_back,
                  width: 40,
                  height: 40,
                  iconSize: 30,
                  mainAlignment: Alignment.center,
                  defaultBackgroundColor: Colors.transparent,
                  clickedBackgroundColor: Colors.white,
                ),
                const SizedBox(
                  width: 8,
                ),
                Expanded(
                  child: Text(
                    "${widget.forMember}",
                    textScaleFactor: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ]),
            ),

            SizedBox(
              height: 16,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Container(
                      height: 5,
                      width: 5,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade600, shape: BoxShape.circle),
                    ),
                  ),
                  Builder(builder: (context) {
                    int size = widget.allMentions.length;
                    return Text(
                      size > 1 ? "$size mentions" : "$size mention",
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    );
                  })
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        textAlignVertical: TextAlignVertical.bottom,
                        controller: searchResultController,
                        decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade400)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                    color: const Color(getMainPinkColor)
                                        .withOpacity(0.4))),
                            hintText: "Search here",
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.black,
                            )),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 16,
            ),
            Expanded(
              child: WidgetStateConsumer(
                  widgetStateNotifier: searchNotifier,
                  widgetStateBuilder: (context, filterText) {
                    if (widget.allMentions.isEmpty) {
                      return Center(
                          child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              "There are no mentions.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17),
                            ),
                          ),
                        ],
                      ));
                    }

                    final displayConnection = widget.allMentions
                        .where((element) =>
                            element.membersFullname
                                .toLowerCase()
                                .contains(filterText?.toLowerCase() ?? '') ||
                            (filterText?.isEmpty ?? true))
                        .toList();

                    return CustomWrapListBuilder(
                        paginateSize: 20,
                        itemCount: displayConnection.length,
                        shrinkWrap: false,
                        wrapListBuilder: (context, index) {
                          ConnectInfo connectInfo = displayConnection[index];

                          return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 24),
                              child: Row(children: [
                                Container(
                                    height: 40,
                                    width: 40,
                                    clipBehavior: Clip.hardEdge,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey.shade300,
                                    ),
                                    child: ProfileImage(
                                      iconSize: 40,
                                      textSize: 16,
                                      canDisplayImage: true,
                                      imageUri: MembersOperation()
                                          .getMemberProfileBucketPath(
                                              connectInfo.membersId,
                                              connectInfo.membersProfileIndex),
                                      fullName: connectInfo.membersFullname,
                                    )),
                                const SizedBox(
                                  width: 8,
                                ),
                                Expanded(
                                    child: CustomOnClickContainer(
                                  onTap: () {
                                    viewUserProfile(connectInfo);
                                  },
                                  defaultColor: Colors.transparent,
                                  clickedColor: Colors.transparent,
                                  child: Text(
                                    connectInfo.membersFullname,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                )),
                              ]));
                        });
                  }),
            )
          ],
        ),
      ),
    );
  }
}
