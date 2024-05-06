import 'dart:math';

import 'package:yabnet/db_references/Members.dart';

import '../../components/CustomProject.dart';
import '../../supabase/SupabaseConfig.dart';
import '../db_references/Profile.dart';

class ProfileOperation {
  String generateIndexCode() {
    Random random = Random();
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ123456789";
    String combination = "";

    for (int i = 0; i < 14; i++) {
      combination += chars[random.nextInt(chars.length)];
    }

    return combination.toUpperCase();
  }

  static String getFullNameTextImage(String fullName) {
    if (fullName.length <= 1) {
      return fullName;
    }
    return "${fullName.split(" ").first[0]}${fullName.split(" ").length > 1 ? fullName.split(" ")[1][0] : ""}"
        .trim();
  }

  Future saveUserProfileIndex(String index, String userId) {
    return SupabaseConfig.client
        .from(dbReference(Members.table))
        .update({
          dbReference(Profile.image_index): index,
        })
        .eq(dbReference(Members.id), userId)
        .select(dbReference(Profile.image_index))
        .maybeSingle();
  }
}
