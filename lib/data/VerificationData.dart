class VerificationData {
  String? sessionCode;
  DateTime? verificationEnd;
  String? verificationCode;
  String? verificationType;
  DateTime? verificationStart;

  VerificationData({
    required this.sessionCode,
    required this.verificationEnd,
    required this.verificationCode,
    required this.verificationType,
    required this.verificationStart,
  });

  factory VerificationData.fromJson(Map<dynamic, dynamic>? json) {
    if (json == null) {
      return VerificationData(
          sessionCode: null,
          verificationEnd: null,
          verificationCode: null,
          verificationType: null,
          verificationStart: null);
    }

    return VerificationData(
      sessionCode: json['session_code'],
      verificationEnd: DateTime.parse(json['verification_end']),
      verificationCode: json['verification_code'],
      verificationType: json['verification_type'],
      verificationStart: DateTime.parse(json['verification_start']),
    );
  }
}
