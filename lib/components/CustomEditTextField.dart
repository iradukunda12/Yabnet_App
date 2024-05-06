import 'package:flutter/material.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';

import '../main.dart';

enum PasswordValid { empty, valid, not_valid }

class PasswordStrengthIndicator extends StatelessWidget {
  final String validityText;
  final PasswordValid isValid;
  final IconData? icon;
  final Color validColor;
  final Color notColor;

  const PasswordStrengthIndicator({
    Key? key,
    required this.isValid,
    required this.icon,
    required this.validColor,
    required this.validityText,
    required this.notColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;

    if (isValid == PasswordValid.valid) {
      color = validColor;
    } else if (isValid == PasswordValid.not_valid) {
      color = notColor;
    }
    return Row(
      children: [
        if (icon != null)
          Icon(
            icon,
            size: 10,
            color: color,
          ),
        SizedBox(
          width: 5,
        ),
        Expanded(
            child: Text(
          validityText,
          style: TextStyle(fontSize: 14, color: color),
        ))
      ],
    );
  }
}

class CustomEditTextFormatter {
  late CustomEditTextFieldFormatOptions? customEditTextFieldFormatter;

  CustomEditTextFormatter(this.customEditTextFieldFormatter);

  bool isEmail(String value) {
    final emailRegex =
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$', caseSensitive: false);
    return emailRegex.hasMatch(value);
  }

  bool validatePassword(String value) {
    final formatter = customEditTextFieldFormatter;
    // Check if the password contains a number
    if (formatter?.hasNumbers == true && !containsNumber(value)) {
      return false;
    }

    // Check if the password length is at least 8 characters
    if (!isLengthGreaterThan(value, formatter?.hasLengthOf ?? 8)) {
      return false;
    }

    // Check if the password contains upperCase
    if (formatter?.hasUpperCase == true && !containsUpperCase(value)) {
      return false;
    }

    // Check if the password contains lowercase
    if (formatter?.hasLowerCase == true && !containsLowerCase(value)) {
      return false;
    }

    // Check if the password contains special character
    if (formatter?.hasSpecialCharacter == true &&
        !containsSpecialCharacter(value)) {
      return false;
    }

    if (formatter == null) {
      return false;
    }
    return true;
  }

  bool containsNumber(String value) {
    return value.contains(RegExp(r'\d'));
  }

  bool containsSpecialCharacter(String value) {
    return value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  bool isLengthGreaterThan(String value, int length) {
    return value.length >= length;
  }

  bool containsUpperCase(String value) {
    return value.contains(RegExp(r'[A-Z]'));
  }

  bool containsLowerCase(String value) {
    return value.contains(RegExp(r'[a-z]'));
  }
}

class PasswordCheckWidget extends StatelessWidget {
  final WidgetStateNotifier<String> textNotifier;
  final ValueChanged<bool> validated;
  final CustomEditTextFieldFormatOptions customEditTextFieldFormatter;

  const PasswordCheckWidget(
      {super.key,
      required this.customEditTextFieldFormatter,
      required this.textNotifier,
      required this.validated});

  @override
  Widget build(BuildContext context) {
    return WidgetStateConsumer(
        widgetStateNotifier: textNotifier,
        widgetStateBuilder: (context, text) {
          final formatter =
              CustomEditTextFormatter(customEditTextFieldFormatter);
          final formatterValue = formatter.customEditTextFieldFormatter;

          validated(formatter.validatePassword(text ?? ''));
          return Column(
            children: [
              if ((formatterValue?.iEmail ?? false) == false)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Password must contain: ",
                        style: const TextStyle(color: Color(getDarkGreyColor)),
                      ),

                      // Uppercase
                      if (formatterValue?.hasUpperCase == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Builder(builder: (context) {
                            PasswordValid valid = PasswordValid.empty;
                            if (formatter.containsUpperCase(text ?? "")) {
                              valid = PasswordValid.valid;
                            } else if (text?.isNotEmpty == true) {
                              valid = PasswordValid.not_valid;
                            }
                            return PasswordStrengthIndicator(
                                isValid: valid,
                                icon: Icons.circle,
                                validColor: Colors.green,
                                validityText: "An uppercase",
                                notColor: Colors.red);
                          }),
                        ),

                      // Length
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Builder(builder: (context) {
                          PasswordValid valid = PasswordValid.empty;
                          if (formatter.isLengthGreaterThan(
                              text ?? "", formatterValue?.hasLengthOf ?? 8)) {
                            valid = PasswordValid.valid;
                          } else if (text?.isNotEmpty == true) {
                            valid = PasswordValid.not_valid;
                          }
                          return PasswordStrengthIndicator(
                              isValid: valid,
                              icon: Icons.circle,
                              validColor: Colors.green,
                              validityText:
                                  "A minimum of ${formatterValue?.hasLengthOf ?? 8} characters",
                              notColor: Colors.red);
                        }),
                      ),

                      // LowerCase
                      if (formatterValue?.hasLowerCase == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Builder(builder: (context) {
                            PasswordValid valid = PasswordValid.empty;
                            if (formatter.containsLowerCase(text ?? "")) {
                              valid = PasswordValid.valid;
                            } else if (text?.isNotEmpty == true) {
                              valid = PasswordValid.not_valid;
                            }
                            return PasswordStrengthIndicator(
                                isValid: valid,
                                icon: Icons.circle,
                                validColor: Colors.green,
                                validityText: "A lowercase",
                                notColor: Colors.red);
                          }),
                        ),

                      // Number
                      if (formatterValue?.hasLowerCase == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Builder(builder: (context) {
                            PasswordValid valid = PasswordValid.empty;
                            if (formatter.containsNumber(text ?? "")) {
                              valid = PasswordValid.valid;
                            } else if (text?.isNotEmpty == true) {
                              valid = PasswordValid.not_valid;
                            }
                            return PasswordStrengthIndicator(
                                isValid: valid,
                                icon: Icons.circle,
                                validColor: Colors.green,
                                validityText: "A number",
                                notColor: Colors.red);
                          }),
                        ),

                      // Special character
                      if (formatterValue?.hasLowerCase == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Builder(builder: (context) {
                            PasswordValid valid = PasswordValid.empty;
                            if (formatter
                                .containsSpecialCharacter(text ?? "")) {
                              valid = PasswordValid.valid;
                            } else if (text?.isNotEmpty == true) {
                              valid = PasswordValid.not_valid;
                            }
                            return PasswordStrengthIndicator(
                                isValid: valid,
                                icon: Icons.circle,
                                validColor: Colors.green,
                                validityText: "A special character",
                                notColor: Colors.red);
                          }),
                        ),
                    ],
                  ),
                ),
            ],
          );
        });
  }
}

