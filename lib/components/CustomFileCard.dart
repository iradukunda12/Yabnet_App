import 'package:flutter/material.dart';

import 'CustomOnClickContainer.dart';

class CustomFileCard extends StatefulWidget {
  final String fileTypeImage;
  final String fileName;
  final String fileSize;
  final String fileCreated;
  final Color defaultColor;
  final Color clickedColor;
  final double borderRadius;
  final double textGap;
  final EdgeInsets padding;
  final EdgeInsets iconPadding;
  final TextStyle nameStyle;
  final TextStyle detailsStyle;
  final bool showClickable;
  final bool usBoxShadow;
  final Function() onTap;
  final List<MapEntry<Widget, Function()>> menus;

  const CustomFileCard(
      {super.key,
      required this.fileName,
      required this.defaultColor,
      required this.clickedColor,
      this.borderRadius = 10,
      this.padding = const EdgeInsets.all(12),
      this.iconPadding = const EdgeInsets.only(left: 8),
      this.nameStyle = const TextStyle(),
      required this.onTap,
      this.showClickable = false,
      this.usBoxShadow = true,
      required this.fileTypeImage,
      required this.fileSize,
      required this.fileCreated,
      this.detailsStyle = const TextStyle(),
      this.textGap = 4,
      required this.menus});

  @override
  State<CustomFileCard> createState() => _CustomFileCardState();
}

class _CustomFileCardState extends State<CustomFileCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: widget.defaultColor,
        boxShadow: widget.usBoxShadow
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomOnClickContainer(
              onTap: widget.onTap,
              defaultColor: widget.defaultColor,
              clickedColor: widget.clickedColor,
              child: Padding(
                padding: widget.padding.copyWith(right: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    widget.fileTypeImage.isNotEmpty
                        ? Image.asset(
                            widget.fileTypeImage,
                            height: 40,
                          )
                        : Icon(
                            Icons.not_interested,
                            size: (widget.nameStyle.fontSize ?? 15) * 1.3,
                            color: widget.detailsStyle.color,
                          ),

                    // File Info
                    SizedBox(
                      width: widget.padding.left,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          // File Name
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.fileName,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: widget.nameStyle,
                                ),
                              ),
                            ],
                          ),

                          //   Size -> Date
                          SizedBox(
                            height: widget.textGap,
                          ),
                          Row(
                            children: [
                              //   Size
                              Text(
                                widget.fileSize,
                                style: widget.detailsStyle,
                              ),

                              // Date Created
                              SizedBox(
                                width: widget.textGap * 5.5,
                              ),
                              Expanded(
                                child: Text(
                                  widget.fileCreated,
                                  overflow: TextOverflow.ellipsis,
                                  style: widget.detailsStyle,
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          //   Icon
          PopupMenuButton(onSelected: (itemIndex) {
            widget.menus.elementAtOrNull(itemIndex)?.value.call();
          }, itemBuilder: (context) {
            return widget.menus
                .asMap()
                .map((index, e) {
                  return MapEntry(
                      index, PopupMenuItem(value: index, child: e.key));
                })
                .values
                .toList();
          }),
        ],
      ),
    );
  }
}
