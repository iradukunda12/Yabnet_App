import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'CustomProject.dart';
import 'SizeReportingWidget.dart';

class CustomTabBarController extends ChangeNotifier {
  int? toIndex;

  void jumpToIndex(int index) {
    toIndex = index;
    notifyListeners();
  }
}

// class SlidingTabIndicator extends StatelessWidget {
//   final int numTabs;
//   final int currentIndex;
//   final double width;
//
//   const SlidingTabIndicator({super.key, required this.numTabs, required this.currentIndex, required this.width});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 2.0,
//       child: Stack(
//         children: [
//           Row(
//             children: List.generate(
//               numTabs,
//                   (index) => Expanded(
//                 child: Container(
//                   color: currentIndex == index ? Colors.blue : Colors.transparent,
//                 ),
//               ),
//             ),
//           ),
//           AnimatedPositioned(
//             left: width * currentIndex,
//             duration: const Duration(milliseconds: 300),
//             child: Container(
//               width: width,
//               height: 2.0,
//               color: Colors.blue,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

class SlidingTabIndicator extends StatelessWidget {
  final int numTabs;
  final int currentIndex;
  final double width;
  final double padding;
  final double spacing;

  const SlidingTabIndicator({
    Key? key,
    required this.numTabs,
    required this.currentIndex,
    required this.width,
    required this.padding,
    required this.spacing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2.0,
      child: Stack(
        children: [
          // Row(
          //   children: List.generate(
          //     numTabs,
          //         (index) => Expanded(
          //       child: Container(
          //         color: currentIndex == index ? Colors.red : Colors.transparent,
          //       ),
          //     ),
          //   ),
          // ),
          AnimatedPositioned(
            left: (width + 0) * currentIndex + 0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: width,
              height: 2.0,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

class CustomTabBar extends StatefulWidget {
  final ValueChanged<int> currentItem;
  final CustomTabBarController? tabBarController;
  final int startingIndex;
  final bool useIcon;
  final bool useBottomDivider;
  final bool isScrollable;
  final EdgeInsets padding;
  final Color? tabActiveColor;
  final Color tabNormalColor;
  final Color tabBackground;
  final double textSize;
  final FontWeight textWeight;
  final bool boldUnSelected;
  final bool boldSelected;
  final double tabItemPadding;
  final double bottomDividerHeight;
  final Color bottomDividerColor;
  final BorderRadiusGeometry borderRadius;
  final bool directAncestorUseController;
  final Duration toAncestor;
  final Curve curve;
  final double offsetAddon;
  final List<TabItem> tabItems;

  const CustomTabBar(
      {super.key,
      this.startingIndex = 0,
      this.useIcon = false,
      required this.tabItems,
      required this.tabActiveColor,
      required this.tabNormalColor,
      this.textSize = 16.0,
      this.textWeight = FontWeight.bold,
      this.borderRadius = BorderRadius.zero,
      this.tabItemPadding = 5.0,
      required this.padding,
      this.toAncestor = const Duration(milliseconds: 400),
      this.curve = Curves.linear,
      this.useBottomDivider = true,
      this.bottomDividerHeight = 2.0,
      this.directAncestorUseController = false,
      this.bottomDividerColor = Colors.transparent,
      required this.currentItem,
      this.boldUnSelected = false,
      this.boldSelected = true,
      this.tabBarController,
      this.offsetAddon = 19,
      this.isScrollable = false,
      this.tabBackground = Colors.transparent});

  @override
  State<CustomTabBar> createState() => _CustomTabBarState();
}

class _CustomTabBarState extends State<CustomTabBar>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  int currentlySelected = 0;
  ScrollController controller = ScrollController();
  GlobalKey containerKey = GlobalKey();
  List<Size> childrenSizes = [];
  Size parentSize = const Size(0, 0);
  var leftOverScroll = 0.0;
  var rightOverScroll = 0.0;
  PageController? ancestorPageController;
  late AnimationController _indicatorController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    childrenSizes = widget.tabItems.map((e) => const Size(0, 0)).toList();
    ancestorPageController =
        context.findAncestorWidgetOfExactType<PageView>()?.controller;

    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        currentlySelected = (widget.tabItems.length) > widget.startingIndex ||
                widget.startingIndex >= 0
            ? widget.startingIndex
            : 0;
      });
      widget.currentItem(currentlySelected);
    });

    widget.tabBarController?.addListener(() {
      int? toIndex = widget.tabBarController?.toIndex;

      if (toIndex != null && toIndex != currentlySelected) {
        setState(() {
          currentlySelected = toIndex;
        });
        _indicatorController.forward(
            from: 0.0); // Trigger the indicator animation
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    _indicatorController.dispose(); // Trigger the indicator animation
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void scrollToChildPosition(int position) {
    double totalWidth = 0.0;
    for (int i = 0; i <= position; i++) {
      totalWidth = totalWidth + childrenSizes[i].width;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? containerBox =
          containerKey.currentContext?.findRenderObject() as RenderBox?;

      if (containerBox != null) {
        final double containerWidth = containerBox.size.width;
        final double itemExtent = containerWidth / position;
        final double offset =
            totalWidth - containerWidth; // Adjust the offset calculation.

        final double maxVisibleOffset = controller.offset + containerWidth;
        final double minVisibleOffset = controller.offset;

        // Adjust the visibility conditions.
        final bool isPositionVisible = offset >= minVisibleOffset;
        final bool isPositionPartiallyVisible =
            offset + itemExtent >= minVisibleOffset;

        if (totalWidth > parentSize.width ||
            (!isPositionVisible || isPositionPartiallyVisible) &&
                offset.isFinite &&
                minVisibleOffset.isFinite &&
                maxVisibleOffset.isFinite) {
          controller.animateTo(
            offset + widget.offsetAddon,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      scrollToChildPosition(currentlySelected);
    }
  }

  bool handleNotificationListener(Notification notification) {
    if (widget.directAncestorUseController) {
      // over scroll to the left side
      if (notification is OverscrollNotification &&
          notification.overscroll < 0) {
        double goToOffset =
            ancestorPageController!.position.pixels + notification.overscroll;

        if (goToOffset >= ancestorPageController!.position.minScrollExtent &&
            goToOffset <= ancestorPageController!.position.maxScrollExtent) {
          leftOverScroll += notification.overscroll;
          ancestorPageController?.position.correctPixels(goToOffset);
          ancestorPageController?.position.notifyListeners();
        }
      }

      // scroll back after left over scrolling
      if (leftOverScroll < 0) {
        if (notification is ScrollUpdateNotification) {
          final newOverScroll =
              min(notification.metrics.pixels + leftOverScroll, 0.0);
          final diff = newOverScroll - leftOverScroll;
          ancestorPageController?.position
              .correctPixels(ancestorPageController!.position.pixels + diff);
          ancestorPageController?.position.notifyListeners();
          leftOverScroll = newOverScroll;
          controller.position.correctPixels(0);
          controller.position.notifyListeners();
        }
      }

      // release left
      if (notification is UserScrollNotification &&
          notification.direction == ScrollDirection.idle &&
          leftOverScroll != 0) {
        double screenWidth = getScreenWidth(context);
        double goToCurrentOffset =
            ancestorPageController!.position.pixels - leftOverScroll;
        double goToNextOffset =
            ancestorPageController!.offset - (screenWidth + leftOverScroll);

        if ((leftOverScroll * -1) >= screenWidth / 2) {
          ancestorPageController?.animateTo(goToNextOffset,
              duration: widget.toAncestor, curve: widget.curve);
        } else {
          ancestorPageController?.animateTo(goToCurrentOffset,
              duration: widget.toAncestor, curve: widget.curve);
        }

        leftOverScroll = 0;
      }

      // over scroll to the right side
      if (notification is OverscrollNotification &&
          notification.overscroll > 0) {
        double goToOffset =
            ancestorPageController!.position.pixels + notification.overscroll;

        if (goToOffset >= ancestorPageController!.position.minScrollExtent &&
            goToOffset <= ancestorPageController!.position.maxScrollExtent) {
          rightOverScroll += notification.overscroll;
          ancestorPageController?.position.correctPixels(
              ancestorPageController!.position.pixels +
                  notification.overscroll);
          ancestorPageController?.position.notifyListeners();
        }
      }

      // scroll back after right over scrolling
      if (rightOverScroll > 0) {
        if (notification is ScrollUpdateNotification) {
          final maxScrollExtent = notification.metrics.maxScrollExtent;
          final newOverScroll = max(
              notification.metrics.pixels + rightOverScroll - maxScrollExtent,
              0.0);
          final diff = newOverScroll - rightOverScroll;
          ancestorPageController?.position
              .correctPixels(ancestorPageController!.position.pixels + diff);
          ancestorPageController?.position.notifyListeners();
          rightOverScroll = newOverScroll;
          controller.position.correctPixels(maxScrollExtent);
          controller.position.notifyListeners();
        }
      }

      // release right
      if (notification is UserScrollNotification &&
          notification.direction == ScrollDirection.idle &&
          rightOverScroll != 0) {
        double screenWidth = getScreenWidth(context);
        double goToCurrentOffset =
            ancestorPageController!.position.pixels - rightOverScroll;
        double goToNextOffset =
            (screenWidth - rightOverScroll) + ancestorPageController!.offset;
        if (rightOverScroll >= screenWidth / 2) {
          ancestorPageController?.animateTo(goToNextOffset,
              duration: widget.toAncestor, curve: widget.curve);
        } else {
          ancestorPageController?.animateTo(goToCurrentOffset,
              duration: widget.toAncestor, curve: widget.curve);
        }

        rightOverScroll = 0;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter Widgets

        SizeReportingWidget(
          onSizeChange: (Size size) {
            parentSize = size;
          },
          child: widget.isScrollable
              ? NotificationListener(
                  onNotification: handleNotificationListener,
                  child: SingleChildScrollView(
                    key: containerKey,
                    controller: controller,
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: tabScrollableItems,
                    ),
                  ),
                )
              : Row(
                  children: tabFixedItems,
                ),
        ),

        // Line

        SlidingTabIndicator(
          numTabs: widget.tabItems.length,
          currentIndex: currentlySelected,
          width: childrenSizes[0].width,
          padding: widget.padding.left * 2,
          spacing: widget.padding.right * 2,
        ),

        Container(
          decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Colors.grey.shade500, width: 1))),
        ),

        //  Bottom line
        widget.useBottomDivider
            ? Row(
                children: [
                  Expanded(
                      child: Container(
                    height: widget.bottomDividerHeight,
                    color: widget.bottomDividerColor,
                  )),
                ],
              )
            : const SizedBox()
      ],
    );
  }

  List<Widget> get tabScrollableItems => widget.tabItems
      .asMap()
      .map((index, filterItem) => MapEntry(
          index,
          GestureDetector(
            onTap: () {
              if (currentlySelected != index) {
                setState(() {
                  currentlySelected = index;
                });

                widget.currentItem(currentlySelected);
                scrollToChildPosition(currentlySelected);
                _indicatorController.forward(
                    from: 0.0); // Trigger the indicator animation
              }
            },
            child: SizeReportingWidget(
              onSizeChange: (Size size) {
                childrenSizes[index] = size;
              },
              child: Row(
                children: [
                  // Tab Item
                  Padding(
                    padding: widget.padding,
                    child: Row(
                      children: [
                        // Icon

                        widget.useIcon && filterItem.icon != null
                            ? Icon(
                                filterItem.icon,
                                color: filterItem.iconColor ??
                                    (index == currentlySelected
                                        ? widget.tabActiveColor
                                        : widget.tabNormalColor),
                              )
                            : const SizedBox(),

                        // Filter Text
                        widget.useIcon && filterItem.icon != null
                            ? const SizedBox(
                                width: 4,
                              )
                            : const SizedBox(),
                        Text(
                          filterItem.filterText,
                          style: TextStyle(
                              color: index == currentlySelected
                                  ? widget.tabActiveColor
                                  : widget.tabNormalColor,
                              fontSize: widget.textSize,
                              fontWeight: index == currentlySelected &&
                                          widget.boldSelected ||
                                      widget.boldUnSelected &&
                                          index != currentlySelected
                                  ? widget.textWeight
                                  : FontWeight.normal),
                        ),
                      ],
                    ),
                  ),

                  //  Space
                  const SizedBox(
                    width: 16,
                  )
                ],
              ),
            ),
          )))
      .values
      .toList();

  List<Widget> get tabFixedItems => widget.tabItems
      .asMap()
      .map((index, tabItem) => MapEntry(
          index,
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (currentlySelected != index) {
                  setState(() {
                    currentlySelected = index;
                  });

                  widget.currentItem(currentlySelected);
                }
              },
              child: SizeReportingWidget(
                onSizeChange: (Size size) {
                  childrenSizes[index] = size;
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Tab Item
                    Padding(
                      padding: widget.padding,
                      child: Row(
                        children: [
                          // Icon
                          widget.useIcon && tabItem.icon != null
                              ? Icon(
                                  tabItem.icon,
                                  color: tabItem.iconColor ??
                                      (index == currentlySelected
                                          ? widget.tabActiveColor
                                          : widget.tabNormalColor),
                                )
                              : const SizedBox(),

                          // Filter Text
                          widget.useIcon && tabItem.icon != null
                              ? const SizedBox(
                                  width: 4,
                                )
                              : const SizedBox(),
                          Text(
                            tabItem.filterText,
                            style: TextStyle(
                                color: index == currentlySelected
                                    ? widget.tabActiveColor
                                    : widget.tabNormalColor,
                                fontSize: widget.textSize,
                                fontWeight: index == currentlySelected &&
                                            widget.boldSelected ||
                                        widget.boldUnSelected &&
                                            index != currentlySelected
                                    ? widget.textWeight
                                    : FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )))
      .values
      .toList();
}

class TabItem {
  final IconData? icon;
  final double iconSize;
  final Color? iconColor;
  final String filterText;

  TabItem({
    this.icon,
    required this.filterText,
    this.iconSize = 16,
    this.iconColor,
  });
}

//
// import 'package:crods_manager/components/CustomProject.dart';
// import 'package:flutter/material.dart';
//
// void main() {
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: Text('Custom Sliding Tab Indicator'),
//         ),
//         body: CustomTabBar(),
//       ),
//     );
//   }
// }
//
// class CustomTabBar extends StatefulWidget {
//   const CustomTabBar({super.key});
//
//   @override
//   _CustomTabBarState createState() => _CustomTabBarState();
// }
//
// class _CustomTabBarState extends State<CustomTabBar> {
//   int _currentIndex = 0;
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//           children: [
//             CustomTab(
//               text: 'Tab 1',
//               isSelected: _currentIndex == 0,
//               onTap: () {
//                 setState(() {
//                   _currentIndex = 0;
//                 });
//               },
//             ),
//             CustomTab(
//               text: 'Tab 2',
//               isSelected: _currentIndex == 1,
//               onTap: () {
//                 setState(() {
//                   _currentIndex = 1;
//                 });
//               },
//             ),
//             CustomTab(
//               text: 'Tab 3',
//               isSelected: _currentIndex == 2,
//               onTap: () {
//                 setState(() {
//                   _currentIndex = 2;
//                 });
//               },
//             ),
//           ],
//         ),
//         SizedBox(height: 16.0),
//         SlidingTabIndicator(numTabs: 3, currentIndex: _currentIndex),
//       ],
//     );
//   }
// }
//
// class CustomTab extends StatelessWidget {
//   final String text;
//   final bool isSelected;
//   final VoidCallback onTap;
//
//   const CustomTab({super.key, required this.text, required this.isSelected, required this.onTap});
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
//         child: Text(
//           text,
//           style: TextStyle(
//             color: isSelected ? Colors.blue : Colors.black,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }
// }
