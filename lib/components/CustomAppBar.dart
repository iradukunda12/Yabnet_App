import 'package:flutter/cupertino.dart';
import 'package:yabnet/components/SizeReportingWidget.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Size size;
  final Widget child;

  const CustomAppBar({
    super.key,
    required this.child,
    required this.size,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize {
    return size;
  }
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizeReportingWidget(
          onSizeChange: (Size value) {}, child: widget.child),
    );
  }
}
