import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yabnet/builders/ControlledStreamBuilder.dart';
import 'package:yabnet/builders/CustomWrapListBuilder.dart';
import 'package:yabnet/components/CustomProject.dart';
import 'package:yabnet/data/HomePagePostData.dart';
import 'package:yabnet/data_notifiers/CommentsNotifier.dart';
import 'package:yabnet/data_notifiers/ConnectsNotifier.dart';
import 'package:yabnet/data_notifiers/PostNotifier.dart';
import 'package:yabnet/data_notifiers/PostProfileNotifier.dart';
import 'package:yabnet/data_notifiers/RepostsNotifier.dart';
import 'package:yabnet/operations/ConnectOperation.dart';
import 'package:yabnet/operations/PostOperation.dart';

import '../data_notifiers/LikesNotifier.dart';
import '../pages/common_pages/DisplayPostMediaPage.dart';
import '../supabase/SupabaseConfig.dart';
import 'HomePageCommentHandler.dart';

class ExtendedPostViewHandler extends StatefulWidget {
  final bool fromHome;
  final int? startAt;
  final HomePagePostData homePagePostData;
  final CommentsNotifier commentsNotifier;
  final LikesNotifier likesNotifier;
  final PostNotifier? postNotifier;
  final RepostsNotifier repostsNotifier;
  final ConnectsNotifier connectsNotifier;
  final PostProfileNotifier postProfileNotifier;

  const ExtendedPostViewHandler(
      {super.key,
      required this.homePagePostData,
      required this.commentsNotifier,
      required this.postNotifier,
      this.startAt,
      required this.likesNotifier,
      required this.repostsNotifier,
      required this.connectsNotifier,
      required this.postProfileNotifier,
      this.fromHome = false});

  @override
  State<ExtendedPostViewHandler> createState() =>
      _ExtendedPostViewHandlerState();
}

