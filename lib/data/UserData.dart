import '../components/CustomProject.dart';
import '../db_references/Members.dart';
import '../db_references/Profile.dart';

class UserData {
  final String userId;
  final String fullName;
  final String? bio;
  final String email;
  final String profileIndex;
  final String? phone;
  final String? phoneCode;
  final bool restricted;
  final String dob;
  final String location;
  final String gender;
  final String profession;
  final String church;

  UserData(
      this.userId,
      this.fullName,
      this.bio,
      this.email,
      this.profileIndex,
      this.phone,
      this.phoneCode,
      this.restricted,
      this.dob,
      this.location,
      this.gender,
      this.profession,
      this.church);

  factory UserData.fromJson(Map<dynamic, dynamic> json) {
    return UserData(
      json['userId'],
      json['fullName'],
      json['bio'],
      json['email'],
      json['profileIndex'] ?? '',
      json['phone'],
      json['phoneCode'],
      json['restricted'] ?? false,
      json['dob'],
      json['location'],
      json['gender'],
      json['profession'],
      json['church'],
    );
  }

  Map<dynamic, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'bio': bio,
      'email': email,
      'profileIndex': profileIndex,
      'phone': phone,
      'phoneCode': phoneCode,
      'restricted': restricted,
      'dob': dob,
      'location': location,
      'gender': gender,
      'profession': profession,
      'church': church,
    };
  }

  factory UserData.fromOnlineData(Map<dynamic, dynamic> userRecord) {
    return UserData(
      userRecord[dbReference(Members.id)],
      userRecord[dbReference(Members.lastname)] +
          " " +
          userRecord[dbReference(Members.firstname)],
      userRecord[dbReference(Members.bio)],
      userRecord[dbReference(Members.email)],
      userRecord[dbReference(Profile.image_index)] ?? '',
      userRecord[dbReference(Members.phone_no)],
      userRecord[dbReference(Members.phone_code)],
      false,
      userRecord[dbReference(Members.dob)],
      userRecord[dbReference(Members.location)],
      userRecord[dbReference(Members.gender)],
      userRecord[dbReference(Members.profession)],
      userRecord[dbReference(Members.church)],
    );
  }
}