class CustomEditTextFieldFormatOptions {
  final bool iEmail;
  final bool hasUpperCase;
  final bool hasLowerCase;
  final bool hasNumbers;
  final bool hasSpecialCharacter;
  final int hasLengthOf;

  CustomEditTextFieldFormatOptions(
      {this.iEmail = false,
      this.hasUpperCase = false,
      this.hasLowerCase = false,
      this.hasNumbers = false,
      this.hasSpecialCharacter = false,
      this.hasLengthOf = 8});
}

class CustomEditTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final double textSize;
  final double gap;
  final int? maxLength;
  final WidgetStateNotifier<String>? textNotifier;
  final int? minLine;
  final int? maxLine;
  final String? textTitle;
  final String? readOnlyText;
  final bool focusedOnStart;
  final Color suffixColor;
  final Color fillColor;
  final TextStyle textInputStyle;
  final TextStyle hintStyle;
  final TextStyle titleStyle;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;
  final bool useShadow;
  final ValueChanged<int>? onDropDownItemChange;
  final List<MapEntry<Widget, Function()>>? dropDownItems;

  const CustomEditTextField(
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
      this.minLine,
      this.maxLine,
      this.textNotifier,
      this.textInputStyle = const TextStyle(
        fontSize: 16,
        color: Colors.black,
        decoration: TextDecoration.none,
        decorationThickness: 0,
      ),
      this.hintStyle = const TextStyle(color: Colors.grey),
      this.suffixColor = Colors.black,
      this.fillColor = Colors.grey,
      this.titleStyle =
          const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)});

  @override
  CustomEditTextFieldState createState() => CustomEditTextFieldState();
}

class CustomEditTextFieldState extends State<CustomEditTextField> {
  bool getObscured = true;
  bool change = false;
  FocusNode focusNode = FocusNode();
  String? getReadOnly;
  int? currentDropDown;

  TextEditingController readOnlyTextController = TextEditingController();

  @override
  void initState() {
    getObscured = widget.obscureText;
    widget.controller.addListener(() {
      if (mounted) {
        widget.textNotifier?.sendNewState(widget.controller.text);
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
  void didUpdateWidget(covariant CustomEditTextField oldWidget) {
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
          style: widget.titleStyle
              .copyWith(color: widget.titleStyle.color ?? Colors.grey.shade200),
        ),

        // Text Field
        SizedBox(
          height: widget.gap,
        ),
        Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
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
          ),
          child: Row(
            children: [
              widget.dropDownItems != null && widget.dropDownItems!.isNotEmpty
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
                child: TextField(
                  readOnly: getReadOnly != null,
                  focusNode: focusNode,
                  minLines: widget.obscureText ? 1 : widget.minLine,
                  maxLines: widget.obscureText ? 1 : widget.maxLine,
                  textCapitalization: widget.capitalization,
                  maxLength: widget.maxLength,
                  keyboardType: widget.keyboardType,
                  controller: widget.readOnlyText == null
                      ? widget.controller
                      : readOnlyTextController,
                  obscureText: getObscured,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.transparent),
                        borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: Color(getMainPinkColor)),
                        borderRadius: BorderRadius.circular(10)),
                    suffixIcon: !change
                        ? widget.controller.text.isNotEmpty &&
                                getReadOnly == null
                            ? getTheEndIcon()
                            : null
                        : null,
                    suffixIconColor: widget.suffixColor,
                    hintText: widget.hintText,
                    hintStyle: widget.hintStyle.copyWith(
                        color: widget.hintStyle.color ?? Colors.grey.shade500),
                    fillColor: widget.fillColor == Colors.grey
                        ? Colors.grey.withOpacity(0.01)
                        : widget.fillColor,
                    filled: true,
                  ),
                  style:
                      widget.textInputStyle.copyWith(fontSize: widget.textSize),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
