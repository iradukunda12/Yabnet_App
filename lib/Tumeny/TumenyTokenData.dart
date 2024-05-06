import 'package:yabnet/Tumeny/TumenyExpireData.dart';

class TumenyTokenData {
  final String token;
  final TumenyExpireData expireAt;
  final DateTime fromWhen;

  TumenyTokenData(this.token, this.expireAt, this.fromWhen);

  // Method to convert TumenyTokenData instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'expireAt': expireAt.toJson(),
      // Convert TumenyExpireData to JSON
      'fromWhen': fromWhen.toIso8601String(),
      // Convert DateTime to ISO 8601 string
    };
  }

  // Factory constructor to create TumenyTokenData instance from JSON
  factory TumenyTokenData.fromJson(Map<dynamic, dynamic> json) {
    return TumenyTokenData(
      json['token'],
      TumenyExpireData.fromJson(json['expireAt']),
      // Parse TumenyExpireData from JSON
      DateTime.parse(json['fromWhen']), // Parse ISO 8601 string to DateTime
    );
  }

  factory TumenyTokenData.fromResponse(
      DateTime fromWhen, Map<dynamic, dynamic> response) {
    return TumenyTokenData(
      response['token'],
      TumenyExpireData.fromJson(response['expireAt']),
      fromWhen,
    );
  }

  // Method to create a copy of TumenyTokenData instance with updated values
  TumenyTokenData copyWith({String? token, TumenyExpireData? expireAt}) {
    return TumenyTokenData(
      token ?? this.token,
      expireAt ?? this.expireAt,
      this.fromWhen,
    );
  }
}
