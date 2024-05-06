import 'package:flutter/material.dart';

import '../components/CustomOnClickContainer.dart';

class CustomIconViewCard extends StatefulWidget {
  final String text;
  final Icon? icon;
  final Widget? widget;
  final Color defaultColor;
  final Color onClickColor;
  final Color textColor;
  final double textSize;
  final EdgeInsets padding;
  final double borderRadius;
  final double gap;
  final BoxFit fit;
  final Function() onTap;

  const CustomIconViewCard(
      {Key? key,
      required this.text,
      required this.onTap,
      this.icon,
      required this.defaultColor,
      this.fit = BoxFit.contain,
      this.gap = 8,
      this.padding =
          const EdgeInsets.only(top: 12, bottom: 15, left: 12, right: 12),
      required this.textColor,
      this.textSize = 14,
      this.borderRadius = 20,
      this.widget,
      required this.onClickColor})
      : super(key: key);

  @override
  State<CustomIconViewCard> createState() => _CustomIconViewCardState();
}

class _CustomIconViewCardState extends State<CustomIconViewCard> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomOnClickContainer(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(widget.borderRadius),
      defaultColor: widget.defaultColor,
      clickedColor: widget.onClickColor,
      child: Padding(
        padding: widget.padding,
        child: Column(
          children: [
            //  Icon / Leading

            widget.icon != null
                ? Column(
                    children: [
                      widget.widget ?? widget.icon ?? SizedBox(),
                      SizedBox(height: widget.gap),
                    ],
                  )
                : SizedBox(),

            //  Text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    widget.text,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    textScaleFactor: 1,
                    style: TextStyle(
                        color: widget.textColor, fontSize: widget.textSize),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
