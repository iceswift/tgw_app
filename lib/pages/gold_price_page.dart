import 'dart:async'; // Add async for Timer
import 'package:gold_app/utils/ad_config.dart';
import 'package:flutter/material.dart';

import 'package:gold_app/models/gold_price_latest_model.dart';
import 'package:gold_app/models/gold_board_model.dart';
import 'package:flutter/foundation.dart';
import 'package:gold_app/utils/image_saver_web.dart';
import 'package:gold_app/models/jewelry_price_model.dart';
import 'package:intl/intl.dart';

import 'package:gold_app/widgets/main_layout_scaffold.dart';
import 'package:shimmer/shimmer.dart';

import 'package:gold_app/models/shop_price_model.dart';
import 'package:gold_app/models/gold_price_model.dart';
import 'package:gold_app/repositories/gold_data_repository.dart';
import 'package:gold_app/widgets/daily_price_graph.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class GoldPricePage extends StatefulWidget {
  const GoldPricePage({super.key});

  @override
  State<GoldPricePage> createState() => GoldPricePageState();
}

class GoldPricePageState extends State<GoldPricePage> {
  final GoldDataRepository _repository = GoldDataRepository.instance;
  GoldBoard? _lastBoundSnapshot;
  final ScrollController _scrollController =
      ScrollController(); // Added Controller // Initialize WidgetService
  late Future<GoldPriceLatest> _mainPriceFuture;
  late Future<List<JewelryPrice>> _jewelryFuture;
  late Future<List<ShopPrice>> _shopFuture;
  late Future<List<GoldPrice>> _historyFuture; // Add History Future

  bool _isBoardStale = false; // Flag for stale data from board API

  // Refresh Cooldown Logic
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  // Screenshot Logic
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCapturing = false;

