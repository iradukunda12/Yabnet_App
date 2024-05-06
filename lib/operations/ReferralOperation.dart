// import 'dart:async';
// import 'dart:math';
//
//
// import 'package:flutter/foundation.dart';
// import 'package:hive_flutter/adapters.dart';
//
// import '../components/CustomProject.dart';
// import '../db_references/Referral.dart';
// import '../db_references/Members.dart';
// import '../local_database.dart';
// import '../supabase/SupabaseConfig.dart';
//
// class ReferralOperation {
//   static int referralCodeLength = 7;
//
//   Future<void> initialize() {
//     return LocalDatabase().interface().openBox(dbReference(Referral.database));
//   }
//
//   ValueListenable<Box> listenable() {
//     return LocalDatabase().getBox(dbReference(Referral.database)).listenable();
//   }
//
//
//   List<ReferralData> getSavedReferralRecords(){
//     Box referralBox = LocalDatabase().getBox(dbReference(Referral.database));
//
//     List<dynamic>? allSavedReferralData = referralBox.values.toList();
//
//     if(allSavedReferralData.isNotEmpty){
//       return  allSavedReferralData.map((savedReferralRecordJson) => ReferralData.fromJsonMap(savedReferralRecordJson)).toList();
//     }else{
//       return [];
//     }
//
//   }
//
//   List<ReferralData> saveOnlineRecordAndGetSavedRecords(List<MapEntry<String, ReferralData>> listOfReferralData)  {
//
//     Box referralBox = LocalDatabase().getBox(dbReference(Referral.database));
//
//
//
//
//     for (var index = 0; index < listOfReferralData.length; index++) {
//
//       MapEntry<String, ReferralData> onlineRecord = listOfReferralData[index];
//
//       String onlineRecordKey = onlineRecord.key;
//       ReferralData onlineRecordValue = onlineRecord.value;
//
//       bool containSavedKey = referralBox.containsKey(onlineRecordKey);
//
//       if(!containSavedKey){
//         referralBox.put(onlineRecordKey, onlineRecordValue.toJsonMap());
//       }else{
//
//         Map<dynamic,dynamic> savedRecordValue = referralBox.get(onlineRecordKey);
//         ReferralData savedReferralData = ReferralData.fromJsonMap(savedRecordValue);
//
//         if(savedReferralData != onlineRecordValue){
//           referralBox.delete(onlineRecordKey);
//           referralBox.put(onlineRecordKey, onlineRecordValue.toJsonMap());
//         }
//
//       }
//
//     }
//
//     deleteSavedRecordFromList(listOfReferralData);
//     return getSavedReferralRecords();
//
//   }
//
//   void deleteSavedRecordFromList(
//       List<MapEntry<String, ReferralData>> listOfReferralData) {
//     Box referralBox = LocalDatabase().getBox(dbReference(Referral.database));
//
//     List<dynamic>? referralRecordKeys =
//         referralBox.keys.toList() ;
//
//     if (referralRecordKeys.isNotEmpty) {
//
//       for (var index = 0; index < referralRecordKeys.length; index++) {
//         String currentSavedRecordKey = referralRecordKeys[index];
//
//         bool containOnlineKey = listOfReferralData
//             .map((onlineRecord) => onlineRecord.key)
//             .contains(currentSavedRecordKey);
//
//         if (!containOnlineKey) {
//           referralBox.delete(currentSavedRecordKey);
//         }
//       }
//
//     }
//   }
//
//   String generateReferralCode() {
//     Random random = Random();
//     const chars =
//         "ABCDEFGHIJKLMNOPQRSTUVWXYZ123456789";
//     String combination = "";
//
//     for (int i = 0; i < referralCodeLength; i++) {
//       combination += chars[random.nextInt(chars.length)];
//     }
//
//     return combination.toUpperCase();
//   }
//
//   Future<dynamic> getReferralRecord(String referralId) async {
//     return await SupabaseConfig.client
//         .from(dbReference(User.table))
//         .select(dbReference(User.display_name))
//         .eq(dbReference(User.id), referralId)
//         .maybeSingle();
//   }
//
//   Stream<List<Map<String, dynamic>>> getOnlineReferredReferrals() {
//     return SupabaseConfig.client
//         .from(dbReference(Referral.table))
//         .stream(primaryKey: [dbReference(Referral.id)]).eq(
//             dbReference(Referral.to_user_id),
//             SupabaseConfig.client.auth.currentUser?.id);
//   }
//
//   Future<bool> verifyReferee(String referralCode) async {
//     return await SupabaseConfig.client
//         .from(dbReference(User.table))
//         .select(dbReference(dbReference(User.refer_id)))
//         .eq(dbReference(User.refer_id), referralCode)
//         .maybeSingle()
//         .then((value) {
//       if (value != null) {
//         return true;
//       } else {
//         return false;
//       }
//     }).onError((error, stackTrace) {
//       return false;
//     }).timeout(TimeOut.checkReferralTimeout);
//   }
//
//   Future<bool?> verifyReferId(String referralCode) async {
//     return await SupabaseConfig.client
//         .from(dbReference(User.table))
//         .select(dbReference(dbReference(User.refer_id)))
//         .eq(dbReference(User.refer_id), referralCode)
//         .maybeSingle()
//         .then((value) {
//           return value == null;
//         })
//         .onError((error, stackTrace) => false)
//         .timeout(TimeOut.checkReferralTimeout);
//   }
//
//   Future clearEntries() {
//     return LocalDatabase().getBox(dbReference(Referral.database)).clear();
//   }
// }
