import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:postgrest/src/postgrest_builder.dart';
import 'package:postgrest/src/types.dart';
import 'package:supabase/src/supabase_stream_builder.dart';
import 'package:yabnet/db_references/Subscription.dart';
import 'package:yabnet/operations/CacheOperation.dart';

import '../components/CustomProject.dart';
import '../db_references/Connect.dart';
import '../db_references/Members.dart';
import '../db_references/Plans.dart';
import '../db_references/Profession.dart';
import '../db_references/Profile.dart';
import '../supabase/SupabaseConfig.dart';

class MembersOperation {
  String foreignKey(
    String secondTable,
    String thisTable,
    String secondTableId,
  ) {
    return "$secondTable!${thisTable}_${secondTableId}_fkey";
  }

  String get userSelect =>
      "*,${foreignKey(dbReference(Subscriptions.table), dbReference(Members.table), dbReference(Subscriptions.id))}(*, ${foreignKey(dbReference(Plans.table), dbReference(Subscriptions.table), dbReference(Plans.id))}(*))";

  Future<ValueListenable<Box>?> listenable() async {
    return await CacheOperation().getListenable(dbReference(Members.database));
  }

  String getMemberProfileBucketPath(String id, String? index) {
    if (index == null) return '';
    final imagePath = "${id}_$index";
    return SupabaseConfig.client.storage
        .from(dbReference(Profile.bucket))
        .getPublicUrl(imagePath);
  }

  Future<dynamic> userOnlineRecord(String? userId) async {
    if (userId == null) return null;
    return await SupabaseConfig.client
        .from(dbReference(Members.table))
        .select()
        .eq(dbReference(Members.id), userId)
        .maybeSingle();
  }

  Future<dynamic> updateMembersSubscription(
      String subscriptionsId, String? userId) async {
    if (userId == null) return null;
    return await SupabaseConfig.client
        .from(dbReference(Members.table))
        .update({
          dbReference(Subscriptions.id): subscriptionsId,
        })
        .eq(dbReference(Members.id), userId)
        .select(userSelect)
        .maybeSingle();
  }

  Future<dynamic> userNewSessionAndOnlineRecord(
      String? userId, String sessionCode, String fcmToken) async {
    if (userId == null) return null;
    return await SupabaseConfig.client
        .from(dbReference(Members.table))
        .update({
          dbReference(Members.session_code): sessionCode,
          dbReference(Members.fcm_token): fcmToken
        })
        .eq(dbReference(Members.id), userId)
        .select(userSelect)
        .maybeSingle();
  }

  Stream<List<Map<String, dynamic>>> userOnlineRecordStream(String userId) {
    return SupabaseConfig.client
        .from(dbReference(Members.table))
        .stream(primaryKey: [dbReference(Members.id)]).eq(
            dbReference(Members.id), userId);
  }

  Future<PostgrestList> allFields() async {
    return await SupabaseConfig.client
        .from(dbReference(Profession.field))
        .select();
  }

