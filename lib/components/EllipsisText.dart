import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:widget_state_notifier/widget_state_notifier.dart';
import 'package:yabnet/components/CustomProject.dart';

class EllipsisText extends StatefulWidget {
  final String text;
  final String moreText;
  final String lessText;
  final int maxLength;
  final TextStyle textStyle;
  final TextAlign textAlign;
  final VoidCallback? onMorePressed;
  final VoidCallback? onLessPressed;

  EllipsisText({
    required this.text,
    required this.maxLength,
    this.onMorePressed,
    required this.textStyle,
    this.textAlign = TextAlign.start,
    this.moreText = "more",
    this.lessText = "less",
    this.onLessPressed,
  });

  @override
  State<EllipsisText> createState() => _EllipsisTextState();
}

class _EllipsisTextState extends State<EllipsisText> {
  WidgetStateNotifier<int> _maxLengthNotifier = WidgetStateNotifier();
  late TapGestureRecognizer _moreTapGesture;
  late TapGestureRecognizer _lessTapGesture;

  @override
  void initState() {
    super.initState();
    _maxLengthNotifier.sendNewState(widget.maxLength);
    _moreTapGesture = TapGestureRecognizer()
      ..onTap = acceptMoreGestureTapGestureRecognizer;
    _lessTapGesture = TapGestureRecognizer()
      ..onTap = acceptLessGestureTapGestureRecognizer;
  }

  void acceptMoreGestureTapGestureRecognizer() {
    widget.onMorePressed?.call();
    morePressed();
  }

  void acceptLessGestureTapGestureRecognizer() {
    widget.onLessPressed?.call();
    lessPressed();
  }

  String getText(String text, int maxLength) {
    if ((maxLength - (widget.moreText.length + 4)) > text.length ||
        maxLength >= text.length) {
      return text;
    }
    return text.substring(0, maxLength - (widget.moreText.length + 4));
  }

  void morePressed() {
    int textLength = widget.text.length;
    int displayTextLength =
        getText(widget.text, _maxLengthNotifier.currentValue ?? 0).length;
    int nextMaxLength =
        (_maxLengthNotifier.currentValue ?? 0) + widget.maxLength;

    if (displayTextLength < textLength) {
      _maxLengthNotifier.sendNewState(
          (_maxLengthNotifier.currentValue ?? 0) + widget.maxLength);
    }
  }

  void lessPressed() {
    int currentMaxLength = _maxLengthNotifier.currentValue ?? widget.maxLength;

    if (currentMaxLength > widget.maxLength) {
      _maxLengthNotifier.sendNewState(currentMaxLength - widget.maxLength);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WidgetStateConsumer(
        widgetStateNotifier: _maxLengthNotifier,
        widgetStateBuilder: (context, data) {
          int maxLength = (data ?? widget.maxLength);
          String displayText = getText(widget.text, maxLength);

          bool more =
              (widget.text.length - (widget.moreText.length + 4)) > maxLength;

          bool less = (displayText.length > widget.maxLength ||
                  displayText.length == widget.text.length) &&
              widget.text.length > widget.maxLength;
          return Row(
            children: [
              Expanded(
                child: RichText(
                  textAlign: widget.textAlign,
                  text: TextSpan(
                    style: widget.textStyle,
                    children: <TextSpan>[
                      LinkifySpan(
                          onOpen: (link) async {
                            try {
                              Uri linkUrl = Uri.parse(link.url);
                              if (await canLaunchUrl(linkUrl)) {
                                await launchUrl(linkUrl);
                              } else {
                                showToastMobile(msg: "An error occurred");
                              }
                            } catch (e) {
                              showToastMobile(msg: "An error occurred");
                            }
                          },
                          linkStyle: TextStyle(color: Colors.blueAccent),
                          text: displayText),

                      // Less
                      if (less
                          // && !more
                          )
                        TextSpan(
                          text: '... ',
                          style: widget.textStyle,
                        ),
                      if (less
                          // && !more
                          )
                        TextSpan(
                          text: widget.lessText,
                          style: widget.textStyle.copyWith(color: Colors.blue),
                          recognizer: _lessTapGesture,
                        ),

                      // More
                      if (more)
                        TextSpan(
                          text: '... ',
                          style: widget.textStyle,
                        ),
                      if (more)
                        TextSpan(
                          text: widget.moreText,
                          style: widget.textStyle.copyWith(color: Colors.blue),
                          recognizer: _moreTapGesture,
                        ),
                    ],
                  ),
                  // overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        });
  }
}
