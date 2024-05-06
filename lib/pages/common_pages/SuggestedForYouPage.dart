import 'package:flutter/material.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/data/HomePagePostData.dart';
import 'package:yabnet/data_notifiers/PostNotifier.dart';

import '../../data_notifiers/CommentsNotifier.dart';
import '../../data_notifiers/ConnectsNotifier.dart';
import '../../data_notifiers/LikesNotifier.dart';
import '../../data_notifiers/PostProfileNotifier.dart';
import '../../data_notifiers/PostSearchNotifier.dart';
import '../../data_notifiers/RepostsNotifier.dart';
import '../../data_notifiers/SearchSuggestionNotifier.dart';
import '../../data_notifiers/SearchedPageNotifier.dart';
import '../../db_references/NotifierType.dart';
import '../../handler/HomePagePostViewHandler.dart';

class SuggestedForYouPage extends StatefulWidget {
  final WidgetStateNotifier<Map> searchResultNotifier;
  final WidgetStateNotifier<SearchTextData> searchTextNotifier;

  const SuggestedForYouPage(
      {super.key,
      required this.searchTextNotifier,
      required this.searchResultNotifier});

  @override
  State<SuggestedForYouPage> createState() => _SuggestedForYouPageState();
}

class _SuggestedForYouPageState extends State<SuggestedForYouPage> {
  Widget getSuggestionView(SearchSuggestionData suggestion) {
    if (suggestion.data is HomePagePostData) {
      HomePagePostData homePagePostData = suggestion.data as HomePagePostData;

      PostNotifier? postNotifier =
          PostSearchNotifier().getPostsNotifiers(homePagePostData.postId);

      CommentsNotifier? commentNotifier = postNotifier?.getCommentNotifier(
          homePagePostData.postId, NotifierType.external);
      LikesNotifier? likesNotifier = postNotifier?.getLikeNotifier(
          homePagePostData.postId, NotifierType.external);

      RepostsNotifier? repostNotifier = postNotifier?.getRepostsNotifier(
          homePagePostData.postId, NotifierType.external);

      ConnectsNotifier? connectsNotifier = postNotifier?.getConnectsNotifier(
          homePagePostData.postBy, NotifierType.external);

      PostProfileNotifier? postProfileNotifier =
          postNotifier?.getPostProfileNotifier(
              homePagePostData.postBy, NotifierType.external);

      bool showPost = commentNotifier != null &&
          likesNotifier != null &&
          repostNotifier != null &&
          connectsNotifier != null &&
          postProfileNotifier != null;

      return showPost
          ? HomePagePostViewHandler(
              index: 0,
              homePagePostData: homePagePostData,
              commentsNotifier: commentNotifier,
              postNotifier: postNotifier!,
              likesNotifier: likesNotifier,
              repostsNotifier: repostNotifier,
              connectsNotifier: connectsNotifier,
              postProfileNotifier: postProfileNotifier,
            )
          : SizedBox();
    }
    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    return WidgetStateConsumer(
        widgetStateNotifier: widget.searchResultNotifier,
        widgetStateBuilder: (context, result) {
          return WidgetStateConsumer(
              widgetStateNotifier: widget.searchTextNotifier,
              widgetStateBuilder: (context, text) {
                return WidgetStateConsumer(
                    widgetStateNotifier: SearchSuggestionNotifier().state,
                    widgetStateBuilder: (context, suggestions) {
                      List<Widget> suggestionViews = suggestions
                              ?.asMap()
                              .map((key, value) {
                                return MapEntry(key, getSuggestionView(value));
                              })
                              .values
                              .toList() ??
                          [];

                      List<Widget> displayedSuggestion =
                          suggestionViews.sublist(
                              0,
                              suggestionViews.length > 15
                                  ? 15
                                  : suggestionViews.length);

                      if (displayedSuggestion.isEmpty) return const SizedBox();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Suggested for you",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          for (int index = 0;
                              index < displayedSuggestion.length;
                              index++)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: displayedSuggestion[index],
                            ),
                        ],
                      );
                    });
              });
        });
  }
}
