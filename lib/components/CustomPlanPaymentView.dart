import 'package:flutter/material.dart';
import 'package:yabnet/components/CustomOnClickContainer.dart';

class CustomPlanPaymentView extends StatefulWidget {
  final bool selected;
  final Color color;
  final Color borderColor;
  final Color backgroundColor;
  final String text;
  final String currency;
  final String title;
  final int period;
  final double price;
  final TextStyle buttonStyle;
  final TextStyle titleStyle;
  final TextStyle subMainTitleStyle;
  final TextStyle subTitleStyle;
  final TextStyle bottomStyle;
  final Function() onSelect;
  final Function() onTap;

  const CustomPlanPaymentView(
      {super.key,
      required this.selected,
      required this.color,
      required this.borderColor,
      required this.currency,
      required this.titleStyle,
      required this.title,
      required this.period,
      required this.price,
      required this.subTitleStyle,
      required this.bottomStyle,
      required this.buttonStyle,
      required this.onSelect,
      required this.backgroundColor,
      required this.subMainTitleStyle,
      required this.onTap,
      required this.text});

  @override
  State<CustomPlanPaymentView> createState() => _CustomPlanPaymentViewState();
}

class _CustomPlanPaymentViewState extends State<CustomPlanPaymentView> {
  @override
  Widget build(BuildContext context) {
    return CustomOnClickContainer(
      defaultColor: widget.backgroundColor,
      clickedColor: Colors.grey.shade200,
      border: Border.all(color: widget.selected ? widget.color : Colors.grey),
      borderRadius: BorderRadius.circular(16),
      onTap: widget.onSelect,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //   Selection
                  Container(
                    height: 16,
                    width: 16,
                    decoration: BoxDecoration(
                        color:
                            widget.selected ? widget.color : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(color: widget.borderColor)),
                  ),

                  SizedBox(
                    height: 16,
                  ),

                  Text(
                    widget.title,
                    style: widget.titleStyle,
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  Row(
                    children: [
                      Text(
                        "${widget.currency}${widget.price.toStringAsFixed(0)}",
                        style: widget.subMainTitleStyle,
                      ),
                      Text(
                        "/${widget.period} ${(widget.period > 1) ? 'months' : 'month'}",
                        style: widget.subTitleStyle,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Terms and condition",
                        style: widget.bottomStyle,
                      ),
                      CustomOnClickContainer(
                          onTap: widget.selected ? widget.onTap : null,
                          defaultColor: widget.selected
                              ? widget.color
                              : Colors.transparent,
                          clickedColor: widget.selected
                              ? widget.color.withOpacity(0.6)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: widget.selected
                                  ? Colors.transparent
                                  : widget.borderColor),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              widget.text,
                              style: widget.buttonStyle,
                            ),
                          ))
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
