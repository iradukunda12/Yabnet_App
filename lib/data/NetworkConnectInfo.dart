import 'package:yabnet/components/CustomProject.dart';

import '../db_references/Members.dart';
import '../db_references/Profile.dart';
import 'ConnectData.dart';

enum NetworkConnect { not_connected, is_connected, ignored_connection }

class NetworkConnectInfo {
  final String membersId;
  final String membersFullname;
  final String membersField;
  final String? membersBio;
  final String? membersProfileIndex;
  final List<ConnectData> connectData;
  final NetworkConnect membersNetworkConnect;

  NetworkConnectInfo(
    this.membersId,
    this.membersFullname,
    this.membersField,
    this.membersBio,
    this.membersProfileIndex,
    this.connectData,
    this.membersNetworkConnect,
  );

  // Method to convert ConnectInfo object to JSON
  Map<String, dynamic> toJson() {
    return {
      'membersId': membersId,
      'membersFullname': membersFullname,
      'membersField': membersField,
      'membersBio': membersBio,
      'membersProfileIndex': membersProfileIndex,
      'connectData': connectData.map((data) => data.toJson()).toList(),
      'membersNetworkConnect': membersNetworkConnect.toString(),
    };
  }

  // Factory method to create a ConnectInfo object from JSON
  factory NetworkConnectInfo.fromJson(Map<String, dynamic> json) {
    return NetworkConnectInfo(
      json['membersId'] as String,
      json['membersFullname'] as String,
      json['membersField'] as String,
      json['membersBio'] as String?,
      json['membersProfileIndex'] as String?,
      (json['connectData'] as List<dynamic>)
          .map((data) => ConnectData.fromJson(data))
          .toList(),
      NetworkConnect.values.firstWhere(
          (element) => element.toString() == json['membersNetworkConnect']),
    );
  }

  // Factory method to create a ConnectInfo object from online data
  factory NetworkConnectInfo.fromOnline(
      Map<String, dynamic> json, List<ConnectData> connectData,
      {NetworkConnect networkConnect = NetworkConnect.not_connected}) {
    return NetworkConnectInfo(
      json[dbReference(Members.id)] as String,
      (json[dbReference(Members.lastname)] as String) +
          " " +
          (json[dbReference(Members.firstname)] as String),
      json[dbReference(Members.profession)] as String,
      json[dbReference(Members.bio)] as String?,
      json[dbReference(Profile.image_index)] as String?,
      connectData,
      networkConnect,
    );
  }

  // Method to create a copy of ConnectInfo object with new values
  NetworkConnectInfo copyWith({
    String? membersId,
    String? membersFullname,
    String? membersField,
    String? membersProfileIndex,
    String? membersBio,
    List<ConnectData>? connectData,
    NetworkConnect? membersNetworkConnect,
  }) {
    return NetworkConnectInfo(
      membersId ?? this.membersId,
      membersFullname ?? this.membersFullname,
      membersField ?? this.membersField,
      membersBio ?? this.membersBio,
      membersProfileIndex ?? this.membersProfileIndex,
      connectData ?? this.connectData,
      membersNetworkConnect ?? this.membersNetworkConnect,
    );
  }
}
