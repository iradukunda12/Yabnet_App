import 'package:flutter/material.dart';

import 'CustomOnClickContainer.dart';

class CustomSelectableCard extends StatefulWidget {
  final String text;
  final String image;
  final Color defaultColor;
  final Color clickedColor;
  final double borderRadius;
  final EdgeInsets padding;
  final EdgeInsets iconPadding;
  final TextStyle textStyle;
  final bool showClickable;
  final bool usBoxShadow;
  final Function() onTap;

  const CustomSelectableCard(
      {super.key,
      required this.text,
      required this.defaultColor,
      required this.clickedColor,
      this.borderRadius = 10,
      this.padding = const EdgeInsets.all(12),
      this.iconPadding = const EdgeInsets.only(left: 8),
      this.textStyle = const TextStyle(),
      required this.onTap,
      this.showClickable = false,
      this.usBoxShadow = true,
      required this.image});

  @override
  State<CustomSelectableCard> createState() => _CustomSelectableCardState();
}

class _CustomSelectableCardState extends State<CustomSelectableCard> {
  @override
  Widget build(BuildContext context) {
    return CustomOnClickContainer(
      onTap: widget.onTap,
      defaultColor: widget.defaultColor,
      clickedColor: widget.clickedColor,
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
      child: Padding(
        padding: widget.padding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Image
            ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  widget.image,
                  height: 35,
                  width: 35,
                  fit: BoxFit.cover,
                )),

            // Text
            const SizedBox(
              width: 8,
            ),
            Expanded(
              child: Text(
                widget.text,
                style: widget.textStyle,
              ),
            ),

            //   Icon
            widget.showClickable
                ? Padding(
                    padding: widget.iconPadding,
                    child: Icon(
                      Icons.keyboard_arrow_right,
                      size: (widget.textStyle.fontSize ?? 15) * 1.3,
                      color: widget.textStyle.color,
                    ),
                  )
                : const SizedBox()
          ],
        ),
      ),
    );
  }
}
