import 'package:postgrest/src/postgrest_builder.dart';
import 'package:postgrest/src/types.dart';
import 'package:yabnet/db_references/Members.dart';

import '../Tumeny/TumenyConfig.dart';
import '../components/CustomProject.dart';
import '../data/TumenyCustomerData.dart';
import '../data/TumenyPaymentData.dart';
import '../data/TumenySmsData.dart';
import '../db_references/Subscription.dart';
import '../supabase/SupabaseConfig.dart';

class SubscriptionsOperation {
  Stream<List<Map<String, dynamic>>> getUserSubscription(String thisUser,
      {SupabaseStreamPaginationOption? fetchOptions}) {
    final stream = SupabaseConfig.client
        .from(dbReference(Subscriptions.table))
        .stream(primaryKey: [dbReference(Subscriptions.id)]).eq(
            dbReference(Members.id), thisUser);

    if (fetchOptions != null) {
      stream.limit(fetchOptions.supabaseStreamPaginationController.fetchBy);
    }
    return stream;
  }

  PostgrestFilterBuilder deleteSubscription(String subscriptionId) {
    return SupabaseConfig.client
        .from(dbReference(Subscriptions.table))
        .delete()
        .eq(dbReference(Subscriptions.id), subscriptionId);
  }

  PostgrestTransformBuilder<PostgrestMap?> updateSubscription(
      String subscriptionId) {
    return SupabaseConfig.client
        .from(dbReference(Subscriptions.table))
        .update({
          dbReference(Subscriptions.status):
              dbReference(Subscriptions.failed_payment)
        })
        .eq(dbReference(Subscriptions.id), subscriptionId)
        .select()
        .maybeSingle();
  }

  PostgrestTransformBuilder<PostgrestList> updateVerifiedSubscription(
      String subscriptionId, String subscriptionTo) {
    return SupabaseConfig.client.from(dbReference(Subscriptions.table)).update({
      dbReference(Subscriptions.status):
          dbReference(Subscriptions.verified_payment),
      dbReference(Subscriptions.active): true,
      dbReference(Subscriptions.payment_verified): true,
      dbReference(Subscriptions.to): subscriptionTo,
    }).match({
      dbReference(Subscriptions.id): subscriptionId,
      dbReference(Subscriptions.status):
          dbReference(Subscriptions.pending_payment),
    }).select();
  }

  bool isTimeBetween(
      DateTime startTime, DateTime endTime, DateTime timeToCheck) {
    if (startTime.isAfter(endTime)) {
      return false;
    }

    return timeToCheck.isAfter(startTime) && timeToCheck.isBefore(endTime);
  }

  Future<TumenyPaymentData?> createTumenyPay(
      TumenyCustomerData tumenyCustomerData, String title,
      {int amount = 1}) async {
    TumenyPaymentData? payment = await TumenyConfig()
        .createNewPayment(tumenyCustomerData, title, amount);
    return payment;
  }

  Future<TumenyPaymentData?> getPaymentStatus(
      TumenyCustomerData tumenyCustomerData, String? id) async {
    TumenyPaymentData? paymentStatus =
        await TumenyConfig().getPaymentStatus(tumenyCustomerData, id ?? '');
    return paymentStatus;
  }

  Future<TumenySmsData?> sendSms(TumenyCustomerData tumenyCustomerData,
      {String message = "Please, pay up"}) async {
    TumenySmsData? smsStatus =
        await TumenyConfig().sendSMS(tumenyCustomerData, message);

    return smsStatus;
  }
}
