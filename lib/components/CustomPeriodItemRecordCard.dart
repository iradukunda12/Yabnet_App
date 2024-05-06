import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'CustomWrappingLayout.dart';

class CustomPeriodItemRecordCard extends StatefulWidget {
  final TextStyle topTextStyle;
  final TextStyle topLabelStyle;
  final TextStyle dateLabelStyle;
  final TextStyle dateTextStyle;
  final double topTextGap;
  final double dividerWidth;
  final double borderRadius;
  final EdgeInsets padding;
  final Color dividerColor;
  final Color containerColor;
  final Color iconColor;
  final double? totalReceives;
  final double? totalSold;
  final TextEditingController fromTextEditingController;
  final TextEditingController toTextEditingController;
  final Function(TextEditingController textEditingController) onDateClicked;
  final Function() sendDateRequest;

  const CustomPeriodItemRecordCard(
      {super.key,
      required this.topTextStyle,
      required this.topLabelStyle,
      this.dividerWidth = 1.5,
      this.borderRadius = 10,
      this.padding = const EdgeInsets.all(8.0),
      this.topTextGap = 8,
      required this.dividerColor,
      required this.containerColor,
      this.totalReceives,
      this.totalSold,
      required this.dateLabelStyle,
      required this.dateTextStyle,
      required this.onDateClicked,
      required this.fromTextEditingController,
      required this.toTextEditingController,
      required this.sendDateRequest,
      required this.iconColor});

  @override
  State<CustomPeriodItemRecordCard> createState() =>
      _CustomPeriodItemRecordCardState();
}

class _CustomPeriodItemRecordCardState
    extends State<CustomPeriodItemRecordCard> {
  DateTime? fromDate;
  DateTime? toDate;

  @override
  void initState() {
    super.initState();

    //   From

    widget.fromTextEditingController.addListener(() {
      DateTime from =
          DateTime.parse(widget.fromTextEditingController.text.trim());

      setState(() {
        fromDate = from;
      });
    });

    //   To

    widget.toTextEditingController.addListener(() {
      DateTime to = DateTime.parse(widget.toTextEditingController.text.trim());

      setState(() {
        toDate = to;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Record
        Container(
          decoration: BoxDecoration(
              color: widget.containerColor,
              borderRadius: BorderRadius.circular(widget.borderRadius)),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Receives -> Sold
                CustomWrappingLayout(
                    minHeight: 10,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    wlChildren: [
                      // Total Receives
                      WLView(
                          expandMain: true,
                          child: Column(
                            children: [
                              //   Label
                              Text(
                                "Receives",
                                textAlign: TextAlign.center,
                                style: widget.topLabelStyle,
                              ),

                              //   Value
                              SizedBox(
                                height: widget.topTextGap,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  (widget.totalReceives ?? '-').toString(),
                                  textAlign: TextAlign.center,
                                  style: widget.topTextStyle,
                                ),
                              )
                            ],
                          )),

                      //   Divider

                      WLView(
                          crossDimension: WlDimension.match,
                          child: Container(
                            width: widget.dividerWidth,
                            decoration:
                                BoxDecoration(color: widget.dividerColor),
                          )),

                      //   Total Sold
                      WLView(
                          expandMain: true,
                          child: Column(
                            children: [
                              //   Label
                              Text("Sold", style: widget.topLabelStyle),

                              //   Value
                              SizedBox(
                                height: widget.topTextGap,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  (widget.totalSold ?? '-').toString(),
                                  style: widget.topTextStyle,
                                  textAlign: TextAlign.center,
                                ),
                              )
                            ],
                          )),
                    ]),
              ],
            ),
          ),
        ),

        //   Controls
        const SizedBox(
          height: 8,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // From
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //   Label
                  Text("From", style: widget.dateLabelStyle),

                  // Date Text
                  const SizedBox(
                    height: 8,
                  ),
                  dateText(fromDate, widget.fromTextEditingController)
                ],
              ),
            ),
            // To
            const SizedBox(
              width: 5,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //   Label
                  Text(
                    "To",
                    style: widget.dateLabelStyle,
                  ),

                  // Date Text
                  const SizedBox(
                    height: 8,
                  ),
                  dateText(toDate, widget.toTextEditingController)
                ],
              ),
            ),

            GestureDetector(
              onTap: toDate != null && fromDate != null
                  ? widget.sendDateRequest
                  : null,
              child: Icon(
                Icons.arrow_circle_right,
                size: (widget.dateTextStyle.fontSize ?? 0) * 2.3,
                color: toDate != null && fromDate != null
                    ? widget.iconColor
                    : null,
              ),
            )
          ],
        )
      ],
    );
  }

  Widget dateText(DateTime? date, TextEditingController textEditingController) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              widget.onDateClicked(textEditingController);
            },
            child: Container(
              decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.dateLabelStyle.color ?? Colors.transparent,
                  ),
                  borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  date != null
                      ? DateFormat("yyyy-MM-dd").format(date)
                      : "yyyy-mm-dd",
                  style: widget.dateTextStyle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
