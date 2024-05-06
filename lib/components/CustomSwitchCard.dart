import 'package:flutter/material.dart';

import '../main.dart';

class CustomSwitchCard extends StatefulWidget {
  final String text;
  final Color defaultColor;
  final double borderRadius;
  final EdgeInsets padding;
  final EdgeInsets iconPadding;
  final TextStyle textStyle;
  final bool usBoxShadow;
  final bool isSwitched;
  final ValueChanged<bool> onSwitchChange;

  const CustomSwitchCard(
      {super.key,
      required this.text,
      required this.defaultColor,
      this.borderRadius = 10,
      this.padding = const EdgeInsets.all(12),
      this.iconPadding = const EdgeInsets.only(left: 8),
      this.textStyle =
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      this.usBoxShadow = true,
      required this.isSwitched,
      required this.onSwitchChange});

  @override
  State<CustomSwitchCard> createState() => _CustomSwitchCardState();
}

class _CustomSwitchCardState extends State<CustomSwitchCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.defaultColor,
        boxShadow: widget.usBoxShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Padding(
        padding: widget.padding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            //   Push Text
            Expanded(
              child: Text(
                widget.text,
                style: widget.textStyle,
              ),
            ),

            // Switch
            const SizedBox(
              width: 5,
            ),
            SizedBox(
              height: 35,
              child: Switch(
                  value: widget.isSwitched,
                  activeColor: const Color(getMainPinkColor),
                  inactiveThumbColor: const Color(getDarkGreyColor),
                  activeTrackColor:
                      const Color(getMainPinkColor).withOpacity(0.5),
                  inactiveTrackColor:
                      const Color(getDarkGreyColor).withOpacity(0.5),
                  onChanged: widget.onSwitchChange),
            )
          ],
        ),

        // Row(
        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //   children: [
        //     // Text
        //     Expanded(
        //       child: Text(
        //         widget.text,
        //         style: widget.textStyle,
        //       ),
        //     ),
        //
        //     //   Icon
        //     widget.showClickable
        //         ? Padding(
        //             padding: widget.iconPadding,
        //             child: Icon(
        //               Icons.keyboard_arrow_right,
        //               size: (widget.textStyle.fontSize ?? 15) * 1.3,
        //               color: widget.textStyle.color,
        //             ),
        //           )
        //         : const SizedBox()
        //   ],
        // ),
      ),
    );
  }
}
