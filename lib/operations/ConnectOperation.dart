import 'package:supabase_flutter/supabase_flutter.dart';

import '../components/CustomProject.dart';
import '../db_references/Connect.dart';
import '../db_references/Members.dart';
import '../supabase/SupabaseConfig.dart';

class ConnectOperation {
  PostgrestFilterBuilder connectToMember(String membersId, String userId) {
    return SupabaseConfig.client.from(dbReference(Connect.table)).insert({
      dbReference(Connect.to): membersId,
      dbReference(Members.id): userId,
    });
  }

  PostgrestFilterBuilder disconnectMember(String membersId, String userId) {
    return SupabaseConfig.client
        .from(dbReference(Connect.table))
        .delete()
        .match({
      dbReference(Connect.to): membersId,
      dbReference(Members.id): userId,
    });
  }
}
