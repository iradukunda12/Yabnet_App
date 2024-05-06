import 'dart:convert';

import 'package:http/http.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yabnet/Tumeny/TumenyTokenData.dart';
import 'package:yabnet/data/TumenyPaymentData.dart';

import '../components/CustomProject.dart';
import '../data/TumenyCustomerData.dart';
import '../data/TumenySmsData.dart';
import '../supabase/SupabaseConfig.dart';

class TumenyConfig {
  static final TumenyConfig instance = TumenyConfig.internal();

  factory TumenyConfig() => instance;

  TumenyConfig.internal();

  static String senderId = "YOUNGADVENT";
  static String tokenUrl = "https://tumeny.herokuapp.com/api/token";
  static String paymentUrl = "https://tumeny.herokuapp.com/api/v1/payment";
  static String paymentStatusUrl =
      "https://tumeny.herokuapp.com/api/v1/payment";
  static String smsUrl = "https://tumeny.herokuapp.com/api/v1/sms/send";
  static String apiKey = "aeee242c-ea9b-4806-b447-740ded6daebc";
  static String apiSecret = "db81e9f7556cc2e212afc14fee30f767256afb71";

  static String supabasePaymentUrl = "create_tumeny_payment";

  TumenyTokenData? _tumenyTokenData;

  Future<FunctionResponse> sendPaymentRequest(
    String accessToken,
    String customerFirstName,
    String customerLastName,
    String phoneNumber,
    double amount,
    String email,
    String description,
    String plans_id,
    String members_id,
    String subscriptions_from,
    String subscriptions_to,
    int plans_selected,
    bool subscriptions_payment_verified,
    bool subscriptions_active,
  ) {
    dynamic bodyParam = {
      'get_accessToken': accessToken,
      'get_customerFirstName': customerFirstName,
      'get_customerLastName': customerLastName,
      'get_phoneNumber': phoneNumber,
      'get_amount': amount,
      'get_email': email,
      'get_description': description,
      'get_plans_id': plans_id,
      'get_members_id': members_id,
      'get_subscriptions_from': subscriptions_from,
      'get_subscriptions_to': subscriptions_to,
      'get_plans_selected': plans_selected,
      'get_subscriptions_payment_verified': subscriptions_payment_verified,
      'get_subscriptions_active': subscriptions_active,
    };

    return SupabaseConfig.client.functions
        .invoke(supabasePaymentUrl, body: bodyParam);
  }

  Future<void> _createAToken() async {
    // data in JSON format
    final Map<String, dynamic> data = {};

    // Convert data to JSON string
    final String jsonData = jsonEncode(data);

    try {
      final response = await post(
        Uri.parse(tokenUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'apiKey': apiKey,
          'apiSecret': apiSecret,
        },
        body: jsonData,
      );

      if (response.statusCode == 200) {
        _tumenyTokenData = TumenyTokenData.fromResponse(
            DateTime.now().toUtc(), jsonDecode(response.body) as Map);
      } else {
        showDebug(msg: 'Error: ${response.body} ');
      }
    } catch (e) {
      showDebug(msg: 'Error: $e');
    }
  }

  Future<TumenyTokenData> getTokenData() async {
    if (_tumenyTokenData != null) {
      //   There is a token

      if (_tumenyTokenData!.expireAt.date
              .toUtc()
              .difference(_tumenyTokenData!.fromWhen)
              .inSeconds >
          0) {
        // Token Expired
        await _createAToken();
        return await getTokenData();
      }
      ;

      return _tumenyTokenData!;
    } else {
      await _createAToken();
      return await getTokenData();
    }
  }

  Future<TumenyPaymentData?> createNewPayment(
      TumenyCustomerData tumenyCustomerData,
      String description,
      int amount) async {
    TumenyTokenData token = await getTokenData();

    // paymentData in JSON format
    final Map<String, dynamic> paymentData = {
      'description': description,
      'amount': amount,
      'customerFirstName': tumenyCustomerData.customerFirstName,
      'customerLastName': tumenyCustomerData.customerLastName,
      'email': tumenyCustomerData.email,
      'phoneNumber': tumenyCustomerData.phoneNumber,
    };

    // Convert paymentData to JSON string
    final String jsonData = jsonEncode(paymentData);

    try {
      final response = await post(
        Uri.parse(paymentUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token.token}'
        },
        body: jsonData,
      );

      if (response.statusCode == 200) {
        return TumenyPaymentData.fromResponse(
            tumenyCustomerData, jsonDecode(response.body) as Map);
      } else {
        showDebug(msg: 'Error: ${response.body} ');
      }
    } catch (e) {
      showDebug(msg: 'Error: $e');
    }
    return null;
  }

  Future<TumenyPaymentData?> getPaymentStatus(
      TumenyCustomerData tumenyCustomerData, String paymentId) async {
    TumenyTokenData token = await getTokenData();

    String paymentUrlId = "$paymentStatusUrl/$paymentId";
    try {
      final response = await get(
        Uri.parse(paymentUrlId),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token.token}'
        },
      );

      if (response.statusCode == 200) {
        showDebug(msg: response.body);
        return TumenyPaymentData.fromResponse(
            tumenyCustomerData, jsonDecode(response.body) as Map);
      } else {
        showDebug(msg: 'Error: ${response.body} ');
      }
    } catch (e) {
      showDebug(msg: 'Error: $e');
    }
    return null;
  }

  Future<TumenySmsData?> sendSMS(
      TumenyCustomerData tumenyCustomerData, String message) async {
    TumenyTokenData token = await getTokenData();

    // smsData in JSON format
    final Map<String, dynamic> smsData = {
      'sender': senderId,
      'message': message,
      'recipient': tumenyCustomerData.phoneNumber
    };

    // Convert smsData to JSON string
    final String jsonData = jsonEncode(smsData);

    try {
      final response = await post(
        Uri.parse(smsUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token.token}'
        },
        body: jsonData,
      );

      if (response.statusCode == 200) {
        return TumenySmsData.fromResponse(
            tumenyCustomerData, jsonDecode(response.body) as Map);
      } else {
        showDebug(msg: 'Error: ${response.body}');
      }
    } catch (e) {
      showDebug(msg: 'Error: $e');
    }
    return null;
  }
}
