import '../components/CustomProject.dart';
import '../db_references/Members.dart';
import '../db_references/Profile.dart';

class PostProfileData {
  final String userId;
  final String fullName;
  final String email;
  final String profileIndex;
  final String? phone;
  final String? phoneCode;

  PostProfileData(this.userId, this.fullName, this.email, this.profileIndex,
      this.phone, this.phoneCode);

  factory PostProfileData.fromJson(Map<dynamic, dynamic> json) {
    return PostProfileData(
      json['userId'],
      json['fullName'],
      json['email'],
      json['profileIndex'] ?? '',
      json['phone'],
      json['phoneCode'],
    );
  }

  Map<dynamic, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'profileIndex': profileIndex,
      'phone': phone,
      'phoneCode': phoneCode,
    };
  }

  factory PostProfileData.fromOnlineData(Map<dynamic, dynamic> userRecord) {
    return PostProfileData(
      userRecord[dbReference(Members.id)],
      userRecord[dbReference(Members.lastname)] +
          " " +
          userRecord[dbReference(Members.firstname)],
      userRecord[dbReference(Members.email)],
      userRecord[dbReference(Profile.image_index)] ?? '',
      userRecord[dbReference(Members.phone_no)],
      userRecord[dbReference(Members.phone_code)],
    );
  }
}
