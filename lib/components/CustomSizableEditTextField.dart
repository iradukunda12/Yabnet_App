import 'package:flutter/material.dart';

import '../main.dart';

class CustomSizableEditTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final double textSize;
  final double height;
  final double gap;
  final int? maxLength;
  final String? textTitle;
  final String? readOnlyText;
  final bool focusedOnStart;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;
  final TextAlign textAlign;
  final TextAlignVertical textAlignVertical;
  final bool useShadow;
  final ValueChanged<int>? onDropDownItemChange;
  final List<MapEntry<Widget, Function()>>? dropDownItems;

  const CustomSizableEditTextField(
      {super.key,
      required this.controller,
      required this.hintText,
      required this.obscureText,
      required this.textSize,
      this.maxLength,
      this.keyboardType,
      this.capitalization = TextCapitalization.none,
      this.focusedOnStart = false,
      this.gap = 8,
      this.readOnlyText,
      this.useShadow = true,
      this.dropDownItems,
      this.onDropDownItemChange,
      this.textTitle,
      required this.height,
      required this.textAlign,
      required this.textAlignVertical});

  @override
  CustomSizableEditTextFieldState createState() =>
      CustomSizableEditTextFieldState();
}

class CustomSizableEditTextFieldState
    extends State<CustomSizableEditTextField> {
  bool getObscured = true;
  bool change = false;
  bool isFocused = false;
  FocusNode focusNode = FocusNode();
  String? getReadOnly;
  int? currentDropDown;

  TextEditingController readOnlyTextController = TextEditingController();

  @override
  void initState() {
    getObscured = widget.obscureText;
    widget.controller.addListener(() {
      if (mounted) {
        setState(() {
          change = true;
          change = false;
        });
      }
    });

    // Set the focus to the EditText when the page opens
    Future.delayed(const Duration(milliseconds: 500), () {
      if (widget.focusedOnStart && context.mounted) {
        FocusScope.of(context).requestFocus(focusNode);
      }
    });

    // Read Only

    if (widget.readOnlyText != null) {
      setState(() {
        readOnlyTextController.text = widget.readOnlyText ?? "";
        getReadOnly = widget.readOnlyText;
        widget.controller.text = getReadOnly ?? '';
      });
    }

    super.initState();
  }

  @override
  void didUpdateWidget(covariant CustomSizableEditTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.readOnlyText != null) {
      widget.controller.text = getReadOnly ?? '';
    }
  }

  Widget getTheEndIcon() {
    if (widget.obscureText) {
      return IconButton(
          onPressed: () {
            setState(() {
              getObscured = !getObscured;
            });
          },
          icon: getObscured
              ? const Icon(Icons.visibility)
              : const Icon(Icons.visibility_off));
    } else {
      return IconButton(
          onPressed: () {
            widget.controller.clear();
          },
          icon: const Icon(Icons.cancel));
    }
  }

  void onChangedDropDown(int? itemIndex) {
    if (itemIndex == null) {
      return;
    }
    if (widget.onDropDownItemChange != null) {
      widget.onDropDownItemChange!(itemIndex);
    }
    setState(() {
      currentDropDown = itemIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text
        Text(
          widget.textTitle ?? widget.hintText,
          style: const TextStyle(
              color: Color(getDarkGreyColor), fontWeight: FontWeight.bold),
        ),

        // Text Field
        SizedBox(
          height: widget.gap,
        ),
        Focus(
          onFocusChange: (focused) {
            setState(() {
              isFocused = focused;
            });
          },
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(focusNode);
            },
            child: Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isFocused
                        ? const Color(getMainPinkColor)
                        : Colors.transparent),
                boxShadow: widget.useShadow
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: SizedBox(
                height: widget.height,
                child: Row(
                  children: [
                    widget.dropDownItems != null &&
                            widget.dropDownItems!.isNotEmpty
                        ? Row(
                            children: [
                              const SizedBox(
                                width: 10,
                              ),
                              DropdownButton(
                                  menuMaxHeight: 300,
                                  value: currentDropDown ??
                                      widget.dropDownItems!
                                          .indexOf(widget.dropDownItems!.first),
                                  onChanged: onChangedDropDown,
                                  items: widget.dropDownItems!
                                      .asMap()
                                      .map((key, value) {
                                        return MapEntry(
                                          key,
                                          DropdownMenuItem(
                                              value: key, child: value.key),
                                        );
                                      })
                                      .values
                                      .toList()),
                            ],
                          )
                        : const SizedBox(),
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: TextField(
                          readOnly: getReadOnly != null,
                          focusNode: focusNode,
                          textAlign: widget.textAlign,
                          textAlignVertical: widget.textAlignVertical,
                          textCapitalization: widget.capitalization,
                          maxLength: widget.maxLength,
                          keyboardType: widget.keyboardType,
                          controller: widget.readOnlyText == null
                              ? widget.controller
                              : readOnlyTextController,
                          obscureText: getObscured,
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.transparent),
                                borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.transparent),
                                borderRadius: BorderRadius.circular(10)),
                            suffixIcon: !change
                                ? widget.controller.text.isNotEmpty &&
                                        getReadOnly == null
                                    ? getTheEndIcon()
                                    : null
                                : null,
                            suffixIconColor: Colors.black,
                            hintText: widget.hintText,
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          style: TextStyle(
                            fontSize: widget.textSize,
                            color: const Color(getGreyTextColor),
                            decoration: TextDecoration.none,
                            decorationThickness: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
