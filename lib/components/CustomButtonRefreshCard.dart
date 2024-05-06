import 'package:flutter/material.dart';

import '../builders/ControlledStreamBuilder.dart';
import '../main.dart';
import 'CustomPrimaryButton.dart';

class CustomButtonRefreshCard extends StatefulWidget {
  final String displayText;
  final String buttonText;
  final TextStyle? textStyle;
  final double gap;
  final EdgeInsets padding;
  final Icon topIcon;
  final RetryStreamListener retryStreamListener;

  const CustomButtonRefreshCard(
      {super.key,
      required this.retryStreamListener,
      required this.displayText,
      this.textStyle,
      this.gap = 16,
      this.buttonText = "Refresh",
      this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      required this.topIcon});

  @override
  State<CustomButtonRefreshCard> createState() =>
      _CustomButtonRefreshCardState();
}

class _CustomButtonRefreshCardState extends State<CustomButtonRefreshCard> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: widget.padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error Icon

              widget.topIcon,

              //   Text
              SizedBox(
                height: widget.gap * 0.7,
              ),
              Text(
                widget.displayText,
                textAlign: TextAlign.center,
                style: widget.textStyle ??
                    const TextStyle(color: Color(getGreyTextColor)),
              ),

              //   RefreshButton
              SizedBox(
                height: widget.gap,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: CustomPrimaryButton(
                    buttonText: widget.buttonText,
                    onTap: () {
                      widget.retryStreamListener.startRetrying();
                    }),
              )
            ],
          ),
        ),
      ),
    );
  }
}
