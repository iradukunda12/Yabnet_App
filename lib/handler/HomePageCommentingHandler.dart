import 'package:flutter/material.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/components/CustomProject.dart';
import 'package:yabnet/data/HomePageCommentData.dart';
import 'package:yabnet/data/HomePagePostData.dart';
import 'package:yabnet/data_notifiers/CommentsNotifier.dart';
import 'package:yabnet/data_notifiers/ProfileNotifier.dart';
import 'package:yabnet/db_references/NotifierType.dart';
import 'package:yabnet/handler/HomePageCommentHandler.dart';
import 'package:yabnet/operations/CommentOperation.dart';
import 'package:yabnet/operations/MembersOperation.dart';
import 'package:yabnet/operations/PostOperation.dart';
import 'package:yabnet/supabase/SupabaseConfig.dart';

import '../collections/common_collection/ProfileImage.dart';
import '../components/CustomOnClickContainer.dart';
import '../db_references/Comments.dart';

class HomePageCommentingHandler extends StatefulWidget {
  final CommentsNotifier commentsNotifier;
  final HomePagePostData homePagePostData;
  final String? commentTo;
  final String? commentParent;
  final bool openKeyboard;
  final WidgetStateNotifier<CommentingReplyInfoData> commentingInfo;
  final WidgetStateNotifier<bool> openTextFocus;

  const HomePageCommentingHandler(
      {super.key,
      required this.homePagePostData,
      required this.commentsNotifier,
      this.commentTo,
      this.commentParent,
      required this.commentingInfo,
      required this.openTextFocus,
      required this.openKeyboard});

  @override
  State<HomePageCommentingHandler> createState() =>
      _HomePageCommentingHandlerState();
}

class _HomePageCommentingHandlerState extends State<HomePageCommentingHandler> {
  TextEditingController commentingTextController = TextEditingController();
  WidgetStateNotifier<bool> sendCommentNotifier = WidgetStateNotifier();
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    widget.openTextFocus.stream.listen((event) {
      if (widget.openTextFocus.currentValue == true && !focusNode.hasFocus) {
        FocusScope.of(context).requestFocus(focusNode);
      } else if (widget.openTextFocus.currentValue != true) {
        FocusScope.of(context).unfocus();
        hideKeyboard(context);
      }
    });

