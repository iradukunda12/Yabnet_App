import 'package:flutter/material.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';

import '../../data_notifiers/RecentSearchNotifier.dart';
import '../../data_notifiers/SearchSuggestionNotifier.dart';
import '../../data_notifiers/SearchedPageNotifier.dart';

class SearchRecentPage extends StatefulWidget {
  final WidgetStateNotifier<Map> searchResultNotifier;
  final WidgetStateNotifier<List<SearchSuggestionData>>
      searchSuggestionNotifier;
  final WidgetStateNotifier<SearchTextData> searchTextNotifier;

  const SearchRecentPage(
      {super.key,
      required this.searchTextNotifier,
      required this.searchResultNotifier,
      required this.searchSuggestionNotifier});

  @override
  State<SearchRecentPage> createState() => _SearchRecentPageState();
}

class _SearchRecentPageState extends State<SearchRecentPage> {
  int getSubList(
      int minLength, int maxLength, int limit, int listA, int listB) {
    int controlLength = listA;

    if (listB >= limit) {
      return 1;
    }

    if (listB > 0) {
      int difference = limit - listB;
      if (listA > difference) {
        return difference;
      }
    }

    if (listB >= limit && listA > minLength) {
      return minLength;
    }

    if (controlLength > maxLength) {
      return maxLength;
    }

    return controlLength;
  }

  @override
  Widget build(BuildContext context) {
    return WidgetStateConsumer(
        widgetStateNotifier: widget.searchResultNotifier,
        widgetStateBuilder: (context, result) {
          return WidgetStateConsumer(
              widgetStateNotifier: widget.searchTextNotifier,
              widgetStateBuilder: (context, search) {
                return WidgetStateConsumer(
                    widgetStateNotifier: widget.searchSuggestionNotifier,
                    widgetStateBuilder: (context, suggestions) {
                      return WidgetStateConsumer(
                          widgetStateNotifier: RecentSearchNotifier().state,
                          widgetStateBuilder: (context, recentTexts) {
                            if (recentTexts == null) return const SizedBox();

                            List<String> resultCheck = recentTexts
                                .where((element) =>
                                    element.contains(search?.text ?? '') ||
                                    search?.text.isEmpty == true)
                                .toList();
                            resultCheck.sort();
                            // List<String> finalResult = resultCheck.sublist(0, resultCheck.length > 5 ? 5 : resultCheck.length);
                            List<String> finalResult = resultCheck.sublist(
                                0,
                                getSubList(4, 15, 20, resultCheck.length,
                                    suggestions?.length ?? 0));

                            if (finalResult.isEmpty) return const SizedBox();

                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Recents",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                    GestureDetector(
                                        onTap: () {
                                          RecentSearchNotifier().clearRecents();
                                        },
                                        child: Icon(
                                          Icons.cancel,
                                          color: Colors.black.withOpacity(0.8),
                                          size: 24,
                                        )),
                                  ],
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                                for (int index = 0;
                                    index < finalResult.length;
                                    index++)
                                  Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              SearchedPageNotifier()
                                                  .handleSearchTextClickFromRecent(
                                                      finalResult[index]);
                                              RecentSearchNotifier()
                                                  .useRecentSearch(
                                                      finalResult[index]);
                                            },
                                            child: Text(
                                              finalResult[index],
                                              style: TextStyle(
                                                  color: Colors.black
                                                      .withOpacity(0.7),
                                                  fontSize: 16),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 8,
                                        ),
                                        GestureDetector(
                                            onTap: () {
                                              RecentSearchNotifier()
                                                  .deleteRecent(
                                                      finalResult[index]);
                                            },
                                            child: Icon(
                                              Icons.clear,
                                              color:
                                                  Colors.black.withOpacity(0.7),
                                              size: 20,
                                            )),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          });
                    });
              });
        });
  }
}
