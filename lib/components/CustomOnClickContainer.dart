import 'package:flutter/cupertino.dart';

class CustomOnClickContainer extends StatefulWidget {
  final Color defaultColor;
  final Color clickedColor;
  final Color? notEnabledColor;
  final Function()? onTap;
  final Function()? onLongTap;
  final Function()? onLongTapCancel;
  final bool isEnabled;
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding;
  final Decoration? foregroundDecoration;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? margin;
  final Matrix4? transform;
  final AlignmentGeometry? transformAlignment;
  final Widget child;
  final Clip clipBehavior;
  final DecorationImage? image;
  final BoxBorder? border;
  final BorderRadiusGeometry? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final BlendMode? backgroundBlendMode;
  final BoxShape shape;

  const CustomOnClickContainer(
      {super.key,
      this.onTap,
      this.isEnabled = true,
      required this.defaultColor,
      required this.clickedColor,
      this.notEnabledColor,
      this.alignment,
      this.padding,
      this.foregroundDecoration,
      this.width,
      this.height,
      this.constraints,
      this.margin,
      this.transform,
      this.transformAlignment,
      required this.child,
      this.clipBehavior = Clip.none,
      this.image,
      this.border,
      this.borderRadius,
      this.boxShadow,
      this.gradient,
      this.backgroundBlendMode,
      this.shape = BoxShape.rectangle,
      this.onLongTap,
      this.onLongTapCancel});

  @override
  State<CustomOnClickContainer> createState() => _CustomOnClickContainerState();
}

class _CustomOnClickContainerState extends State<CustomOnClickContainer> {
  bool isClicked = false;

  void changeClicked(TapDownDetails tapDownDetails) {
    setState(() {
      isClicked = true;
    });
  }

  void changeNotClicked(TapUpDetails tapUpDetails) {
    setState(() {
      isClicked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressCancel: widget.onLongTapCancel,
      onLongPress: widget.onLongTap,
      onTapCancel: widget.onTap != null
          ? () {
              setState(() {
                isClicked = false;
              });
            }
          : null,
      onTapDown: widget.onTap != null ? changeClicked : null,
      onTapUp: widget.onTap != null ? changeNotClicked : null,
      onTap: widget.isEnabled ? widget.onTap : null,
      child: Container(
        decoration: BoxDecoration(
            color: /* When button is enabled */ widget.isEnabled
                /* When button is enabled and clicked and onTapped */ ? isClicked &&
                        widget.onTap != null
                    ? widget.clickedColor
                    /* When button is enabled and not clicked */ : widget
                        .defaultColor
                /* When button is disabled */ : widget.notEnabledColor,
            borderRadius: widget.borderRadius,
            image: widget.image,
            border: widget.border,
            boxShadow: widget.boxShadow,
            gradient: widget.gradient,
            backgroundBlendMode: widget.backgroundBlendMode,
            shape: widget.shape),
        width: widget.width,
        height: widget.height,
        alignment: widget.alignment,
        padding: widget.padding,
        foregroundDecoration: widget.foregroundDecoration,
        constraints: widget.constraints,
        transform: widget.transform,
        transformAlignment: widget.transformAlignment,
        clipBehavior: widget.clipBehavior,
        child: widget.child,
      ),
    );
  }
}
