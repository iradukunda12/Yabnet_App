import 'package:yabnet/data/HomePagePostData.dart';
import 'package:yabnet/data_notifiers/PostNotifier.dart';
import 'package:yabnet/operations/PostOperation.dart';

import '../components/CustomProject.dart';
import '../db_references/Members.dart';
import '../db_references/NotifierType.dart';
import '../db_references/Post.dart';
import 'PostProfileNotifier.dart';
import 'SearchSuggestionNotifier.dart';
import 'SearchedPageNotifier.dart';

class PostSearchNotifier {
  static final PostSearchNotifier instance = PostSearchNotifier.internal();

  factory PostSearchNotifier() => instance;

  PostSearchNotifier.internal();

  final List<HomePagePostData> _data = [];

  bool started = false;

  final Map<String, PostNotifier> _postsNotifiers = {};

  PostNotifier? getPostsNotifiers(String postId) {
    return _postsNotifiers[postId];
  }

  PostSearchNotifier startSearch() {
    if (!started) {
      started = true;
      SearchedPageNotifier().searchTextNotifier.stream.listen((event) {
        if (event != null) {
          handleSearch(event);
        }
      });
    }
    return this;
  }

  List<String> keys = [];

  void handleSearch(SearchTextData searchTextData) {
    if (searchTextData.searchTextDirection == SearchTextDirection.forward ||
        searchTextData.searchTextDirection == SearchTextDirection.changed) {
      _fetchRelatedPostsData(searchTextData.text);
    }
    for (var key in keys) {
      SearchSuggestionNotifier().removeKey(key);
    }
    keys.clear();
    if (searchTextData.searchTextDirection == SearchTextDirection.end) {
      _data.clear();
      SearchSuggestionNotifier().sendSuggestionUpdate();
      return;
    }
    List<HomePagePostData> search = _data.where((element) {
      PostProfileNotifier? postProfileNotifier = _postsNotifiers[element.postId]
          ?.getPostProfileNotifier(element.postBy, NotifierType.external);
      return postProfileNotifier?.state.currentValue?.fullName
              .toLowerCase()
              .contains(searchTextData.text.toLowerCase()) ??
          false;
    }).toList();

    for (var data in search) {
      String key = "posts_${keys.length}";
      keys.add(key);
      PostProfileNotifier? postProfileNotifier = _postsNotifiers[data.postId]
          ?.getPostProfileNotifier(data.postBy, NotifierType.external);
      SearchSuggestionNotifier().addSuggestion(key,
          postProfileNotifier?.state.currentValue?.fullName ?? "null", data);
    }

    SearchSuggestionNotifier().sendSuggestionUpdate();
  }

  void _fetchRelatedPostsData(String likeText) {
    PostOperation()
        .getPostDataForFirstNameSearch(likeText, 10)
        .then((value) async {
      PostOperation()
          .getPostDataForLastNameSearch(likeText, 10)
          .then((newValue) async {
        value.addAll(newValue);
        for (var data in value) {
          final id = data[dbReference(Post.id)];
          if (!_postsNotifiers.containsKey(id)) {
            _postsNotifiers[id] = PostNotifier();
          }
        }

        final check = value.map((e) async {
          return (await _postsNotifiers[e[dbReference(Post.id)]]
              ?.getPublicPostLinkedData(e, [e[dbReference(Members.id)]]));
        });

        List<HomePagePostData?> getData = await Future.wait(check);

        final postsIds = _data.map((e) => e.postId).toList();
        for (var element in getData) {
          if (element != null && !postsIds.contains(element.postId)) {
            _postsNotifiers[element.postId]
                ?.getPublicPostLinkedNotifiers(element.postId, element.postBy);
            _data.add(element);
          }
        }
        final latestSearchData =
            SearchedPageNotifier().searchTextNotifier.currentValue;
        if (latestSearchData != null &&
            latestSearchData.searchTextDirection != SearchTextDirection.end) {
          handleSearch(SearchTextData(
              SearchTextDirection.stagnat, latestSearchData.text));
        }
      });
    });
  }
}
