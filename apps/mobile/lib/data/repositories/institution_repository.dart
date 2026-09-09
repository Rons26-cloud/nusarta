import '../../core/data/supabase_client.dart';
import '../models/institution.dart';

class InstitutionRepository {
  InstitutionRepository._();

  static const _table = 'institutions';

  /// Lists active institutions from the catalog.
  static Future<List<Institution>> listActive() async {
    final rows = await SupabaseConfig.client
        .from(_table)
        .select()
        .eq('is_active', true)
        .order('name');
    return rows.map((r) => Institution.fromMap(r)).toList();
  }
}
