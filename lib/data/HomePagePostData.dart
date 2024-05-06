import 'package:yabnet/data/ConnectInfo.dart';

enum HomePageMediaType { image, video, document }

class HomePageMediaData {
  final HomePageMediaType mediaType;
  final String mediaData;

  HomePageMediaData(this.mediaType, this.mediaData);

  factory HomePageMediaData.fromJson(Map<dynamic, dynamic> json) {
    return HomePageMediaData(
      HomePageMediaType.values[json['mediaType']],
      json['mediaData'],
    );
  }

  Map<dynamic, dynamic> toJson() {
    return {
      'mediaType': mediaType.index,
      'mediaData': mediaData,
    };
  }
}

class HomePagePostData {
  final String postId;
  final String postBy;
  final String postCreatedAt;
  final String postText;
  final List<HomePageMediaData> postMedia;
  final List<ConnectInfo> postMentions;
  final bool online;
  final HomePagePostData? postReposted; // 1. Added postReposted field

  HomePagePostData(
    this.postId,
    this.postBy,
    this.postCreatedAt,
    this.postText,
    this.postMedia,
    this.postMentions,
    this.online,
    this.postReposted, // 1. Updated constructor
  );

  factory HomePagePostData.fromJson(Map<dynamic, dynamic> json) {
    return HomePagePostData(
      json['postId'],
      json['postBy'],
      json['postCreatedAt'],
      json['postText'],
      (json['postMedia'] as List<dynamic>)
          .map((media) => HomePageMediaData.fromJson(media))
          .toList(),
      (json['postMentions'] as List<dynamic>)
          .map((media) => ConnectInfo.fromJson(media))
          .toList(),
      json['online'],
      json['postReposted'] != null
          ? HomePagePostData.fromJson(json['postReposted'])
          : null, // 2. Parse postReposted
    );
  }

  Map<dynamic, dynamic> toJson() {
    return {
      'postId': postId,
      'postBy': postBy,
      'postCreatedAt': postCreatedAt,
      'postText': postText,
      'postMedia': postMedia.map((media) => media.toJson()).toList(),
      'postMentions':
          postMentions.map((mentions) => mentions.toJson()).toList(),
      'online': online,
      'postReposted':
          postReposted?.toJson(), // 3. Include postReposted in toJson
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomePagePostData &&
          runtimeType == other.runtimeType &&
          postId == other.postId;

  @override
  int get hashCode => postId.hashCode ^ 2;

  HomePagePostData copyWith({
    String? postId,
    String? postBy,
    int? postConnects,
    String? postCreatedAt,
    String? postText,
    List<HomePageMediaData>? postMedia,
    List<ConnectInfo>? postMentions,
    bool? online,
    bool? connectedTo,
    HomePagePostData? postReposted, // 4. Added postReposted parameter
  }) {
    return HomePagePostData(
      postId ?? this.postId,
      postBy ?? this.postBy,
      postCreatedAt ?? this.postCreatedAt,
      postText ?? this.postText,
      postMedia ?? this.postMedia,
      postMentions ?? this.postMentions,
      online ?? this.online,
      postReposted ?? this.postReposted, // 4. Update postReposted field
    );
  }
}
