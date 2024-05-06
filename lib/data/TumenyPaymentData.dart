import 'package:yabnet/data/TumenyCustomerData.dart';

class TumenyPaymentData {
  final TumenyCustomerData tumenyCustomerData;
  final String id;
  final double amount;
  final String status;
  final String message;

  TumenyPaymentData(
      this.tumenyCustomerData, this.id, this.amount, this.status, this.message);

  // Method to convert TumenyPaymentData instance to JSON
  Map<dynamic, dynamic> toJson() {
    return {
      'tumenyCustomerData': tumenyCustomerData.toJson(),
      // Convert TumenyCustomerData to JSON
      'id': id,
      'amount': amount,
      'status': status,
      'message': message,
    };
  }

  // Factory constructor to create TumenyPaymentData instance from JSON
  factory TumenyPaymentData.fromJson(Map<dynamic, dynamic> json) {
    return TumenyPaymentData(
      TumenyCustomerData.fromJson(json['tumenyCustomerData']),
      // Parse TumenyCustomerData from JSON
      json['id'],
      json['amount'].toDouble(),
      json['status'],
      json['message'],
    );
  }

  factory TumenyPaymentData.fromResponse(
      TumenyCustomerData tumenyCustomerData, Map<dynamic, dynamic> response) {
    dynamic json = response['payment'];
    return TumenyPaymentData(
      tumenyCustomerData,
      json['id'],
      json['amount'].toDouble(),
      json['status'],
      json['message'],
    );
  }

  // Method to create a copy of TumenyPaymentData instance with updated values
  TumenyPaymentData copyWith({
    TumenyCustomerData? tumenyCustomerData,
    String? id,
    double? amount,
    String? status,
    String? message,
  }) {
    return TumenyPaymentData(
      tumenyCustomerData ?? this.tumenyCustomerData,
      id ?? this.id,
      amount ?? this.amount,
      status ?? this.status,
      message ?? this.message,
    );
  }
}