  Future<void> _captureAndShare() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true; // Show watermark
    });

    try {
      final image = await _screenshotController.capture(
        delay: const Duration(milliseconds: 10),
        pixelRatio: 3.0, // High res
      );

      if (image != null) {
        if (kIsWeb) {
          await saveImageWeb(
            image,
            'gold_price_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ดาวน์โหลดรูปภาพเรียบร้อยแล้ว'),
                backgroundColor: Color(0xFF4CAF50),
              ),
            );
          }
        } else {
          // 1. Save to Gallery
          await Gal.putImageBytes(image);

          // 2. Share
          final directory = await getTemporaryDirectory();
          final imagePath = await File(
            '${directory.path}/gold_price_${DateTime.now().millisecondsSinceEpoch}.png',
          ).create();
          await imagePath.writeAsBytes(image);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('กำลังบันทึกและแชร์...')),
            );
          }

          // iPad share handling
          final box = context.findRenderObject() as RenderBox?;
          await Share.shareXFiles(
            [XFile(imagePath.path)],
            text: 'ราคาทองคำ',
            sharePositionOrigin: box != null
                ? box.localToGlobal(Offset.zero) & box.size
                : null,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false; // Hide watermark
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _repository.addListener(_onRepositoryChanged);
    final cachedSnapshot = _repository.snapshot;
    if (cachedSnapshot != null) {
      _bindBoardFuture(Future.value(cachedSnapshot));
      _repository
          .refresh(reason: GoldRefreshReason.startup)
          .then((board) {
            if (mounted) _bindBoardFuture(Future.value(board));
          })
          .catchError((Object error) {
            debugPrint(
              'Background refresh failed; keeping cached snapshot: $error',
            );
          });
    } else {
      _bindBoardFuture(_repository.refresh(reason: GoldRefreshReason.startup));
    }
  }

  @override
  void dispose() {
    _repository.removeListener(_onRepositoryChanged);
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _onRepositoryChanged() {
    final snapshot = _repository.snapshot;
    if (!mounted ||
        snapshot == null ||
        identical(snapshot, _lastBoundSnapshot)) {
      return;
    }
    _bindBoardFuture(Future.value(snapshot));
  }

  void _startCooldown() {
    setState(() {
      _cooldownSeconds = 60;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

  void _loadData() {
    _bindBoardFuture(_repository.refresh());
  }

  void _bindBoardFuture(Future<GoldBoard> boardFuture) {
    final observedBoardFuture = boardFuture.then((board) {
      _lastBoundSnapshot = board;
      if (mounted) {
        setState(() {
          _isBoardStale = board.stale;
        });
      }
      return board;
    });

    setState(() {
      _mainPriceFuture = observedBoardFuture.then((board) {
        return board.latest;
      });

      _jewelryFuture = observedBoardFuture.then((board) => board.jewelry);

      _shopFuture = observedBoardFuture.then((board) => board.shops);

      _historyFuture = observedBoardFuture.then((board) => board.history);
    });
  }

  Future<void> _refresh() async {
    if (_cooldownSeconds > 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
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
          backgroundColor: Colors.grey[900],
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

    _loadData();
    _startCooldown();

    // Wait for all to finish for the refresh indicator
    await Future.wait([
      _mainPriceFuture.catchError(
        (_) => GoldPriceLatest(
          date: '',
          time: '',
          round: '',
          marketStatus: '',
          bullionBuy: '',
          bullionSell: '',
          ornamentBuy: '',
          ornamentSell: '',
          spot: '',
          thb: '',
          change: '',
        ),
      ),
      _jewelryFuture.catchError((_) => <JewelryPrice>[]),
      _shopFuture.catchError((_) => <ShopPrice>[]),
      _historyFuture.catchError((_) => <GoldPrice>[]), // Catch error
    ]);
  }

  // Scroll Keys
  final Map<String, GlobalKey<ShopCardState>> _shopKeys = {};
  final GlobalKey _puritySectionKey =
      GlobalKey(); // Key for "Price by Percent" section

  GlobalKey<ShopCardState> _getShopKey(String shopName) {
    if (!_shopKeys.containsKey(shopName)) {
      _shopKeys[shopName] = GlobalKey<ShopCardState>();
    }
    return _shopKeys[shopName]!;
  }

  void _scrollToShop(String shopName) async {
    final key = _shopKeys[shopName];
    if (key != null && key.currentContext != null) {
      await Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        alignment: 0.1, // Scroll to be slightly below the top (header)
      );
      // Trigger bounce after scroll
      key.currentState?.triggerAnimation();
    }
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

  bool _hasValidShopData(ShopPrice shop) {
    return shop.goldBar965 != null ||
        shop.goldBar9999 != null ||
        shop.ornament965 != null ||
        shop.ornamentBuyBack != null;
  }

  @override
  Widget build(BuildContext context) {
    return MainLayoutScaffold(
      adUnitId: AdConfig.homePageBanner,
      controller: _scrollController, // Connected Controller
      showScrollToTop: true,
      scrollDownTarget: _puritySectionKey, // Enable Smart FAB
      scrollDownIcon: Icons.percent_rounded, // Use Percent Icon
      onRefresh: _refresh,
      header: _buildModernHeader(),
      body: Column(
        children: [
          _buildMainSection(),
          const SizedBox(height: 24),
          _buildDailyGraph(), // Add Graph Here
          const SizedBox(height: 24),
          _buildShopNavigation(), // Shop Navigation

          const SizedBox(height: 24),
          Container(
            key: _puritySectionKey, // Target for scroll down
            child: _buildJewelrySection(),
          ),
          const SizedBox(height: 32),
          _buildShopSection(),
          // Extra padding at bottom for ease of scrolling
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildShopNavigation() {
    return FutureBuilder<List<ShopPrice>>(
      future: _shopFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final shops = snapshot.data!.where(_hasValidShopData).toList();

        if (shops.isEmpty) {
          return const SizedBox.shrink();
        }

        final primaryGold = const Color(0xFFD4AF37);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label removed as per request
            SizedBox(
              height: 80, // Increased height to allow space for shadow
              child: ListView.separated(
                clipBehavior: Clip
                    .none, // Allow items to show outside bounds (fix cropping)
                padding: const EdgeInsets.fromLTRB(
                  16,
                  0,
                  24, // Increased right padding
                  16,
                ), // Bottom padding for shadow
                scrollDirection: Axis.horizontal,
                itemCount: shops.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final shop = shops[index];
                  return GestureDetector(
                    onTap: () => _scrollToShop(shop.name),
                    child: _buildShopLogo(
                      shop.name,
                      primaryGold,
                      size: 60, // Enlarged to fill the previous square size
                    ),
                  ); // Removed comma
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModernHeader() {
    final now = DateTime.now();
    // Greeting logic (hardcoded Thai)
    String greeting = '';
    int hour = DateTime.now().hour;
    if (hour < 12) {
      greeting = 'สวัสดีตอนเช้า';
    } else if (hour < 17) {
      greeting = 'สวัสดีตอนบ่าย';
    } else if (hour < 20) {
      greeting = 'สวัสดีตอนเย็น';
    } else {
      greeting = 'ราตรีสวัสดิ์';
    }

    final thDays = [
      'อาทิตย์',
      'จันทร์',
      'อังคาร',
      'พุธ',
      'พฤหัสบดี',
      'ศุกร์',
      'เสาร์',
    ];
    final thMonths = [
      'มกราคม',
      'กุมภาพันธ์',
      'มีนาคม',
      'เมษายน',
      'พฤษภาคม',
      'มิถุนายน',
      'กรกฎาคม',
      'สิงหาคม',
      'กันยายน',
      'ตุลาคม',
      'พฤศจิกายน',
      'ธันวาคม',
    ];
    final dayName = thDays[now.weekday % 7];
    final date = now.day;
    final month = thMonths[now.month - 1];
    final year = now.year + 543;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // 1. Align to top
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'วัน$dayNameที่ $date $month $year',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Transform.translate(
          offset: const Offset(0, -10), // 2. Shift up by 20 pixels
          child: Image.asset(
            'assets/icon/logo-no-background.png',
            height: 111,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  Widget _buildMainSection() {
    return FutureBuilder<GoldPriceLatest>(
      future: _mainPriceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerHeader(context);
        } else if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString(), isMain: true);
        } else if (!snapshot.hasData) {
          return Center(child: Text('ไม่มีข้อมูลราคาทองคำ'));
        }

        final gold = snapshot.data!;
        final dateTime = '${gold.date} ${gold.time}'.trim();
        final hasRound = gold.round.isNotEmpty;
        final hasSpot = gold.spot.isNotEmpty;
        final hasThb = gold.thb.isNotEmpty;
        final isClosed =
            gold.marketStatus.isNotEmpty &&
            gold.marketStatus.toLowerCase().contains('closed');

        return Column(
          children: [
            // Header (Date, Round/Status)
            Column(
              children: [
                Text(
                  dateTime.isEmpty ? 'ราคาเปลี่ยนแปลง!' : dateTime,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                if (isClosed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Text(
                      gold.marketStatus,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (hasRound)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ประกาศครั้งที่ ${gold.round}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_isBoardStale)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'ข้อมูลอาจล่าช้ากว่าปกติ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),

            // Unified Price Card
            _buildUnifiedMainCard(context, gold),
            const SizedBox(height: 24),

            // Secondary Stats (Spot & Currency) - Only show if data exists
            if (hasSpot || hasThb)
              Row(
                children: [
                  if (hasSpot)
                    Expanded(
                      child: _buildSecondaryCard(
                        context,
                        title: 'Gold Spot',
                        value: gold.spot,
                        diff: '', // API doesn't allow spot diff separately?
                        icon: Icons.public,
                        subtitle: 'USD/oz',
                      ),
                    ),
                  if (hasSpot && hasThb) const SizedBox(width: 16),
                  if (hasThb)
                    Expanded(
                      child: _buildSecondaryCard(
                        context,
                        title: 'บาท',
                        value: gold.thb,
                        diff: '', // API doesn't provide thb diff
                        icon: Icons.currency_exchange,
                        subtitle: 'THB/USD',
                        isCurrency: true,
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  Widget _buildUnifiedMainCard(BuildContext context, GoldPriceLatest gold) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGold = const Color(0xFFD4AF37);

    return Screenshot(
      controller: _screenshotController,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              // --- HEADER ---
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryGold.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.verified_outlined,
                              color: primaryGold,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'ราคาทองวันนี้',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (!_isCapturing)
                          IconButton(
                            icon: Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.grey[400],
                              size: 20,
                            ),
                            tooltip: 'บันทึกรูปภาพ',
                            onPressed: _captureAndShare,
                          ),
                        const SizedBox(width: 8),
                        _buildChangeBadge(context, gold.change),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- HERO SECTION: GOLD BAR ---
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryGold.withOpacity(0.08), // Very soft gold tint
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _buildHeroPriceBlock(
                  context,
                  'ทองคำแท่ง',
                  gold.bullionBuy,
                  gold.bullionSell,
                  primaryGold,
                ),
              ),

              const SizedBox(height: 12),

              // --- SECONDARY SECTION: ORNAMENT ---
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.02)
                      : Colors.grey.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _buildHeroPriceBlock(
                  context,
                  'ทองรูปพรรณ',
                  gold.ornamentBuy,
                  gold.ornamentSell,
                  isDark ? Colors.grey[400]! : Colors.grey[700]!,
                ),
              ),

              const SizedBox(height: 16),

              // --- FOOTER ---
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ที่มา: สมาคมค้าทองคำ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    if (_isCapturing) ...[
                      const SizedBox(height: 8),
                      // Date & Time Context for Image
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ประจำวันที่ ${gold.date} เวลา ${gold.time} น. (ครั้งที่ ${gold.round})',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Thai Gold View',
                        style: TextStyle(
                          fontFamily: 'Playfair Display',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroPriceBlock(
    BuildContext context,
    String title,
    String buy,
    String sell,
    Color titleColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.grey[500] : Colors.grey[600];
    final primaryGold = const Color(0xFFD4AF37);

    return Column(
      children: [
        // Title
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 16),

        // Price Grid
        Row(
          children: [
            // BUY COLUMN
            Expanded(
              child: Column(
                children: [
                  Text(
                    'รับซื้อ (บาท)',
                    style: TextStyle(
                      fontSize: 12,
                      color: labelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    buy,
                    style: TextStyle(
                      fontSize: 26, // Hero Size
                      fontWeight: FontWeight.bold,
                      color: primaryGold, // Gold for Buy
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),

            // DIVIDER
            Container(
              height: 40,
              width: 1,
              color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.2),
            ),

            // SELL COLUMN
            Expanded(
              child: Column(
                children: [
                  Text(
                    'ขายออก (บาท)',
                    style: TextStyle(
                      fontSize: 12,
                      color: labelColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sell,
                    style: TextStyle(
                      fontSize: 26, // Hero Size
                      fontWeight: FontWeight.w400, // Slightly lighter
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChangeBadge(
    BuildContext context,
    String change, {
    bool useWhiteTheme = false,
  }) {
    // Clean string to parse
    final cleanChange = change.replaceAll(',', '').replaceAll('+', '');
    final val = double.tryParse(cleanChange) ?? 0;
    final isNegative = val < 0;
    final isZero = val == 0;

    Color bg;
    Color text;
    IconData icon;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (useWhiteTheme) {
      // --- White Theme (For Gold Background) ---
      bg = Colors.white.withOpacity(0.2);
      text = Colors.white;
      icon = isZero
          ? Icons.remove
          : (isNegative ? Icons.trending_down : Icons.trending_up);
    } else {
      // --- Standard Theme ---
      if (isZero) {
        bg = isDark ? Colors.white10 : Colors.grey.withOpacity(0.1);
        text = Colors.grey;
        icon = Icons.remove;
      } else if (isNegative) {
        bg = const Color(0xFFC62828).withOpacity(0.15); // Standard Red
        text = const Color(0xFFC62828);
        icon = Icons.trending_down;
        if (isDark) {
          bg = const Color(0xFFFF8A80).withOpacity(0.15); // Light Red
          text = const Color(0xFFFF8A80);
        }
      } else {
        bg = const Color(0xFF2E7D32).withOpacity(0.15); // Standard Green
        text = const Color(0xFF2E7D32);
        icon = Icons.trending_up;
        if (isDark) {
          bg = const Color(0xFF69F0AE).withOpacity(0.15); // Light Green
          text = const Color(0xFF69F0AE);
        }
      }
    }

    // Format text with +
    String displayText = change;
    if (!isNegative && !isZero && !change.contains('+')) {
      displayText = '+$change';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: text, size: 18),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required String diff,
    required IconData icon,
    String? subtitle,
    bool isCurrency = false,
  }) {
    if (value.isEmpty) return const SizedBox();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryGold = const Color(0xFFD4AF37);

    // Diff logic
    bool isNegative = false;
    bool hasDiff = diff.isNotEmpty;
    if (hasDiff) {
      isNegative = diff.startsWith('-');
    }
    final diffColor = isNegative
        ? const Color(0xFFE57373)
        : const Color(0xFF81C784);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: primaryGold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w300,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
          if (hasDiff) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isNegative ? Icons.trending_down : Icons.trending_up,
                  color: diffColor,
                  size: 14,
                ),
                Text(
                  diff,
                  style: TextStyle(
                    color: diffColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmerHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: [
          // Header
          Container(
            height: 20,
            width: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 38,
            width: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 32),

          // Main Cards
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 32),

          // Stats
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: [
          // List Header
          Container(
            height: 40,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          // List Items
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error, {required bool isMain}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('เกิดข้อผิดพลาด', style: TextStyle(color: Colors.grey[600])),
            if (error.contains('SocketException') ||
                error.contains('ClientException') ||
                error.contains('Failed host lookup')) ...[
              const SizedBox(height: 8),
              const Text(
                'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้\nกรุณาตรวจสอบอินเทอร์เน็ต',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ] else if (error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                _loadData();
              },
              child: const Text('ลองใหม่'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJewelrySection() {
    return FutureBuilder<List<JewelryPrice>>(
      future: _jewelryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerList(context);
        } else if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString(), isMain: false);
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox();
        }

        final jewelryList = snapshot.data!;
        final primaryGold = const Color(0xFFD4AF37);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryGold.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.percent_rounded,
                      color: primaryGold,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ราคาตามเปอร์เซ็นต์ทอง',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey.withOpacity(0.1),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  children: [
                    _buildJewelryTableHeader(context),
                    Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
                    ...jewelryList.map(
                      (item) => _buildJewelryRow(context, item),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildJewelryTableHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withOpacity(0.02)
          : Colors.grey.withOpacity(0.03),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'เปอร์เซ็นต์',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'รับซื้อ (บาท)',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'ขาย (บาท)',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJewelryRow(BuildContext context, JewelryPrice item) {
    // Parse Percentage from Type name (e.g., "ทอง 99.99%" -> "99.99%")
    final percentRegex = RegExp(r'(\d+(\.\d+)?%)');
    final match = percentRegex.firstMatch(item.type);

    String percentText = item.type;
    String nameText = 'ทองรูปพรรณ'; // Default fallback

    if (match != null) {
      percentText = match.group(0)!;
      // Remove the percentage from the name if you want, or just keep the full name as subtitle
      // For now, let's keep the full original string as the "Name" (subtitle)
      // or try to clean it.
      // User requested: "Name on new line".
      // Let's use the full original text as specific descriptor if distinct,
      // or just "ทองรูปพรรณ" if the original text IS just the percentage.

      String remainder = item.type.replaceAll(percentText, '').trim();
      if (remainder.isNotEmpty) {
        nameText = remainder;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Big Percentage (Top Line)
                Text(
                  percentText,
                  style: TextStyle(
                    fontSize: 22, // Slightly larger for elegance
                    fontWeight: FontWeight.w300, // Light/Thin = Minimal
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: -1.0, // Tight spacing
                  ),
                ),
                const SizedBox(height: 2),
                // 2. Name (Bottom Line)
                Text(
                  nameText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[500],
                  ),
                ),
                if (item.perGramBuy != 'n/a')
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'กรัมละ ${item.perGramBuy}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              alignment: Alignment.centerRight,
              child: Text(
                item.perBahtBuy,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              alignment: Alignment.centerRight,
              child: Text(
                item.perBahtSell,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGraph() {
    return FutureBuilder<List<GoldPrice>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        return DailyPriceGraph(prices: snapshot.data!);
      },
    );
  }

  Widget _buildShopSection() {
    return FutureBuilder<List<ShopPrice>>(
      future: _shopFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerList(context);
        } else if (snapshot.hasError) {
          return _buildErrorWidget(snapshot.error.toString(), isMain: false);
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox();
        }

        final shopList = snapshot.data!.where(_hasValidShopData).toList();

        if (shopList.isEmpty) {
          return const SizedBox();
        }

        final primaryGold = const Color(0xFFD4AF37);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.storefront_outlined, color: primaryGold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'ราคาจากร้านค้า',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Individual Cards for each shop
            ...shopList.asMap().entries.map((entry) {
              final shop = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ShopCard(key: _getShopKey(shop.name), shop: shop),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildShopLogo(
    String shopName,
    Color primaryColor, {
    double size = 36,
  }) {
    String? assetName;
    final lowerName = shopName.toLowerCase();

    if (lowerName.contains('aurora')) {
      assetName = 'aurora.png';
    } else if (lowerName.contains('mts')) {
      assetName = 'mts_gold.png';
    } else if (lowerName.contains('hua seng heng') ||
        lowerName.contains('ฮั่วเซ่งเฮง')) {
      assetName = 'hua_seng_heng.png';
    } else if (lowerName.contains('chin hua heng') ||
        lowerName.contains('จินฮั้วเฮง')) {
      assetName = 'chin_hua_heng.png';
    } else if (lowerName.contains('ausiris')) {
      assetName = 'ausiris.png';
    }

    if (assetName != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          'assets/logos/$assetName',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackIcon(primaryColor, size: size);
          },
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(child: _buildFallbackIcon(primaryColor, size: size)),
    );
  }

  Widget _buildFallbackIcon(Color color, {required double size}) {
    return Icon(Icons.store, color: color, size: size * 0.6);
  }
}

class ShopCard extends StatefulWidget {
  final ShopPrice shop;
  const ShopCard({super.key, required this.shop});

  @override
  State<ShopCard> createState() => ShopCardState();
}

class ShopCardState extends State<ShopCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  // Screenshot Logic
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void triggerAnimation() {
    _controller.forward(from: 0.0);
  }

  Future<void> _captureAndShare() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      final image = await _screenshotController.capture(
        delay: const Duration(milliseconds: 10),
        pixelRatio: 3.0,
      );

      if (image != null) {
        if (kIsWeb) {
          await saveImageWeb(
            image,
            'gold_shop_${widget.shop.name}_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ดาวน์โหลดรูปภาพเรียบร้อยแล้ว'),
                backgroundColor: Color(0xFF4CAF50),
              ),
            );
          }
        } else {
          // 1. Save to Gallery
          await Gal.putImageBytes(image);

          // 2. Share
          final directory = await getTemporaryDirectory();
          final imagePath = await File(
            '${directory.path}/gold_shop_${widget.shop.name}_${DateTime.now().millisecondsSinceEpoch}.png',
          ).create();
          await imagePath.writeAsBytes(image);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('บันทึก ${widget.shop.name} และเริ่มแชร์...'),
              ),
            );
          }

          final box = context.findRenderObject() as RenderBox?;
          await Share.shareXFiles(
            [XFile(imagePath.path)],
            text: 'ราคาทอง ${widget.shop.name} โดย Thai Gold View',
            sharePositionOrigin: box != null
                ? box.localToGlobal(Offset.zero) & box.size
                : null,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึกภาพ: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryGold = const Color(0xFFD4AF37);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Screenshot(
      controller: _screenshotController,
      child: Stack(
        children: [
          // Glow Layer
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                final val = _glowAnimation.value;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      if (val > 0)
                        BoxShadow(
                          color: primaryGold.withOpacity(0.6 * val),
                          blurRadius: 10 + (20 * val),
                          spreadRadius: 2 + (15 * val),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Content Layer
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryGold.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Logo + Name + Save Button
                  Row(
                    children: [
                      _buildShopLogo(widget.shop.name, primaryGold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.shop.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (!_isCapturing)
                        IconButton(
                          icon: Icon(
                            Icons.save_alt_rounded,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          tooltip: 'บันทึกรูปภาพ',
                          onPressed: _captureAndShare,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Table Header
                  _buildShopTableHeader(context),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: Colors.grey.withOpacity(0.1)),

                  // Content Rows
                  if (widget.shop.goldBar965 != null)
                    _buildShopTableRow(
                      context,
                      "ทองคำแท่ง 96.5%",
                      widget.shop.goldBar965!,
                    ),

                  if (widget.shop.goldBar9999 != null)
                    _buildShopTableRow(
                      context,
                      "ทองคำแท่ง 99.99%",
                      widget.shop.goldBar9999!,
                    ),

                  if (widget.shop.ornament965 != null)
                    _buildShopTableRow(
                      context,
                      "ทองรูปพรรณ 96.5%",
                      (widget.shop.name.contains('จินฮั้วเฮง') ||
                              widget.shop.name.toLowerCase().contains(
                                'chin hua heng',
                              ))
                          ? ShopGoldData(
                              buy: widget
                                  .shop
                                  .ornament965!
                                  .sell, // Swap for Chin Hua Heng
                              sell: widget.shop.ornament965!.buy,
                            )
                          : widget.shop.ornament965!,
                    ),

                  if (widget.shop.ornamentBuyBack != null)
                    _buildShopTableRow(
                      context,
                      "รับซื้อคืนรูปพรรณ",
                      widget.shop.ornamentBuyBack!,
                    ),

                  // Conditional Watermark Footer
                  if (_isCapturing) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ข้อมูล ณ ${DateFormat('d MMM yyyy HH:mm').format(DateTime.now())}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Thai Gold View',
                            style: TextStyle(
                              fontFamily: 'Playfair Display',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: Color(0xFFD4AF37),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER METHODS (Moved inside) ---

  Widget _buildShopLogo(
    String shopName,
    Color primaryColor, {
    double size = 36,
  }) {
    String? assetName;
    final lowerName = shopName.toLowerCase();

    if (lowerName.contains('aurora')) {
      assetName = 'aurora.png';
    } else if (lowerName.contains('mts')) {
      assetName = 'mts_gold.png';
    } else if (lowerName.contains('hua seng heng') ||
        lowerName.contains('ฮั่วเซ่งเฮง')) {
      assetName = 'hua_seng_heng.png';
    } else if (lowerName.contains('chin hua heng') ||
        lowerName.contains('จินฮั้วเฮง')) {
      assetName = 'chin_hua_heng.png';
    } else if (lowerName.contains('ausiris')) {
      assetName = 'ausiris.png';
    }

    if (assetName != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          'assets/logos/$assetName',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackIcon(primaryColor, size: size),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(child: _buildFallbackIcon(primaryColor, size: size)),
    );
  }

  Widget _buildFallbackIcon(Color color, {required double size}) {
    return Icon(Icons.store, color: color, size: size * 0.6);
  }

  Widget _buildShopTableHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            'ประเภท',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'รับซื้อ',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            'ขายออก',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShopTableRow(
    BuildContext context,
    String title,
    ShopGoldData data,
  ) {
    String buyText = data.buy.isNotEmpty ? data.buy : '-';
    String sellText = data.sell.isNotEmpty ? data.sell : '-';
    if (sellText.contains('ไม่ระบุ')) sellText = '-';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.05)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              buyText,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFD4AF37),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              sellText,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
