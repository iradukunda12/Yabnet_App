import 'dart:async';

import 'package:flutter/material.dart';

import '../builders/ControlledStreamBuilder.dart';
import 'CustomOnClickContainer.dart';

class SelectionActions {
  void selectAllSelection() {}

  void cancelAllSelections() {}

  List getSelections() {
    return [];
  }
}

class SelectionControllerNotifier<T> extends ChangeNotifier {
  SelectionActions? getSelectionActions;
  StreamController<List> streamController = StreamController<List>.broadcast();

  void attachSelectionAction(SelectionActions selectionActions) {
    getSelectionActions = selectionActions;
    notifyListeners();
  }

  void sendSelection(List selections) {
    streamController.add(selections);
  }
}

typedef SelectionClickedBuilder<T> = Function()? Function(
    BuildContext context, List<T>? selections);

class SelectionWidget<T> {
  final Widget lead;
  final SelectionClickedBuilder<T> onClicked;

  SelectionWidget(this.lead, this.onClicked);
}

class SelectionController {
  final Widget icon;
  final SelectionControllerNotifier selectionControllerNotifier;

  SelectionController(this.icon, this.selectionControllerNotifier);
}

class CustomSelectionDisplayCard<T> extends StatefulWidget {
  final Color? defaultButtonColor;
  final Color clickedButtonColor;
  final Icon cancelSelection;
  final double selectionGap;
  final double leadingGap;
  final SelectionControllerNotifier<T?> selectionControllerNotifier;
  final List<SelectionWidget>? leading;
  final double spaceGap;
  final double sideGap;
  final double controlGap;
  final TextStyle? textStyle;
  final Widget defaultWidget;
  final BoxShape shape;

  const CustomSelectionDisplayCard(
      {super.key,
      this.defaultButtonColor,
      required this.clickedButtonColor,
      required this.cancelSelection,
      this.selectionGap = 10,
      required this.selectionControllerNotifier,
      this.textStyle,
      this.leading,
      this.leadingGap = 5,
      this.spaceGap = 5,
      this.sideGap = 8,
      this.controlGap = 12,
      required this.defaultWidget,
      this.shape = BoxShape.circle});

  @override
  State<CustomSelectionDisplayCard<T>> createState() =>
      _CustomSelectionDisplayCardState<T>();
}

class _CustomSelectionDisplayCardState<T>
    extends State<CustomSelectionDisplayCard<T>> {
  @override
  Widget build(BuildContext context) {
    return ControlledStreamBuilder<List>(streamProvider: (context) {
      return widget.selectionControllerNotifier.streamController.stream;
    }, builder: (context, streamSnapshot) {
      if (streamSnapshot.data?.isEmpty == true || !streamSnapshot.hasData) {
        return widget.defaultWidget;
      }

      return Column(
        children: [
          // Controls

          Row(
            children: [
              // Left Cancel Selection
              CustomOnClickContainer(
                  shape: widget.shape,
                  onTap: widget.selectionControllerNotifier.getSelectionActions
                      ?.cancelAllSelections,
                  defaultColor: widget.defaultButtonColor ?? Colors.transparent,
                  clickedColor: widget.clickedButtonColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: widget.cancelSelection,
                  )),

              SizedBox(width: widget.selectionGap),

              Expanded(
                  child: Text(
                streamSnapshot.data?.length.toString() ?? "",
                style: widget.textStyle,
              )),

              SizedBox(width: widget.leadingGap),

              for (var eachLead in (widget.leading ?? []))
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: EdgeInsets.only(left: widget.spaceGap),
                    child: CustomOnClickContainer(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      shape: widget.shape,
                      onTap: eachLead.onClicked(context, streamSnapshot.data),
                      defaultColor:
                          widget.defaultButtonColor ?? Colors.transparent,
                      clickedColor: widget.clickedButtonColor,
                      child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: (eachLead.lead ?? const SizedBox())),
                    ),
                  ),
                ),
            ],
          ),
        ],
      );
    });
  }
}
