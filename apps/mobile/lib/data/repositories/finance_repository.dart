import '../../core/data/supabase_client.dart';
import '../models/finance.dart';

class BudgetRepository {
  BudgetRepository._();

  static const _table = 'budgets';

  static Future<List<Budget>> listAll() async {
    final rows = await SupabaseConfig.client.from(_table).select();
    return rows.map((r) => Budget.fromMap(r)).toList();
  }

  static Future<Budget> create(Budget b) async {
    final rows = await SupabaseConfig.client
        .from(_table)
        .insert(b.toMap())
        .select()
        .single();
    return Budget.fromMap(rows);
  }

  static Future<void> update(Budget b) async {
    final map = b.toMap()..remove('user_id');
    await SupabaseConfig.client.from(_table).update(map).eq('id', b.id);
  }

  static Future<void> delete(String id) async {
    await SupabaseConfig.client.from(_table).delete().eq('id', id);
  }
}

class GoalRepository {
  GoalRepository._();

  static const _table = 'financial_goals';

  static Future<List<FinancialGoal>> listActive() async {
    final rows = await SupabaseConfig.client
        .from(_table)
        .select()
        .eq('is_archived', false)
        .order('created_at');
    return rows.map((r) => FinancialGoal.fromMap(r)).toList();
  }

  static Future<FinancialGoal> create(FinancialGoal g) async {
    final rows = await SupabaseConfig.client
        .from(_table)
        .insert(g.toMap())
        .select()
        .single();
    return FinancialGoal.fromMap(rows);
  }

  static Future<void> update(FinancialGoal g) async {
    final map = g.toMap()..remove('user_id');
    await SupabaseConfig.client.from(_table).update(map).eq('id', g.id);
  }

  static Future<void> delete(String id) async {
    await SupabaseConfig.client.from(_table).delete().eq('id', id);
  }
}
