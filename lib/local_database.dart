import 'package:hive_flutter/adapters.dart';
import 'package:yabnet/operations/CacheOperation.dart';

class LocalDatabase {
  static final LocalDatabase offlineDatabaseInstance = LocalDatabase.internal();

  factory LocalDatabase() => offlineDatabaseInstance;

  LocalDatabase.internal();

  Future<void> startHive() async {
    return await interface().initFlutter();
  }

  Future<List<bool>> clearAll() async {
    return await CacheOperation().clearBoxes();
  }

  Box getBox(String name) {
    return interface().box(name);
  }

  HiveInterface interface() {
    return Hive;
  }

  void firstTimeDefaultWrite() async {}
}
