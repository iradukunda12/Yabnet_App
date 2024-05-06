import 'package:yabnet/components/CustomProject.dart';

import '../db_references/Members.dart';
import '../db_references/Profile.dart';

class ConnectInfo {
  final String membersId;
  final String membersFullname;
  final String? membersProfileIndex;

  ConnectInfo(this.membersId, this.membersFullname, this.membersProfileIndex);

  // Method to convert ConnectInfo object to JSON
  Map<dynamic, dynamic> toJson() {
    return {
      'membersId': membersId,
      'membersFullname': membersFullname,
      'membersProfileIndex': membersProfileIndex,
    };
  }

  // Factory method to create a ConnectInfo object from JSON
  factory ConnectInfo.fromJson(Map<dynamic, dynamic> json) {
    return ConnectInfo(
      json['membersId'] as String,
      json['membersFullname'] as String,
      json['membersProfileIndex'],
    );
  }

  factory ConnectInfo.fromOnline(Map<dynamic, dynamic> json) {
    return ConnectInfo(
      json[dbReference(Members.id)] as String,
      (json[dbReference(Members.lastname)] as String) +
          " " +
          (json[dbReference(Members.firstname)] as String),
      json[dbReference(Profile.image_index)],
    );
  }

  // Method to create a copy of ConnectInfo object with new values
  ConnectInfo copyWith({
    String? membersId,
    String? membersFullname,
    String? membersProfileIndex,
  }) {
    return ConnectInfo(
      membersId ?? this.membersId,
      membersFullname ?? this.membersFullname,
      membersProfileIndex ?? this.membersProfileIndex,
    );
  }
}
