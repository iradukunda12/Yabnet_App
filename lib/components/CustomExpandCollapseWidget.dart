import 'dart:ui';

import 'package:flutter/material.dart';

import '../components/CustomProject.dart';
import '../components/SizeReportingWidget.dart';

class ExpandCollapseController extends ChangeNotifier {
  bool showingSmall = true;

  void changeTheViewDisplay(bool showSmallView) {
    if (showingSmall == showSmallView) {
      return;
    }
    showingSmall = showSmallView;
    notifyListeners();
  }
}

class CustomExpandCollapseWidget extends StatefulWidget {
  final Widget smallView;
  final Widget bigView;
  final BoxDecoration decoration;
  final Duration duration;
  final ExpandCollapseController expandCollapseController;
  final bool showingSmallFirst;

  const CustomExpandCollapseWidget(
      {super.key,
      required this.smallView,
      required this.bigView,
      required this.decoration,
      this.duration = const Duration(milliseconds: 500),
      required this.expandCollapseController,
      this.showingSmallFirst = true});

  @override
  State<StatefulWidget> createState() {
    return _CustomExpandCollapseWidgetState();
  }
}

class _CustomExpandCollapseWidgetState extends State<CustomExpandCollapseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    if (!widget.showingSmallFirst) {
      widget.expandCollapseController
          .changeTheViewDisplay(widget.showingSmallFirst);
    }
    widget.expandCollapseController.addListener(() {
      _toggleExpansion(widget.expandCollapseController.showingSmall);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion(bool smallView) {
    if (_controller.isDismissed) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  double smallHeight = 0;
  double bigHeight = 0;
  bool firstViewed = false;

  double getAnimationValue(double animationValue) {
    if (firstViewed) {
      if (widget.showingSmallFirst) {
        return animationValue;
      } else {
        return 1 - animationValue;
      }
    } else if (!widget.showingSmallFirst && bigHeight > 0) {
      firstViewed = true;
      return 1 - animationValue;
    } else {
      if (widget.showingSmallFirst) {
        firstViewed = true;
      }
      return animationValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        double heightValue = lerpDouble(
                smallHeight, bigHeight, getAnimationValue(_animation.value)) ??
            0;
        showDebug(msg: heightValue);

        return Container(
          decoration: widget.decoration,
          height: heightValue,
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              if (widget.expandCollapseController.showingSmall)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SizeReportingWidget(
                    onSizeChange: (size) {
                      setState(() {
                        smallHeight = size.height;
                      });
                    },
                    child: Opacity(
                        opacity: heightValue > smallHeight ? 0 : 1,
                        child: widget.smallView),
                  ),
                ),
              if (heightValue > smallHeight ||
                  !widget.expandCollapseController.showingSmall)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SizeReportingWidget(
                    onSizeChange: (size) {
                      setState(() {
                        bigHeight = size.height;
                      });
                    },
                    child: Opacity(
                      opacity: 1,
                      child: widget.bigView,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
