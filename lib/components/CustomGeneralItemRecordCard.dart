import 'package:flutter/material.dart';

import 'CustomWrappingLayout.dart';

class CustomGeneralItemRecordCard extends StatelessWidget {
  final TextStyle topTextStyle;
  final TextStyle topLabelStyle;
  final TextStyle bottomTextStyle;
  final TextStyle bottomLabelStyle;
  final double topTextGap;
  final double bottomTextGap;
  final double dividerWidth;
  final double borderRadius;
  final EdgeInsets padding;
  final Color dividerColor;
  final Color containerColor;
  final String? totalReceives;
  final String? totalSold;
  final String? recordSize;
  final String? inStock;
  final Function()? onTappedSoldInfo;
  final Function()? onTappedStockInfo;

  const CustomGeneralItemRecordCard(
      {super.key,
      required this.topTextStyle,
      required this.topLabelStyle,
      required this.bottomTextStyle,
      required this.bottomLabelStyle,
      this.dividerWidth = 1.5,
      this.borderRadius = 10,
      this.padding = const EdgeInsets.all(8.0),
      this.topTextGap = 8,
      this.bottomTextGap = 5,
      required this.dividerColor,
      required this.containerColor,
      this.totalReceives,
      this.totalSold,
      this.recordSize,
      this.inStock,
      this.onTappedSoldInfo,
      this.onTappedStockInfo});

  Widget getTheInfoWidget(Function()? onTappedInfo) {
    return GestureDetector(
        onTap: onTappedInfo,
        child: Icon(
          Icons.info,
          color: topTextStyle.color,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: containerColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(borderRadius)),
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
                            style: topLabelStyle,
                          ),

                          //   Value
                          SizedBox(
                            height: topTextGap,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              (totalReceives ?? '-').toString(),
                              textAlign: TextAlign.center,
                              style: topTextStyle,
                            ),
                          )
                        ],
                      )),

                  //   Divider

                  WLView(
                      crossDimension: WlDimension.match,
                      child: Container(
                        width: dividerWidth,
                        decoration: BoxDecoration(color: dividerColor),
                      )),

                  //   Total Sold
                  WLView(
                      expandMain: true,
                      child: Column(
                        children: [
                          //   Label
                          Text("Sold", style: topLabelStyle),

                          //   Value
                          SizedBox(
                            height: topTextGap,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: totalSold != null
                                ? Text(
                                    totalSold.toString(),
                                    style: topTextStyle,
                                    textAlign: TextAlign.center,
                                  )
                                : getTheInfoWidget(onTappedSoldInfo),
                          )
                        ],
                      )),
                ]),

            //   In Stock
            Row(
              children: [
                Expanded(
                    child: Divider(
                  thickness: dividerWidth,
                  color: dividerColor,
                )),
              ],
            ),

            CustomWrappingLayout(
                minHeight: 10,
                crossAxisAlignment: CrossAxisAlignment.start,
                wlChildren: [
                  // Start Quantity
                  WLView(
                    expandMain: true,
                    child: Column(
                      children: [
                        // Label
                        Text(
                          "Records",
                          style: bottomLabelStyle,
                        ),

                        //   Value
                        SizedBox(
                          height: bottomTextGap,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            (recordSize ?? '-').toString(),
                            style: bottomTextStyle,
                            textAlign: TextAlign.center,
                          ),
                        )
                      ],
                    ),
                  ),

                  //   Divider

                  WLView(
                      crossDimension: WlDimension.match,
                      child: Container(
                        width: dividerWidth,
                        decoration: BoxDecoration(color: dividerColor),
                      )),

                  //   In Stock
                  WLView(
                      expandMain: true,
                      child: Column(
                        children: [
                          //   Label
                          Text("In Stock", style: bottomLabelStyle),
                          SizedBox(
                            height: bottomTextGap,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: inStock != null
                                ? Text(
                                    inStock.toString(),
                                    textAlign: TextAlign.center,
                                    style: bottomTextStyle,
                                  )
                                : getTheInfoWidget(onTappedStockInfo),
                          )
                        ],
                      )),
                ]),
          ],
        ),
      ),
    );
  }
}
