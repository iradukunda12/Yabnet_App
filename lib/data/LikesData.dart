import 'package:yabnet/components/CustomProject.dart';

import '../db_references/Likes.dart';
import '../db_references/Members.dart';

class LikesData {
  final String likesId;
  final String likesCreatedAt;
  final String? likesIsPost;
  final String? likesIsMember;
  final String? likesIsComment;
  final String membersIdentity;
  final String membersId;

  LikesData(
      this.likesId,
      this.likesCreatedAt,
      this.likesIsPost,
      this.likesIsMember,
      this.likesIsComment,
      this.membersIdentity,
      this.membersId);

  // Method to convert LikesData object to a Map
  Map<dynamic, dynamic> toJson() {
    return {
      'likesId': likesId,
      'likesCreatedAt': likesCreatedAt,
      'likesIsPost': likesIsPost,
      'likesIsMember': likesIsMember,
      'likesIsComment': likesIsComment,
      'membersIdentity': membersIdentity,
      'membersId': membersId,
    };
  }

  // Factory method to create a LikesData object from a Map
  factory LikesData.fromJson(Map<dynamic, dynamic> json) {
    return LikesData(
      json['likesId'],
      json['likesCreatedAt'],
      json['likesIsPost'],
      json['likesIsMember'],
      json['likesIsComment'],
      json['membersIdentity'],
      json['membersId'],
    );
  }

  factory LikesData.fromOnline(
      Map<String, dynamic> json, String membersIdentity) {
    return LikesData(
      json[dbReference(Likes.id)],
      json[dbReference(Likes.created_at)],
      json[dbReference(Likes.is_post)],
      json[dbReference(Likes.is_member)],
      json[dbReference(Likes.is_comment)],
      membersIdentity,
      json[dbReference(Members.id)],
    );
  }

  // Method to create a copy of the LikesData object with optional modified properties
  LikesData copyWith({
    String? likesId,
    String? likesCreatedAt,
    String? likesIsPost,
    String? likesIsMember,
    String? likesIsComment,
    String? membersIdentity,
    String? membersId,
  }) {
    return LikesData(
      likesId ?? this.likesId,
      likesCreatedAt ?? this.likesCreatedAt,
      likesIsPost ?? this.likesIsPost,
      likesIsMember ?? this.likesIsMember,
      likesIsComment ?? this.likesIsComment,
      membersIdentity ?? this.membersIdentity,
      membersId ?? this.membersId,
    );
  }
}
