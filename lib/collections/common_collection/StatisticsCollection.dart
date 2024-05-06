import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:yabnet/builders/CustomWrapListBuilder.dart';
import "package:yabnet/main.dart";

class StatisticsCollection extends StatefulWidget {
  const StatisticsCollection({super.key});

  @override
  State<StatisticsCollection> createState() => _StatisticsCollectionState();
}

class _StatisticsCollectionState extends State<StatisticsCollection> {
  PageController pageController = PageController();

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                  child: Text("Statistics",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        SizedBox(
          height: 8,
        ),
        Container(
          height: 300,
          child: PageView(
            controller: pageController,
            children: [
              pieChartWidget(),
              barChart1(),
              barChart2(),
            ],
          ),
        ),
        SizedBox(
          height: 8,
        ),
        SmoothPageIndicator(
          controller: pageController,
          count: 3,
          effect: WormEffect(
              dotHeight: 10,
              dotWidth: 10,
              activeDotColor: Color(getMainPinkColor)),
        ),
        SizedBox(
          height: 8,
        ),
      ],
    );
  }
}

Widget barChart2() {
  final dataMap = <String, double>{
    "Kigali": 54,
    "Lagos": 154,
    "Zambia": 500,
  };

  double total = dataMap.entries.fold(
      0, (previousValue, element) => (previousValue ?? 0) + element.value);
  final colorList = <Color>[
    Color(getMainPinkColor).withOpacity(0.7),
    Color(getMainOrangeColor),
  ];
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Container(
      height: 300,
      padding: EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Location",
            style: TextStyle(color: Colors.grey.shade800, fontSize: 15),
          ),
          CustomWrapListBuilder(
              itemCount: 6,
              wrapListBuilder: (context, index) {
                String label =
                    dataMap.entries.toList().elementAtOrNull(5 - index)?.key ??
                        '';
                double value = dataMap.entries
                        .toList()
                        .elementAtOrNull(5 - index)
                        ?.value ??
                    0;
                String percentage = label.isNotEmpty
                    ? "${(value / total * 100).toStringAsFixed(1)}%"
                    : '';
                return Padding(
                  padding: EdgeInsets.only(
                      top: (index == 0) ? 0 : 8.0,
                      bottom: (index + 1) == dataMap.entries.length ? 8 : 0),
                  child: barWidget(
                      25,
                      100,
                      1,
                      value / total,
                      label.isNotEmpty
                          ? Colors.grey.shade600
                          : Colors.transparent,
                      colorList.elementAtOrNull(5 - index) ??
                          Color(getMainPinkColor).withOpacity(0.2),
                      5,
                      label,
                      percentage,
                      TextStyle(color: Colors.grey.shade900, fontSize: 14),
                      12),
                );
              }),
        ],
      ),
    ),
  );
}

Widget barChart1() {
  final dataMap = <String, double>{
    "18-24": 54,
    "25-34": 34,
    "35-44": 25,
    "45-54": 8,
    "55-64": 3,
    "  65+": 5,
  };

  double total = dataMap.entries.fold(
      0, (previousValue, element) => (previousValue ?? 0) + element.value);
  final colorList = <Color>[
    Color(getMainPinkColor).withOpacity(0.7),
    Color(getMainOrangeColor),
  ];
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Container(
      height: 300,
      padding: EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.topCenter,
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Ages",
            style: TextStyle(color: Colors.grey.shade800, fontSize: 15),
          ),
          SizedBox(
            height: 4,
          ),
          CustomWrapListBuilder(
              itemCount: dataMap.length,
              wrapListBuilder: (context, index) {
                String label = dataMap.entries.toList()[index].key;
                double value = dataMap.entries.toList()[index].value;
                String percentage = (value / total * 100).toStringAsFixed(1);
                return Padding(
                  padding: EdgeInsets.only(
                      top: (index == 0) ? 0 : 8.0,
                      bottom: (index + 1) == dataMap.entries.length ? 8 : 0),
                  child: barWidget(
                      25,
                      100,
                      1,
                      value / total,
                      Colors.grey.shade600,
                      colorList.elementAtOrNull(index) ??
                          Color(getMainPinkColor).withOpacity(0.2),
                      5,
                      label,
                      "${percentage}%",
                      TextStyle(color: Colors.grey.shade900, fontSize: 14),
                      12),
                );
              }),
        ],
      ),
    ),
  );
}

