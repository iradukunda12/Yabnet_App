import 'package:flutter/material.dart';

import 'CustomOnClickContainer.dart';

class CustomMenuCard extends StatelessWidget {
  final Icon icon;
  final String text;
  final double textSize;
  final Color textColor;
  final Color defaultColor;
  final Color clickedColor;
  final double? textScaleFactor;
  final double gap;
  final EdgeInsets padding;
  final bool useShadow;
  final bool bottomLine;
  final Function() onTap;

  const CustomMenuCard(
      {super.key,
      required this.icon,
      required this.textSize,
      required this.textColor,
      this.textScaleFactor,
      this.gap = 8,
      required this.text,
      required this.defaultColor,
      required this.clickedColor,
      required this.onTap,
      required this.padding,
      this.useShadow = false,
      this.bottomLine = false});

  @override
  Widget build(BuildContext context) {
    return CustomOnClickContainer(
      defaultColor: defaultColor,
      clickedColor: clickedColor,
      boxShadow: useShadow
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ]
          : [],
      onTap: onTap,
      child: Column(
        children: [
          // Menu
          Padding(
            padding: padding,
            child: Row(
              children: [
                icon,
                SizedBox(
                  width: gap,
                ),
                Expanded(
                  child: Text(
                    text,
                    textScaleFactor: 1,
                    style: TextStyle(color: textColor, fontSize: textSize),
                  ),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.keyboard_arrow_right,
                          size: textSize * 1.3,
                          color: textColor,
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),

          bottomLine
              ? Row(
                  children: [
                    Expanded(
                        child: Container(
                      height: 1,
                      color: textColor.withOpacity(0.2),
                    ))
                  ],
                )
              : const SizedBox()
        ],
      ),
    );
  }
}
