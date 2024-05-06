import 'package:yabnet/components/CustomProject.dart';
import 'package:yabnet/db_references/Members.dart';

import '../db_references/Connect.dart';

class ConnectData {
  final String connectId;
  final String connectTo;
  final String connectCreatedAt;
  final String membersId;

  ConnectData(
      this.connectId, this.connectTo, this.connectCreatedAt, this.membersId);

  // Method to convert ConnectData object to a Map
  Map<dynamic, dynamic> toJson() {
    return {
      'connectId': connectId,
      'connectTo': connectTo,
      'connectCreatedAt': connectCreatedAt,
      'membersId': membersId,
    };
  }

  // Factory method to create ConnectData object from a Map
  factory ConnectData.fromJson(Map<dynamic, dynamic> json) {
    return ConnectData(
      json['connectId'] as String,
      json['connectTo'] as String,
      json['connectCreatedAt'] as String,
      json['membersId'] as String,
    );
  }

  factory ConnectData.fromOnline(Map<dynamic, dynamic> json) {
    return ConnectData(
      json[dbReference(Connect.id)] as String,
      json[dbReference(Connect.to)] as String,
      json[dbReference(Connect.created_at)] as String,
      json[dbReference(Members.id)] as String,
    );
  }

  // Method to create a copy of ConnectData object with optional new values
  ConnectData copyWith({
    String? connectId,
    String? connectTo,
    String? connectCreatedAt,
    String? membersId,
  }) {
    return ConnectData(
      connectId ?? this.connectId,
      connectTo ?? this.connectTo,
      connectCreatedAt ?? this.connectCreatedAt,
      membersId ?? this.membersId,
    );
  }
}
