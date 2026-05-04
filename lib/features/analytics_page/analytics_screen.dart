// lib/features/analytics/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:splitzon/core/constants/app_colors.dart';
import 'package:splitzon/provider/user_providers.dart';
import 'package:splitzon/providers/expense_provider.dart';
import 'analytics_controller.dart';

class AnalyticsScreen extends StatelessWidget {
  final String? groupId;
  final String title;

  const AnalyticsScreen({super.key, this.groupId, required this.title});

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<UserProviders>().user?.id ?? '';

    return ChangeNotifierProvider(
      create: (_) => AnalyticsController(
        expenseProvider: context.read<ExpenseProvider>(),
        groupId: groupId,
        currentUserId: currentUserId,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Consumer<AnalyticsController>(
          builder: (context, controller, _) {
            final total = controller.totalSpending;
            final categoryData = controller.getCategoryData();

            if (total == 0) {
              return const Center(
                child: Text(
                  "No expenses recorded yet",
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTotalCard(total, groupId == null),
                  const SizedBox(height: 32),

                  if (groupId == null) ...[
                    const Text(
                      "SPENDING BY GROUP",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildGroupBarChart(controller),
                    const SizedBox(height: 40),
                  ],

                  const Text(
                    "CATEGORY BREAKDOWN",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 260,
                    child: _CategoryPieChart(controller: controller),
                  ),
                  const SizedBox(height: 24),
                  _buildCategoryList(categoryData, total),

                  const SizedBox(height: 40),

                  if (groupId != null)
                    _buildMemberContributions(controller)
                  else
                    _buildMySpendingAcrossGroups(controller),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTotalCard(double total, bool isGlobal) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF334155), Color(0xFF1E2937)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            isGlobal ? "TOTAL SPEND ACROSS ALL GROUPS" : "TOTAL GROUP SPEND",
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text(
            "₹${total.toStringAsFixed(0)}",
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Bar Chart with Group Name + Amount on Top
  Widget _buildGroupBarChart(AnalyticsController controller) {
    final data = controller.getGroupComparisonData();
    if (data.isEmpty) return const SizedBox.shrink();

    final maxY = data.values.reduce((a, b) => a > b ? a : b) * 1.2;

    return Container(
      height: 310,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barTouchData: const BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final groupIds = data.keys.toList();
                  if (value.toInt() >= groupIds.length) return const SizedBox();
                  final gid = groupIds[value.toInt()];
                  final name = controller.getGroupName(gid);
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      name.length > 10 ? "${name.substring(0, 10)}..." : name,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: data.entries.map((entry) {
            final index = data.keys.toList().indexOf(entry.key);
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  color: const Color(0xFF64748B),
                  width: 34,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryList(Map<String, double> data, double total) {
    return Column(
      children: data.entries.map((e) {
        final percent = total > 0 ? (e.value / total) * 100 : 0.0;
        final color =
            Colors.primaries[data.keys.toList().indexOf(e.key) %
                Colors.primaries.length];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(Icons.category, color: color),
            ),
            title: Text(
              e.key,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text("${percent.toStringAsFixed(1)}%"),
            trailing: Text(
              "₹${e.value.toStringAsFixed(0)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMemberContributions(AnalyticsController controller) {
    final contributions = controller.getMemberContributions();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "MEMBER CONTRIBUTIONS",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        ...contributions.entries.map(
          (e) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(child: Text(e.key[0])),
              title: Text(e.key),
              trailing: Text(
                "₹${e.value.toStringAsFixed(0)}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMySpendingAcrossGroups(AnalyticsController controller) {
    final myData = controller.getMyDetailedSpendingPerGroup();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "MY SPENDING ACROSS GROUPS",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        ...myData.entries.map((entry) {
          final groupId = entry.key;
          final groupName = controller.getGroupName(groupId);
          final paid = entry.value['paid'] ?? 0.0;
          final owedToMe = entry.value['owedToMe'] ?? 0.0;
          final iOwe = entry.value['iOwe'] ?? 0.0;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    groupName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSmallStat("I Paid", paid, Colors.blue),
                      _buildSmallStat("Owed to Me", owedToMe, Colors.green),
                      _buildSmallStat("I Owe", iOwe, Colors.red),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSmallStat(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          "₹${amount.toStringAsFixed(0)}",
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

// Category Pie Chart
class _CategoryPieChart extends StatelessWidget {
  final AnalyticsController controller;
  const _CategoryPieChart({required this.controller});

  @override
  Widget build(BuildContext context) {
    final data = controller.getCategoryData();
    if (data.isEmpty) return const Center(child: Text("No category data"));

    return PieChart(
      PieChartData(
        sectionsSpace: 6,
        centerSpaceRadius: 60,
        sections: data.entries.map((e) {
          final index = data.keys.toList().indexOf(e.key);
          final percent = (e.value / controller.totalSpending) * 100;
          final color = Colors.primaries[index % Colors.primaries.length];

          return PieChartSectionData(
            value: e.value,
            title: '${percent.toStringAsFixed(0)}%',
            color: color,
            radius: 70,
            titleStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList(),
      ),
    );
  }
}