  Future<PostgrestList> allUserOnlineNotInRecord(
      String profession, List<String> userIds) async {
    String? userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId != null) {
      userIds.add(userId);
    }
    return await SupabaseConfig.client
        .from(dbReference(Members.table))
        .select()
        .eq(dbReference(Members.profession), profession)
        .not(dbReference(Members.id), "in", userIds);
  }

  SupabaseStreamBuilder? thisUserConnects(String? userId) {
    if (userId == null) return null;
    return SupabaseConfig.client
        .from(dbReference(Connect.table))
        .stream(primaryKey: [dbReference(Connect.id)]).eq(
            dbReference(Connect.to), userId);
  }

  PostgrestTransformBuilder<PostgrestMap?> updateUserKnowsAboutUs(
      String userId, bool knows) {
    return SupabaseConfig.client
        .from(dbReference(Members.table))
        .update({dbReference(Members.knows_us): knows})
        .eq(dbReference(Members.id), userId)
        .select()
        .maybeSingle();
  }

  SupabaseStreamBuilder? thisUserConnections(String? userId) {
    if (userId == null) return null;
    return SupabaseConfig.client
        .from(dbReference(Connect.table))
        .stream(primaryKey: [dbReference(Connect.id)]).eq(
            dbReference(Members.id), userId);
  }

  Future<bool> userDataExistLocal() async {
    return (await CacheOperation().getCacheData(
            dbReference(Members.database), dbReference(Members.record))) !=
        null;
  }

  Future<bool> userLocalVerificationData(String uuid) async {
    return (await CacheOperation().getCacheData(
            dbReference(Members.verification_database),
            dbReference(Members.verification))) ==
        uuid;
  }

  Future<bool> setUserLocalVerification(String uuid) async {
    return CacheOperation().saveCacheData(
        dbReference(Members.verification_database),
        dbReference(Members.verification),
        uuid);
  }

  static Future<bool> updateTheValue(String column, dynamic value,
      {bool forceUpdate = false}) async {
    dynamic record = await CacheOperation().getCacheData(
        dbReference(Members.database), dbReference(Members.record));
    if (record != null && record is Map<dynamic, dynamic>) {
      if (record[column] != value || forceUpdate) {
        record[column] = value;
        return CacheOperation().saveCacheData(
            dbReference(Members.database), dbReference(Members.record), record);
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  Future<PostgrestMap?> updateUserRecordBothOnlineAndLocal(
      String id,
      String lastName,
      String firstName,
      String bio,
      String location,
      String church,
      String address) async {
    return await SupabaseConfig.client
        .from(dbReference(Members.table))
        .update({
          dbReference(Members.lastname): lastName,
          dbReference(Members.firstname): firstName,
          dbReference(Members.bio): bio,
          dbReference(Members.location): location,
          dbReference(Members.church): church,
          dbReference(Members.address): address,
        })
        .eq(dbReference(Members.id), id)
        .select()
        .maybeSingle()
        .then((value) async {
          await updateTheValue(dbReference(Members.lastname), lastName);
          await updateTheValue(dbReference(Members.firstname), firstName);
          await updateTheValue(dbReference(Members.bio), bio);
          await updateTheValue(dbReference(Members.location), location);
          await updateTheValue(dbReference(Members.church), church);
          await updateTheValue(dbReference(Members.address), address);
          return value;
        });
  }

  Future<bool> insertUserRecordBothOnlineAndLocal(
      String uuid,
      String lastName,
      String firstName,
      String bio,
      String email,
      String location,
      String address,
      String gender,
      String phone,
      String phone_code,
      String privacy_policy,
      String session_code,
      String fcm_token,
      String dob,
      String field,
      String church,
      String referId,
      String referee) async {
    return await SupabaseConfig.client
        .from(dbReference(Members.table))
        .insert({
          dbReference(Members.id): uuid,
          dbReference(Members.lastname): lastName,
          dbReference(Members.firstname): firstName,
          dbReference(Members.bio): bio,
          dbReference(Members.location): location,
          dbReference(Members.address): address,
          dbReference(Members.gender): gender,
          dbReference(Members.dob): dob,
          dbReference(Members.profession): field,
          dbReference(Members.church): church,
          dbReference(Members.phone_no): phone,
          dbReference(Members.phone_code): phone_code,
          dbReference(Members.privacy_policy): privacy_policy,
          dbReference(Members.session_code): session_code,
          dbReference(Members.fcm_token): fcm_token,
          dbReference(Members.email): email,
        })
        .select()
        .maybeSingle()
        .then((userData) {
          if (userData != null) {
            saveOnlineUserRecordToLocal(userData);
          }
          return true;
        })
        .onError((error, stackTrace) {
          showDebug(msg: "$error $stackTrace");

          return false;
        });
  }

  Future<String> getFullName() async {
    String lastname = await MembersOperation()
        .getUserRecord(field: dbReference(Members.lastname));
    String firstname = await MembersOperation()
        .getUserRecord(field: dbReference(Members.firstname));
    return "$lastname $firstname";
  }

  Future<bool> saveOnlineUserRecordToLocal(dynamic data,
      {bool useOther = false}) async {
    if (data == null && useOther) {
      return false;
    }

    return CacheOperation().saveCacheData(
        dbReference(Members.database), dbReference(Members.record), data);
  }

  Future<dynamic> getUserRecord({String? field}) async {
    final record = await CacheOperation().getCacheData(
        dbReference(Members.database), dbReference(Members.record));
    if (record is Map) {
      if (field != null) {
        return record[field];
      } else {
        return record;
      }
    } else {
      return record;
    }
  }

  Future<List<bool>> removeExistedUserRecord() async {
    return await CacheOperation().clearBoxes();
  }

  String getSessionCode() {
    Random random = Random();
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ123456789";
    String combination = "";

    for (int i = 0; i < 6; i++) {
      combination += chars[random.nextInt(chars.length)];
    }

    return combination.toUpperCase();
  }

  String formatFullName(String input) {
    if (input.isEmpty) {
      return input;
    }

    // Split the input string by spaces
    List<String> words = input.split(' ');

    // Capitalize the first letter of each word
    for (int i = 0; i < words.length; i++) {
      if (words[i].isNotEmpty) {
        words[i] = words[i][0].toUpperCase() + words[i].substring(1);
      }
    }

    // Join the words back together with spaces
    return words.join(' ');
  }
}
