import 'package:yabnet/data/TumenyCustomerData.dart';

class TumenySmsData {
  final TumenyCustomerData tumenyCustomerData;
  final double? recipient;
  final double? amount;
  final String? status;
  final String? message;

  TumenySmsData(this.tumenyCustomerData, this.recipient, this.amount,
      this.status, this.message);

  // Method to convert TumenyPaymentData instance to JSON
  Map<dynamic, dynamic> toJson() {
    return {
      'tumenyCustomerData': tumenyCustomerData.toJson(),
      // Convert TumenyCustomerData to JSON
      'recipient': recipient,
      'amount': amount,
      'status': status,
      'message': message,
    };
  }

  // Factory constructor to create TumenyPaymentData instance from JSON
  factory TumenySmsData.fromJson(Map<dynamic, dynamic> json) {
    return TumenySmsData(
      TumenyCustomerData.fromJson(json['tumenyCustomerData']),
      // Parse TumenyCustomerData from JSON
      double.tryParse(json['recipient']),
      double.tryParse(json['amount']),
      json['status'],
      json['message'],
    );
  }

  factory TumenySmsData.fromResponse(
      TumenyCustomerData tumenyCustomerData, Map<dynamic, dynamic> response) {
    dynamic json = response['sms'];
    return TumenySmsData(
      tumenyCustomerData,
      double.tryParse(json['recipient'] ?? ''),
      double.tryParse(json['amount'] ?? ''),
      json['status'],
      json['message'],
    );
  }

  // Method to create a copy of TumenyPaymentData instance with updated values
  TumenySmsData copyWith({
    TumenyCustomerData? tumenyCustomerData,
    double? recipient,
    double? amount,
    String? status,
    String? message,
  }) {
    return TumenySmsData(
      tumenyCustomerData ?? this.tumenyCustomerData,
      recipient ?? this.recipient,
      amount ?? this.amount,
      status ?? this.status,
      message ?? this.message,
    );
  }
}
