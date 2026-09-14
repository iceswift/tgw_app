import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gold_app/models/gold_price_model.dart';
import 'package:gold_app/repositories/gold_data_repository.dart';
import 'package:gold_app/widgets/main_layout_scaffold.dart';
import 'package:gold_app/utils/ad_config.dart';
import 'package:gold_app/widgets/banner_ad_with_close_button.dart';

class GoldHistoryPage extends StatefulWidget {
  const GoldHistoryPage({super.key});

  @override
  State<GoldHistoryPage> createState() => GoldHistoryPageState();
}

class GoldHistoryPageState extends State<GoldHistoryPage> {
  final GoldDataRepository _repository = GoldDataRepository.instance;
  late Future<List<GoldPrice>> _goldPricesFuture;
  Object? _lastSnapshot;

  // Reload Cooldown Logic
  int _cooldownSeconds = 0;
  Timer? _timer;

  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    final snapshot = _repository.snapshot;
    _lastSnapshot = snapshot;
    _goldPricesFuture = snapshot != null
        ? Future.value(snapshot.history)
        : _repository.refresh().then((board) => board.history);
    _repository.addListener(_onRepositoryChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _repository.removeListener(_onRepositoryChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onRepositoryChanged() {
    final snapshot = _repository.snapshot;
    if (!mounted || snapshot == null || identical(snapshot, _lastSnapshot)) {
      return;
    }
    _lastSnapshot = snapshot;
    setState(() {
      _goldPricesFuture = Future.value(snapshot.history);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll > 0) {
      setState(() {
        _scrollProgress = (currentScroll / maxScroll).clamp(0.0, 1.0);
      });
    }
  }

  void _onSliderChanged(double value) {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final targetScroll = value * maxScroll;
    _scrollController.jumpTo(targetScroll);
    setState(() {
      _scrollProgress = value;
    });
  }

  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _startCooldown() {
    setState(() {
      _cooldownSeconds = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_cooldownSeconds > 0) {
        setState(() {
          _cooldownSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _manualReload() async {
    if (_cooldownSeconds > 0) return;

    // Refresh Data
    final refresh = _repository.refresh();
    setState(() {
      _goldPricesFuture = refresh.then((board) => board.history);
    });
    await refresh;

    // Start Cooldown
    _startCooldown();
  }

  Future<void> _refreshPrices() async {
    // This is called by RefreshIndicator (Pull-to-refresh)
    if (_cooldownSeconds > 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).clearSnackBars(); // Clear existing to prevent stacking
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                'กรุณารออีก $_cooldownSeconds วินาที',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          backgroundColor: Colors.grey[900], // Dark background
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    await _manualReload();
  }

  Widget _buildTimelineScrubber(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGold = const Color(0xFFD4AF37);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Timeline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  '${(_scrollProgress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 24,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: primaryGold,
                  inactiveTrackColor: isDark
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  thumbColor: Colors.white,
                  overlayColor: primaryGold.withOpacity(0.2),
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16,
                  ),
                ),
                child: Slider(
                  value: _scrollProgress,
                  onChanged: _onSliderChanged,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ล่าสุด',
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                ),
                Text(
                  'ก่อนหน้า',
                  style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayoutScaffold(
      // adUnitId: AdConfig.historyPageBanner, // Moved to body
      showScrollToTop: true,
      onRefresh: _refreshPrices,
      controller: _scrollController, // Pass controller to scaffold
      header: Center(
        child: Transform.translate(
          offset: const Offset(0, -20),
          child: const Text(
            'ประวัติราคาทอง',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      bottomWidget: _buildTimelineScrubber(context), // Attach bottom widget
      body: FutureBuilder<List<GoldPrice>>(
        future: _goldPricesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _goldPricesFuture = _repository.refresh().then(
                          (board) => board.history,
                        );
                      });
                    },
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่พบข้อมูลราคาทอง'));
          }

          final prices = snapshot.data!;

          return _buildHistoryList(prices);
        },
      ),
    );
  }

  Widget _buildHistoryList(List<GoldPrice> prices) {
    // Use Column instead of ListView to scroll with the sheet
    return Column(
      children: [
        // Ad at the top of the content (Paper Sheet)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: BannerAdWithCloseButton(adUnitId: AdConfig.historyPageBanner),
        ),
        ...prices.map((price) => _buildHistoryCard(context, price)),
        // Add extra padding at bottom for better scroll experience
        const SizedBox(height: 100), // Increased for bottom widget overlay
      ],
    );
  }

  Widget _buildHistoryCard(BuildContext context, GoldPrice price) {
    final isNegative = price.change.startsWith('-');
    final changeColor = isNegative
        ? const Color(0xFFE57373)
        : const Color(0xFF81C784); // Softer Red/Green
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryGold = const Color(0xFFD4AF37); // Premium Gold

    // Parsing Time
    final timeParts = price.dateTime.split(' ');
    final timeStr = timeParts.length > 1 ? timeParts.last : price.dateTime;
    final dateStr = timeParts.isNotEmpty ? timeParts.first : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10), // Soft, deep shadow
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Minimal Date & Change
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w300, // Thin & Elegant
                        color: Theme.of(context).colorScheme.onSurface,
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
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: changeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isNegative
                                ? Icons.trending_down
                                : Icons.trending_up,
                            color: changeColor,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            price.change,
                            style: TextStyle(
                              color: changeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ครั้งที่ ${price.no}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Body: Price Blocks
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Gold Bar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ทองคำแท่ง',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryGold, // Gold Accent
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildMinimalPrice(
                          context,
                          'รับซื้อ',
                          price.goldBarBuy,
                        ),
                        const SizedBox(height: 16),
                        _buildMinimalPrice(
                          context,
                          'ขายออก',
                          price.goldBarSell,
                        ),
                      ],
                    ),
                  ),
                  // Divider
                  Container(
                    width: 1,
                    // No fixed height, lets IntrinsicHeight handle it
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  // Gold Ornament
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ทองรูปพรรณ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryGold, // Gold Accent
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildMinimalPrice(
                          context,
                          'รับซื้อ',
                          price.goldOrnamentBuy,
                        ),
                        const SizedBox(height: 16),
                        _buildMinimalPrice(
                          context,
                          'ขายออก',
                          price.goldOrnamentSell,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Footer: Minimal Spot & THB
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.05),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: _buildMinimalFooterItem(
                      context,
                      'Spot',
                      price.spot,
                      '\$',
                    ),
                  ),
                ),
                Container(width: 1, height: 16, color: Colors.grey[200]),
                Expanded(
                  child: Center(
                    child: _buildMinimalFooterItem(
                      context,
                      'THB',
                      price.thb,
                      '฿',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalPrice(BuildContext context, String label, String price) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          price,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalFooterItem(
    BuildContext context,
    String label,
    String value,
    String unit,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '$value $unit',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
