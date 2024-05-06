import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yabnet/components/CustomOnClickContainer.dart';
import 'package:yabnet/main.dart';

class CustomProfileButton extends StatefulWidget {
  final Icon icon;
  final double spacing;
  final String text;
  final Color defaultColor;
  final Color clickedColor;
  final Color textColor;
  final EdgeInsets padding;
  final Function()? onTap;
  final bool isEnabled;
  final double textSize;

  const CustomProfileButton(
      {Key? key,
      required this.icon,
      required this.spacing,
      required this.padding,
      this.onTap,
      required this.isEnabled,
      required this.textSize,
      required this.defaultColor,
      required this.clickedColor,
      required this.text,
      required this.textColor})
      : super(key: key);

  @override
  State<CustomProfileButton> createState() => _CustomProfileButtonState();
}

class _CustomProfileButtonState extends State<CustomProfileButton> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CustomOnClickContainer(
            defaultColor: widget.defaultColor,
            clickedColor: widget.clickedColor,
            onLongTap: widget.isEnabled ? widget.onTap : null,
            child: Padding(
              padding: widget.padding,
              child: Column(
                children: [
                  Container(
                      decoration: BoxDecoration(
                          color: Color(getMainPinkColor).withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: widget.icon,
                      )),
                  SizedBox(height: widget.spacing),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          widget.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: widget.textColor,
                              fontSize: widget.textSize),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
