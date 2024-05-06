import 'dart:async';

import 'package:flutter/cupertino.dart';

import 'CustomProject.dart';

class CustomControlledProgressBar {
  // final BuildContext context;

  CustomControlledProgressBar();

  bool? showing;
  Timer? timer;
  BuildContext? usingContext;

  void showProgressBarHere(BuildContext context) {
    if (showing == null && usingContext == null) {
      showing = true;
      timer?.cancel();
      timer = null;
      // usingContext = showCustomProgressBar(context);
    }
  }

  void closeProgressBarHere() {
    if (showing == true && usingContext != null) {
      closeCustomProgressBar(usingContext!);
      showing = null;
      timer?.cancel();
      timer = null;
      usingContext = null;
    }
  }

  void closeProgressBarWithAMessage(String messageText) {
    if (showing == true && usingContext != null) {
      closeCustomProgressBar(usingContext!);
      showToastMobile(msg: messageText);
      showing = null;
      timer?.cancel();
      timer = null;
      usingContext = null;
    }
  }

  void closeProgressBarAfterDuration(Duration duration, {String? messageText}) {
    if (showing == true && usingContext != null) {
      timer = Timer(duration, () {
        if (showing == true) {
          closeCustomProgressBar(usingContext!);
          showing = null;
          timer?.cancel();
          timer = null;
          usingContext = null;
          if (messageText != null) {
            showToastMobile(msg: messageText);
          }
        }
      });
    }
  }
}
