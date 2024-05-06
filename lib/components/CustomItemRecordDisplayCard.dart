import 'package:flutter/material.dart';

class CustomItemRecordDisplayCard extends StatelessWidget {
  final double? openingStock;
  final double? closingStock;
  final double? damagedStock;
  final double? receivingStock;
  final String reportFor;
  final bool reportStatus;
  final Color containerColor;
  final double borderRadius;
  final double gap;
  final double space;
  final EdgeInsets padding;
  final TextStyle dateTextStyle;
  final TextStyle labelTextStyle;
  final TextStyle recordTextStyle;
  final Function()? onTapMenu;
  final Function()? onTapInfo;

  const CustomItemRecordDisplayCard(
      {super.key,
      this.openingStock,
      this.closingStock,
      this.damagedStock,
      this.receivingStock,
      required this.reportFor,
      required this.containerColor,
      this.borderRadius = 10,
      this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      this.gap = 16,
      this.space = 4,
      required this.dateTextStyle,
      required this.labelTextStyle,
      required this.recordTextStyle,
      required this.reportStatus,
      this.onTapMenu,
      this.onTapInfo});

  Widget recordView(String label, String? record, Widget? infoWidget) {
    return Expanded(
      child: Column(
        children: [
          // Label
          Text(
            label,
            style: labelTextStyle,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),

          //   Record
          SizedBox(
            height: space,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: space * 1.5),
            child: record != null
                ? Text(
                    record,
                    style: recordTextStyle,
                    textAlign: TextAlign.center,
                  )
                : Row(
                    children: [
                      const Text(""),
                      Expanded(
                          child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          infoWidget ?? const SizedBox(),
                        ],
                      )),
                      const Text("")
                    ],
                  ),
          )
        ],
      ),
    );
  }

  String getStatusText(bool status) {
    return status ? "Active" : "Closed";
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]),
            child: Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //   Date - Status
                  Row(
                    children: [
                      // Date
                      Text(reportFor, style: dateTextStyle),

                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(getStatusText(reportStatus),
                                style: TextStyle(
                                    color: reportStatus
                                        ? Colors.green
                                        : Colors.red)),
                            const SizedBox(
                              width: 4,
                            ),
                            GestureDetector(
                                onTap: onTapMenu,
                                child: Icon(
                                  Icons.more_vert,
                                  color: dateTextStyle.color,
                                ))
                          ],
                        ),
                      )
                    ],
                  ),

                  //   Records
                  SizedBox(
                    height: gap,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1st Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          //   Opening
                          recordView(
                              "Opening",
                              openingStock != null ? "$openingStock" : "-",
                              null),
                          const Expanded(child: SizedBox()),
                          recordView(
                              "Receiving",
                              receivingStock != null ? "$receivingStock" : "-",
                              null),
                        ],
                      ),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          //   Opening
                          recordView(
                              "Damaged",
                              damagedStock != null ? "$damagedStock" : "-",
                              null),
                          const Expanded(child: SizedBox()),
                          recordView(
                              "Closing",
                              // closingStock?."null",
                              closingStock != null
                                  ? closingStock.toString()
                                  : null,
                              GestureDetector(
                                  onTap: onTapInfo,
                                  child: const Icon(
                                    Icons.info,
                                    color: Colors.red,
                                  ))),
                        ],
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