Widget barWidget(
    double height,
    double width,
    double heightF,
    double widthF,
    Color backColor,
    Color colorF,
    double borderRadius,
    String labelText,
    String percentageText,
    TextStyle textStyle,
    double spacing,
    {bool fromLeft = true}) {
  return Row(
    children: [
      Expanded(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              labelText,
              style: textStyle,
            ),
          ],
        ),
      ),
      SizedBox(
        width: spacing,
      ),
      Expanded(
        child: Stack(
          children: [
            Container(
              height: height,
              width: width,
              decoration: BoxDecoration(
                  color: backColor,
                  borderRadius: BorderRadius.circular(borderRadius)),
            ),
            Container(
              height: heightF >= 1
                  ? height
                  : heightF < 0
                      ? 0
                      : (height * heightF),
              width: widthF >= 1
                  ? width
                  : widthF < 0
                      ? 0
                      : (width * widthF),
              decoration: BoxDecoration(
                color: colorF,
                borderRadius: BorderRadius.only(
                  topLeft: fromLeft
                      ? Radius.circular(borderRadius)
                      : Radius.circular(0),
                  bottomLeft: fromLeft
                      ? Radius.circular(borderRadius)
                      : Radius.circular(0),
                  topRight: fromLeft
                      ? Radius.circular(0)
                      : Radius.circular(borderRadius),
                  bottomRight: fromLeft
                      ? Radius.circular(0)
                      : Radius.circular(borderRadius),
                ),
              ),
            )
          ],
        ),
      ),
      SizedBox(
        width: spacing,
      ),
      Expanded(
        child: Row(
          children: [
            Text(
              percentageText,
              style: textStyle,
            ),
          ],
        ),
      )
    ],
  );
}

Widget pieChartWidget() {
  final dataMap = <String, double>{
    "Flutter": 5.3,
    "C++": 14.7,
  };
  final colorList = <Color>[
    Color(getMainPinkColor).withOpacity(0.1),
    Color(getMainPinkColor),
  ];
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Container(
      height: 300,
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Gender",
            style: TextStyle(color: Colors.grey.shade800, fontSize: 15),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: PieChart(
              dataMap: dataMap,
              chartRadius: 150,
              chartType: ChartType.disc,
              baseChartColor: Colors.white,
              colorList: colorList,
              legendOptions: LegendOptions(showLegends: false),
              chartValuesOptions: ChartValuesOptions(
                  showChartValuesInPercentage: true, showChartValues: false),
              totalValue: dataMap.entries.fold(
                  0,
                  (previousValue, element) =>
                      (previousValue ?? 0) + element.value),
            ),
          ),
          SizedBox(
            height: 24,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              getLegendWidget(
                  "${(14.7 / 20 * 100).toStringAsFixed(1)}%",
                  TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                  Color(getMainPinkColor),
                  "Women",
                  TextStyle(color: Colors.grey.shade800, fontSize: 13)),
              getLegendWidget(
                  "${(5.3 / 20 * 100).toStringAsFixed(1)}%",
                  TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                  Color(getMainPinkColor).withOpacity(0.1),
                  "Men",
                  TextStyle(color: Colors.grey.shade800, fontSize: 13)),
            ],
          )
        ],
      ),
    ),
  );
}

Widget getLegendWidget(String perText, TextStyle perTextStyle,
    Color indicatorColor, String labelText, TextStyle labelTextStyle) {
  return Column(
    children: [
      Text(
        perText,
        style: perTextStyle,
      ),
      Row(
        children: [
          Container(
            height: 10,
            width: 10,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: indicatorColor),
          ),
          SizedBox(
            width: 4,
          ),
          Text(
            labelText,
            style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
          )
        ],
      )
    ],
  );
}
