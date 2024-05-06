import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:popover/popover.dart';

import '../builders/CustomWrapListBuilder.dart';
import '../main.dart';

void setNormalUiViewOverlay() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Color(getMainPinkColor),
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.light,
    statusBarColor: Colors.grey.shade50,
    statusBarIconBrightness: Brightness.dark,
  ));
}

void setLightUiViewOverlay() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.white,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    statusBarColor: Colors.grey.shade50,
    statusBarIconBrightness: Brightness.dark,
  ));
}

void setDarkGreyUiViewOverlay() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.grey.shade200,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.dark,
    statusBarColor: Colors.grey.shade50,
    statusBarIconBrightness: Platform.isIOS ? Brightness.dark : Brightness.dark,
  ));
}

void setDarkUiViewOverlay() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.black,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    statusBarBrightness: Platform.isIOS ? Brightness.dark : Brightness.light,
    statusBarColor: Colors.black,
    statusBarIconBrightness:
        Platform.isIOS ? Brightness.dark : Brightness.light,
  ));
}

void setTransparentUIViewOverlay() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarColor: Colors.grey.shade200,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light));
}

void setFullScreenMode() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

bool closeCustomProgressBar(BuildContext context) {
  Navigator.pop(context);
  return false;
}

Future showCustomProgressBar(BuildContext context, {var cancelTouch = false}) {
  return showDialog(
    context: context,
    builder: (usedContext) {
      return WillPopScope(
        onWillPop: () async {
          // Handle back button press here
          if (cancelTouch) {
            // If cancelTouch is true, allow the progress to be canceled
            // and dismiss the dialog
            Navigator.of(usedContext).pop();
            return true;
          } else {
            // If cancelTouch is false, prevent the progress from being canceled
            return false;
          }
        },
        child: Center(
          child: Platform.isIOS
              ? Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8)),
                  child: CupertinoActivityIndicator(
                    color: Colors.white,
                    radius: 35 / 2,
                  ))
              : CircularProgressIndicator(
                  color: Color(getMainPinkColor),
                ),
        ),
      );
    },
    barrierDismissible: false, // Always set to false here
  );
}

showDebug({dynamic msg = ''}) {
  if (kDebugMode) {
    print(msg);
  }
}

double getSpanLimiter(double requiredHeight, double expecter) {
  if (expecter > requiredHeight) {
    return requiredHeight;
  }

  return expecter;
}

DateTime utcDateTime(DateTime dateTime) {
  return DateTime.utc(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
      dateTime.millisecond,
      dateTime.microsecond);
}

List<List<T>> createSubgroups<T>(List<T> list, int subgroupLength) {
  List<List<T>> result = [];

  for (int i = 0; i < list.length; i += subgroupLength) {
    int end =
        (i + subgroupLength < list.length) ? i + subgroupLength : list.length;
    result.add(list.sublist(i, end));
  }

  return result;
}

Future openBottomSheet(BuildContext context, Widget content,
        {Color color = Colors.white,
        double cornerRadius = 15,
        bool isDismissible = true}) =>
    showModalBottomSheet(
        context: context,
        backgroundColor: color,
        isScrollControlled: true,
        isDismissible: isDismissible,
        useSafeArea: true,
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(cornerRadius))),
        builder: (BuildContext context) {
          return Container(
              decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(cornerRadius))),
              child: content);
        });

Future openDialog(BuildContext context, Widget? title, Widget content,
        List<Widget> actions,
        {EdgeInsets? padding,
        Function()? onClosed,
        bool cancelTouch = true,
        Color color = Colors.white}) =>
    showDialog(
        context: context,
        builder: (usedContext) {
          return WillPopScope(
              onWillPop: () async {
                // Handle back button press here
                if (cancelTouch) {
                  // If cancelTouch is true, allow the dialog to be canceled
                  // and dismiss the dialog
                  Navigator.of(usedContext).pop();
                  return true;
                } else {
                  // If cancelTouch is false, prevent the progress from being canceled
                  return false;
                }
              },
              child: AlertDialog(
                backgroundColor: color,
                contentPadding: padding,
                title: title,
                content: content,
                actions: actions,
                surfaceTintColor: Colors.transparent,
              ));
        }).then((value) {
      try {
        onClosed!();
      } catch (e) {
        null;
      }
    });

