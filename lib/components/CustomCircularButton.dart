import 'package:flutter/material.dart';

import 'CustomOnClickContainer.dart';

class CustomCircularButton extends StatefulWidget {
  final double width;
  final double height;
  final IconData icon;
  final String? imagePath;
  final Color? defaultBackgroundColor;
  final Color? clickedBackgroundColor;
  final Color? iconColor;
  final Color? badgeColor;
  final Color? textColor;
  final double textSize;
  final double iconSize;
  final double? gap;
  final bool colorImage;
  final bool showShadow;
  final int? badgeNumber;
  final Alignment mainAlignment;
  final Alignment badgeAlignment;
  final Function()? onPressed;

  const CustomCircularButton(
      {super.key,
      required this.icon,
      this.onPressed,
      required this.width,
      required this.height,
      this.imagePath,
      this.defaultBackgroundColor,
      this.colorImage = false,
      this.badgeColor,
      this.textColor,
      this.textSize = 13,
      this.gap = 2,
      this.iconSize = 20,
      this.iconColor,
      this.badgeNumber,
      this.badgeAlignment = Alignment.topRight,
      this.clickedBackgroundColor,
      this.mainAlignment = Alignment.centerLeft,
      this.showShadow = false});

  @override
  State<CustomCircularButton> createState() => CustomCircularButtonState();
}

class CustomCircularButtonState extends State<CustomCircularButton> {
  double getPadding() {
    double firstPadding = (widget.gap ?? 0.0) / 2;
    double secondPadding = (widget.gap ?? 0.0) / 2.5;

    if (firstPadding <= 6.0 && firstPadding >= 2) {
      return firstPadding;
    } else if (secondPadding <= 6.0 && secondPadding >= 2) {
      return secondPadding;
    } else {
      return 3;
    }
  }

  String formatString(String input) {
    if (input.length >= 3) {
      if (input.length > 3) {
        return "${input.substring(0, 3)}+";
      } else {
        return input;
      }
    } else {
      return input.padRight(3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomOnClickContainer(
      onTap: widget.onPressed,
      shape: BoxShape.circle,
      width: widget.width,
      height: widget.height,
      defaultColor: widget.imagePath == null || widget.colorImage
          ? widget.defaultBackgroundColor ?? Colors.transparent
          : Colors.transparent,
      clickedColor: widget.imagePath == null || widget.colorImage
          ? widget.clickedBackgroundColor ?? Colors.transparent
          : Colors.transparent,
      boxShadow: widget.showShadow
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ]
          : [],
      child: Stack(
        children: [
          widget.imagePath != null
              ? Padding(
                  padding: EdgeInsets.all((widget.gap ?? 0)),
                  child: Align(
                    child: Image.asset(
                      widget.imagePath!,
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              : Align(
                  alignment: widget.mainAlignment,
                  child: Icon(
                    widget.icon,
                    size: widget.iconSize,
                    color: widget.iconColor,
                  )),
          // ),

          (widget.badgeNumber ?? 0) > 0
              ? Align(
                  alignment: widget.badgeAlignment,
                  child: Container(
                      decoration: BoxDecoration(
                          color: widget.badgeColor,
                          borderRadius: BorderRadius.circular(widget.height)),
                      child: Padding(
                        padding: EdgeInsets.all(getPadding()),
                        child: Text(
                          formatString("${widget.badgeNumber}"),
                          textAlign: TextAlign.center,
                          textScaleFactor: 1,
                          style: TextStyle(
                              color: widget.textColor,
                              fontSize: widget.textSize),
                        ),
                      )),
                )
              : const SizedBox()
        ],
      ),
    );
  }
}
