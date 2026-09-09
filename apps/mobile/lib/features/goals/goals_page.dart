import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/finance.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_providers.dart';
import '../../widgets/empty_state.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tujuan Keuangan')),
      body: goals.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Gagal memuat tujuan')),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.flag_outlined,
              title: 'Belum ada tujuan keuangan',
              message: 'Tentukan target keuanganmu, misalnya dana darurat.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final g = list[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g.name,
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: g.progress,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                color: g.progress >= 1
                                    ? AppColors.primary
                                    : AppColors.accent,
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_format(g.current)} dari ${_format(g.target)}'
                              ' (${(g.progress * 100).toStringAsFixed(0)}%)',
                              style: const TextStyle(
                                  color: AppColors.neutral, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            color: AppColors.primary,
                            tooltip: 'Ubah tujuan',
                            onPressed: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => _EditGoalSheet(goal: g),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: AppColors.expense,
                            tooltip: 'Hapus tujuan',
                            onPressed: () => _confirmDelete(context, ref, g),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _AddGoalSheet(),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Tujuan'),
      ),
    );
  }

  String _format(double v) => NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp',
        decimalDigits: 0,
      ).format(v);

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, FinancialGoal g) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus tujuan ini?'),
        content: const Text('Tujuan keuangan akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(goalsControllerProvider).delete(g.id);
  }
}

class _AddGoalSheet extends ConsumerStatefulWidget {
  const _AddGoalSheet();

  @override
  ConsumerState<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<_AddGoalSheet> {
  final _name = TextEditingController();
  final _target = TextEditingController();
  final _current = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _current.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Tambah Tujuan',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Nama Tujuan'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _target,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Target (Rp)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _current,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Progres saat ini (Rp)'),
            ),
            const SizedBox(height: 8),
            Text(
              'Catatan: ini pelacakan tujuan manual, bukan transfer '
              'tabungan sungguhan ke rekening terpisah.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.neutral),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving
                  ? null
                  : () async {
                      final name = _name.text.trim();
                      final target =
                          double.tryParse(_target.text.replaceAll(',', '')) ??
                              0;
                      final current =
                          double.tryParse(_current.text.replaceAll(',', '')) ??
                              0;
                      if (name.isEmpty || target <= 0) return;
                      setState(() => _saving = true);
                      final userId = ref.read(currentUserProvider)?.id ?? '';
                      await ref.read(goalsControllerProvider).create(
                            FinancialGoal(
                              id: '',
                              userId: userId,
                              name: name,
                              target: target,
                              current: current,
                            ),
                          );
                      if (context.mounted) Navigator.pop(context);
                    },
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditGoalSheet extends ConsumerStatefulWidget {
  const _EditGoalSheet({required this.goal});

  final FinancialGoal goal;

  @override
  ConsumerState<_EditGoalSheet> createState() => _EditGoalSheetState();
}

class _EditGoalSheetState extends ConsumerState<_EditGoalSheet> {
  late final TextEditingController _name;
  late final TextEditingController _target;
  late final TextEditingController _current;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _name = TextEditingController(text: g.name);
    _target = TextEditingController(text: g.target.toStringAsFixed(0));
    _current = TextEditingController(text: g.current.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _current.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ubah Tujuan', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _name,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Nama Tujuan'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _target,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Target (Rp)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _current,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Progres saat ini (Rp)'),
            ),
            const SizedBox(height: 8),
            Text(
              'Catatan: ini pelacakan tujuan manual, bukan transfer '
              'tabungan sungguhan ke rekening terpisah.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.neutral),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving
                  ? null
                  : () async {
                      final name = _name.text.trim();
                      final target =
                          double.tryParse(_target.text.replaceAll(',', '')) ??
                              0;
                      final current =
                          double.tryParse(_current.text.replaceAll(',', '')) ??
                              0;
                      if (name.isEmpty || target <= 0) return;
                      setState(() => _saving = true);
                      final g = widget.goal;
                      await ref.read(goalsControllerProvider).update(
                            FinancialGoal(
                              id: g.id,
                              userId: g.userId,
                              name: name,
                              target: target,
                              current: current,
                              deadline: g.deadline,
                            ),
                          );
                      if (context.mounted) Navigator.pop(context);
                    },
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
