import 'package:flutter/material.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/components/CustomProject.dart';
import 'package:yabnet/db_references/Connect.dart';
import 'package:yabnet/operations/ConnectOperation.dart';
import 'package:yabnet/supabase/SupabaseConfig.dart';

import '../../components/CustomCircularButton.dart';
import '../../components/NetworkCard.dart';
import '../../data/ConnectInfo.dart';
import '../../data/NetworkConnectInfo.dart';
import '../../data_notifiers/ConnectFieldNotifer.dart';
import '../../data_notifiers/NetworkConnectsNotifier.dart';
import 'MemberProfilePage.dart';
import 'ProfilePage.dart';

class DisplayAllProfessionMemberPage extends StatefulWidget {
  final NetworkConnectsNotifier networkConnectsNotifier;
  final ConnectFieldNotifier connectFieldNotifier;

  const DisplayAllProfessionMemberPage({
    super.key,
    required this.networkConnectsNotifier,
    required this.connectFieldNotifier,
  });

  @override
  State<DisplayAllProfessionMemberPage> createState() =>
      _DisplayAllProfessionMemberPageState();
}

class _DisplayAllProfessionMemberPageState
    extends State<DisplayAllProfessionMemberPage> {
  void performBackPressed() {
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    setLightUiViewOverlay();
  }

  @override
  void dispose() {
    super.dispose();
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
                    widget.connectFieldNotifier.state.currentValue?.firstOrNull
                            ?.membersField ??
                        "Error",
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
                      widgetStateNotifier: widget.connectFieldNotifier.state,
                      widgetStateBuilder: (context, data) {
                        int size = data?.length ?? 0;
                        return Text(
                          size > 1 ? "$size members" : "$size member",
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        );
                      })
                ],
              ),
            ),

            SizedBox(
              height: 16,
            ),

            Expanded(
              child: WidgetStateConsumer(
                  widgetStateNotifier: widget.connectFieldNotifier.state,
                  widgetStateBuilder: (context, data) {
                    if (data == null || data.isEmpty == true) return SizedBox();
                    return NetworkCard(
                      forAll: true,
                      connectInfoList: data,
                      onHandleClick: handleConnectClick,
                    );
                  }),
            )
          ],
        ),
      ),
    );
  }

  void handleConnectClick(
      NetworkConnectInfo? networkConnectInfo, Connect connect) {
    if (networkConnectInfo == null) {
      showToastMobile(msg: "An error has occurred");
      return;
    } else {
      String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';

      if (thisUser.isEmpty) {
        showToastMobile(msg: "An error has occurred");
        return;
      }

      if (connect == Connect.connect) {
        ConnectOperation()
            .connectToMember(networkConnectInfo.membersId, thisUser)
            .then((value) {
          widget.networkConnectsNotifier.removeNetworkInfo(networkConnectInfo);
        });
      } else if (connect == Connect.viewProfile) {
        String membersId = networkConnectInfo.membersId;
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
    }
  }
}
