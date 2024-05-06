class HomePageCommentData {
  final String commentId;
  final String commentBy;
  final String commentCreatedAt;
  final String commentText;
  final List<HomePageCommentData> commentsPost;
  final bool online;
  final String? commentTo;
  final String? commentToBy;
  final String? commentParent;

  HomePageCommentData(
    this.commentId,
    this.commentBy,
    this.commentCreatedAt,
    this.commentText,
    this.commentsPost,
    this.online,
    this.commentTo,
    this.commentToBy,
    this.commentParent,
  );

  factory HomePageCommentData.fromJson(Map<dynamic, dynamic> json) {
    return HomePageCommentData(
      json['commentId'],
      json['commentBy'],
      json['commentCreatedAt'],
      json['commentText'],
      (json['commentsPost'] as List<dynamic>)
          .map((comment) => HomePageCommentData.fromJson(comment))
          .toList(),
      json['online'],
      json['commentTo'],
      json['commentToBy'],
      json['postIsLiked'],
    );
  }

  Map<dynamic, dynamic> toJson() {
    return {
      'commentId': commentId,
      'commentBy': commentBy,
      'commentCreatedAt': commentCreatedAt,
      'commentText': commentText,
      'commentsPost': commentsPost.map((post) => post.toJson()).toList(),
      'online': online,
      'commentTo': commentTo,
      'commentToBy': commentToBy,
      'commentParent': commentParent,
    };
  }

  HomePageCommentData copyWith({
    String? commentId,
    String? commentBy,
    String? commentCreatedAt,
    String? commentText,
    List<HomePageCommentData>? commentsPost,
    bool? online,
    String? commentTo,
    String? commentToBy,
    String? commentParent,
  }) {
    return HomePageCommentData(
      commentId ?? this.commentId,
      commentBy ?? this.commentBy,
      commentCreatedAt ?? this.commentCreatedAt,
      commentText ?? this.commentText,
      commentsPost ?? this.commentsPost,
      online ?? this.online,
      commentTo ?? this.commentTo,
      commentToBy ?? this.commentToBy,
      commentParent ?? this.commentParent,
    );
  }
}
