import 'package:flutter/material.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/report_model.dart';
import '../../services/api_service.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  ReportModel? report;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    final now = DateTime.now();

    try {
      final res = await ApiService().get(
        '/reports/monthly',
        query: {'year': now.year, 'month': now.month},
      );
      if (!mounted) return;
      setState(() => report = ReportModel.fromJson((res['data'] as Map<String, dynamic>? ?? {})));
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = report;
    final biggestCategories = data?.byCategory.entries.toList()
      ?..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Savings Analyzer')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _ErrorState(message: error!, onRetry: load)
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            data?.savingSuggestion ??
                                'Add more expense data to get saving suggestions.',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.savings_outlined),
                          title: const Text('Potential 30% reduction on pending spend'),
                          subtitle: Text(
                            formatInr((data?.totalPending ?? 0) * 0.3),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Top Spending Categories',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      if (biggestCategories == null || biggestCategories.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No category spend available yet.'),
                          ),
                        )
                      else
                        ...biggestCategories.take(5).map(
                          (entry) => Card(
                            child: ListTile(
                              title: Text(entry.key),
                              trailing: Text(formatInr(entry.value)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
