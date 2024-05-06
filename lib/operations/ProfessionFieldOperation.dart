import 'package:postgrest/src/types.dart';

import '../components/CustomProject.dart';
import '../db_references/Profession.dart';
import '../supabase/SupabaseConfig.dart';

class ProfessionFieldOperation {
  Future<PostgrestList> getProfessionList() async {
    return await SupabaseConfig.client
        .from(dbReference(Profession.field))
        .select();
  }
}
