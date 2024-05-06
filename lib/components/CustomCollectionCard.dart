import 'package:flutter/material.dart';

import 'CustomOnClickContainer.dart';

class CustomCollectionCard extends StatelessWidget {
  final Icon? startIcon;
  final String text;
  final Widget? endWidget;
  final TextStyle? textStyle;
  final double gap;
  final Color? defaultColor;
  final Color? clickedColor;
  final Function()? onClick;

  const CustomCollectionCard(
      {super.key,
      this.startIcon,
      required this.text,
      this.endWidget,
      this.onClick,
      this.textStyle,
      this.gap = 16,
      this.defaultColor,
      this.clickedColor});

  @override
  Widget build(BuildContext context) {
    return CustomOnClickContainer(
      onTap: onClick,
      defaultColor: defaultColor ?? Colors.transparent,
      clickedColor: clickedColor ?? Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                //   Start Icon

                startIcon ?? const SizedBox(),

                // Text
                SizedBox(
                  width: startIcon != null ? gap : 0,
                ),
                Text(
                  text,
                  style: textStyle,
                )
              ],
            ),

            // End Icon
            endWidget ?? const SizedBox()
          ],
        ),
      ),
    );
  }
}
