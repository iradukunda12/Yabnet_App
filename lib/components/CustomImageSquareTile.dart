import 'package:flutter/material.dart';

import 'CustomOnClickContainer.dart';

class CustomImageSquareTile extends StatefulWidget {
  final String imagePath;
  final Color defaultColor;
  final Color clickedColor;
  final Function()? onTap;

  const CustomImageSquareTile(
      {super.key,
      required this.imagePath,
      required this.defaultColor,
      required this.clickedColor,
      this.onTap});

  @override
  State<StatefulWidget> createState() {
    return CustomImageSquareTileState();
  }
}

class CustomImageSquareTileState extends State<CustomImageSquareTile> {
  @override
  Widget build(BuildContext context) {
    return CustomOnClickContainer(
      onTap: widget.onTap,
      clipBehavior: Clip.hardEdge,
      border: Border.all(color: Colors.grey.shade100),
      borderRadius: BorderRadius.circular(8),
      defaultColor: widget.defaultColor,
      clickedColor: widget.clickedColor,
      child: Center(
          child: Image.asset(
        widget.imagePath,
        height: 50,
      )),
    );
  }
}
