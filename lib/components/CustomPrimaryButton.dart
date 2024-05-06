import 'package:flutter/material.dart';

import '../main.dart';

class CustomPrimaryButton extends StatefulWidget {
  final EdgeInsets padding;
  final String buttonText;
  final Function()? onTap;
  final bool isEnabled;
  final bool useBoxShadow;
  final double borderRadius;
  final double textSize;
  final bool wrapText;
  final bool expanded;
  final Color activeButtonColor;
  final Color activeTextColor;

  const CustomPrimaryButton(
      {super.key,
      required this.buttonText,
      required this.onTap,
      this.isEnabled = true,
      this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      this.borderRadius = 10,
      this.textSize = 17,
      this.useBoxShadow = true,
      this.wrapText = false,
      this.activeButtonColor = const Color(getMainPinkColor),
      this.activeTextColor = Colors.white,
      this.expanded = true});

  @override
  CustomPrimaryButtonState createState() => CustomPrimaryButtonState();
}

class CustomPrimaryButtonState extends State<CustomPrimaryButton> {
  bool isClicked = false;

  void changeClicked(TapDownDetails tapDownDetails) {
    setState(() {
      isClicked = true;
    });
  }

  void changeNotClicked(TapUpDetails tapUpDetails) {
    setState(() {
      isClicked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapCancel: () {
        setState(() {
          isClicked = false;
        });
      },
      onTapDown: changeClicked,
      onTapUp: changeNotClicked,
      onTap: widget.isEnabled ? widget.onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: /* When button is enabled */ widget.isEnabled
              /* When button is enabled and clicked and onTapped */ ? isClicked &&
                      widget.onTap != null
                  ? widget.activeButtonColor.withOpacity(0.65)
                  /* When button is enabled and not clicked */ : widget
                      .activeButtonColor
              /* When button is disabled */ : const Color(getMainPinkColor)
                  .withOpacity(0.3),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: widget.useBoxShadow && widget.isEnabled
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            widget.expanded
                ? Expanded(
                    child: getWidget(),
                  )
                : getWidget(),
          ],
        ),
      ),
    );
  }

  Widget getWidget() {
    return Padding(
      padding: widget.padding,
      child: Text(
        widget.buttonText,
        textAlign: TextAlign.center,
        overflow: widget.wrapText ? null : TextOverflow.ellipsis,
        style: TextStyle(
            color: widget.isEnabled
                ? widget.activeTextColor
                : widget.activeTextColor.withOpacity(0.6),
            fontSize: widget.textSize),
      ),
    );
  }
}
