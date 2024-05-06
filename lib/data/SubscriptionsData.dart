import 'package:yabnet/components/CustomProject.dart';

import '../db_references/Members.dart';
import '../db_references/Plans.dart';
import '../db_references/Subscription.dart';
import 'PlanData.dart';

class SubscriptionData {
  final String subscriptionsId;
  final String plansId;
  final String membersId;
  final bool subscriptionsActive;
  final DateTime subscriptionsFrom;
  final DateTime subscriptionsTo;
  final bool subscriptionsPaymentVerified;
  final String plansSelected;
  final String paymentReference;
  final String subscriptionsStatus;
  final PlanData? plansData;

  SubscriptionData({
    required this.subscriptionsId,
    required this.plansId,
    required this.membersId,
    required this.subscriptionsActive,
    required this.subscriptionsFrom,
    required this.subscriptionsTo,
    required this.subscriptionsPaymentVerified,
    required this.plansSelected,
    required this.paymentReference,
    required this.subscriptionsStatus,
    required this.plansData,
  });

  factory SubscriptionData.fromJson(Map<dynamic, dynamic> json) {
    return SubscriptionData(
      subscriptionsId: json['subscriptions_id'],
      plansId: json['plans_id'],
      membersId: json['members_id'],
      subscriptionsActive: json['subscriptions_active'],
      subscriptionsFrom: DateTime.parse(json['subscriptions_from']),
      subscriptionsTo: DateTime.parse(json['subscriptions_to']),
      subscriptionsPaymentVerified: json['subscriptions_payment_verified'],
      plansSelected: json['plans_selected'],
      paymentReference: json['payment_reference'],
      subscriptionsStatus: json['subscriptionsStatus'],
      plansData: json['plansData'] != null
          ? PlanData.fromOnline(json['plansData'])
          : null,
    );
  }

  factory SubscriptionData.fromOnline(
      Map<dynamic, dynamic> json, Map<dynamic, dynamic>? meta) {
    return SubscriptionData(
      subscriptionsId: json[dbReference(Subscriptions.id)],
      plansId: json[dbReference(Plans.id)],
      membersId: json[dbReference(Members.id)],
      subscriptionsActive: json[dbReference(Subscriptions.active)],
      subscriptionsFrom: DateTime.parse(json[dbReference(Subscriptions.from)]),
      subscriptionsTo: DateTime.parse(json[dbReference(Subscriptions.to)]),
      subscriptionsPaymentVerified:
          json[dbReference(Subscriptions.payment_verified)],
      plansSelected: json[dbReference(Plans.selected)],
      paymentReference: json['payment_reference'],
      subscriptionsStatus: json[dbReference(Subscriptions.status)],
      plansData: meta != null ? PlanData.fromOnline(meta) : null,
    );
  }

  Map<dynamic, dynamic> toJson() {
    return {
      'subscriptions_id': subscriptionsId,
      'plans_id': plansId,
      'members_id': membersId,
      'subscriptions_active': subscriptionsActive,
      'subscriptions_from': subscriptionsFrom.toIso8601String(),
      'subscriptions_to': subscriptionsTo.toIso8601String(),
      'subscriptions_payment_verified': subscriptionsPaymentVerified,
      'plans_selected': plansSelected,
      'payment_reference': paymentReference,
      'subscriptionsStatus': subscriptionsStatus,
      'plansData: ': plansData,
    };
  }

  SubscriptionData copyWith(
      {String? subscriptionsId,
      String? plansId,
      String? membersId,
      bool? subscriptionsActive,
      DateTime? subscriptionsFrom,
      DateTime? subscriptionsTo,
      bool? subscriptionsPaymentVerified,
      String? plansSelected,
      String? paymentReference,
      String? subscriptionsStatus,
      PlanData? plansData}) {
    return SubscriptionData(
      subscriptionsId: subscriptionsId ?? this.subscriptionsId,
      plansId: plansId ?? this.plansId,
      membersId: membersId ?? this.membersId,
      subscriptionsActive: subscriptionsActive ?? this.subscriptionsActive,
      subscriptionsFrom: subscriptionsFrom ?? this.subscriptionsFrom,
      subscriptionsTo: subscriptionsTo ?? this.subscriptionsTo,
      subscriptionsPaymentVerified:
          subscriptionsPaymentVerified ?? this.subscriptionsPaymentVerified,
      plansSelected: plansSelected ?? this.plansSelected,
      paymentReference: paymentReference ?? this.paymentReference,
      subscriptionsStatus: subscriptionsStatus ?? this.subscriptionsStatus,
      plansData: plansData ?? this.plansData,
    );
  }
}
