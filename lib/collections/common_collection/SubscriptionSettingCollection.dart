import 'package:flutter/material.dart';

import '../../components/CustomClickableCard.dart';

class SubscriptionSettingCollection extends StatefulWidget {
  const SubscriptionSettingCollection({super.key});

  @override
  State<SubscriptionSettingCollection> createState() =>
      _SubscriptionSettingCollectionState();
}

class _SubscriptionSettingCollectionState
    extends State<SubscriptionSettingCollection> {
  void checkPlan() {
    //   CompanySubscriptionPlanService().atCompanyPlanPage = true;
    //   Navigator.push(context,
    //           MaterialPageRoute(builder: (builder) => const CompanyPlanPage()))
    //       .then((value) {
    //     CompanySubscriptionPlanService().atCompanyPlanPage = false;
    //   });
  }

  void checkSubscriptionPlan() {
    // int? planIndex = PlanOperation().planTypeIndex(
    //     PlanOperation().getPlanType() ?? dbReference(Plan.for_free));
    // int nextIndex = (planIndex ?? 0);
    //
    // Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //         builder: (builder) => CompanySubscriptionPage(
    //               defaultSelection: nextIndex,
    //             )));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          children: [
            // My Plan
            Row(
              children: [
                Expanded(
                  child: CustomClickableCard(
                    showClickable: true,
                    onTap: checkPlan,
                    borderRadius: 0,
                    defaultColor: Colors.white,
                    clickedColor: Colors.grey.shade200,
                    text: "My Plan",
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            //
            // // Subscription Plan
            // Row(
            //   children: [
            //     Expanded(
            //       child: CustomClickableCard(
            //         showClickable: true,
            //         onTap: checkSubscriptionPlan,
            //         borderRadius: 0,
            //         defaultColor: Colors.white,
            //         clickedColor: Colors.grey.shade200,
            //         text: "Subscription plans",
            //         textStyle: const TextStyle(
            //             fontSize: 15, fontWeight: FontWeight.w500),
            //       ),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}
