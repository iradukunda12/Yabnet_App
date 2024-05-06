class PaymentMethodData {
  final String paymentMethodId;
  final String paymentMethodIdentity;
  final String companyCode;

  PaymentMethodData(
      this.paymentMethodId, this.paymentMethodIdentity, this.companyCode);

  // Convert the object to a Map
  Map<dynamic, dynamic> toJson() {
    return {
      'paymentMethodId': paymentMethodId,
      'paymentMethodIdentity': paymentMethodIdentity,
      'companyCode': companyCode,
    };
  }

  // Create an instance from a Map
  factory PaymentMethodData.fromJson(Map<dynamic, dynamic> json) {
    return PaymentMethodData(
      json['paymentMethodId'],
      json['paymentMethodIdentity'],
      json['companyCode'],
    );
  }
}
