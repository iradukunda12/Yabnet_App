import 'package:flutter/cupertino.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';

import 'RecentSearchNotifier.dart';

enum SearchTextDirection { begin, forward, backward, end, changed, stagnat }

class SearchTextData {
  final SearchTextDirection searchTextDirection;
  final String text;

  SearchTextData(this.searchTextDirection, this.text);
}

class SearchedPageNotifier {
  static final SearchedPageNotifier instance = SearchedPageNotifier.internal();

  factory SearchedPageNotifier() => instance;

  SearchedPageNotifier.internal();

  WidgetStateNotifier<SearchTextData> searchTextNotifier = WidgetStateNotifier(
      currentValue: SearchTextData(SearchTextDirection.begin, ''));
  WidgetStateNotifier<Map> searchResultNotifier =
      WidgetStateNotifier(currentValue: {});

  int _previousLength = 0;

  TextEditingController? _editingController;

  String _searchText = "";

  void attachTextListener(TextEditingController textEditingController) {
    _editingController = null;
    _editingController = textEditingController;
    _editingController?.addListener(_addListener);
    RecentSearchNotifier().loadRecentSearches();
  }

  void _addListener() {
    int newLength = (_editingController?.text.length ?? 0);

    RecentSearchNotifier().loadRecentSearches();

    if ((newLength - _previousLength) == 1) {
      searchTextNotifier.sendNewState(SearchTextData(
          SearchTextDirection.forward, _editingController?.text ?? ''));
    } else if ((_previousLength - _previousLength) == 1) {
      searchTextNotifier.sendNewState(SearchTextData(
          SearchTextDirection.backward, _editingController?.text ?? ''));
    } else {
      if (newLength == 0) {
        searchTextNotifier.sendNewState(SearchTextData(
            SearchTextDirection.end, _editingController?.text ?? ''));
      } else {
        searchTextNotifier.sendNewState(SearchTextData(
            SearchTextDirection.changed, _editingController?.text ?? ''));
      }
    }

    _previousLength = _editingController?.text.length ?? 0;
  }

  void removeTextListener() {
    _editingController?.removeListener(_addListener);
  }

  void handleSearchTextClick(String finalResult) {
    _searchText = finalResult;
    if (_editingController?.text.isNotEmpty == true) {
      _editingController?.clear();
    } else {
      searchTextNotifier.sendNewState(SearchTextData(
          SearchTextDirection.end, _editingController?.text ?? ''));
    }
  }

  void handleSearchTextClickFromRecent(String finalResult) {
    _searchText = finalResult;
    _editingController?.text = _searchText;
  }
}
