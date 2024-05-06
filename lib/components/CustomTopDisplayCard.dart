import 'package:flutter/material.dart';

class CustomTopDisplayCard extends StatelessWidget {
  final Color shareColor;
  final Color backgroundColor;
  final double labelTextSize;
  final double codeTextSize;
  final String codeText;
  final Color labelTextColor;
  final Color smallTextColor;
  final EdgeInsets resourcePadding;
  final double borderRadius;
  final double textGap;
  final Function()? onTapShare;

  const CustomTopDisplayCard(
      {super.key,
      required this.backgroundColor,
      required this.labelTextSize,
      required this.codeTextSize,
      required this.codeText,
      required this.labelTextColor,
      required this.smallTextColor,
      required this.resourcePadding,
      required this.textGap,
      this.onTapShare,
      this.borderRadius = 10,
      required this.shareColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: resourcePadding,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //   Title
                          Text(
                            "Company Identity Code",
                            textScaleFactor: 1,
                            style: TextStyle(
                                color: labelTextColor, fontSize: labelTextSize),
                          ),
                          SizedBox(
                            height: textGap,
                          ),
                          Text(
                            codeText,
                            style: TextStyle(
                                color: smallTextColor,
                                fontSize: codeTextSize,
                                fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),

                    //   Share

                    GestureDetector(
                      onTap: onTapShare,
                      child: Row(
                        children: [
                          // Text
                          Text(
                            "Share",
                            textScaleFactor: 1,
                            style: TextStyle(color: shareColor),
                          ),
                          //   Icon
                          const SizedBox(
                            width: 4,
                          ),
                          Icon(
                            Icons.share,
                            color: shareColor,
                          )
                        ],
                      ),
                    )
                  ],
                ),
              )),
        ),
      ],
    );
  }
}
