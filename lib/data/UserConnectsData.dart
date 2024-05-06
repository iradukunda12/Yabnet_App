import 'ConnectInfo.dart';

class UserConnectsData {
  final List<ConnectInfo>? connects;
  final List<ConnectInfo>? connection;

  UserConnectsData(this.connects, this.connection);

  // Method to convert UserConnectsData object to JSON
  Map<dynamic, dynamic> toJson() {
    return {
      'connects': connects?.map((connect) => connect.toJson()).toList(),
      'connection': connection?.map((connect) => connect.toJson()).toList(),
    };
  }

  // Factory method to create UserConnectsData object from JSON
  factory UserConnectsData.fromJson(Map<dynamic, dynamic> json) {
    return UserConnectsData(
      (json['connects']) != null
          ? (json['connects'] as List<dynamic>)
              .map((item) => ConnectInfo.fromJson(item))
              .toList()
          : null,
      (json['connection']) != null
          ? (json['connection'] as List<dynamic>)
              .map((item) => ConnectInfo.fromJson(item))
              .toList()
          : null,
    );
  }

  // Method to create a copy of the UserConnectsData object with optional parameter overrides
  UserConnectsData copyWith({
    List<ConnectInfo>? connects,
    List<ConnectInfo>? connection,
  }) {
    return UserConnectsData(
      connects ?? this.connects,
      connection ?? this.connection,
    );
  }
}
