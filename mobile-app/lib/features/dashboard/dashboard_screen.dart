import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/profile_service.dart';
import '../../shared/widgets/app_sidebar_drawer.dart';
import '../credit_cards/credit_card_screen.dart';
import '../debts/debt_screen.dart';
import '../expenses/add_expense_screen.dart';
import '../expenses/expense_list_screen.dart';
import '../loans/loan_screen.dart';
import '../reminders/reminder_screen.dart';
import '../reports/report_screen.dart';
import '../rents/rent_screen.dart';
import '../savings/savings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? report;
  UserModel? user;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final now = DateTime.now();
    try {
      final results = await Future.wait([
        ApiService().get(
          '/reports/monthly',
          query: {'year': now.year, 'month': now.month},
        ),
        const ProfileService().getProfile(),
      ]);

      if (!mounted) return;
      setState(() {
        report = (results[0] as Map<String, dynamic>)['data'] as Map<String, dynamic>?;
        user = results[1] as UserModel;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => report = null);
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> openModule(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    await loadData();
  }

  @override
  Widget build(BuildContext context) {
    final data = report ?? <String, dynamic>{};
    final totalExpense = (data['totalExpense'] ?? 0) as num;
    final totalPaid = (data['totalPaid'] ?? 0) as num;
    final totalPending = (data['totalPending'] ?? 0) as num;
    final loanBalance = (data['loanBalance'] ?? 0) as num;
    final creditCardBalance = (data['creditCardBalance'] ?? 0) as num;
    final debtBalance = (data['debtBalance'] ?? 0) as num;
    final totalLiabilities = loanBalance + creditCardBalance + debtBalance;

    final modules = <_DashboardModule>[
      _DashboardModule(
        title: 'Expenses',
        subtitle: 'Daily spending',
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF5B6EF5),
        onTap: () => openModule(const ExpenseListScreen()),
      ),
      _DashboardModule(
        title: 'Loans',
        subtitle: 'EMI tracker',
        icon: Icons.account_balance_outlined,
        color: const Color(0xFF2EB67D),
        onTap: () => openModule(const LoanScreen()),
      ),
      _DashboardModule(
        title: 'Credit Cards',
        subtitle: 'Card dues and EMIs',
        icon: Icons.credit_card_outlined,
        color: const Color(0xFFF2A541),
        onTap: () => openModule(const CreditCardScreen()),
      ),
      _DashboardModule(
        title: 'BC Tracker',
        subtitle: 'Paid and left cycles',
        icon: Icons.groups_2_outlined,
        color: const Color(0xFFE35D6A),
        onTap: () => openModule(const CreditCardScreen(recordType: 'BC', pageTitle: 'BC Tracker')),
      ),
      _DashboardModule(
        title: 'Debts',
        subtitle: 'Money flow',
        icon: Icons.people_outline,
        color: const Color(0xFFE35D6A),
        onTap: () => openModule(const DebtScreen()),
      ),
      _DashboardModule(
        title: 'Rent',
        subtitle: 'Tenant dues',
        icon: Icons.home_work_outlined,
        color: const Color(0xFF0FA3B1),
        onTap: () => openModule(const RentScreen()),
      ),
      _DashboardModule(
        title: 'Reminders',
        subtitle: 'Due alerts',
        icon: Icons.notifications_active_outlined,
        color: const Color(0xFF6EC6FF),
        onTap: () => openModule(const ReminderScreen()),
      ),
      _DashboardModule(
        title: 'Reports',
        subtitle: 'Analytics',
        icon: Icons.bar_chart_outlined,
        color: const Color(0xFF9B8AFB),
        onTap: () => openModule(const ReportScreen()),
      ),
      _DashboardModule(
        title: 'Savings',
        subtitle: 'Insights',
        icon: Icons.savings_outlined,
        color: const Color(0xFF6EC6FF),
        onTap: () => openModule(const SavingsScreen()),
      ),
    ];

    return Scaffold(
      drawer: const AppSidebarDrawer(),
      appBar: AppBar(
        title: const Text('Home'),
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'dashboard_add_expense_fab',
        onPressed: () async {
          final changed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
          if (changed == true) {
            await loadData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  _HeroSummaryCard(
                    name: user?.firstName?.isNotEmpty == true ? user!.firstName! : 'there',
                    totalExpense: totalExpense.toDouble(),
                    totalPaid: totalPaid.toDouble(),
                    totalPending: totalPending.toDouble(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _CompactMetricCard(
                          title: 'This Month',
                          value: formatInr(totalExpense),
                          icon: Icons.currency_rupee,
                          color: const Color(0xFF5B6EF5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _CompactMetricCard(
                          title: 'Liabilities',
                          value: formatInr(totalLiabilities),
                          icon: Icons.account_balance_wallet_outlined,
                          color: const Color(0xFFE35D6A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionHeader(
                    title: 'Cash Flow Snapshot',
                    subtitle: 'Paid vs pending for this month',
                  ),
                  const SizedBox(height: 12),
                  _CashFlowCard(
                    paid: totalPaid.toDouble(),
                    pending: totalPending.toDouble(),
                  ),
                  const SizedBox(height: 18),
                  _SectionHeader(
                    title: 'Liability Overview',
                    subtitle: 'Outstanding balances across accounts',
                  ),
                  const SizedBox(height: 12),
                  _LiabilityBoard(
                    loanBalance: loanBalance.toDouble(),
                    creditCardBalance: creditCardBalance.toDouble(),
                    debtBalance: debtBalance.toDouble(),
                  ),
                  const SizedBox(height: 18),
                  _SectionHeader(
                    title: 'Quick Access',
                    subtitle: 'Jump into your most-used modules',
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: modules.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.18,
                    ),
                    itemBuilder: (context, index) {
                      final module = modules[index];
                      return _ModuleCard(module: module);
                    },
                  ),
                  const SizedBox(height: 18),
                  _SectionHeader(
                    title: 'Smart Insight',
                    subtitle: 'A small nudge to improve spending',
                  ),
                  const SizedBox(height: 12),
                  _InsightCard(
                    message: data['savingSuggestion'] as String? ??
                        'Add more expenses to unlock savings insights.',
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => openModule(const ExpenseListScreen()),
                    child: const Text('View All Expenses'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _HeroSummaryCard extends StatelessWidget {
  const _HeroSummaryCard({
    required this.name,
    required this.totalExpense,
    required this.totalPaid,
    required this.totalPending,
  });

  final String name;
  final double totalExpense;
  final double totalPaid;
  final double totalPending;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2A78), Color(0xFF5B6EF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x225B6EF5),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, $name',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your monthly finance pulse at a glance.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'This Month Expense',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatInr(totalExpense),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 118,
                height: 118,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 34,
                        sections: [
                          PieChartSectionData(
                            value: math.max(totalPaid, 0.1),
                            color: const Color(0xFF2ED3A1),
                            title: '',
                            radius: 16,
                          ),
                          PieChartSectionData(
                            value: math.max(totalPending, 0.1),
                            color: const Color(0xFFFFC857),
                            title: '',
                            radius: 16,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Pending',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white70,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatInr(totalPending),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _HeroChip(
                color: const Color(0x332ED3A1),
                bullet: const Color(0xFF2ED3A1),
                label: 'Paid',
                value: formatInr(totalPaid),
              ),
              const SizedBox(width: 10),
              _HeroChip(
                color: const Color(0x33FFC857),
                bullet: const Color(0xFFFFC857),
                label: 'Pending',
                value: formatInr(totalPending),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.color,
    required this.bullet,
    required this.label,
    required this.value,
  });

  final Color color;
  final Color bullet;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: bullet,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactMetricCard extends StatelessWidget {
  const _CompactMetricCard({
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
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

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

class _CashFlowCard extends StatelessWidget {
  const _CashFlowCard({
    required this.paid,
    required this.pending,
  });

  final double paid;
  final double pending;

  @override
  Widget build(BuildContext context) {
    final total = paid + pending;
    final paidRatio = total <= 0 ? 0.0 : paid / total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _LegendValue(
                    color: const Color(0xFF2ED3A1),
                    label: 'Paid',
                    value: formatInr(paid),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LegendValue(
                    color: const Color(0xFFFFC857),
                    label: 'Pending',
                    value: formatInr(pending),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 14,
                value: paidRatio,
                backgroundColor: const Color(0xFFFFE7B2),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF2ED3A1)),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                total <= 0
                    ? 'No payments recorded yet.'
                    : '${(paidRatio * 100).toStringAsFixed(0)}% of this month is already cleared.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendValue extends StatelessWidget {
  const _LegendValue({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LiabilityBoard extends StatelessWidget {
  const _LiabilityBoard({
    required this.loanBalance,
    required this.creditCardBalance,
    required this.debtBalance,
  });

  final double loanBalance;
  final double creditCardBalance;
  final double debtBalance;

  @override
  Widget build(BuildContext context) {
    final values = [loanBalance, creditCardBalance, debtBalance];
    final maxValue = values.fold<double>(0, math.max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _LiabilityRow(
              label: 'Loan Balance',
              value: loanBalance,
              color: const Color(0xFF5B6EF5),
              maxValue: maxValue,
              icon: Icons.account_balance_outlined,
            ),
            const SizedBox(height: 14),
            _LiabilityRow(
              label: 'Credit Card Balance',
              value: creditCardBalance,
              color: const Color(0xFFF2A541),
              maxValue: maxValue,
              icon: Icons.credit_card_outlined,
            ),
            const SizedBox(height: 14),
            _LiabilityRow(
              label: 'Debt Balance',
              value: debtBalance,
              color: const Color(0xFFE35D6A),
              maxValue: maxValue,
              icon: Icons.people_outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _LiabilityRow extends StatelessWidget {
  const _LiabilityRow({
    required this.label,
    required this.value,
    required this.color,
    required this.maxValue,
    required this.icon,
  });

  final String label;
  final double value;
  final Color color;
  final double maxValue;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue <= 0 ? 0.0 : value / maxValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
            Text(
              formatInr(value),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: ratio,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});

  final _DashboardModule module;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: module.onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: module.color.withValues(alpha: 0.1),
          border: Border.all(color: module.color.withValues(alpha: 0.18)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(module.icon, color: module.color),
              ),
              const Spacer(),
              Text(
                module.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                module.subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFFF7F8FF), Color(0xFFE9EEFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF5B6EF5).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome_outlined, color: Color(0xFF5B6EF5)),
          ),
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

class _DashboardModule {
  const _DashboardModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}
