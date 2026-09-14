import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gold_app/models/gold_price_model.dart';
import 'package:intl/intl.dart'; // For number formatting

class DailyPriceGraph extends StatefulWidget {
  final List<GoldPrice> prices;

  const DailyPriceGraph({super.key, required this.prices});

  @override
  State<DailyPriceGraph> createState() => _DailyPriceGraphState();
}

class _DailyPriceGraphState extends State<DailyPriceGraph>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // Animate Stroke Width from 4 to 12
    _animation = Tween<double>(
      begin: 4.0,
      end: 12.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.prices.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Sort & Filter Data
    final sortedPrices = List<GoldPrice>.from(widget.prices)
      ..sort((a, b) => a.no.compareTo(b.no));

    // 2. Calculate Stats
    final spots = <FlSpot>[];
    double minPrice = double.infinity;
    double maxPrice = double.negativeInfinity;

    double openPriceVal = 0;
    double closePriceVal = 0;

    for (int i = 0; i < sortedPrices.length; i++) {
      final price = sortedPrices[i];

      final timeParts = price.dateTime.split(' ').last.split(':');
      double xValue = 0;
      if (timeParts.length >= 2) {
        final hour = double.tryParse(timeParts[0]) ?? 0;
        final minute = double.tryParse(timeParts[1]) ?? 0;
        xValue = hour + (minute / 60.0);
      }

      final rawPrice = price.goldBarBuy.replaceAll(',', '');
      final yValue = double.tryParse(rawPrice) ?? 0;

      if (yValue > 0) {
        spots.add(FlSpot(xValue, yValue));
        if (yValue < minPrice) minPrice = yValue;
        if (yValue > maxPrice) maxPrice = yValue;

        if (i == 0) openPriceVal = yValue;
        if (i == sortedPrices.length - 1) closePriceVal = yValue;
      }
    }

    if (spots.isEmpty) return const SizedBox.shrink();

    // EXTEND LINE LOGIC REMOVED
    // Graph ends at the last price update time per user request.

    final change = closePriceVal - openPriceVal;
    final isPositive = change >= 0;

    // Higher contrast colors for readability match standard financial apps
    final changeColor = isPositive
        ? const Color(0xFF2E7D32)
        : const Color(0xFFC62828);
    final displayChangeColor = isDark
        ? (isPositive ? const Color(0xFF69F0AE) : const Color(0xFFFF8A80))
        : changeColor;

    double displayMin = minPrice;
    double displayMax = maxPrice;

    // Add padding to Y-axis for Graph
    final double yInterval = (maxPrice - minPrice) == 0
        ? 50
        : (maxPrice - minPrice);
    minPrice -= yInterval * 0.2;
    maxPrice += yInterval * 0.2;

    final primaryGold = const Color(0xFFD4AF37);
    final textColor = isDark ? Colors.white : Colors.black87;
    final labelColor = Colors.grey[500];

    final numFormat = NumberFormat("#,##0", "en_US");

    return Container(
      height: 280,
      padding: const EdgeInsets.fromLTRB(24, 16, 32, 10),
      margin: EdgeInsets.zero, // Full width (no margin)
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24), // Rounded corners
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2C2C2C), const Color(0xFF1E1E1E)]
              : [Colors.white, const Color(0xFFF9F9F9)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            offset: const Offset(0, 10),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- STOCK HEADER ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ราคาทองวันนี้',
                    style: TextStyle(
                      fontSize: 14,
                      color: labelColor,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    numFormat.format(closePriceVal),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                      color: primaryGold,
                      letterSpacing: -1.0,
                      height: 1.0,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: displayChangeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive ? Icons.trending_up : Icons.trending_down,
                          color: displayChangeColor,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${isPositive ? '+' : ''}${numFormat.format(change)}',
                          style: TextStyle(
                            color: displayChangeColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // --- STATS ROW ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'Open',
                numFormat.format(openPriceVal),
                labelColor,
                textColor,
              ),
              _buildStatItem(
                'Low',
                numFormat.format(displayMin),
                labelColor,
                textColor,
              ),
              _buildStatItem(
                'High',
                numFormat.format(displayMax),
                labelColor,
                textColor,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --- CHART ---
          Expanded(
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.05),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: 3,
                          getTitlesWidget: (value, meta) {
                            final int hour = value.toInt();
                            if (![9, 12, 15, 18].contains(hour)) {
                              return const SizedBox.shrink();
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                '${hour.toString().padLeft(2, '0')}:00',
                                style: TextStyle(
                                  color: labelColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 9,
                    maxX: 18,
                    minY: minPrice,
                    maxY: maxPrice,
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: false,
                        isStepLineChart: true,
                        lineChartStepData: const LineChartStepData(
                          stepDirection: 0,
                        ),
                        color: primaryGold,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        shadow: const Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 4),
                          blurRadius: 4,
                        ),
                        dotData: FlDotData(
                          show: true,
                          checkToShowDot: (spot, barData) {
                            return spot.x == spots.last.x; // Only show last dot
                          },
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4, // Smaller dot
                              color: const Color(0xFFB8860B), // Dark Gold
                              strokeWidth: _animation.value, // Animated stroke
                              strokeColor: primaryGold.withOpacity(
                                0.5 - ((_animation.value - 4) / 16),
                              ), // Fade out as expands
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              primaryGold.withOpacity(0.15),
                              primaryGold.withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          applyCutOffY: false,
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) =>
                            isDark ? const Color(0xFF333333) : Colors.white,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((LineBarSpot touchedSpot) {
                            final timeVal = touchedSpot.x;
                            final hour = timeVal.toInt();
                            final minute = ((timeVal - hour) * 60).toInt();
                            final timeStr =
                                '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
                            return LineTooltipItem(
                              '$timeStr\n${numFormat.format(touchedSpot.y)}',
                              TextStyle(
                                color: primaryGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    Color? labelColor,
    Color textColor,
  ) {
    return Row(
      children: [
        Text('$label: ', style: TextStyle(color: labelColor, fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
