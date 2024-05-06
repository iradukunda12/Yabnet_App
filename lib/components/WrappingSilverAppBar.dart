import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../components/SizeReportingWidget.dart';

class WrappingSliverAppBar extends StatefulWidget {
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final Widget? title;
  final List<Widget>? actions;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;
  final double? elevation;
  final double? scrolledUnderElevation;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final bool forceElevated;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconThemeData? iconTheme;
  final IconThemeData? actionsIconTheme;
  final bool primary;
  final bool? centerTitle;
  final bool excludeHeaderSemantics;
  final double? titleSpacing;
  final double? expandedHeight;
  final double? collapsedHeight;
  final double? topPadding;
  final bool floating;
  final bool pinned;
  final ShapeBorder? shape;
  final double? leadingWidth;
  final TextStyle? toolbarTextStyle;
  final TextStyle? titleTextStyle;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final double? bottomHeight;
  final bool forceMaterialTransparency;
  final Clip? clipBehavior;
  final bool snap;
  final bool stretch;
  final double stretchTriggerOffset;
  final Future<void> Function()? onStretchTrigger;
  final ScrollNotifier? notifier;

  const WrappingSliverAppBar({
    super.key,
    this.leading,
    this.automaticallyImplyLeading = false,
    this.title,
    this.actions,
    this.flexibleSpace,
    this.bottom,
    this.elevation,
    this.scrolledUnderElevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.forceElevated = false,
    this.backgroundColor,
    this.foregroundColor,
    this.iconTheme,
    this.actionsIconTheme,
    this.primary = true,
    this.centerTitle,
    this.excludeHeaderSemantics = false,
    this.titleSpacing,
    this.collapsedHeight,
    this.expandedHeight,
    this.floating = false,
    this.pinned = false,
    this.snap = false,
    this.stretch = false,
    this.stretchTriggerOffset = 100.0,
    this.onStretchTrigger,
    this.shape,
    this.leadingWidth,
    this.toolbarTextStyle,
    this.titleTextStyle,
    this.systemOverlayStyle,
    this.forceMaterialTransparency = false,
    this.clipBehavior,
    this.topPadding,
    this.bottomHeight,
    this.notifier,
  });

  @override
  State<WrappingSliverAppBar> createState() => WrappingSliverAppBarState();
}

class WrappingSliverAppBarState extends State<WrappingSliverAppBar> {
  double currentHeight = 0;

  @override
  void initState() {
    super.initState();
    currentHeight = kToolbarHeight;
  }

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (BuildContext context, SliverConstraints sliverConstraints) {
        double changingHeight = (sliverConstraints.cacheOrigin * -1) +
            sliverConstraints.precedingScrollExtent;
        double scrollCovered = 0.0;

        if (widget.notifier != null && sliverConstraints.cacheOrigin >= 0.0) {
          scrollCovered = sliverConstraints.overlap;

          widget.notifier?.sendScrollCovered(scrollCovered);
        } else if (widget.notifier != null &&
            sliverConstraints.cacheOrigin != 0.0 &&
            changingHeight > sliverConstraints.precedingScrollExtent &&
            changingHeight <= currentHeight) {
          scrollCovered = changingHeight;

          widget.notifier?.sendScrollCovered(scrollCovered);
        }

        return SliverAppBar(
          key: widget.key,
          leading: widget.leading,
          automaticallyImplyLeading: widget.automaticallyImplyLeading,
          title: SizeReportingWidget(
            onSizeChange: (Size size) {
              setState(() {
                currentHeight = size.height;
              });
            },
            child: widget.title ?? const SizedBox(),
          ),
          actions: widget.actions,
          flexibleSpace: widget.flexibleSpace,
          bottom: widget.bottom,
          elevation: widget.elevation,
          shadowColor: widget.shadowColor,
          backgroundColor: widget.backgroundColor,
          foregroundColor: widget.foregroundColor,
          iconTheme: widget.iconTheme,
          actionsIconTheme: widget.actionsIconTheme,
          primary: widget.primary,
          centerTitle: widget.centerTitle,
          excludeHeaderSemantics: widget.excludeHeaderSemantics,
          titleSpacing: widget.titleSpacing,
          collapsedHeight: widget.collapsedHeight,
          expandedHeight: widget.expandedHeight,
          floating: widget.floating,
          pinned: widget.pinned,
          snap: widget.snap,
          stretch: widget.stretch,
          stretchTriggerOffset: widget.stretchTriggerOffset,
          onStretchTrigger: widget.onStretchTrigger,
          shape: widget.shape,
          toolbarHeight: currentHeight,
          leadingWidth: widget.leadingWidth,
          toolbarTextStyle: widget.toolbarTextStyle,
          titleTextStyle: widget.titleTextStyle,
          systemOverlayStyle: widget.systemOverlayStyle,
          forceMaterialTransparency: widget.forceMaterialTransparency,
          clipBehavior: widget.clipBehavior,
        );
      },
    );
  }
}

class ScrollNotifier extends ChangeNotifier {
  double scrollCovered = 0;
  double opacity = 1;

  void sendScrollCovered(double currentScroll) {
    scrollCovered = currentScroll;
    notifyListeners();
  }

  void opacityChange(double currentHeight) {
    if (scrollCovered > 0 && scrollCovered <= currentHeight) {
      double check = (1 - (scrollCovered / currentHeight));
      if (check > 0.1) {
        opacity = check;
      } else {
        opacity = 0.1;
      }
    } else if (scrollCovered > currentHeight) {
      opacity = 0.1;
    } else {
      opacity = 1;
    }
    notifyListeners();
  }
}
