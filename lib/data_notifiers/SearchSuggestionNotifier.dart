import 'package:widget_state_notifier/widget_state_notifier.dart';

class SearchSuggestionData {
  final String key;
  final String param;
  final dynamic data;

  SearchSuggestionData(
    this.key,
    this.param,
    this.data,
  );
}

class SearchSuggestionNotifier {
  static final SearchSuggestionNotifier instance =
      SearchSuggestionNotifier.internal();

  factory SearchSuggestionNotifier() => instance;

  SearchSuggestionNotifier.internal();

  WidgetStateNotifier<List<SearchSuggestionData>> state =
      WidgetStateNotifier(currentValue: []);

  List<String> getKeys() {
    return (state.currentValue ?? []).map((e) => e.key).toList();
  }

  bool removeKey(String key) {
    int found = getKeys().indexWhere((element) => element == key);
    if (found != -1) {
      state.currentValue?.removeAt(found);
    }
    return found != -1;
  }

  void addSuggestion(String key, String param, dynamic data) {
    state.currentValue ??= [];
    state.currentValue?.add(SearchSuggestionData(key, param, data));
  }

  void sendSuggestionUpdate() {
    state.currentValue?.sort((a, b) {
      return a.param.compareTo(b.param);
    });
    state.sendNewState(state.currentValue);
  }
}