    sendCommentNotifier.addController(commentingTextController,
        (stateNotifier) {
      stateNotifier.sendNewState(commentingTextController.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    super.dispose();
    focusNode.dispose();
    commentingTextController.dispose();
    sendCommentNotifier.removeController();
  }

  void sendLocalMainCommentAdded(HomePageCommentData homePageCommentData) {
    widget.commentsNotifier.addLocalMainComment(homePageCommentData);
  }

  void sendLocalSubCommentAdded(
      HomePageCommentData homePageCommentData, String commentId) {
    widget.commentsNotifier.addLocalSubComment(homePageCommentData, commentId);
  }

  void sendANewComment() async {
    HomePageCommentData? commentToHomePageCommentData =
        widget.commentingInfo.currentValue?.homePageCommentData;
    String? commentTo = commentToHomePageCommentData?.commentId;
    String? commentParent =
        commentToHomePageCommentData?.commentParent ?? commentTo;
    String commentText = commentingTextController.text.trim();
    String postId = widget.homePagePostData.postId;
    String? membersId = SupabaseConfig.client.auth.currentUser?.id;

    showDebug(msg: commentToHomePageCommentData?.toJson());

    if (membersId == null) {
      showToastMobile(msg: "An error occurred");
      return;
    }

    hideKeyboard(context);

    String localCommentId =
        dbReference(Comments.local) + "(->)" + PostOperation().getUUID();

    HomePageCommentData _homePageCommentData = HomePageCommentData(
      localCommentId,
      membersId,
      DateTime.now().toUtc().toString(),
      commentText,
      [],
      false,
      commentTo,
      commentToHomePageCommentData?.commentBy,
      commentParent,
    );

    if (commentParent == null) {
      sendLocalMainCommentAdded(_homePageCommentData);
    } else {
      sendLocalSubCommentAdded(_homePageCommentData, commentParent);
    }

    commentingTextController.clear();
    clearReplyData();
    CommentOperation()
        .sendANewComment(commentText, membersId, postId,
            commentTo: commentTo, commentParent: commentParent)
        .then((value) async {
      if (value != null) {
        HomePageCommentData homePageCommentData = _homePageCommentData.copyWith(
          commentId: value[dbReference(Comments.id)],
          commentCreatedAt: value[dbReference(Comments.created_at)],
          online: true,
        );
        String? commentTo = homePageCommentData.commentTo;
        String? commentParent = homePageCommentData.commentParent;
        if (commentTo == null) {
          await widget.commentsNotifier.makeUpdateOnSuccessfulComment(
              localCommentId, homePageCommentData);
        } else {
          widget.commentsNotifier.makeUpdateOnSubSuccessfulComment(
              localCommentId, commentParent!, homePageCommentData);
        }
      } else {
        showToastMobile(msg: "An error occurred");
      }
    }).onError((error, stackTrace) {
      showToastMobile(msg: "An error occurred");
      showDebug(msg: "$error $stackTrace");
    });
  }

  void clearReplyData() {
    widget.openTextFocus.sendNewState(null);
    widget.commentingInfo.sendNewState(null);
  }

  BuildContext get latestContext => context;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder(
            initialData: widget.commentingInfo.currentValue,
            stream: widget.commentingInfo.stream,
            builder: (context, snapshot) {
              HomePageCommentData? commentToHomePageCommentData =
                  snapshot.data?.homePageCommentData;
              String? commentTo = commentToHomePageCommentData?.commentId;
              String? commentParent =
                  commentToHomePageCommentData?.commentParent ??
                      commentToHomePageCommentData?.commentId;
              final commentToBy = widget.commentsNotifier
                  .getPostProfileNotifier(
                      commentToHomePageCommentData?.commentBy ?? '',
                      NotifierType.normal)
                  ?.state;

              return WidgetStateConsumer(
                  widgetStateNotifier:
                      commentToBy ?? WidgetStateNotifier(currentValue: null),
                  widgetStateBuilder: (context, profile) {
                    return Column(
                      children: [
                        if (commentTo != null && commentToBy != null)
                          SizedBox(
                            height: 8,
                          ),
                        if (commentTo != null && commentToBy != null)
                          Row(
                            children: [
                              Builder(builder: (context) {
                                Color color = Colors.black.withOpacity(0.7);
                                return Row(
                                  children: [
                                    Text(
                                      "Replying",
                                      textScaler: TextScaler.noScaling,
                                      style:
                                          TextStyle(color: color, fontSize: 14),
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Icon(
                                      Icons.arrow_right,
                                      color: color,
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                  ],
                                );
                              }),
                              Expanded(
                                  child: Text(
                                profile?.fullName ?? "Error",
                                textScaler: TextScaler.noScaling,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.black.withOpacity(0.7),
                                    fontSize: 14),
                              )),
                              SizedBox(
                                width: 8,
                              ),
                              IconButton(
                                  onPressed: clearReplyData,
                                  icon: Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                    size: 24,
                                  ))
                            ],
                          ),
                      ],
                    );
                  });
            }),
        SizedBox(
          height: 8,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WidgetStateConsumer(
                widgetStateNotifier: ProfileNotifier().state,
                widgetStateBuilder: (context, data) {
                  return Container(
                      height: 40,
                      width: 40,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade300,
                      ),
                      child: ProfileImage(
                        iconSize: 40,
                        canDisplayImage: false,
                        imageUri: MembersOperation().getMemberProfileBucketPath(
                            data?.userId ?? "", data?.profileIndex),
                        fullName: data?.fullName ?? 'Error',
                      ));
                }),
            SizedBox(
              width: 5,
            ),
            Expanded(
              child: TextField(
                textAlignVertical: TextAlignVertical.center,
                focusNode: focusNode,
                controller: commentingTextController,
                style: TextStyle(color: Colors.black, fontSize: 14),
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 4,
                maxLength: 80,
                decoration: InputDecoration(
                  filled: false,
                  fillColor: Colors.transparent,
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey.shade400)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey.shade400)),
                  hintText: "Add a comment",
                ),
              ),
            ),
            StreamBuilder(
                initialData: sendCommentNotifier.currentValue,
                stream: sendCommentNotifier.stream,
                builder: (context, snapshot) {
                  if (snapshot.data != true) {
                    return SizedBox();
                  }
                  return Row(children: [
                    SizedBox(
                      width: 2,
                    ),
                    IconButton(
                        onPressed: () {
                          sendANewComment();
                        },
                        icon: Icon(Icons.arrow_upward))
                  ]);
                })
          ],
        ),
        if (widget.openKeyboard)
          CustomOnClickContainer(
            onTap: () {
              hideKeyboard(context);
            },
            padding: EdgeInsets.only(top: 8),
            defaultColor: Colors.grey.shade200,
            clickedColor: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Hide keyboard",
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                SizedBox(
                  width: 4,
                ),
                Icon(
                  Icons.cancel,
                  size: 24,
                  color: Colors.red,
                ),
                SizedBox(
                  width: 8,
                )
              ],
            ),
          ),
        if (!widget.openKeyboard)
          SizedBox(
            height: 16,
          )
      ],
    );
  }
}
