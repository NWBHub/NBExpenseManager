import 'package:flutter/material.dart';

import '../../shared/widgets/app_sidebar_drawer.dart';
import '../billing/shopkeeper_statement_screen.dart';
import '../credit_cards/credit_card_screen.dart';
import '../debts/debt_screen.dart';
import '../loans/loan_screen.dart';
import '../reports/report_screen.dart';
import '../rents/rent_screen.dart';
import '../savings/savings_screen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  Future<void> openScreen(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppSidebarDrawer(),
      appBar: AppBar(
        title: const Text('More'),
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
                  _SectionTitle(
                    title: 'Billing & Analytics',
                    subtitle: 'Generate monthly reports and share vendor statements',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionFeatureCard(
                          icon: Icons.insert_chart_outlined,
                          color: const Color(0xFF5B6EF5),
                          title: 'Reports',
                          subtitle: 'Expense analytics',
                          onTap: () => openScreen(const ReportScreen()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionFeatureCard(
                          icon: Icons.receipt_long_outlined,
                          color: const Color(0xFF2EB67D),
                          title: 'Statements',
                          subtitle: 'Ledger summary',
                          onTap: () => openScreen(const ShopkeeperStatementScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle(
                    title: 'Finance Modules',
                    subtitle: 'Balance tracking across your money buckets',
                  ),
                  const SizedBox(height: 12),
                  _MoreTile(
                    icon: Icons.account_balance_outlined,
                    title: 'Loans',
                    subtitle: 'Manage EMIs and balances',
                    onTap: () => openScreen(const LoanScreen()),
                  ),
                  _MoreTile(
                    icon: Icons.credit_card_outlined,
                    title: 'Credit Cards',
                    subtitle: 'Track limits, bills, and EMI progress',
                    onTap: () => openScreen(const CreditCardScreen()),
                  ),
                  _MoreTile(
                    icon: Icons.groups_2_outlined,
                    title: 'BC Tracker',
                    subtitle: 'Track paid cycles, left cycles, and completion',
                    onTap: () => openScreen(
                      const CreditCardScreen(recordType: 'BC', pageTitle: 'BC Tracker'),
                    ),
                  ),
                  _MoreTile(
                    icon: Icons.people_outline,
                    title: 'Debts',
                    subtitle: 'Record money given and returned',
                    onTap: () => openScreen(const DebtScreen()),
                  ),
                  _MoreTile(
                    icon: Icons.home_work_outlined,
                    title: 'Rent Collection',
                    subtitle: 'Track shop or apartment rent and send reminders',
                    onTap: () => openScreen(const RentScreen()),
                  ),
                  _MoreTile(
                    icon: Icons.savings_outlined,
                    title: 'Savings',
                    subtitle: 'View saving opportunities',
                    onTap: () => openScreen(const SavingsScreen()),
                  ),
                ],
              ),
    );
  }
}

class _ActionFeatureCard extends StatelessWidget {
  const _ActionFeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
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

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
