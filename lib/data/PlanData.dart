import 'package:yabnet/components/CustomProject.dart';

import '../db_references/Plans.dart';

class PlanData {
  final String plansId;
  final String plansTitle;
  final String plansDescription;
  final double plansMonthlyPayment;
  final double plansQuarterlyPayment;
  final double plansBiAnnualPayment;
  final double plansYearlyPayment;
  final String plansCurrency;

  PlanData(
      this.plansId,
      this.plansTitle,
      this.plansDescription,
      this.plansMonthlyPayment,
      this.plansQuarterlyPayment,
      this.plansBiAnnualPayment,
      this.plansYearlyPayment,
      this.plansCurrency);

  Map<dynamic, dynamic> toJson() {
    return {
      'plansId': plansId,
      'plansTitle': plansTitle,
      'plansDescription': plansDescription,
      'plansMonthlyPayment': plansMonthlyPayment,
      'plansQuarterlyPayment': plansQuarterlyPayment,
      'plansBiAnnualPayment': plansBiAnnualPayment,
      'plansYearlyPayment': plansYearlyPayment,
      'plansCurrency': plansCurrency,
    };
  }

  factory PlanData.fromJson(Map<dynamic, dynamic> json) {
    return PlanData(
      json['plansId'],
      json['plansTitle'],
      json['plansDescription'],
      json['plansMonthlyPayment'],
      json['plansQuarterlyPayment'],
      json['plansBiAnnualPayment'],
      json['plansYearlyPayment'],
      json['plansCurrency'],
    );
  }

  factory PlanData.fromOnline(Map<dynamic, dynamic> json) {
    return PlanData(
      json[dbReference(Plans.id)],
      json[dbReference(Plans.title)],
      json[dbReference(Plans.description)],
      json[dbReference(Plans.monthly_payment)],
      json[dbReference(Plans.quarterly_payment)],
      json[dbReference(Plans.bi_annual_payment)],
      json[dbReference(Plans.yearly_payment)],
      json[dbReference(Plans.currency)],
    );
  }

  PlanData copyWith({
    String? plansId,
    String? plansTitle,
    String? plansDescription,
    double? plansMonthlyPayment,
    double? plansQuarterlyPayment,
    double? plansBiAnnualPayment,
    double? plansYearlyPayment,
    String? plansCurrency,
  }) {
    return PlanData(
      plansId ?? this.plansId,
      plansTitle ?? this.plansTitle,
      plansDescription ?? this.plansDescription,
      plansMonthlyPayment ?? this.plansMonthlyPayment,
      plansQuarterlyPayment ?? this.plansQuarterlyPayment,
      plansBiAnnualPayment ?? this.plansBiAnnualPayment,
      plansYearlyPayment ?? this.plansYearlyPayment,
      plansCurrency ?? this.plansCurrency,
    );
  }
}
