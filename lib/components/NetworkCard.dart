import 'package:flutter/material.dart';
import 'package:yabnet/components/CustomProject.dart';
import 'package:yabnet/main.dart';
import 'package:yabnet/operations/MembersOperation.dart';

import '../collections/common_collection/ProfileImage.dart';
import '../data/NetworkConnectInfo.dart';
import '../db_references/Connect.dart';
import 'CustomOnClickContainer.dart';

class NetworkCard extends StatefulWidget {
  final bool forAll;
  final List<NetworkConnectInfo> connectInfoList;
  final void Function(NetworkConnectInfo? networkConnectInfo, Connect connect)
      onHandleClick;

  const NetworkCard(
      {super.key,
      required this.connectInfoList,
      required this.onHandleClick,
      this.forAll = false});

  @override
  State<NetworkCard> createState() => _NetworkCardState();
}

class _NetworkCardState extends State<NetworkCard> {
  Widget connectCard(NetworkConnectInfo networkConnectInfo) {
    double top = 8;

    int connectLength = networkConnectInfo.connectData.length;

    if (networkConnectInfo.membersBio == null) {
      top += 40;
    }
    if (connectLength <= 0) {
      if (networkConnectInfo.membersBio == null) {
        top += 10;
      } else {
        top += 20;
      }
    }

    return Container(
      height: 250,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade500),
      ),
      child: Stack(
        children: [
          Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 40.0 + top,
                      color: Colors.grey,
                    ),
                  ),
                ],
              )),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(top: top),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomOnClickContainer(
                    defaultColor: Colors.grey.shade200,
                    clickedColor: Colors.grey.shade300,
                    height: 80,
                    width: 80,
                    clipBehavior: Clip.hardEdge,
                    shape: BoxShape.circle,
                    child: ProfileImage(
                      fullName: networkConnectInfo.membersFullname,
                      canDisplayImage: true,
                      fromHome: true,
                      imageUri: MembersOperation().getMemberProfileBucketPath(
                          networkConnectInfo.membersId,
                          networkConnectInfo.membersProfileIndex),
                      iconSize: 50,
                      imageUrl: (imageAddress) {},
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      widget.onHandleClick(
                          networkConnectInfo, Connect.viewProfile);
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        networkConnectInfo.membersFullname,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (networkConnectInfo.membersBio != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          networkConnectInfo.membersBio!,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.black.withOpacity(0.7),
                              fontSize: 14),
                        ),
                      ),
                    ),
                  if (connectLength > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "$connectLength ${connectLength > 1 ? "connect" : "connects"}",
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.black.withOpacity(0.6), fontSize: 13),
                      ),
                    ),
                  Expanded(child: SizedBox()),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomOnClickContainer(
                              onTap: () {
                                widget.onHandleClick(
                                    networkConnectInfo, Connect.connect);
                              },
                              defaultColor: Colors.transparent,
                              clickedColor: Colors.grey.shade200,
                              border:
                                  Border.all(color: Color(getMainPinkColor)),
                              borderRadius: BorderRadius.circular(50),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                    child: Text(
                                  "Connect",
                                  style:
                                      TextStyle(color: Color(getMainPinkColor)),
                                )),
                              )),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget getConnectCardView(List<NetworkConnectInfo> networkConnectList) {
    final subGroups = createSubgroups(networkConnectList, 2).sublist(
        0,
        (!widget.forAll)
            ? (networkConnectList.length >= 2)
                ? 1
                : networkConnectList.length
            : networkConnectList.length - 1);
    return Column(
      children: [
        for (int index = 0; index < subGroups.length; index++)
          Padding(
            padding: EdgeInsets.only(
                top: (index == 1) ? 4 : 0, bottom: (index == 0) ? 4 : 0),
            child: Row(
              children: [
                for (int position = 0;
                    position < subGroups[index].length;
                    position++)
                  Expanded(
                      child: Padding(
                    padding: EdgeInsets.only(
                        left: (position == 1) ? 4 : 0,
                        right: (position == 0) ? 4 : 0),
                    child: Builder(builder: (context) {
                      NetworkConnectInfo networkConnectInfo =
                          networkConnectList[position];
                      return connectCard(networkConnectInfo);
                    }),
                  ))
              ],
            ),
          ),
        if (networkConnectList.length > 2 && !widget.forAll)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: CustomOnClickContainer(
              onTap: () {
                widget.onHandleClick(networkConnectList.first, Connect.seeAll);
              },
              defaultColor: Colors.transparent,
              clickedColor: Color(getMainPinkColor).withOpacity(0.15),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(
                      "See All",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Color(getMainPinkColor),
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    )),
                  ],
                ),
              ),
            ),
          )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(getDarkGreyColor),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: !widget.forAll ? 8.0 : 0),
        child: Container(
          decoration: BoxDecoration(color: Colors.white),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!widget.forAll)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            widget.connectInfoList.first.membersField,
                            style: TextStyle(color: Colors.black, fontSize: 16),
                          ),
                        ),
                      if (widget.forAll)
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                getConnectCardView(widget.connectInfoList),
                              ],
                            ),
                          ),
                        ),
                      if (!widget.forAll)
                        getConnectCardView(widget.connectInfoList),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
