import 'package:flutter/material.dart';

import '../main.dart';
import 'CustomOnClickContainer.dart';

typedef SelectDialogFuture<T> = Future<T> Function(BuildContext context);
typedef SelectedValue<T> = String Function(BuildContext context, T value);

class CustomSelectDialogField<T> extends StatefulWidget {
  final String hintText;
  final String? text;
  final double gap;
  final double opacity;
  final EdgeInsets padding;
  final bool useShadow;
  final bool wrap;
  final TextStyle textStyle;
  final Function() onTap;

  const CustomSelectDialogField({
    super.key,
    required this.hintText,
    this.gap = 8,
    required this.useShadow,
    this.text,
    required this.padding,
    required this.onTap,
    required this.textStyle,
    this.opacity = 0.3,
    this.wrap = false,
  });

  @override
  CustomSelectDialogFieldState<T> createState() =>
      CustomSelectDialogFieldState<T>();
}

class CustomSelectDialogFieldState<T>
    extends State<CustomSelectDialogField<T>> {
  Widget get textWidget => Text(
        widget.text ?? widget.hintText,
        style: widget.textStyle.copyWith(
            color: widget.text != null
                ? widget.textStyle.color
                : widget.textStyle.color != null
                    ? widget.textStyle.color?.withOpacity(widget.opacity)
                    : Colors.black.withOpacity(widget.opacity)),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text
        Text(
          widget.hintText,
          style: const TextStyle(
              color: Color(getDarkGreyColor), fontWeight: FontWeight.bold),
        ),

        // Text Field
        SizedBox(
          height: widget.gap,
        ),
        CustomOnClickContainer(
          onTap: widget.onTap,
          clipBehavior: Clip.hardEdge,
          clickedColor: Colors.grey.shade300,
          defaultColor: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
          boxShadow: widget.useShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
          child: Padding(
            padding: widget.padding,
            child: Row(
              children: [
                !widget.wrap
                    ? Expanded(
                        child: textWidget,
                      )
                    : textWidget,
                Icon(
                  Icons.arrow_drop_down,
                  color: widget.textStyle.color,
                  size: (widget.textStyle.fontSize ?? 15) * 1.3,
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
