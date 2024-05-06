import 'package:flutter/material.dart';
import 'package:yabnet/components/CustomOnClickContainer.dart';

enum IconListDisplay { extended, disable, all, normal }

class IconView {
  final Icon icon;
  final Text text;
  final bool canDisable;
  final bool disabled;
  final Function(int index) onTap;

  IconView(this.icon, this.text, this.onTap,
      {this.disabled = false, this.canDisable = true});
}

class IconListView extends StatefulWidget {
  final List<IconView> iconViews;
  final double spacing;
  final int? limitTo;
  final Icon? moreIcon;
  final double? moreSpace;
  final Color? disabledColor;
  final Function()? onTappedMore;

  const IconListView({
    super.key,
    required this.iconViews,
    this.spacing = 16,
    this.limitTo,
    this.moreIcon,
    this.moreSpace,
    this.onTappedMore,
    this.disabledColor,
  });

  @override
  State<IconListView> createState() => _IconListViewState();
}

class _IconListViewState extends State<IconListView> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Row(
              children: [
                ...widget.iconViews
                    .asMap()
                    .map((key, iconView) {
                      return MapEntry(
                          key,
                          Padding(
                            padding: EdgeInsets.only(
                              right: widget.spacing,
                            ),
                            child: CustomOnClickContainer(
                              defaultColor: Colors.transparent,
                              clickedColor: Colors.grey.shade200,
                              shape: BoxShape.circle,
                              onTap: () {
                                iconView.disabled ? null : iconView.onTap(key);
                              },
                              child: Icon(
                                iconView.icon.icon,
                                key: iconView.icon.key,
                                size: iconView.icon.size,
                                color: iconView.disabled
                                    ? widget.disabledColor
                                    : iconView.icon.color,
                              ),
                            ),
                          ));
                    })
                    .values
                    .toList()
                    .sublist(0, widget.limitTo),
                widget.moreIcon != null
                    ? GestureDetector(
                        onTap: widget.onTappedMore, child: (widget.moreIcon!))
                    : SizedBox(),
                widget.moreIcon != null
                    ? (SizedBox(
                        width: widget.moreSpace,
                      ))
                    : SizedBox(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