class _ExtendedPostViewHandlerState extends State<ExtendedPostViewHandler>
    implements CommentsImplement {
  RetryStreamListener commentRetryStreamListener = RetryStreamListener();
  PaginationProgressController commentPaginationProgressController =
      PaginationProgressController();

  @override
  BuildContext? getLatestContext() {
    return context;
  }

  @override
  RetryStreamListener? getRetryStreamListener() {
    return commentRetryStreamListener;
  }

  @override
  PaginationProgressController? getPaginationProgressController() {
    return commentPaginationProgressController;
  }

  @override
  void initState() {
    super.initState();
    widget.commentsNotifier
        .start(this, widget.homePagePostData.postId, startFetching: false);
  }

  @override
  void dispose() {
    super.dispose();
    widget.commentsNotifier.stop();
  }

  void clickOnLike() {
    bool online = widget.homePagePostData.online;
    String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';
    bool isLiked = widget.likesNotifier
        .getLatestData()
        .where((element) => element.membersId == thisUser)
        .isNotEmpty;

    if (online) {
      if (!isLiked) {
        addLocalLike();
        addOnlineLike();
      } else {
        removeLocalLike();
        removeOnlineLike();
      }
    } else {
      if (isLiked) {
        removeLocalLike();
        removeOnlineLike();
      } else {
        addLocalLike();
      }
    }
  }

  void addLocalLike() {
    String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';
    widget.likesNotifier.addLikes(thisUser);
  }

  void removeLocalLike() {
    String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';
    widget.likesNotifier.removeLikes(thisUser);
  }

  void addOnlineLike() async {
    String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';
    PostOperation()
        .addLike(widget.homePagePostData.postId, thisUser)
        .then((value) {})
        .onError((error, stackTrace) {
      showDebug(msg: "$error $stackTrace");
      showToastMobile(msg: "Unable to like post right now");
    });
  }

  void removeOnlineLike() {
    String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';
    PostOperation()
        .removeLike(widget.homePagePostData.postId, thisUser)
        .then((value) {})
        .onError((error, stackTrace) {
      showDebug(msg: "$error $stackTrace");
      showToastMobile(msg: "Unable to remove like from post");
    });
  }

  void clickOnConnect() {
    bool online = widget.homePagePostData.online;
    String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';
    bool connectedTo = widget.connectsNotifier
            .getLatestData()
            .where((element) => element.membersId == thisUser)
            .isNotEmpty ??
        false;

    if (online) {
      if (!connectedTo) {
        addLocalConnect();
        addOnlineConnect();
      } else {
        removeLocalConnect();
        removeOnlineConnect();
      }
    } else {
      if (connectedTo) {
        removeLocalConnect();
        removeOnlineConnect();
      } else {
        addLocalConnect();
      }
    }
  }

  void addLocalConnect() {
    String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';
    String postBy = widget.homePagePostData.postBy;
    widget.postNotifier?.getAllPostByUserId(postBy).forEach((element) {
      widget.postNotifier?.makeUpdateOnFindByPostId(
          widget.homePagePostData.postId,
          online: false);
    });
    widget.connectsNotifier
        .addConnect(widget.homePagePostData.postBy, thisUser);
  }

  void removeLocalConnect() {
    String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';
    String postBy = widget.homePagePostData.postBy;
    widget.postNotifier?.getAllPostByUserId(postBy).forEach((element) {
      widget.postNotifier?.makeUpdateOnFindByPostId(
          widget.homePagePostData.postId,
          online: false);
    });
    widget.connectsNotifier.removeConnect(thisUser);
  }

  void addOnlineConnect() async {
    String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';
    ConnectOperation()
        .connectToMember(widget.homePagePostData.postBy, thisUser)
        .then((value) {})
        .onError((error, stackTrace) {
      showDebug(msg: "$error $stackTrace");
      showToastMobile(msg: "Unable to connect to member");
    });
  }

  void removeOnlineConnect() {
    String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';
    ConnectOperation()
        .disconnectMember(widget.homePagePostData.postBy, thisUser)
        .then((value) {})
        .onError((error, stackTrace) {
      showDebug(msg: "$error $stackTrace");
      showToastMobile(msg: "Unable to remove member connection");
    });
  }

  void clickOnComment() {
    HomePageCommentHandler(
        context,
        widget.homePagePostData,
        widget.commentsNotifier,
        commentRetryStreamListener,
        commentPaginationProgressController,
        fromExtended: true);
  }

  void repostThisPost() {
    String postId = widget.homePagePostData.postId;
    String? membersId = SupabaseConfig.client.auth.currentUser?.id;

    // Check for existence
    if (membersId == null) {
      showToastMobile(msg: "An unexpected error has occurred");
      return;
    }

    // Repost post
    showCustomProgressBar(context);
    PostOperation().repostPost(postId, membersId, true).then((value) {
      closeCustomProgressBar(context);
      addLocalReposted();
      showToastMobile(msg: "Reposted this post");
    }).onError((error, stackTrace) {
      closeCustomProgressBar(context);
      showDebug(msg: "$error $stackTrace");
      showToastMobile(msg: "Unable to repost");
    }); // Repost post
  }

  void addLocalReposted() {
    String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';
    widget.postNotifier?.makeUpdateOnFindByPostId(
        widget.homePagePostData.postId,
        online: false);
    widget.repostsNotifier.addRepost(thisUser);
  }

  void removeLocalReposted() {
    String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';
    widget.postNotifier?.makeUpdateOnFindByPostId(
        widget.homePagePostData.postId,
        online: false);
    widget.repostsNotifier.removePost(thisUser);
  }

  void removePostReposted() {
    String postId = widget.homePagePostData.postId;
    String? membersId = SupabaseConfig.client.auth.currentUser?.id;
    // Check for existence
    if (membersId == null) {
      showToastMobile(msg: "An unexpected error has occurred");
      return;
    }

    showCustomProgressBar(context);
    PostOperation().removeRepostedPost(postId, membersId).then((value) {
      closeCustomProgressBar(context);
      removeLocalReposted();
      showToastMobile(msg: "Remove repost from post");
    }).onError((error, stackTrace) {
      closeCustomProgressBar(context);
      showDebug(msg: "$error $stackTrace");
      showToastMobile(msg: "Unable to repost");
    });
  }

  void clickOnRepost() {
    String thisUser = SupabaseConfig.client.auth.currentUser?.id ?? '';
    bool reposted = widget.repostsNotifier
        .getLatestData()
        .where((element) => element.postBy == thisUser)
        .isNotEmpty;

    if (!reposted) {
      repostThisPost();
    } else {
      removePostReposted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DisplayPostMediaPage(
      startAt: widget.startAt,
      commentsNotifier: widget.commentsNotifier,
      onClickedQuick: (String operation) {
        if (operation == "Like") {
          clickOnLike();
        } else if (operation == "Connect") {
          clickOnConnect();
        } else if (operation == "Comment") {
          clickOnComment();
        } else if (operation == "Repost") {
          clickOnRepost();
        }
      },
      likesNotifier: widget.likesNotifier,
      homePagePostData: widget.homePagePostData,
      repostsNotifier: widget.repostsNotifier,
      postProfileNotifier: widget.postProfileNotifier,
      fromHome: widget.fromHome,
    );
  }
}
