import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:open_document/my_files/init.dart';
import 'package:postgrest/src/postgrest_builder.dart';
import 'package:postgrest/src/types.dart';
import 'package:yabnet/data_notifiers/PostNotifier.dart';
import 'package:yabnet/db_references/Feeds.dart';
import 'package:yabnet/db_references/Members.dart';
import 'package:yabnet/operations/CacheOperation.dart';

import '../components/CustomProject.dart';
import '../data/HomePagePostData.dart';
import '../supabase/SupabaseConfig.dart';

class PostFeedsGenerator {
  static final PostFeedsGenerator instance = PostFeedsGenerator.internal();

  factory PostFeedsGenerator() => instance;

  PostFeedsGenerator.internal();

  Future<void> start() async {
    return _startPostFeed();
  }

  Future<ValueListenable<Box>?> listenable() async {
    return await CacheOperation().getListenable(dbReference(Feeds.database));
  }

  String? getThisUser() {
    return SupabaseConfig.client.auth.currentUser?.id;
  }

  Future<bool> saveFeedToDb(Map<dynamic, dynamic> feed) {
    return CacheOperation().saveCacheData(
        dbReference(Feeds.database), dbReference(Feeds.value), feed);
  }

  Future<void> saveLastPostTimeChecked(String time) {
    return CacheOperation().saveCacheData(dbReference(Feeds.database),
        dbReference(Feeds.last_post_time_checked), time);
  }

  dynamic getFeedFromDb() async {
    return await CacheOperation()
        .getCacheData(dbReference(Feeds.database), dbReference(Feeds.value));
  }

  Future<String?> getLastPostTimeChecked() async {
    return await CacheOperation().getCacheData(
        dbReference(Feeds.database), dbReference(Feeds.last_post_time_checked));
  }

  List<FeedField> personalizedTool = [];

  String personalisedPostFromTime = DateTime.now().toUtc().toString();
  List<HomePagePostData> suggestionPosts = [];
  List<HomePagePostData> batchedPersonalizedPosts = [];

  int _postFetchOffset = 20;

  int _retryPeriod = 4;
  int _postRetry = 4;
  bool _nothingFoundInRetryPeriod = false;

  /// Post Factors
  /// ============
  /// User Fields
  /// Locations checked and in
  ///
  ///
  ///

  List<FeedField> getFeedFieldsFromMap(Map<dynamic, dynamic> map) {
    List<FeedField> feedFields = [];
    map.forEach((key, value) {
      List<FeedValue> feedValues = [];
      if (value is List) {
        value.forEach((item) {
          feedValues.add(FeedValue.fromJson(item));
        });
      }
      feedFields.add(FeedField(key, feedValues));
    });
    return feedFields;
  }

  Map<String, dynamic> feedFieldsToMap(List<FeedField> feedFields) {
    Map<String, dynamic> map = {};
    feedFields.forEach((field) {
      map[field.feedField] =
          field.feedValues.map((value) => value.toJson()).toList();
    });
    return map;
  }

  PostgrestTransformBuilder<PostgrestMap?> getUserPostFeed(String userId,
      {SupabaseStreamPaginationOption? fetchOptions}) {
    return SupabaseConfig.client
        .from(dbReference(Feeds.table))
        .select()
        .eq(dbReference(Members.id), userId)
        .maybeSingle();
  }

  void _startPostFeed() {
    // Check last user
    String? thisUser = getThisUser();
    if (thisUser == null) return;

    // Fetch the local feed and time
    final localFeed = getFeedFromDb();
    if (localFeed is Map) {
      personalizedTool = getFeedFieldsFromMap(localFeed);
    }
    getLastPostTimeChecked().then((value) => getLatestPostReceived(value));

    // Check for feed online if null
    if (personalizedTool.isEmpty) {
      getUserPostFeed(thisUser).then((value) {
        if (value != null) {
          processFeedFromOnline(value);
        }
      });
    }
  }

  void processFeedFromOnline(Map<dynamic, dynamic> feed) async {
    final feedFields = getFeedFieldsFromMap(feed);
    await saveFeedToDb(feed);
    personalizedTool = feedFields;
  }

