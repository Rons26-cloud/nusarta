import '../../core/data/supabase_client.dart';
import '../models/category.dart';
import '../models/transaction.dart';

class CategoryRepository {
  CategoryRepository._();

  static const _table = 'categories';

  static Future<List<Category>> list({TransactionKind? kind}) async {
    var query = SupabaseConfig.client.from(_table).select();
    if (kind != null) query = query.eq('kind', kind.name);
    final rows = await query.order('name');
    return rows.map((r) => Category.fromMap(r)).toList();
  }

  static Future<Category> create(Category c) async {
    final rows = await SupabaseConfig.client
        .from(_table)
        .insert(c.toMap())
        .select()
        .single();
    return Category.fromMap(rows);
  }

  static Future<void> update(Category c) async {
    final map = c.toMap()..remove('user_id');
    await SupabaseConfig.client.from(_table).update(map).eq('id', c.id);
  }

  static Future<void> delete(String id) async {
    await SupabaseConfig.client.from(_table).delete().eq('id', id);
  }
}
