class TumenyExpireData {
  final DateTime date;
  final int timezoneType;
  final String timezone;

  TumenyExpireData(this.date, this.timezoneType, this.timezone);

  // Method to convert CustomDateTime instance to JSON
  Map<dynamic, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'timezone_type': timezoneType,
      'timezone': timezone,
    };
  }

  // Factory constructor to create CustomDateTime instance from JSON
  factory TumenyExpireData.fromJson(Map<dynamic, dynamic> json) {
    return TumenyExpireData(
      DateTime.parse(json['date']),
      json['timezone_type'],
      json['timezone'],
    );
  }

  // Method to create a copy of CustomDateTime instance with updated values
  TumenyExpireData copyWith(
      {DateTime? date, int? timezoneType, String? timezone}) {
    return TumenyExpireData(
      date ?? this.date,
      timezoneType ?? this.timezoneType,
      timezone ?? this.timezone,
    );
  }
}
