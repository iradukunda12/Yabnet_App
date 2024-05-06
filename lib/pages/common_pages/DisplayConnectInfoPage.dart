import 'package:flutter/material.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/components/CustomProject.dart';
import 'package:yabnet/data_notifiers/UserConnectsNotifier.dart';
import 'package:yabnet/db_references/Connect.dart';
import 'package:yabnet/operations/ConnectOperation.dart';
import 'package:yabnet/supabase/SupabaseConfig.dart';

import '../../builders/ControlledStreamBuilder.dart';
import '../../builders/CustomWrapListBuilder.dart';
import '../../collections/common_collection/ProfileImage.dart';
import '../../components/CustomButtonRefreshCard.dart';
import '../../components/CustomCircularButton.dart';
import '../../components/CustomOnClickContainer.dart';
import '../../data/ConnectInfo.dart';
import '../../main.dart';
import '../../operations/MembersOperation.dart';
import 'MemberProfilePage.dart';
import 'ProfilePage.dart';

class DisplayConnectInfoPage extends StatefulWidget {
  final String forMember;
  final Connect titleType;
  final UserConnectsNotifier userConnectsNotifier;
  final RetryStreamListener connectionRetryStreamListener;

  const DisplayConnectInfoPage(
      {super.key,
      required this.forMember,
      required this.titleType,
      required this.userConnectsNotifier,
      required this.connectionRetryStreamListener});

  @override
  State<DisplayConnectInfoPage> createState() => _DisplayConnectInfoPageState();
}

class _DisplayConnectInfoPageState extends State<DisplayConnectInfoPage> {
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

  void removeThisUser(ConnectInfo connectInfo) {
    if (widget.titleType == Connect.connect) {
      disconnectFromConnect(connectInfo);
    } else if (widget.titleType == Connect.connection) {
      disconnectFromConnection(connectInfo);
    }
  }

  void disconnectFromConnection(ConnectInfo connectInfo) {
    String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';
    if (thisUser.isEmpty) {
      showToastMobile(msg: "An error has occurred");
      return;
    }
    ConnectOperation()
        .disconnectMember(connectInfo.membersId, thisUser)
        .then((value) {
      widget.userConnectsNotifier.removeConnection(connectInfo);
    });
  }

  void disconnectFromConnect(ConnectInfo connectInfo) {
    String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';
    if (thisUser.isEmpty) {
      showDebug(msg: "An error has occurred");
      return;
    }
    ConnectOperation()
        .disconnectMember(thisUser, connectInfo.membersId)
        .then((value) {
      widget.userConnectsNotifier.removeConnect(connectInfo);
    });
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
                  WidgetStateConsumer(
                      widgetStateNotifier: widget.userConnectsNotifier.state,
                      widgetStateBuilder: (context, data) {
                        List<ConnectInfo> connectInfo = [];
                        if (widget.titleType == Connect.connect) {
                          connectInfo = data?.connects ?? [];
                        } else if (widget.titleType == Connect.connection) {
                          connectInfo = data?.connection ?? [];
                        }
                        int size = connectInfo.length;
                        String title;
                        if ((widget.titleType == Connect.connect)) {
                          title = "Connect";
                        } else {
                          title = (widget.titleType == Connect.connection)
                              ? "Connection"
                              : "Error";
                        }
                        ;
                        return Text(
                          size > 1
                              ? "$size ${title.replaceFirst(title[0], title[0].toUpperCase())}s"
                              : "$size ${title.replaceFirst(title[0], title[0].toUpperCase())}",
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
              child: MultiWidgetStateConsumer(
                  widgetStateListNotifiers: [
                    widget.userConnectsNotifier.state,
                    searchNotifier
                  ],
                  widgetStateListBuilder: (
                    context,
                  ) {
                    final data = widget.userConnectsNotifier.state.currentValue;

                    List<ConnectInfo> connectInfo = [];
                    if (widget.titleType == Connect.connect) {
                      connectInfo = data?.connects ?? [];
                    } else if (widget.titleType == Connect.connection) {
                      connectInfo = data?.connection ?? [];
                    }

                    final filterText = searchNotifier.currentValue;
                    if (connectInfo.isEmpty == true) {
                      String title;
                      if ((widget.titleType == Connect.connect)) {
                        title = "Connect";
                      } else {
                        title = (widget.titleType == Connect.connection)
                            ? "Connection"
                            : "Error";
                      }
                      ;
                      return Center(
                          child: CustomButtonRefreshCard(
                              topIcon: const Icon(
                                Icons.not_interested,
                                size: 50,
                              ),
                              retryStreamListener:
                                  widget.connectionRetryStreamListener,
                              displayText:
                                  "There are no user ${title.toLowerCase()}s yet."));
                    }

                    final displayConnection = connectInfo
                        .where((element) =>
                            element.membersFullname
                                .toLowerCase()
                                .contains(filterText?.toLowerCase() ?? '') ||
                            (filterText?.isEmpty ?? true))
                        .toList();

                    return CustomWrapListBuilder(
                        paginateSize: 20,
                        retryStreamListener:
                            widget.connectionRetryStreamListener,
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
                                CustomOnClickContainer(
                                    onTap: () {
                                      removeThisUser(connectInfo);
                                    },
                                    defaultColor: Colors.transparent,
                                    clickedColor: Colors.grey.shade200,
                                    border:
                                        Border.all(color: Colors.grey.shade400),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6, horizontal: 10),
                                      child: Text(
                                        "Remove",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Colors.black.withOpacity(0.8),
                                            fontSize: 14),
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
