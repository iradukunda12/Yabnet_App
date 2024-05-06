import 'package:flutter/material.dart';

import '../../components/CustomClickableCard.dart';

class BusinessCollection extends StatefulWidget {
  const BusinessCollection({super.key});

  @override
  State<BusinessCollection> createState() => _BusinessCollectionState();
}

class _BusinessCollectionState extends State<BusinessCollection> {
  void clickManageBusiness() {}

  void clickStatistics() {}

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
            //FAQ
            Row(
              children: [
                Expanded(
                  child: CustomClickableCard(
                    onTap: clickStatistics,
                    borderRadius: 0,
                    defaultColor: Colors.white,
                    showClickable: true,
                    clickedColor: Colors.grey.shade200,
                    text: "My businesses",
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),

            //Acknowledgements
            Row(
              children: [
                Expanded(
                  child: CustomClickableCard(
                    onTap: clickManageBusiness,
                    borderRadius: 0,
                    showClickable: true,
                    defaultColor: Colors.white,
                    clickedColor: Colors.grey.shade200,
                    text: "Announcements",
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
