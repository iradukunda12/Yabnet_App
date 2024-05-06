class TumenyCustomerData {
  final String customerFirstName;
  final String customerLastName;
  final String email;
  final String phoneNumber;

  TumenyCustomerData(
    this.customerFirstName,
    this.customerLastName,
    this.email,
    this.phoneNumber,
  );

  // Method to convert TumenyCustomerData instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'customerFirstName': customerFirstName,
      'customerLastName': customerLastName,
      'email': email,
      'phoneNumber': phoneNumber,
    };
  }

  // Factory constructor to create TumenyCustomerData instance from JSON
  factory TumenyCustomerData.fromJson(Map<dynamic, dynamic> json) {
    return TumenyCustomerData(
      json['customerFirstName'],
      json['customerLastName'],
      json['email'],
      json['phoneNumber'],
    );
  }

  // Method to create a copy of TumenyCustomerData instance with updated values
  TumenyCustomerData copyWith({
    String? customerFirstName,
    String? customerLastName,
    String? email,
    String? phoneNumber,
  }) {
    return TumenyCustomerData(
      customerFirstName ?? this.customerFirstName,
      customerLastName ?? this.customerLastName,
      email ?? this.email,
      phoneNumber ?? this.phoneNumber,
    );
  }
}
