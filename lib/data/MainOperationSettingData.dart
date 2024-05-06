// ignore_for_file: constant_identifier_names

enum MainOperationSetting {
  last_opened,
  first,
  always,
}

class MainOperationSettingData {
  final MainOperationSetting openTo;
  final String which;

  MainOperationSettingData(this.openTo, this.which);

  // Encode to JSON
  Map<dynamic, dynamic> toJson() {
    return {
      'openTo': openTo.toString(), // Convert enum to a string
      'which': which,
    };
  }

  // Decode from JSON
  factory MainOperationSettingData.fromJson(Map<dynamic, dynamic> json) {
    return MainOperationSettingData(
      MainOperationSetting.values
          .firstWhere((e) => e.toString() == json['openTo']),
      json['which'],
    );
  }
}
