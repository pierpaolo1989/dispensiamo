import 'dart:math' as math;

import 'package:dispensiamo/l10n/app_strings.dart';
import 'package:dispensiamo/model/purchase_statistics.dart';
import 'package:dispensiamo/service/database_service.dart';
import 'package:dispensiamo/theme/app_theme.dart';
import 'package:flutter/material.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  List<Map<String, dynamic>> _products = [];
  Object? _loadError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _endDate = DateTime(today.year, today.month, today.day);
    _startDate = _endDate.subtract(const Duration(days: 29));
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final products = await DatabaseService.getAllProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final strings = AppStrings.of(context);
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      helpText: strings.dateRange,
    );
    if (range == null || !mounted) return;
    setState(() {
      _startDate =
          DateTime(range.start.year, range.start.month, range.start.day);
      _endDate = DateTime(range.end.year, range.end.month, range.end.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final statistics = PurchaseStatistics.fromProducts(
      _products,
      startDate: _startDate,
      endDate: _endDate,
    );

    return Scaffold(
      appBar: AppBar(title: Text(strings.spendingStatistics)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${strings.spendingLoadError} $_loadError',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _loadProducts,
                          child: Text(strings.retry),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    OutlinedButton.icon(
                      onPressed: _selectDateRange,
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(
                        '${MaterialLocalizations.of(context).formatMediumDate(_startDate)}'
                        '${strings.dateRangeSeparator}'
                        '${MaterialLocalizations.of(context).formatMediumDate(_endDate)}',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatisticCard(
                            title: strings.totalSpending,
                            value: '€${statistics.total.toStringAsFixed(2)}',
                            icon: Icons.euro_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatisticCard(
                            title: strings.productsPurchased,
                            value: '${statistics.productCount}',
                            icon: Icons.shopping_basket_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      strings.dailySpending,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (statistics.buckets.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Text(
                          strings.noSpendingInRange,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      )
                    else
                      _SpendingChart(buckets: statistics.buckets),
                    if (_products.any(
                      (product) => product['purchase_date'] == null,
                    )) ...[
                      const SizedBox(height: 16),
                      Text(
                        strings.spendingDataUnavailable,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        color: const Color(0xFFF8F8F5),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.muted),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      );
}

class _SpendingChart extends StatelessWidget {
  const _SpendingChart({required this.buckets});

  final List<SpendingBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final maxAmount = buckets.fold<double>(
      0,
      (maximum, bucket) => math.max(maximum, bucket.amount),
    );
    final chartWidth = math.max(
      MediaQuery.sizeOf(context).width - 40,
      buckets.length * 52.0,
    );
    final localizations = MaterialLocalizations.of(context);

    return Card(
      color: const Color(0xFFF8F8F5),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: chartWidth,
            child: Column(
              children: [
                SizedBox(
                  height: 190,
                  width: chartWidth,
                  child: CustomPaint(
                    painter: _SpendingChartPainter(
                      buckets: buckets,
                      maxAmount: maxAmount,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final bucket in buckets)
                      SizedBox(
                        width: 52,
                        child: Text(
                          localizations.formatShortDate(bucket.date),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpendingChartPainter extends CustomPainter {
  const _SpendingChartPainter({
    required this.buckets,
    required this.maxAmount,
  });

  final List<SpendingBucket> buckets;
  final double maxAmount;

  @override
  void paint(Canvas canvas, Size size) {
    const horizontalInset = 10.0;
    const verticalInset = 8.0;
    final chartHeight = size.height - verticalInset * 2;
    final gridPaint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    for (var index = 0; index <= 4; index++) {
      final y = verticalInset + chartHeight * index / 4;
      canvas.drawLine(
        Offset(horizontalInset, y),
        Offset(size.width - horizontalInset, y),
        gridPaint,
      );
    }

    final barPaint = Paint()
      ..color = AppColors.acidGreen
      ..style = PaintingStyle.fill;
    for (var index = 0; index < buckets.length; index++) {
      final bucket = buckets[index];
      final barHeight = maxAmount == 0
          ? 0.0
          : (bucket.amount / maxAmount) * (chartHeight - 8);
      final left = horizontalInset + index * 52 + 13;
      final top = verticalInset + chartHeight - barHeight;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, 26, barHeight),
          const Radius.circular(6),
        ),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_SpendingChartPainter oldDelegate) =>
      oldDelegate.buckets != buckets || oldDelegate.maxAmount != maxAmount;
}
