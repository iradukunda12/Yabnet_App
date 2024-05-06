//
// import 'package:agame/collections/agame_asset/AGameMusics.dart';
// import 'package:agame/components/CustomProject.dart';
// import 'package:agame/db_references/Setting.dart';
// import 'package:agame/local_database.dart';
// import 'package:flutter/src/foundation/change_notifier.dart';
// import 'package:hive_flutter/adapters.dart';
//
// import '../components/CustomProject.dart';
// import '../db_references/Setting.dart';
// import '../local_database.dart';
//
// class SettingsOperation{
//
//
//   Future<void> initialize (){
//     return LocalDatabase().interface().openBox(dbReference(Setting.database));
//  }
//
//  ValueListenable<Box> listenable (){
//     return LocalDatabase().getBox(dbReference(Setting.database)).listenable();
//  }
//
//   void defaultBackgroundMusicSettings() async {
//    // Open Settings Box
//
//     final settingBox =  LocalDatabase().getBox(dbReference(Setting.database));
//
//     //  Settings[Background Music]
//     bool? previousData = settingBox.get(dbReference(Setting.active_music));
//     if(previousData == null){
//       var allMusics =  AGameMusics().getAllMusics();
//       await setMusicActive(true);
//       await setPlayingMusics(allMusics);
//     }
//
//
//   }
//
//   Future<void> setMusicActive(bool active){
//     Box settingBox = LocalDatabase().getBox(dbReference(Setting.database));
//     return settingBox.put(dbReference(Setting.active_music), active);
//   }
//   Future<void> setPlayingMusics(List<String> playingMusics){
//     Box settingBox = LocalDatabase().getBox(dbReference(Setting.database));
//     return settingBox.put(dbReference(Setting.playing_musics),playingMusics);
//   }
//
//   bool? getMusicActive(){
//     Box settingBox = LocalDatabase().getBox(dbReference(Setting.database));
//
//     bool? musicActive = settingBox.get(dbReference(Setting.active_music));
//     return musicActive;
//   }
//
//   List<String>? playingMusics(){
//     Box settingBox = LocalDatabase().getBox(dbReference(Setting.database));
//     List<String>? playingMusics = settingBox.get(dbReference(Setting.playing_musics));
//     return playingMusics;
//   }
//
//
//   Future clearEntries(){
//     return LocalDatabase().getBox(dbReference(Setting.database)).clear();
//   }
//
//
// }
