class ProfessionData {
  final String professionId;
  final String professionTitle;
  final String professionCreatedAt;

  // Constructor
  ProfessionData(
      this.professionId, this.professionTitle, this.professionCreatedAt);

  // Method to convert ProfessionData object to JSON
  Map<dynamic, dynamic> toJson() {
    return {
      'professionId': professionId,
      'professionTitle': professionTitle,
      'professionCreatedAt': professionCreatedAt,
    };
  }

  // Factory method to create ProfessionData object from JSON
  factory ProfessionData.fromJson(Map<dynamic, dynamic> json) {
    return ProfessionData(
      json['professionId'].toString(),
      json['professionTitle'],
      json['professionCreatedAt'],
    );
  }

  factory ProfessionData.fromOnline(Map<dynamic, dynamic> json) {
    return ProfessionData(
      json['profession_id'].toString(),
      json['profession_title'],
      json['profession_created_at'],
    );
  }

  // Method to create a copy of ProfessionData object with optional modified fields
  ProfessionData copyWith({
    String? professionId,
    String? professionTitle,
    String? professionCreatedAt,
  }) {
    return ProfessionData(
      professionId ?? this.professionId,
      professionTitle ?? this.professionTitle,
      professionCreatedAt ?? this.professionCreatedAt,
    );
  }
}
