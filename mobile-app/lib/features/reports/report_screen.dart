import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/report_model.dart';
import '../../services/api_service.dart';
import '../../shared/widgets/app_sidebar_drawer.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late DateTime selectedMonth;
  ReportModel? report;
  bool loading = true;
  String? error;

  static const _chartColors = <Color>[
    Color(0xFF5B6EF5),
    Color(0xFF2EB67D),
    Color(0xFFF2A541),
    Color(0xFFE35D6A),
    Color(0xFF6EC6FF),
    Color(0xFF9B8AFB),
  ];

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await ApiService().get(
        '/reports/monthly',
        query: {
          'year': selectedMonth.year,
          'month': selectedMonth.month,
        },
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

  void changeMonth(int offset) {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + offset);
    });
    load();
  }

  @override
  Widget build(BuildContext context) {
    final data = report;
    final categoryEntries = data?.byCategory.entries.toList() ?? [];
    categoryEntries.sort((a, b) => b.value.compareTo(a.value));
    final topCategories = categoryEntries.take(5).toList();

    return Scaffold(
      drawer: const AppSidebarDrawer(),
      appBar: AppBar(
        title: const Text('Reports'),
        actions: const [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: Text(
                'NBExpenseManager',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _ErrorState(message: error!, onRetry: load)
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      _MonthCalendarPicker(
                        selectedDate: selectedMonth,
                        onChanged: (value) {
                          setState(() {
                            selectedMonth = DateTime(value.year, value.month);
                          });
                          load();
                        },
                      ),
                      const SizedBox(height: 16),
                      if (data != null) ...[
                        _InsightBanner(message: data.savingSuggestion),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Total Expense',
                                value: formatInr(data.totalExpense),
                                icon: Icons.currency_rupee,
                                color: const Color(0xFF5B6EF5),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'Paid',
                                value: formatInr(data.totalPaid),
                                icon: Icons.check_circle_outline,
                                color: const Color(0xFF2EB67D),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                title: 'Pending',
                                value: formatInr(data.totalPending),
                                icon: Icons.pending_actions,
                                color: const Color(0xFFF2A541),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                title: 'Top Category',
                                value: topCategories.isEmpty
                                    ? 'No data'
                                    : topCategories.first.key,
                                icon: Icons.insights_outlined,
                                color: const Color(0xFF9B8AFB),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (topCategories.isNotEmpty) ...[
                          _SectionTitle(
                            title: 'Category Analytics',
                            subtitle: 'Where most of your monthly spending went',
                          ),
                          const SizedBox(height: 12),
                          _CategoryAnalyticsCard(
                            items: topCategories,
                            colors: _chartColors,
                          ),
                          const SizedBox(height: 20),
                        ],
                        _SectionTitle(
                          title: 'Payment vs Liability',
                          subtitle: 'Quick comparison of cleared amounts and balances',
                        ),
                        const SizedBox(height: 12),
                        _ComparisonChartCard(
                          paid: data.totalPaid,
                          pending: data.totalPending,
                          loanBalance: data.loanBalance,
                          creditCardBalance: data.creditCardBalance,
                          debtBalance: data.debtBalance,
                        ),
                        const SizedBox(height: 20),
                        _SectionTitle(
                          title: 'Liabilities Snapshot',
                          subtitle: 'Outstanding balances across key buckets',
                        ),
                        const SizedBox(height: 12),
                        _LiabilitySummaryCard(data: data),
                      ] else
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No expense data available for this month.'),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _MonthCalendarPicker extends StatelessWidget {
  const _MonthCalendarPicker({
    required this.selectedDate,
    required this.onChanged,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Expense Calendar',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat('MMMM yyyy').format(selectedDate),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            CalendarDatePicker(
              initialDate: selectedDate,
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
              onDateChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightBanner extends StatelessWidget {
  const _InsightBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2FF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_graph_rounded, color: Color(0xFF5B6EF5)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _CategoryAnalyticsCard extends StatelessWidget {
  const _CategoryAnalyticsCard({
    required this.items,
    required this.colors,
  });

  final List<MapEntry<String, double>> items;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (sum, item) => sum + item.value);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 48,
                  sections: List.generate(items.length, (index) {
                    final item = items[index];
                    final color = colors[index % colors.length];
                    final percentage = total <= 0 ? 0 : (item.value / total) * 100;

                    return PieChartSectionData(
                      color: color,
                      value: math.max(item.value, 0.1),
                      title: '${percentage.toStringAsFixed(0)}%',
                      radius: 56,
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(items.length, (index) {
              final item = items[index];
              final color = colors[index % colors.length];
              final percentage = total <= 0 ? 0 : (item.value / total) * 100;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.key,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text('${percentage.toStringAsFixed(0)}%'),
                    const SizedBox(width: 10),
                    Text(
                      formatInr(item.value),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ComparisonChartCard extends StatelessWidget {
  const _ComparisonChartCard({
    required this.paid,
    required this.pending,
    required this.loanBalance,
    required this.creditCardBalance,
    required this.debtBalance,
  });

  final double paid;
  final double pending;
  final double loanBalance;
  final double creditCardBalance;
  final double debtBalance;

  @override
  Widget build(BuildContext context) {
    final values = <double>[
      paid,
      pending,
      loanBalance,
      creditCardBalance,
      debtBalance,
    ];
    final maxValue = values.fold<double>(0, math.max);
    final double top = maxValue <= 0 ? 100 : maxValue * 1.25;

    final bars = [
      _BarData('Paid', paid, const Color(0xFF2EB67D)),
      _BarData('Pending', pending, const Color(0xFFF2A541)),
      _BarData('Loan', loanBalance, const Color(0xFF5B6EF5)),
      _BarData('Card', creditCardBalance, const Color(0xFFE35D6A)),
      _BarData('Debt', debtBalance, const Color(0xFF6EC6FF)),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: top,
                  gridData: const FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: 50,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= bars.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              bars[index].label,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(
                    bars.length,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: bars[index].value,
                          width: 22,
                          borderRadius: BorderRadius.circular(8),
                          color: bars[index].color,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: bars
                  .map(
                    (bar) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: bar.color,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(bar.label),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiabilitySummaryCard extends StatelessWidget {
  const _LiabilitySummaryCard({required this.data});

  final ReportModel data;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Loan Balance', data.loanBalance, Icons.account_balance_outlined),
      ('Credit Card Balance', data.creditCardBalance, Icons.credit_card_outlined),
      ('Debt Balance', data.debtBalance, Icons.people_outline),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    children: [
                      Icon(item.$3),
                      const SizedBox(width: 12),
                      Expanded(child: Text(item.$1)),
                      Text(
                        formatInr(item.$2),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _BarData {
  const _BarData(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
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