  List<HomePagePostData> getNextBatchedPostForPaginate(
      PostNotifier postNotifier) {
    List<HomePagePostData> currentPosts = postNotifier.getLatestData();
    List<String> postIds = currentPosts.map((e) => e.postId).toList();

    batchedPersonalizedPosts.removeWhere((element) =>
        postIds.contains(element.postId) || element.postReposted != null);
    return getBatchedPersonalisedFillUp(
        (0.65 * batchedPersonalizedPosts.length).round());
  }

  List<HomePagePostData> processNextOffset(PostNotifier postNotifier,
      List<HomePagePostData> personalizedPosts, bool userAddedPost) {
    // Get the latest Data from ui
    List<HomePagePostData> currentPosts = postNotifier.getLatestData();

    // If New posts and Old Posts is Empty and is online, we will be retrying if
    // we still got retry possibility and no post has been found
    if (currentPosts.isEmpty &&
        personalizedPosts.isEmpty &&
        _postRetry >= 0 &&
        !_nothingFoundInRetryPeriod) {
      makeCurrentLastCheckAdjustment();
      postNotifier.requestPaginate(canForceRetry: true);
      _postRetry--;
      return personalizedPosts;
    }
    ;

    // Post has finally be returned and we can reset retries and flag found posts
    _nothingFoundInRetryPeriod = true;
    _postRetry = _retryPeriod;

    // Get post ids from ui post
    List<String> postIds = currentPosts.map((e) => e.postId).toList();

    // Remove post already existing in the ui from latest post returned
    personalizedPosts
        .removeWhere((element) => postIds.contains(element.postId));

    // Now add the new post to the list of id =s from ui
    postIds.addAll(personalizedPosts.map((e) => e.postId).toList());

    // Store the size of new post
    int personalizedSized = personalizedPosts.length;

    // If latest post is less than offset for post
    if (personalizedSized < _postFetchOffset) {
      // Add 40% of suggested post that are not already in the ui
      // to the latest posts
      suggestionPosts
          .removeWhere((element) => postIds.contains(element.postId));
      personalizedPosts
          .addAll(getSuggestionFillUp((0.4 * suggestionPosts.length).floor()));

      // Add 60% of Next personalized post that are not already in the ui
      // to the latest posts
      batchedPersonalizedPosts
          .removeWhere((element) => postIds.contains(element.postId));
      personalizedPosts.addAll(getBatchedPersonalisedFillUp(
          (0.6 * batchedPersonalizedPosts.length).floor()));

      // Ignore if the last post was user
      if (!userAddedPost) {
        // If we did not get any latest post and we have some post to ui
        if (personalizedSized <= 0 && currentPosts.isNotEmpty) {
          // Get the time of the first showing post on the ui
          getLatestPostReceived(currentPosts.firstOrNull?.postCreatedAt);
        } else {
          // If we got latest post, we get the time of the last post
          getLatestPostReceived(personalizedPosts.lastOrNull?.postCreatedAt);
        }
      }
      return personalizedPosts;
    } else {
      return personalizedPosts;
    }
  }

  List<HomePagePostData> getNextPostToBeDisplayed(PostNotifier postNotifier) {
    List<HomePagePostData> nextPost = [];
    List<HomePagePostData> currentPosts = postNotifier.getLatestData();
    List<String> postIds = currentPosts.map((e) => e.postId).toList();

    batchedPersonalizedPosts
        .removeWhere((element) => postIds.contains(element.postId));
    nextPost.addAll(getBatchedPersonalisedFillUp(
        (0.9 * batchedPersonalizedPosts.length).floor()));
    suggestionPosts.removeWhere((element) => postIds.contains(element.postId));
    nextPost
        .addAll(getSuggestionFillUp((0.9 * suggestionPosts.length).floor()));
    return nextPost;
  }

  List<HomePagePostData> getSuggestionFillUp(int remaining) {
    List<HomePagePostData> fillUp = [];

    while (suggestionPosts.isNotEmpty && fillUp.length < remaining) {
      fillUp.add(suggestionPosts[0]);
      suggestionPosts.removeAt(0);
    }

    return fillUp;
  }

