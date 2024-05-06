import 'package:yabnet/components/CustomProject.dart';

import '../db_references/Members.dart';
import '../db_references/Post.dart';

class RepostData {
  final String postId;
  final String postRepostedId;
  final String postCreatedAt;
  final String postBy;

  RepostData(this.postId, this.postRepostedId, this.postCreatedAt, this.postBy);

  // Method to convert RepostData object to a Map
  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'postRepostedId': postRepostedId,
      'postCreatedAt': postCreatedAt,
      'postBy': postBy,
    };
  }

  // Factory method to create RepostData object from a Map
  factory RepostData.fromJson(Map<dynamic, dynamic> json) {
    return RepostData(
      json['postId'] as String,
      json['postRepostedId'] as String,
      json['postCreatedAt'] as String,
      json['postBy'] as String,
    );
  }

  factory RepostData.fromOnline(Map<dynamic, dynamic> json) {
    return RepostData(
      json[dbReference(Post.id)] as String,
      json[dbReference(Post.reposted)] as String,
      json[dbReference(Post.created_at)] as String,
      json[dbReference(Members.id)] as String,
    );
  }

  // Method to create a copy of RepostData object with optional new values
  RepostData copyWith({
    String? postId,
    String? postRepostedId,
    String? postCreatedAt,
    String? postBy,
  }) {
    return RepostData(
      postId ?? this.postId,
      postRepostedId ?? this.postRepostedId,
      postCreatedAt ?? this.postCreatedAt,
      postBy ?? this.postBy,
    );
  }
}
