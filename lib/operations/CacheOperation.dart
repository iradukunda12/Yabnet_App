import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:yabnet/components/CustomProject.dart';
import 'package:yabnet/local_database.dart';

class CacheOperation {
  static final CacheOperation instance = CacheOperation.internal();

  factory CacheOperation() => instance;

  Map<String, Box> _boxes = {};

  CacheOperation.internal();

  Future<bool> saveCacheData(String boxName, dynamic saveKey, dynamic data,
      {String? fromWhere}) async {
    String extra = fromWhere ?? '';

    if (!_boxes.containsKey(boxName + extra)) {
      _boxes[boxName] =
          await LocalDatabase().interface().openBox(boxName + extra);
    }

    if (_boxes[boxName + extra] == null ||
        _boxes[boxName + extra]?.isOpen == false) {
      return false;
    }

    Box thisBox = _boxes[boxName + extra]!;

    return thisBox
        .put(saveKey, data)
        .then((value) => thisBox.get(saveKey) == data)
        .onError((error, stackTrace) => false);
  }

  Future<dynamic> getCacheData(String boxName, dynamic saveKey,
      {String? fromWhere}) async {
    String extra = fromWhere ?? '';

    if (!_boxes.containsKey(boxName + extra)) {
      _boxes[boxName + extra] =
          await LocalDatabase().interface().openBox(boxName + extra);
    }

    if (_boxes[boxName + extra] == null ||
        _boxes[boxName + extra]?.isOpen == false) {
      return null;
    }

    Box thisBox = _boxes[boxName + extra]!;

    return thisBox.get(saveKey);
  }

  Future<List<dynamic>> getCacheKeys(String boxName,
      {String? fromWhere}) async {
    String extra = fromWhere ?? '';

    if (!_boxes.containsKey(boxName + extra)) {
      _boxes[boxName + extra] =
          await LocalDatabase().interface().openBox(boxName + extra);
    }

    if (_boxes[boxName + extra] == null ||
        _boxes[boxName + extra]?.isOpen == false) {
      return [];
    }

    Box thisBox = _boxes[boxName + extra]!;

    return thisBox.keys.toList();
  }

  Future<bool> deleteCacheData(String boxName, dynamic saveKey,
      {String? fromWhere}) async {
    String extra = fromWhere ?? '';

    if (!_boxes.containsKey(boxName + extra)) {
      _boxes[boxName + extra] =
          await LocalDatabase().interface().openBox(boxName + extra);
    }

    if (_boxes[boxName + extra] == null ||
        _boxes[boxName + extra]?.isOpen == false) {
      return false;
    }

    Box thisBox = _boxes[boxName + extra]!;

    return thisBox
        .delete(saveKey)
        .then((value) => true)
        .onError((error, stackTrace) => false);
  }

  Future<List<bool>> clearBoxes() async {
    return Future.wait(_boxes.keys.map((boxName) => clearBox(boxName)));
  }

  Future<bool> clearBox(String boxName, {bool removeBox = true}) async {
    if (_boxes.containsKey(boxName)) {
      final box = _boxes[boxName];
      if (box != null) {
        await box.deleteFromDisk();
        if (removeBox) {
          _boxes.remove(boxName);
        }
        showDebug(msg: "Cleared The Box -> $boxName");
        return true;
      }
    }
    return false;
  }

  Future<ValueListenable<Box>?> getListenable(String boxName,
      {String? fromWhere}) async {
    String extra = fromWhere ?? '';

    if (!_boxes.containsKey(boxName + extra)) {
      _boxes[boxName + extra] =
          await LocalDatabase().interface().openBox(boxName + extra);
    }

    if (_boxes[boxName + extra] == null ||
        _boxes[boxName + extra]?.isOpen == false) {
      return null;
    }

    return _boxes[boxName + extra]?.listenable();
  }
}
