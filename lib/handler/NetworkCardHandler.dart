import 'package:flutter/material.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/components/CustomProject.dart';
import 'package:yabnet/components/NetworkCard.dart';
import 'package:yabnet/data_notifiers/ConnectFieldNotifer.dart';
import 'package:yabnet/data_notifiers/NetworkConnectsNotifier.dart';
import 'package:yabnet/operations/ConnectOperation.dart';

import '../data/NetworkConnectInfo.dart';
import '../db_references/Connect.dart';
import '../pages/common_pages/DisplayAllProfessionMemberPage.dart';
import '../pages/common_pages/MemberProfilePage.dart';
import '../pages/common_pages/ProfilePage.dart';
import '../supabase/SupabaseConfig.dart';

class NetworkCardHandler extends StatefulWidget {
  final int index;
  final ValueChanged<bool> hasData;
  final NetworkConnectsNotifier networkConnectsNotifier;
  final ConnectFieldNotifier connectFieldNotifier;

  const NetworkCardHandler({
    super.key,
    required this.networkConnectsNotifier,
    required this.connectFieldNotifier,
    required this.index,
    required this.hasData,
  });

  @override
  State<NetworkCardHandler> createState() => _NetworkCardHandlerState();
}

class _NetworkCardHandlerState extends State<NetworkCardHandler> {
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
      } else if (connect == Connect.seeAll) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DisplayAllProfessionMemberPage(
                      networkConnectsNotifier: widget.networkConnectsNotifier,
                      connectFieldNotifier: widget.connectFieldNotifier,
                    ))).then((value) {
          setNormalUiViewOverlay();
        });
      } else if (connect == Connect.viewProfile) {
        String membersId = networkConnectInfo.membersId;
        String? thisUser = SupabaseConfig.client.auth.currentUser?.id;

        if (thisUser == membersId) {
          Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ProfilePage()))
              .then((value) {
            setNormalUiViewOverlay();
          });
        } else {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => MembersProfilePage(
                        membersId: membersId,
                      ))).then((value) {
            setNormalUiViewOverlay();
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WidgetStateConsumer(
        widgetStateNotifier: widget.connectFieldNotifier.state,
        widgetStateBuilder: (context, data) {
          widget.hasData(data?.isNotEmpty ?? false);
          if (data == null || data.isEmpty == true) return SizedBox();
          return NetworkCard(
            connectInfoList: data,
            onHandleClick: handleConnectClick,
          );
        });
  }
}
