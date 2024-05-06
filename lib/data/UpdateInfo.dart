class UpdateInfo {
  final String? iosVersion;
  final String? androidVersion;
  final String? iosInstalledVersion;
  final String? androidInstalledVersion;
  final bool? criticalIOSUpdate;
  final bool? criticalAndroidUpdate;
  final String? releaseIOSNote;
  final String? releaseAndroidNote;
  final String? updateIOSSize;
  final String? updateAndroidSize;
  final DateTime? lastIOSUpdated;
  final DateTime? lastAndroidUpdated;

  UpdateInfo({
    this.iosVersion,
    this.androidVersion,
    this.iosInstalledVersion,
    this.androidInstalledVersion,
    this.criticalIOSUpdate,
    this.criticalAndroidUpdate,
    this.releaseIOSNote,
    this.releaseAndroidNote,
    this.updateIOSSize,
    this.updateAndroidSize,
    this.lastIOSUpdated,
    this.lastAndroidUpdated,
  });

  factory UpdateInfo.fromOnline(
      Map<dynamic, dynamic> json, String? iosVersion, String? androidVersion) {
    return UpdateInfo(
      iosVersion: iosVersion,
      androidVersion: androidVersion,
      iosInstalledVersion: null,
      androidInstalledVersion: null,
      criticalIOSUpdate: json['criticalIOSUpdate'],
      criticalAndroidUpdate: json['criticalAndroidUpdate'],
      releaseIOSNote: json['releaseIOSNote'],
      releaseAndroidNote: json['releaseAndroidNote'],
      updateIOSSize: json['updateIOSSize'],
      updateAndroidSize: json['updateAndroidSize'],
      lastIOSUpdated: json['lastIOSUpdated'] != null
          ? DateTime.parse(json['lastIOSUpdated'])
          : null,
      lastAndroidUpdated: json['lastAndroidUpdated'] != null
          ? DateTime.parse(json['lastAndroidUpdated'])
          : null,
    );
  }

  Map<dynamic, dynamic> toJson() {
    return {
      'iosVersion': iosVersion,
      'androidVersion': androidVersion,
      'iosInstalledVersion': iosInstalledVersion,
      'androidInstalledVersion': androidInstalledVersion,
      'criticalIOSUpdate': criticalIOSUpdate,
      'criticalAndroidUpdate': criticalAndroidUpdate,
      'releaseIOSNote': releaseIOSNote,
      'releaseAndroidNote': releaseAndroidNote,
      'updateIOSSize': updateIOSSize,
      'updateAndroidSize': updateAndroidSize,
      'lastIOSUpdated': lastIOSUpdated?.toIso8601String(),
      'lastAndroidUpdated': lastAndroidUpdated?.toIso8601String(),
    };
  }

  UpdateInfo copyWith({
    String? iosVersion,
    String? androidVersion,
    String? iosInstalledVersion,
    String? androidInstalledVersion,
    bool? criticalIOSUpdate,
    bool? criticalAndroidUpdate,
    String? releaseIOSNote,
    String? releaseAndroidNote,
    String? updateIOSSize,
    String? updateAndroidSize,
    DateTime? lastIOSUpdated,
    DateTime? lastAndroidUpdated,
  }) {
    return UpdateInfo(
      iosVersion: iosVersion ?? this.iosVersion,
      androidVersion: androidVersion ?? this.androidVersion,
      iosInstalledVersion: iosInstalledVersion ?? this.iosInstalledVersion,
      androidInstalledVersion:
          androidInstalledVersion ?? this.androidInstalledVersion,
      criticalIOSUpdate: criticalIOSUpdate ?? this.criticalIOSUpdate,
      criticalAndroidUpdate:
          criticalAndroidUpdate ?? this.criticalAndroidUpdate,
      releaseIOSNote: releaseIOSNote ?? this.releaseIOSNote,
      releaseAndroidNote: releaseAndroidNote ?? this.releaseAndroidNote,
      updateIOSSize: updateIOSSize ?? this.updateIOSSize,
      updateAndroidSize: updateAndroidSize ?? this.updateAndroidSize,
      lastIOSUpdated: lastIOSUpdated ?? this.lastIOSUpdated,
      lastAndroidUpdated: lastAndroidUpdated ?? this.lastAndroidUpdated,
    );
  }
}
