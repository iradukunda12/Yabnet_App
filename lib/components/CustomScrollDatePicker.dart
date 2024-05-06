import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import 'WrappingSilverAppBar.dart';

class CustomScrollDatePicker extends StatefulWidget {
  final ValueChanged<DateTime> currentDate;
  final bool defaultDate;
  final bool quickDate;
  final double opacity;
  final double itemExtent;
  final bool useMagnifier;
  final double magnification;
  final double textSize;
  final double height;
  final Color backgroundColor;
  final Color textColor;
  final ScrollNotifier? notifier;

  const CustomScrollDatePicker(
      {super.key,
      required this.opacity,
      required this.itemExtent,
      this.useMagnifier = true,
      this.magnification = 1.5,
      this.textSize = 18,
      required this.backgroundColor,
      required this.textColor,
      required this.currentDate,
      this.defaultDate = true,
      this.height = 100.0,
      this.quickDate = true,
      this.notifier});

  // List of months
  static Map<String, int> months = {
    'JAN': 31,
    'FEB': 28,
    'MAR': 31,
    'APR': 30,
    'MAY': 31,
    'JUN': 30,
    'JUL': 31,
    'AUG': 31,
    'SEP': 30,
    'OCT': 31,
    'NOV': 30,
    'DEC': 31
  };

  // List of days
  static Map<int, String> days = {
    1: "Monday 🌞",
    2: "Tuesday 😊",
    3: "Wednesday 🤔",
    4: "Thursday 😎",
    5: "Friday 😄",
    6: "Saturday 😁",
    7: "Sunday 😇"
  };

  @override
  State<CustomScrollDatePicker> createState() => _CustomScrollDatePickerState();
}

class _CustomScrollDatePickerState extends State<CustomScrollDatePicker> {
  // Initialize the current date
  DateTime getCurrentDate = DateTime.now();
  late int currentDay;
  late int currentMonth;
  late int currentYear;
  bool? today = true;

  Timer? updateOpacityTimer;
  bool updateOpacity = false;

  // Scroll controllers for the pickers
  final FixedExtentScrollController monthScrollController =
      FixedExtentScrollController();
  final FixedExtentScrollController dayScrollController =
      FixedExtentScrollController();
  final FixedExtentScrollController yearScrollController =
      FixedExtentScrollController();

  // Generate a list of years from 1900 to the current year
  List<int> generateYears() {
    int currentYear = DateTime.now().year + 1;
    return List<int>.generate(currentYear - 1900, (index) => 1900 + index);
  }

  bool isLeapYear(int givenYear) {
    return (givenYear % 4 == 0 && givenYear % 100 != 0) || givenYear % 400 == 0;
  }

  int generateTheDaysNumber(int givenMonth, int givenYear) {
    int daysInMonth;

    // Array to store the number of days in each month
    List<int> daysPerMonth = CustomScrollDatePicker.months.values.toList();

    // Check if the current year is a leap year
    if (isLeapYear(givenYear)) {
      // February has 29 days in a leap year
      daysPerMonth[1] = 29;
    }

    // Check if the current month is within a valid range
    if (givenMonth >= 1 && givenMonth <= 12) {
      // Subtract 1 from the current month to access the correct index in the array
      daysInMonth = daysPerMonth[givenMonth - 1];
    } else {
      // Invalid month, return 0 or handle the error accordingly
      daysInMonth = 0;
    }

    return daysInMonth;
  }

  void sendTheCurrentDate() {
    DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
    DateTime now = DateTime.now();

    setState(() {
      if (getCurrentDate.day == yesterday.day &&
          getCurrentDate.month == yesterday.month &&
          getCurrentDate.year == yesterday.year) {
        today = false;
      } else if (getCurrentDate.day == now.day &&
          getCurrentDate.month == now.month &&
          getCurrentDate.year == now.year) {
        today = true;
      } else {
        today = null;
      }
    });

    widget.currentDate(getCurrentDate);
  }

  void snapScrollController(FixedExtentScrollController controller, int item) {
    controller.jumpToItem(item);
  }

