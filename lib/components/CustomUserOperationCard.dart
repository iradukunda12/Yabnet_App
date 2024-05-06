import 'package:flutter/material.dart';

import 'CustomOnClickContainer.dart';

class CustomUserOperationCard extends StatelessWidget {
  final String? lottiePath;
  final Icon? icon;
  final double? imageSize;
  final Color defaultClickColor;
  final Color onClickedColor;
  final Color resourceBackgroundColor;
  final double bigTextSize;
  final double smallTextSize;
  final String bigText;
  final String smallText;
  final Color bigTextColor;
  final Color smallTextColor;
  final EdgeInsets resourcePadding;
  final double resourceSize;
  final double gap;
  final double textGap;
  final double borderRadius;
  final Function()? onTap;

  const CustomUserOperationCard(
      {super.key,
      this.lottiePath,
      required this.defaultClickColor,
      required this.onClickedColor,
      required this.resourceBackgroundColor,
      this.resourcePadding =
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      this.gap = 12,
      required this.bigText,
      required this.smallText,
      required this.bigTextColor,
      required this.smallTextColor,
      this.borderRadius = 10,
      this.bigTextSize = 14,
      this.smallTextSize = 13,
      this.textGap = 4,
      this.onTap,
      this.imageSize,
      this.icon,
      required this.resourceSize});

  @override
  Widget build(BuildContext context) {
    return CustomOnClickContainer(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      defaultColor: defaultClickColor,
      clickedColor: onClickedColor,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
      child: Padding(
        padding: resourcePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
                height: resourceSize,
                width: resourceSize,
                decoration: BoxDecoration(
                  color: resourceBackgroundColor,
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                child: Center(child: icon)),

            SizedBox(
              height: gap,
            ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //   Title
                      Text(
                        bigText,
                        textScaleFactor: 1,
                        style: TextStyle(
                            color: bigTextColor,
                            fontSize: bigTextSize,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: textGap,
                      ),
                      Text(
                        smallText,
                        textScaleFactor: 1,
                        style: TextStyle(
                            color: smallTextColor, fontSize: smallTextSize),
                      )
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