  List<HomePagePostData> getBatchedPersonalisedFillUp(int remaining) {
    List<HomePagePostData> fillUp = [];

    while (batchedPersonalizedPosts.isNotEmpty && fillUp.length < remaining) {
      fillUp.add(batchedPersonalizedPosts[0]);
      batchedPersonalizedPosts.removeAt(0);
    }

    return fillUp;
  }

  int getSuggestionLimitBy() {
    int suggestionLimit = _postFetchOffset - suggestionPosts.length;
    if (suggestionLimit < 1) {
      return _postFetchOffset;
    } else {
      return suggestionLimit;
    }
  }

  int getPostRetry() {
    return _postRetry;
  }

  int getPersonalizedLimitBy({int? reduce}) {
    return _postFetchOffset - (reduce ?? 0);
  }

  void startSuggestionGenerativePost(
      Future<List<HomePagePostData>> getPostLinkedData) async {
    if (suggestionPosts.isEmpty || suggestionPosts.length < _postFetchOffset) {
      getPostLinkedData.then((value) {
        List<String> postIds = suggestionPosts.map((e) => e.postId).toList();
        value.removeWhere((element) => postIds.contains(element.postId));
        suggestionPosts.addAll(value);
      });

      getPostLinkedData.then((value) {
        List<String> postIds = suggestionPosts.map((e) => e.postId).toList();
        value.removeWhere((element) => postIds.contains(element.postId));
        suggestionPosts.addAll(value);
      });
    }
  }

  void startBatchedPersonalizedGenerativePost(
      Future<List<HomePagePostData>> getPostLinkedData) async {
    if (batchedPersonalizedPosts.isEmpty ||
        batchedPersonalizedPosts.length < _postFetchOffset) {
      getPostLinkedData.then((value) {
        List<String> postIds =
            batchedPersonalizedPosts.map((e) => e.postId).toList();
        value.removeWhere((element) => postIds.contains(element.postId));
        batchedPersonalizedPosts.addAll(value);
      });
    }
  }

  void makeCurrentLastCheckAdjustment() {
    DateTime? timeChecked = DateTime.tryParse(personalisedPostFromTime);
    if (timeChecked != null) {
      DateTime newTimeChecked = timeChecked.subtract(Duration(days: 30));
      personalisedPostFromTime = newTimeChecked.toString();
    }
  }

  void getLatestPostReceived(String? time) async {
    if (time != null) {
      personalisedPostFromTime = time;
      saveLastPostTimeChecked(time);
    }
  }

  String getPostGreaterThanTime(bool restarted) {
    if (restarted) {
      return personalisedPostFromTime;
    } else {
      return personalisedPostFromTime;
    }
  }

  String? getPostLesserThanTime(bool restarted) {
    if (restarted) {
      return null;
    } else {
      return null;
    }
  }
}

class FeedField {
  final String feedField;
  final List<FeedValue> feedValues;

  FeedField(this.feedField, this.feedValues);

  Map<String, dynamic> toJson() {
    return {
      'feedField': feedField,
      'feedValues': feedValues.map((value) => value.toJson()).toList(),
    };
  }

  factory FeedField.fromJson(Map<String, dynamic> json) {
    return FeedField(
      json['feedField'],
      (json['feedValues'] as List)
          .map((value) => FeedValue.fromJson(value))
          .toList(),
    );
  }

  FeedField copyWith({
    String? feedField,
    List<FeedValue>? feedValues,
  }) {
    return FeedField(
      feedField ?? this.feedField,
      feedValues ?? this.feedValues,
    );
  }
}

class FeedValue {
  final dynamic value;
  final int counter;

  FeedValue(this.value, this.counter);

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'counter': counter,
    };
  }

  factory FeedValue.fromJson(Map<String, dynamic> json) {
    return FeedValue(
      json['value'],
      json['counter'],
    );
  }

  FeedValue copyWith({
    dynamic value,
    int? counter,
  }) {
    return FeedValue(
      value ?? this.value,
      counter ?? this.counter,
    );
  }
}