  @override
  void initState() {
    super.initState();
    currentDay = getCurrentDate.day;
    currentMonth = getCurrentDate.month;
    currentYear = getCurrentDate.year;

    if (widget.defaultDate) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        // Set the initial values of the scroll controllers
        setState(() {
          today = true;
        });
        monthScrollController.jumpToItem(getCurrentDate.month - 1);
        dayScrollController.jumpToItem(getCurrentDate.day - 1);
        yearScrollController.jumpToItem(getCurrentDate.year - 1900);

        updateOpacityTimer ??= Timer.periodic(Duration.zero, (timer) {
          setState(() {
            updateOpacity = false;
            updateOpacity = true;
          });
        });
      });
    } else {
      setState(() {
        today = false;
      });
    }
  }

  @override
  void dispose() {
    // Dispose the scroll controllers
    monthScrollController.dispose();
    dayScrollController.dispose();
    yearScrollController.dispose();
    updateOpacityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: updateOpacity
          ? widget.notifier == null
              ? 1
              : widget.notifier?.opacity ?? 1
          : 1,
      child: Container(
        decoration: BoxDecoration(color: widget.backgroundColor),
        child: Padding(
          padding:
              const EdgeInsets.only(left: 32, top: 32, right: 32, bottom: 16),
          child: IgnorePointer(
            ignoring:
                updateOpacity ? (widget.notifier?.opacity ?? 1) != 1 : false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date Scrolls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Day picker
                    Expanded(
                      child: SizedBox(
                        height: widget.height,
                        child: Listener(
                          onPointerUp: (PointerUpEvent pointerUpEvent) {
                            snapScrollController(
                                dayScrollController, currentDay - 1);
                          },
                          child: ListWheelScrollView(
                            controller: dayScrollController,
                            useMagnifier: widget.useMagnifier,
                            magnification: widget.magnification,
                            itemExtent: widget.itemExtent,
                            overAndUnderCenterOpacity: widget.opacity,
                            children: List<Widget>.generate(
                                generateTheDaysNumber(
                                    currentMonth, currentYear), (index) {
                              return Center(
                                  child: Text((index + 1).toString(),
                                      style: TextStyle(
                                          color: widget.textColor,
                                          fontSize: widget.textSize)));
                            }),
                            onSelectedItemChanged: (index) {
                              setState(() {
                                currentDay = index + 1;
                                getCurrentDate = DateTime(getCurrentDate.year,
                                    getCurrentDate.month, currentDay);
                              });
                              sendTheCurrentDate();
                            },
                          ),
                        ),
                      ),
                    ),

                    // Month picker
                    Expanded(
                      child: SizedBox(
                        height: widget.height,
                        child: Listener(
                          onPointerUp: (PointerUpEvent pointerUpEvent) {
                            snapScrollController(
                                monthScrollController, currentMonth - 1);
                          },
                          child: ListWheelScrollView(
                            controller: monthScrollController,
                            useMagnifier: widget.useMagnifier,
                            magnification: widget.magnification,
                            itemExtent: widget.itemExtent,
                            overAndUnderCenterOpacity: widget.opacity,
                            children: CustomScrollDatePicker.months.keys
                                .map((String monthName) => Center(
                                      child: Text(monthName,
                                          style: TextStyle(
                                              color: widget.textColor,
                                              fontSize: widget.textSize)),
                                    ))
                                .toList(),
                            onSelectedItemChanged: (index) {
                              setState(() {
                                currentMonth = index + 1;
                                getCurrentDate = DateTime(getCurrentDate.year,
                                    currentMonth, getCurrentDate.day);
                              });
                              sendTheCurrentDate();
                            },
                          ),
                        ),
                      ),
                    ),

                    // Year picker
                    Expanded(
                      child: SizedBox(
                        height: widget.height,
                        child: Listener(
                          onPointerUp: (PointerUpEvent pointerUpEvent) {
                            snapScrollController(
                                yearScrollController, currentYear - 1900);
                          },
                          child: ListWheelScrollView(
                            controller: yearScrollController,
                            useMagnifier: widget.useMagnifier,
                            magnification: widget.magnification,
                            itemExtent: widget.itemExtent,
                            overAndUnderCenterOpacity: widget.opacity,
                            children: generateYears().map((year) {
                              return Center(
                                  child: Text(year.toString(),
                                      style: TextStyle(
                                          color: widget.textColor,
                                          fontSize: widget.textSize)));
                            }).toList(),
                            onSelectedItemChanged: (index) {
                              setState(() {
                                currentYear = generateYears()[index];
                                getCurrentDate = DateTime(currentYear,
                                    getCurrentDate.month, getCurrentDate.day);
                              });
                              sendTheCurrentDate();
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                //  Quick Date
                widget.quickDate
                    ? const SizedBox(height: 32)
                    : const SizedBox(),
                widget.quickDate
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Quick Yesterday
                          GestureDetector(
                            onTap: () {
                              DateTime now = DateTime.now();
                              DateTime yesterday =
                                  DateTime(now.year, now.month, now.day)
                                      .subtract(const Duration(days: 1));
                              setState(() {
                                today = false;
                                List<int> daysPerMonth = CustomScrollDatePicker
                                    .months.values
                                    .toList();
                                getCurrentDate = yesterday;
                                currentMonth = getCurrentDate.month;
                                currentYear = getCurrentDate.year;
                                monthScrollController
                                    .jumpToItem(getCurrentDate.month - 1);
                                dayScrollController.jumpToItem(
                                    daysPerMonth[getCurrentDate.month - 1] <=
                                            daysPerMonth[now.month - 1]
                                        ? getCurrentDate.day - 1
                                        : getCurrentDate.day);
                                yearScrollController
                                    .jumpToItem(getCurrentDate.year - 1900);
                              });
                            },
                            child: Text(
                              'Yesterday',
                              style: TextStyle(
                                color: today == false
                                    ? widget.textColor
                                    : const Color(getGreyTextColor)
                                        .withOpacity(widget.opacity),
                                fontSize: widget.textSize * 0.8,
                              ),
                            ),
                          ),

                          //  Quick Today
                          const SizedBox(
                            width: 16,
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                today = true;
                                getCurrentDate = DateTime.now();
                                currentMonth = getCurrentDate.month;
                                currentYear = getCurrentDate.year;
                                monthScrollController
                                    .jumpToItem(getCurrentDate.month - 1);
                                dayScrollController
                                    .jumpToItem(getCurrentDate.day - 1);
                                yearScrollController
                                    .jumpToItem(getCurrentDate.year - 1900);
                              });
                            },
                            child: Text(
                              'Today',
                              style: TextStyle(
                                color: today == true
                                    ? widget.textColor
                                    : const Color(getGreyTextColor)
                                        .withOpacity(widget.opacity),
                                fontSize: widget.textSize * 0.8,
                              ),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomDateViewerAppBar extends StatefulWidget {
  final bool display;
  final bool snap;
  final double viewerHeight;
  final DateTime displayDate;
  final DateFormat dateFormatter;
  final Color backgroundColor;
  final Decoration? decoration;
  final TextStyle textStyle;
  final double padding;
  final MainAxisAlignment mainAxisAlignment;
  final double snapFraction;
  final ScrollNotifier notifier;

  const CustomDateViewerAppBar(
      {Key? key,
      required this.displayDate,
      this.display = false,
      required this.viewerHeight,
      required this.backgroundColor,
      this.textStyle = const TextStyle(fontSize: 18, color: Colors.white),
      required this.notifier,
      this.snapFraction = 0.1,
      this.snap = false,
      this.decoration,
      required this.dateFormatter,
      this.padding = 8.0,
      this.mainAxisAlignment = MainAxisAlignment.center})
      : super(key: key);

  @override
  State<CustomDateViewerAppBar> createState() => CustomDateViewerAppBarState();
}

class CustomDateViewerAppBarState extends State<CustomDateViewerAppBar> {
  Timer? updateHeightTimer;
  bool updateHeight = false;
  Key containerKey = GlobalKey();

  @override
  void dispose() {
    updateHeightTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      updateHeightTimer ??= Timer.periodic(Duration.zero, (timer) {
        setState(() {
          updateHeight = false;
          updateHeight = true;
        });
      });
    });
  }

  double expandHeightFromNotifier(double scrollNotifier) {
    double snapStart = widget.viewerHeight * widget.snapFraction;
    double snapEnd = widget.viewerHeight * (1 - widget.snapFraction);

    double currentHeight = 0;

    if (widget.snap) {
      // Snap
      if (scrollNotifier >= 0 &&
          scrollNotifier > currentHeight &&
          scrollNotifier <= widget.viewerHeight) {
        if (scrollNotifier >= snapEnd) {
          currentHeight = widget.viewerHeight;
        } else {
          currentHeight = scrollNotifier;
        }
      } else if (scrollNotifier >= 0 &&
          scrollNotifier < currentHeight &&
          scrollNotifier <= widget.viewerHeight) {
        if (scrollNotifier <= snapStart) {
          currentHeight = 0.0;
        } else {
          currentHeight = scrollNotifier;
        }
      } else if (scrollNotifier > widget.viewerHeight) {
        currentHeight = widget.viewerHeight;
      }
    } else {
      // No snap
      if (scrollNotifier > 0 && scrollNotifier <= widget.viewerHeight) {
        currentHeight = scrollNotifier;
      } else if (scrollNotifier > widget.viewerHeight) {
        currentHeight = widget.viewerHeight;
      }
    }

    widget.notifier.opacityChange(widget.viewerHeight);
    return currentHeight;
  }

  String formatDateTime(DateTime dateTime) {
    return widget.dateFormatter.format(dateTime).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
              child: Container(
            key: containerKey,
            decoration: widget.decoration,
            height: widget.viewerHeight,
            child: Row(
              mainAxisAlignment: widget.mainAxisAlignment,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: widget.padding),
                  child: Opacity(
                    opacity: updateHeight ? 1 - widget.notifier.opacity : 1,
                    child: Text(
                      formatDateTime(widget.displayDate),
                      maxLines: 1,
                      style: widget.textStyle,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
      centerTitle: true,
      pinned: true,
      titleSpacing: 0,
      backgroundColor: widget.decoration != null
          ? (widget.decoration as BoxDecoration).color
          : null,
      toolbarHeight: updateHeight
          ? !widget.display /* if set to display is false */
              ? expandHeightFromNotifier(
                  widget.notifier.scrollCovered) /* expand respect to scroll */
              : widget.viewerHeight /* default display height */
          : 0, /* reset height for update */
    );
  }
}
