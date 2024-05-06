import 'package:flutter/cupertino.dart';

class ScanResultController extends ChangeNotifier {
  String getResultText = '';

  void sendResult(String result) {
    getResultText = result;
    notifyListeners();
  }

  void receivedResult(String? pastResult) {
    if (pastResult == getResultText) {
      getResultText = "";
      notifyListeners();
    }
  }
}
