import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class ScannerConfig {
  static Future<String> getScanner() {
    return FlutterBarcodeScanner.scanBarcode(
        "#ff6666", "Cancel", true, ScanMode.BARCODE);
  }
}
