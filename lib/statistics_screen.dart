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
                    const SizedBox(height: 24),
                    Text(
                      strings.categorySpending,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (statistics.categoryBuckets.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Text(
                          strings.noCategorySpending,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      )
                    else
                      _CategorySpendingChart(
                        buckets: statistics.categoryBuckets,
                      ),
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

class _SpendingChart extends StatefulWidget {
  const _SpendingChart({required this.buckets});

  final List<SpendingBucket> buckets;

  @override
  State<_SpendingChart> createState() => _SpendingChartState();
}

class _SpendingChartState extends State<_SpendingChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final maxAmount = widget.buckets.fold<double>(
      0,
      (maximum, bucket) => math.max(maximum, bucket.amount),
    );
    final chartWidth = math.max(
      MediaQuery.sizeOf(context).width - 40,
      widget.buckets.length * 52.0,
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
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) {
                      final index =
                          ((details.localPosition.dx - 10) / 52).floor();
                      if (index < 0 || index >= widget.buckets.length) return;
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    child: CustomPaint(
                      painter: _SpendingChartPainter(
                        buckets: widget.buckets,
                        maxAmount: maxAmount,
                        selectedIndex: _selectedIndex,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final bucket in widget.buckets)
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
    required this.selectedIndex,
  });

  final List<SpendingBucket> buckets;
  final double maxAmount;
  final int? selectedIndex;

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
    final barOutlinePaint = Paint()
      ..color = AppColors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var index = 0; index < buckets.length; index++) {
      final bucket = buckets[index];
      final barHeight = maxAmount == 0
          ? 0.0
          : (bucket.amount / maxAmount) * (chartHeight - 8);
      final left = horizontalInset + index * 52 + 13;
      final top = verticalInset + chartHeight - barHeight;
      final barRect = Rect.fromLTWH(left, top, 26, barHeight);
      final bar = RRect.fromRectAndRadius(
        barRect,
        const Radius.circular(6),
      );
      canvas.drawRRect(
        bar,
        barPaint,
      );
      canvas.drawRRect(bar, barOutlinePaint);

      if (index == selectedIndex) {
        final label = TextPainter(
          text: TextSpan(
            text: '€${bucket.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.acidGreen,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final labelX = left + (barRect.width - label.width) / 2;
        final labelY = top - label.height - 8 >= verticalInset
            ? top - label.height - 8
            : top + 4;
        final labelRect = Rect.fromLTWH(
          labelX - 5,
          labelY - 3,
          label.width + 10,
          label.height + 6,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(labelRect, const Radius.circular(5)),
          Paint()..color = AppColors.black,
        );
        label.paint(canvas, Offset(labelX, labelY));
      }
    }
  }

  @override
  bool shouldRepaint(_SpendingChartPainter oldDelegate) =>
      oldDelegate.buckets != buckets ||
      oldDelegate.maxAmount != maxAmount ||
      oldDelegate.selectedIndex != selectedIndex;
}

class _CategorySpendingChart extends StatefulWidget {
  const _CategorySpendingChart({required this.buckets});

  final List<CategorySpendingBucket> buckets;

  @override
  State<_CategorySpendingChart> createState() =>
      _CategorySpendingChartState();
}

class _CategorySpendingChartState extends State<_CategorySpendingChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final total = widget.buckets.fold<double>(
      0,
      (sum, bucket) => sum + bucket.amount,
    );
    final selectedIndex =
        _selectedIndex != null && _selectedIndex! < widget.buckets.length
            ? _selectedIndex
            : null;
    final selectedBucket =
        selectedIndex == null ? null : widget.buckets[selectedIndex];

    return Card(
      color: const Color(0xFFF8F8F5),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  final offset = details.localPosition - const Offset(110, 110);
                  if (offset.distance < 54) {
                    setState(() {
                      _selectedIndex = null;
                    });
                    return;
                  }
                  if (offset.distance > 98) return;

                  var angle = math.atan2(offset.dy, offset.dx) + math.pi / 2;
                  if (angle < 0) angle += math.pi * 2;
                  var cumulativeAngle = 0.0;
                  for (var index = 0; index < widget.buckets.length; index++) {
                    cumulativeAngle +=
                        widget.buckets[index].amount / total * math.pi * 2;
                    if (angle < cumulativeAngle) {
                      setState(() {
                        _selectedIndex = index;
                      });
                      return;
                    }
                  }
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size.square(220),
                      painter: _CategoryDonutPainter(
                        buckets: widget.buckets,
                        total: total,
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selectedBucket != null)
                            Text(
                              strings.productCategory(
                                selectedBucket.category,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                            )
                          else
                            Text(
                              strings.totalSpending,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            '€${(selectedBucket?.amount ?? total).toStringAsFixed(2)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < widget.buckets.length; index++)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: widget.buckets[index].category.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          strings.productCategory(
                            widget.buckets[index].category,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '€${widget.buckets[index].amount.toStringAsFixed(2)}',
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '${(widget.buckets[index].amount / total * 100).toStringAsFixed(1)}%',
                          textAlign: TextAlign.end,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryDonutPainter extends CustomPainter {
  const _CategoryDonutPainter({
    required this.buckets,
    required this.total,
  });

  final List<CategorySpendingBucket> buckets;
  final double total;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final chartRect = Rect.fromCircle(center: center, radius: 98);
    var startAngle = -math.pi / 2;
    for (final bucket in buckets) {
      final sweepAngle = bucket.amount / total * math.pi * 2;
      canvas.drawArc(
        chartRect,
        startAngle,
        sweepAngle,
        true,
        Paint()..color = bucket.category.color,
      );
      startAngle += sweepAngle;
    }
    canvas.drawCircle(
      center,
      54,
      Paint()..color = const Color(0xFFF8F8F5),
    );
  }

  @override
  bool shouldRepaint(_CategoryDonutPainter oldDelegate) =>
      oldDelegate.buckets != buckets || oldDelegate.total != total;
}
