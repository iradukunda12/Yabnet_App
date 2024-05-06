class UserLoginData {
  final String businessName;
  final String fullName;
  final String password;
  final String emailAddress;
  final String? phoneNumber;
  final String userId;
  final String companyCode;
  final String? profileImageIndex;
  final String? userPhoneCode;
  final bool userVerified;
  final bool userRestricted;

  UserLoginData(
      this.businessName,
      this.fullName,
      this.password,
      this.emailAddress,
      this.phoneNumber,
      this.userId,
      this.companyCode,
      this.profileImageIndex,
      this.userPhoneCode,
      this.userVerified,
      this.userRestricted);
}
