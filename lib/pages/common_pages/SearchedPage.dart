import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';

import '../../components/CustomCircularButton.dart';
import '../../components/CustomProject.dart';
import '../../data_notifiers/PostSearchNotifier.dart';
import '../../data_notifiers/SearchSuggestionNotifier.dart';
import '../../data_notifiers/SearchedPageNotifier.dart';
import '../../main.dart';
import 'SearchRecentPage.dart';
import 'SuggestedForYouPage.dart';

class SearchedPage extends StatefulWidget {
  const SearchedPage({super.key});

  @override
  State<SearchedPage> createState() => _SearchedPageState();
}

class _SearchedPageState extends State<SearchedPage> {
  TextEditingController searchResultController = TextEditingController();
  WidgetStateNotifier<bool> suggestedPinnedController = WidgetStateNotifier();

  @override
  void dispose() {
    super.dispose();
    suggestedPinnedController.sendNewState(true);
    searchResultController.dispose();
  }

  void openNavigationBar(BuildContext scaffoldContext) {
    Scaffold.of(scaffoldContext).openDrawer();
  }

  @override
  void initState() {
    super.initState();
    setLightUiViewOverlay();
    SearchedPageNotifier().attachTextListener(searchResultController);
    PostSearchNotifier().startSearch();
  }

  void performBackPressed() {
    try {
      if (KeyboardVisibilityProvider.isKeyboardVisible(context)) {
        hideKeyboard(context).then((value) {});
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      Navigator.pop(context);
    }
  }

  void popped(bool pop) {
    searchResultController.clear();
  }

  void clearSearch() {
    searchResultController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: PopScope(
          onPopInvoked: popped,
          child: WidgetStateConsumer(
              widgetStateNotifier: suggestedPinnedController,
              widgetStateBuilder: (context, snapshot) {
                return Column(
                  children: [
                    // Top buttons
                    const SizedBox(
                      height: 24,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CustomCircularButton(
                            imagePath: null,
                            mainAlignment: Alignment.center,
                            iconColor: Color(getDarkGreyColor),
                            onPressed: performBackPressed,
                            icon: Icons.arrow_back,
                            gap: 8,
                            width: 45,
                            height: 45,
                            iconSize: 35,
                            defaultBackgroundColor: Colors.transparent,
                            colorImage: true,
                            showShadow: false,
                            clickedBackgroundColor:
                                const Color(getDarkGreyColor).withOpacity(0.4),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child: SizedBox(
                              // height: 40,
                              child: TextField(
                                textAlignVertical: TextAlignVertical.center,
                                controller: searchResultController,
                                cursorHeight: 22,
                                keyboardType: TextInputType.text,
                                style:
                                    TextStyle(decoration: TextDecoration.none),
                                decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: UnderlineInputBorder(
                                        borderSide: BorderSide.none),
                                    isDense: true,
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade400)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide(
                                            color: const Color(getMainPinkColor)
                                                .withOpacity(0.4))),
                                    hintText: "Search here",
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Colors.grey.shade700,
                                    )),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          CustomCircularButton(
                            imagePath: null,
                            mainAlignment: Alignment.center,
                            iconColor: Color(getDarkGreyColor),
                            onPressed: clearSearch,
                            icon: Icons.clear,
                            gap: 8,
                            width: 45,
                            height: 45,
                            iconSize: 35,
                            defaultBackgroundColor: Colors.transparent,
                            colorImage: true,
                            showShadow: false,
                            clickedBackgroundColor:
                                const Color(getDarkGreyColor).withOpacity(0.4),
                          ),
                        ],
                      ),
                    ),

                    Row(
                      children: [Expanded(child: Divider())],
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: SearchRecentPage(
                                searchTextNotifier:
                                    SearchedPageNotifier().searchTextNotifier,
                                searchSuggestionNotifier:
                                    SearchSuggestionNotifier().state,
                                searchResultNotifier:
                                    SearchedPageNotifier().searchResultNotifier,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: SuggestedForYouPage(
                                searchTextNotifier:
                                    SearchedPageNotifier().searchTextNotifier,
                                searchResultNotifier:
                                    SearchedPageNotifier().searchResultNotifier,
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  ],
                );
              }),
        ),
      ),
    );
  }
}