Future openAlert(BuildContext context, Widget view,
        {EdgeInsets? padding,
        Function()? onClosed,
        bool cancelTouch = true,
        Color color = Colors.white}) =>
    showDialog(
        context: context,
        builder: (usedContext) {
          return WillPopScope(
              onWillPop: () async {
                // Handle back button press here
                if (cancelTouch) {
                  // If cancelTouch is true, allow the dialog to be canceled
                  // and dismiss the dialog
                  Navigator.of(usedContext).pop();
                  return true;
                } else {
                  // If cancelTouch is false, prevent the progress from being canceled
                  return false;
                }
              },
              child: AlertDialog(
                backgroundColor: color,
                contentPadding: padding,
                content: view,
                surfaceTintColor: Colors.transparent,
              ));
        }).then((value) {
      try {
        onClosed!();
      } catch (e) {
        null;
      }
    });

Future<bool> hideKeyboard(BuildContext context,
    {Duration timeOut = const Duration(milliseconds: 500)}) async {
  SystemChannels.textInput.invokeListMethod("TextInput.hide");
  return false;
}

Future showPopMenuTitle(BuildContext context, Widget title, Widget body,
        {double gap = 12,
        EdgeInsets padding =
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        double sideGap = 24,
        double? width,
        double? height,
        PopoverDirection? popoverDirection}) =>
    showPopover(
        width: width ?? getScreenWidth(context) - sideGap,
        height: height,
        context: context,
        direction: popoverDirection ?? PopoverDirection.top,
        bodyBuilder: (context) => Padding(
              padding: padding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title,
                  SizedBox(
                    height: gap,
                  ),
                  body
                ],
              ),
            ));

Future showPopMenuList(BuildContext context, List<Widget> items,
        {double gap = 12,
        double space = 0,
        EdgeInsets padding =
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        double sideGap = 24,
        double? width,
        double? height,
        PopoverDirection? popoverDirection}) =>
    showPopover(
        width: width ?? getScreenWidth(context) - sideGap,
        height: height,
        context: context,
        direction: popoverDirection ?? PopoverDirection.top,
        bodyBuilder: (context) => Padding(
            padding: padding,
            child: CustomWrapListBuilder(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              itemCount: items.length,
              wrapListBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: (index + 1) != items.length ? space : 0),
                  child: items[index],
                );
              },
            )));

Future showToastMobile(
        {dynamic msg = "Nothing to display", bool longTime = false}) =>
    Fluttertoast.showToast(
        msg: "$msg",
        toastLength: longTime ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM_LEFT);

double getScreenWidth(BuildContext context) {
  return MediaQuery.of(context).size.width;
}

double getScreenHeight(BuildContext context) {
  return MediaQuery.of(context).size.height;
}

Widget Function(BuildContext, Widget?)? setMaxTextScaleFactor(
    {double maxFactor = 1, double? returnFactor}) {
  return (BuildContext context, Widget? child) {
    final MediaQueryData data = MediaQuery.of(context);
    return MediaQuery(
        data: data.copyWith(
            textScaleFactor: data.textScaleFactor > maxFactor
                ? maxFactor
                : returnFactor ?? data.textScaleFactor),
        child: child!);
  };
}

Widget progressBarWidget({Color? color, double? size, double? pad}) {
  return Center(
    child: Platform.isIOS
        ? Container(
            padding: EdgeInsets.all(pad ?? 16),
            decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8)),
            child: CupertinoActivityIndicator(
              color: Colors.white,
              radius: size ?? (35 / 2),
            ))
        : CircularProgressIndicator(
            color: color ?? Color(getMainPinkColor),
          ),
  );
}

String dbReference(dynamic ref) {
  return ref.toString().replaceAll(".", "_").toLowerCase().trim();
}

Map<String, dynamic>? dbData(Object? data) {
  return data != null && data is Map<String, dynamic> ? data : null;
}
