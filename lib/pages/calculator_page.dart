import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gold_app/models/gold_board_model.dart';
import 'package:gold_app/models/shop_price_model.dart'; // Import ShopPrice
import 'package:gold_app/repositories/gold_data_repository.dart';
import 'package:gold_app/widgets/main_layout_scaffold.dart';
import 'package:gold_app/utils/ad_config.dart';
import 'package:gold_app/widgets/banner_ad_with_close_button.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:flutter/foundation.dart';
import 'package:gold_app/utils/image_saver_web.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

enum ChartMode { costVsProfit, byShop }

// Model for a Calculator Item
class CalculatorItem {
  String id;
  double? buyPrice; // The price user gets when selling
  double? costPrice; // The price user bought at
  double weight;
  String? priceUpdateTime; // When the buyPrice was fetched
  String? sourceName; // e.g., "Association", "MTS Gold"
  String? sourceType; // e.g., "bar", "ornament"
  String? purity; // '96.5%' or '99.99%'

  CalculatorItem({
    required this.id,
    this.buyPrice,
    this.costPrice,
    this.weight = 1.0,
    this.priceUpdateTime,
    this.sourceName,
    this.sourceType,
    this.purity = '96.5%', // Default to standard
  });

  double get profitLoss {
    if (buyPrice == null || costPrice == null) return 0.0;
    return (buyPrice! - costPrice!) * weight;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'buyPrice': buyPrice,
      'costPrice': costPrice,
      'weight': weight,
      'priceUpdateTime': priceUpdateTime,
      'sourceName': sourceName,
      'sourceType': sourceType,
      'purity': purity,
    };
  }

  factory CalculatorItem.fromMap(Map<String, dynamic> map) {
    return CalculatorItem(
      id: map['id'],
      buyPrice: map['buyPrice'],
      costPrice: map['costPrice'],
      weight: map['weight'] ?? 1.0,
      priceUpdateTime: map['priceUpdateTime'],
      sourceName: map['sourceName'],
      sourceType: map['sourceType'],
      purity: map['purity'] ?? '96.5%',
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => CalculatorPageState();
}

class CalculatorPageState extends State<CalculatorPage> {
  final GoldDataRepository _repository = GoldDataRepository.instance;
  GoldBoard? _lastAppliedSnapshot;
  bool _itemsLoaded = false;
  final GlobalKey _bottomKey = GlobalKey();
  final List<CalculatorItem> _items = [];
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "th_TH");
  final ScrollController _scrollController =
      ScrollController(); // New Controller
  int _touchedIndex = -1; // Track touched chart section
  ChartMode _chartMode = ChartMode.costVsProfit; // Chart display mode

  // Screenshot & Sharing
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCapturing = false;

  // Selective Screenshot
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  Future<void> _captureAndShare() async {
    // 1. Premium Check Removed
    // Captured features are now free for everyone.

    // 2. Show Options
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.crop_free_rounded,
                  color: Colors.blue,
                ),
                title: const Text('บันทึกทั้งหมด'),
                subtitle: const Text('บันทึกรายการคำนวณทั้งหมดในหน้านี้'),
                onTap: () {
                  Navigator.pop(context);
                  _performCapture(); // Capture All
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.checklist_rtl_rounded,
                  color: Colors.green,
                ),
                title: const Text('เลือกรายการ'),
                subtitle: const Text('เลือกเฉพาะรายการที่ต้องการบันทึก'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _isSelectionMode = true;
                    _selectedIds.clear();
                  });
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.refresh_rounded, color: Colors.blue),
                title: const Text('รีโหลดราคาล่าสุด'),
                onTap: () {
                  Navigator.pop(context);
                  _reloadAllPrices();
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_all_rounded, color: Colors.blue),
                title: const Text('คัดลอกทั้งหมด'),
                onTap: () {
                  Navigator.pop(context);
                  _copyAllItems();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                title: const Text(
                  'ล้างรายการทั้งหมด',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _clearAllItems();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.help_outline_rounded,
                  color: Colors.orange,
                ),
                title: const Text('คำอธิบาย'),
                onTap: () {
                  Navigator.pop(context);
                  showHelpDialog();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _performCapture() async {
    // Prepare UI (Hide buttons)
    if (mounted) {
      setState(() {
        _isCapturing = true;
      });
    }

    // Wait for rebuild
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final Uint8List? image = await _screenshotController.capture();

      // Restore UI immediately
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _isSelectionMode = false; // Reset selection mode after capture
        });
      }

      if (image != null) {
        if (kIsWeb) {
          await saveImageWeb(image, 'gold_calculator_summary.png');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ดาวน์โหลดรูปภาพเรียบร้อยแล้ว'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        } else {
          // Save to Gallery
          await Gal.putImageBytes(image);

          // Save to File for Sharing
          final directory = await getApplicationDocumentsDirectory();
          final imagePath = '${directory.path}/gold_calculator_summary.png';
          final file = File(imagePath);
          await file.writeAsBytes(image);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('บันทึกรูปภาพลงแกลเลอรีเรียบร้อยแล้ว'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );

          // iPad share handling
          final box = context.findRenderObject() as RenderBox?;

          // Share
          await Share.shareXFiles(
            [XFile(imagePath)],
            text: 'สรุปกำไรขายทอง โดย Gold App',
            sharePositionOrigin: box != null
                ? box.localToGlobal(Offset.zero) & box.size
                : null,
          );
        }
      }
    } catch (e) {
      // Restore UI on error
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึก: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _repository.addListener(_onRepositoryChanged);
    _loadItems().then((_) {
      _itemsLoaded = true;
      final snapshot = _repository.snapshot;
      if (snapshot != null) _applySnapshot(snapshot);
    });
    if (_repository.snapshot == null) {
      _repository.refresh(reason: GoldRefreshReason.startup);
    }
  }

  @override
  void dispose() {
    _repository.removeListener(_onRepositoryChanged);
    _scrollController.dispose(); // Dispose controller
    super.dispose();
  }

  void _onRepositoryChanged() {
    final snapshot = _repository.snapshot;
    if (!_itemsLoaded || snapshot == null) return;
    _applySnapshot(snapshot);
  }

  void _applySnapshot(GoldBoard snapshot) {
    if (!mounted || identical(snapshot, _lastAppliedSnapshot)) return;
    _lastAppliedSnapshot = snapshot;
    _reloadAllPrices(silent: true, boardSnapshot: snapshot);
  }

  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final String? itemsJson = prefs.getString('calculator_items');

    if (itemsJson != null) {
      final List<dynamic> decodedList = json.decode(itemsJson);
      setState(() {
        _items.clear();
        _items.addAll(
          decodedList.map((item) => CalculatorItem.fromMap(item)).toList(),
        );
      });
    } else {
      // Start with one empty card if no saved data
      _addItem(scrollToBottom: false);
    }
  }

  Future<void> _saveItems({bool silent = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String itemsJson = json.encode(
        _items.map((e) => e.toMap()).toList(),
      );
      await prefs.setString('calculator_items', itemsJson);

      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลเรียบร้อยแล้ว')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกไม่สำเร็จ: $e (พื้นที่เต็ม?)'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  void showHelpDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryGold = const Color(0xFFD4AF37);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryGold.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.help_outline, color: primaryGold, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                'คำอธิบายปุ่ม',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: isDark ? Colors.grey[200] : Colors.grey[800],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHelpItem(
                  Icons.add_circle_outline,
                  'เพิ่มรายการคำนวณใหม่',
                  color: const Color(0xFF81C784), // Soft Green
                ),
                _buildHelpItem(
                  Icons.refresh_rounded,
                  'รีโหลดราคาจากแหล่งข้อมูลทั้งหมด',
                  color: const Color(0xFF2196F3), // Liquid Blue
                ),
                _buildHelpItem(
                  Icons.download_rounded,
                  'ดึงราคาปัจจุบัน (เลือกทองแท่ง/รูปพรรณ)',
                  color: primaryGold,
                ),
                _buildHelpItem(
                  Icons.copy_rounded,
                  'คัดลอกข้อมูลรายการนี้',
                  color: Colors.blueAccent,
                ),
                _buildHelpItem(
                  Icons.cleaning_services_outlined,
                  'ล้างข้อมูลในกล่องนี้',
                  color: Colors.orangeAccent,
                ),
                _buildHelpItem(
                  Icons.close,
                  'ลบกล่องนี้ทิ้ง',
                  color: const Color(0xFFE57373), // Soft Red
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(
                    color: Theme.of(context).dividerColor.withOpacity(0.05),
                  ),
                ),
                _buildHelpItem(
                  Icons.delete_outline,
                  'ลบรายการทั้งหมด (เมนูมุมขวาบน)',
                  color: const Color(0xFFE57373),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'ระบบจะบันทึกข้อมูลให้อัตโนมัติทุกครั้งที่มีการเปลี่ยนแปลง ข้อมูลจะหายไปหากลบแอป',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'เข้าใจแล้ว',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHelpItem(IconData icon, String text, {Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = color ?? (isDark ? Colors.grey[400] : Colors.grey[600]);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (iconColor as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addItem({bool scrollToBottom = true}) {
    setState(() {
      _items.add(CalculatorItem(id: DateTime.now().toIso8601String()));
    });
    _saveItems(silent: true);

    // Smooth Scroll to bottom
    if (scrollToBottom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  void _clearAllItems() {
    if (_items.isEmpty) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE57373).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: Color(0xFFE57373),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'ยืนยันลบทั้งหมด',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'รายการคำนวณทั้งหมดจะถูกลบ\nคุณแน่ใจหรือไม่?',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _items.clear();
              });
              _saveItems(silent: true);
            },
            child: const Text('ลบทั้งหมด', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _removeItem(int index) {
    if (index < 0 || index >= _items.length) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE57373).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline, color: Color(0xFFE57373)),
            ),
            const SizedBox(width: 16),
            const Text(
              'ยืนยันการลบ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'คุณต้องการลบรายการที่ ${index + 1} ใช่ไหม?',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _items.removeAt(index);
              });
              _saveItems(silent: true);
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  double get _totalProfitLoss {
    return _items.fold(0.0, (sum, item) => sum + item.profitLoss);
  }

  // Flexible Fetch Price
  Future<bool> _fetchPriceFromSource(
    int index,
    String sourceName,
    String sourceType,
    String purity, {
    bool silent = false,
    GoldBoard? boardSnapshot,
  }) async {
    bool isCancelled = false;
    bool dialogShown = false;

    try {
      if (!silent) {
        dialogShown = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
            final primaryColor = const Color(0xFF2196F3);

            return AlertDialog(
              backgroundColor: bgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_download_rounded,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'กำลังโหลด',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'แหล่งข้อมูล: $sourceName',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    isCancelled = true;
                    Navigator.pop(context);
                  },
                  child: Text(
                    'ยกเลิก',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }

      double? value;
      String updateTime = '';
      final board = boardSnapshot ?? await _repository.refresh();

      if (sourceName == 'สมาคมค้าทองคำ') {
        final price = board.latest;
        String priceStr = sourceType == 'bar'
            ? price.bullionBuy
            : price.ornamentBuy;
        value = double.tryParse(priceStr.replaceAll(',', ''));
        updateTime = board.updatedAt.isNotEmpty
            ? board.updatedAt
            : '${price.date} ${price.time}'.trim();
      } else {
        // Shop Price
        final shops = board.shops;
        final shop = shops.firstWhere(
          (s) => s.name == sourceName,
          orElse: () => ShopPrice(
            name: '',
            goldBar965: null,
            goldBar9999: null,
            ornament965: null,
            ornamentBuyBack: null,
          ),
        );

        if (shop.name.isEmpty) {
          throw Exception('ไม่พบข้อมูลร้านค้า');
        }

        String priceStr = '';
        if (purity == '99.99%') {
          // 99.99% usually only Bar
          if (sourceType == 'bar') {
            priceStr = shop.goldBar9999?.buy ?? '';
          } else {
            // Fallback if generic ornament
            priceStr = '';
          }
        } else {
          // 96.5%
          if (sourceType == 'bar') {
            priceStr = shop.goldBar965?.buy ?? '';
          } else {
            // Special Exception for Chin Hua Heng (Ornament)
            // User requested to use the 'Sell' price as the 'Buy' price
            if (shop.name.contains('จินฮั้วเฮง') ||
                shop.name.toLowerCase().contains('chin hua heng')) {
              priceStr = shop.ornament965?.sell ?? '';
            } else {
              priceStr = shop.ornament965?.buy ?? '';
            }

            if (priceStr.isEmpty || priceStr == '-') {
              priceStr = shop.ornamentBuyBack?.buy ?? '';
            }
          }
        }

        value = double.tryParse(priceStr.replaceAll(',', ''));
        updateTime = DateFormat('HH:mm').format(DateTime.now());
      }

      if (!mounted) return false;
      if (isCancelled) return false;

      if (dialogShown) {
        Navigator.pop(context); // Close dialog
      }

      if (value != null) {
        setState(() {
          _items[index].buyPrice = value;
          _items[index].priceUpdateTime = updateTime;
          _items[index].sourceName = sourceName;
          _items[index].sourceType = sourceType;
          _items[index].purity = purity;
        });
        _saveItems(silent: true);
        return true;
      } else {
        if (!silent) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบราคารับซื้อสำหรับประเภทนี้')),
          );
        }
        return false;
      }
    } catch (e) {
      if (!mounted) return false;
      if (isCancelled) return false;
      if (dialogShown) {
        Navigator.pop(context);
      }
      if (!silent) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
      return false;
    }
  }

  Future<void> _reloadAllPrices({
    bool silent = false,
    GoldBoard? boardSnapshot,
  }) async {
    if (!silent) {
      // Show global loading snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Text('กำลังอัปเดตราคาจากแหล่งข้อมูล...'),
            ],
          ),
          duration: Duration(days: 1), // Indefinite until dismissed
        ),
      );
    }

    int updatedCount = 0;
    int failedCount = 0;
    bool hasSourceItems = false;

    GoldBoard board;
    try {
      board = boardSnapshot ?? await _repository.refresh();
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('อัปเดตข้อมูลไม่สำเร็จ: $e')));
      }
      return;
    }

    // Filter indices first to avoid concurrent modification issues (though not modifying list here)
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.sourceName != null && item.sourceType != null) {
        hasSourceItems = true;
        // Add artificial delay to prevent rate limiting? No, let's just run.
        final success = await _fetchPriceFromSource(
          i,
          item.sourceName!,
          item.sourceType!,
          item.purity ?? '96.5%',
          silent: true,
          boardSnapshot: board,
        );
        if (success) {
          updatedCount++;
        } else {
          failedCount++;
        }
      }
    }

    if (!mounted) return;

    if (!silent) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (updatedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'อัปเดตสำเร็จ $updatedCount รายการ${failedCount > 0 ? ' (ไม่สำเร็จ $failedCount)' : ''}',
            ),
            backgroundColor: const Color(0xFF4CAF50), // Green
          ),
        );
      } else if (failedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('อัปเดตไม่สำเร็จ $failedCount รายการ'),
            backgroundColor: const Color(0xFFEF5350), // Red
          ),
        );
      } else if (!hasSourceItems) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่พบรายการที่เชื่อมต่อกับแหล่งข้อมูล'),
          ),
        );
      }
    }
  }

  void _showSourceSelector(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        // Default to 'bar' initially or based on previous choice?
        // Let's default to 'bar'.
        // Let's default to 'bar'.
        String selectedType = 'bar';
        String selectedPurity = '96.5%';

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
            final primaryGold = const Color(0xFFD4AF37);

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 20),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Text(
                    'เลือกแหล่งข้อมูล',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Type Toggle (Segmented)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'ประเภททอง',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildSlidingToggle(
                          label1: 'ทองคำแท่ง',
                          label2: 'ทองรูปพรรณ',
                          isFirstSelected: selectedType == 'bar',
                          onSelect1: () =>
                              setSheetState(() => selectedType = 'bar'),
                          onSelect2: () => setSheetState(() {
                            selectedType = 'ornament';
                            if (selectedPurity == '99.99%')
                              selectedPurity = '96.5%';
                          }),
                          isDark: isDark,
                          activeColor: primaryGold,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Purity Toggle (Segmented)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'ความบริสุทธิ์',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildSlidingToggle(
                          label1: '96.5% (มาตรฐาน)',
                          label2: '99.99%',
                          isFirstSelected: selectedPurity == '96.5%',
                          onSelect1: () =>
                              setSheetState(() => selectedPurity = '96.5%'),
                          onSelect2: () => setSheetState(() {
                            selectedPurity = '99.99%';
                            selectedType = 'bar';
                          }),
                          isDark: isDark,
                          activeColor: primaryGold,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Source List
                  Expanded(
                    child: FutureBuilder<List<ShopPrice>>(
                      future: _repository.snapshot != null
                          ? Future.value(_repository.snapshot!.shops)
                          : _repository.refresh().then((board) => board.shops),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        // Association + Shops
                        return ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          children: [
                            // 1. Association (Standard)
                            if (selectedPurity == '96.5%')
                              _buildSourceItem(
                                leading: _buildSourceLogo(
                                  'สมาคมค้าทองคำ',
                                  size: 48,
                                ),
                                name: 'สมาคมค้าทองคำ',
                                desc: 'ราคามาตรฐาน',
                                isDark: isDark,
                                onTap: () {
                                  Navigator.pop(context);
                                  _fetchPriceFromSource(
                                    index,
                                    'สมาคมค้าทองคำ',
                                    selectedType,
                                    selectedPurity,
                                  );
                                },
                              ),

                            if (snapshot.hasData)
                              ...snapshot.data!.map((shop) {
                                // Filter logic
                                if (!_hasValidShopData(shop)) {
                                  return const SizedBox.shrink();
                                }

                                // User Request: Hide Ausiris for Ornament
                                if (selectedType == 'ornament' &&
                                    shop.name.toLowerCase().contains(
                                      'ausiris',
                                    )) {
                                  return const SizedBox.shrink();
                                }

                                return _buildSourceItem(
                                  leading: _buildSourceLogo(
                                    shop.name,
                                    size: 48,
                                  ),
                                  name: shop.name,
                                  desc: 'ราคาร้านค้า',
                                  isDark: isDark,
                                  onTap: () {
                                    Navigator.pop(context);
                                    _fetchPriceFromSource(
                                      index,
                                      shop.name,
                                      selectedType,
                                      selectedPurity,
                                    );
                                  },
                                );
                              }),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSlidingToggle({
    required String label1,
    required String label2,
    required bool isFirstSelected,
    required VoidCallback onSelect1,
    required VoidCallback onSelect2,
    required bool isDark,
    required Color activeColor,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          // Sliding Indicator
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            alignment: isFirstSelected
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF333333) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Labels
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onSelect1,
                  behavior: HitTestBehavior.translucent,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontFamily: 'SukhumvitSet', // Inherit or explicit?
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isFirstSelected
                            ? activeColor
                            : (isDark ? Colors.grey[500] : Colors.grey[600]),
                      ),
                      child: Text(label1),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: onSelect2,
                  behavior: HitTestBehavior.translucent,
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontFamily: 'SukhumvitSet',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: !isFirstSelected
                            ? activeColor
                            : (isDark ? Colors.grey[500] : Colors.grey[600]),
                      ),
                      child: Text(label2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSourceLogo(String name, {double size = 40}) {
    String? assetName;
    final lowerName = name.toLowerCase();

    if (name == 'สมาคมค้าทองคำ') {
      assetName = 'Gold_Traders_Association.png';
    } else if (lowerName.contains('aurora')) {
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
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset('assets/logos/$assetName', fit: BoxFit.cover),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.storefront_rounded,
          color: const Color(0xFFD4AF37),
          size: size * 0.6,
        ),
      ),
    );
  }

  Widget _buildSourceItem({
    required Widget leading,
    required String name,
    required String desc,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Add visual separation
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(20), // More rounded
        border: isDark
            ? Border.all(color: Colors.white.withOpacity(0.05))
            : Border.all(color: Colors.grey.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Logo with subtle glow/shadow
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: leading,
                ),
                const SizedBox(width: 16),
                // Text Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1A1A1A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Trailing Arrow Button
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Color(0xFFD4AF37),
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _copyAllItems() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ไม่มีรายการให้คัดลอก')));
      return;
    }

    final currencyFormat = NumberFormat("#,##0.00", "th_TH");
    final buffer = StringBuffer();
    double totalProfit = 0;

    buffer.writeln('สรุปรายการคำนวณทองคำ');
    buffer.writeln('====================');

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      final profit = item.profitLoss;
      totalProfit += profit;

      final buy = item.buyPrice != null
          ? currencyFormat.format(item.buyPrice)
          : '-';
      final cost = item.costPrice != null
          ? currencyFormat.format(item.costPrice)
          : '-';

      // Simple formatted weight
      String weight = item.weight.toString();
      if (weight.endsWith('.0')) {
        weight = weight.substring(0, weight.length - 2);
      }

      final profitStr = currencyFormat.format(profit);
      final sign = profit > 0 ? '+' : '';

      buffer.writeln('รายการที่ ${i + 1}');
      buffer.writeln('น้ำหนัก: $weight บาท');
      buffer.writeln('รับซื้อ: $buy ฿');
      buffer.writeln('ต้นทุน: $cost ฿');
      buffer.writeln('กำไร: $sign$profitStr ฿');
      buffer.writeln('--------------------');
    }

    final totalSign = totalProfit > 0 ? '+' : '';
    final totalStr = currencyFormat.format(totalProfit);
    final totalLabel = totalProfit >= 0 ? 'กำไรรวม' : 'ขาดทุนรวม';

    buffer.writeln('$totalLabel: $totalSign$totalStr ฿');
    buffer.writeln('====================');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('คัดลอกรายการทั้งหมดแล้ว'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Center(
      child: Transform.translate(
        offset: const Offset(0, -20), // Shift up
        child: const Text(
          'คำนวณกำไรขายทอง',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayoutScaffold(
      // adUnitId: AdConfig.calculatorPageBanner, // Moved to body
      controller: _scrollController, // Pass the controller
      showScrollToTop: true,
      scrollDownTarget: _bottomKey,
      onRefresh: () => _reloadAllPrices(), // Enable Pull-to-Refresh
      header: _buildHeader(context),
      bottomWidget: _isSelectionMode
          ? _buildSelectionBar()
          : _buildTotalSummary(),
      body: Screenshot(
        controller: _screenshotController,
        child: Column(
          children: [
            // Ad at the top of the content (Paper Sheet)
            if (!_isCapturing)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: BannerAdWithCloseButton(
                  adUnitId: AdConfig.calculatorPageBanner,
                ),
              ),

            // Summary Chart with Mode Toggle
            if (_items.isNotEmpty) _buildChartSection(),
            if (_items.isNotEmpty) const SizedBox(height: 24),

            // Popup Menu for actions (Simulated as a row in the "paper" or header?)
            // The original design had it in AppBar actions.
            // Let's put a Row of actions at the top of the paper sheet.
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Switch to Icon-Only mode on small screens (< 380px) to prevent wrapping
                  final isSmallScreen = constraints.maxWidth < 380;
                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;

                  // Hide Actions during Capture/Selection
                  if (_isCapturing || _isSelectionMode)
                    return const SizedBox.shrink();

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLiquidButton(
                        icon: Icons.camera_alt_rounded,
                        label: isSmallScreen ? null : 'บันทึกรูป',
                        tooltip: 'บันทึกรูปภาพ',
                        onTap: _captureAndShare,
                        color: const Color(
                          0xFF2E7D32,
                        ), // Emerald Green for Premium/Save
                      ),
                      const SizedBox(width: 12),
                      _buildLiquidButton(
                        icon: Icons.add,
                        label: isSmallScreen ? null : 'เพิ่มรายการ',
                        tooltip: 'เพิ่มรายการ',
                        onTap: () => _addItem(),
                        color: const Color(0xFFD4AF37), // Liquid Gold
                      ),
                      const SizedBox(width: 12),
                      // Liquid Menu Button (Outlined/Glassy) - Height Fixed
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    Colors.white.withOpacity(0.25),
                                    Colors.white.withOpacity(0.1),
                                  ]
                                : [
                                    Colors.grey.withOpacity(0.1),
                                    Colors.grey.withOpacity(0.05),
                                  ],
                          ),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.4)
                                : Colors.grey.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.2 : 0.15,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _showOptionsMenu,
                            borderRadius: BorderRadius.circular(24),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.more_vert_rounded,
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Items List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _isCapturing && _isSelectionMode
                  ? _items.where((i) => _selectedIds.contains(i.id)).length
                  : (_items.length + 1), // Only show selected during capture
              itemBuilder: (context, index) {
                // 1. FILTERED LIST FOR CAPTURE
                if (_isCapturing && _isSelectionMode) {
                  final selectedItems = _items
                      .where((i) => _selectedIds.contains(i.id))
                      .toList();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildCalculatorCard(
                      _items.indexOf(selectedItems[index]),
                    ),
                  );
                }

                // 2. NORMAL / SELECTION LIST
                if (index == _items.length) {
                  // Bottom Add Button (Hide in selection mode or capture)
                  if (_isSelectionMode || _isCapturing)
                    return const SizedBox.shrink();

                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;
                  final primaryGold = const Color(0xFFD4AF37);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => _addItem(),
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E1E1E)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: primaryGold.withOpacity(0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryGold.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_circle,
                                  color: primaryGold,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'เพิ่มรายการอีก',
                                  style: TextStyle(
                                    color: primaryGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20), // Spacer below button
                      ],
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildCalculatorCard(index),
                );
              },
            ),
            // Extra space for sticky footer overlap prevention (handled by MainLayoutScaffold padding but good to be safe)
            SizedBox(key: _bottomKey, height: 80),
          ],
        ),
      ),
    );
  }

  // --- SELECTION BOTTOM BAR ---
  // We need to override build method of scaffold or use Stack to overlay this bar?
  // Actually, MainLayoutScaffold has body. We can put it in MainLayoutScaffold's bottomWidget?
  // Or just floating on top of body (Stack is already there in scaffold?).
  // Let's return a Stack in body wrapper or use an Overlay.
  // Wait, MainLayoutScaffold has 'bottomWidget'. But that is inside the scrollable area...
  // When in Selection Mode, we should probably REPLACE the "Price Summary" with "Action Bar".

  Widget _buildSelectionBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGold = const Color(0xFFD4AF37);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Left: Counter Badge (Fixed Width)
            Container(
              width: 100, // Fixed width equal to Save button
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: primaryGold.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: primaryGold,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${_selectedIds.length}', // Only Number
                        style: TextStyle(
                          color: primaryGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16), // Gap
            // Center: Cancel Button (Circle)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedIds.clear();
                  });
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Icon(Icons.close, color: Colors.grey[400], size: 24),
                ),
              ),
            ),

            const SizedBox(width: 16), // Gap
            // Right: Save Button (Fixed Width)
            SizedBox(
              width: 100, // Fixed width matching Badge
              height: 48,
              child: ElevatedButton(
                onPressed: _selectedIds.isEmpty ? null : _performCapture,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32), // Emerald Green
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero, // Centered content
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.camera_alt_rounded, size: 20),
                    SizedBox(width: 6),
                    Text(
                      'บันทึก',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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

  Widget _buildLiquidButton({
    required IconData icon,
    String? label,
    String? tooltip,
    required VoidCallback onTap,
    required Color color,
    bool isOutlined = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: tooltip ?? label ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: label != null
              ? const EdgeInsets.symmetric(horizontal: 20, vertical: 12)
              : const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isOutlined
                  ? [color.withOpacity(0.1), color.withOpacity(0.05)]
                  : (isDark
                        ? [color.withOpacity(0.35), color.withOpacity(0.15)]
                        : [color, color.withOpacity(0.8)]),
              stops: const [0.0, 1.0],
            ),
            border: Border.all(
              color: isOutlined
                  ? color.withOpacity(0.3)
                  : (isDark
                        ? color.withOpacity(0.5)
                        : Colors.white.withOpacity(0.2)),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(isDark ? 0.2 : 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: isOutlined ? color : Colors.white),
              if (label != null) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isOutlined ? color : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculatorCard(int index) {
    final item = _items[index];
    final isSelected = _selectedIds.contains(item.id);

    return CalculatorCard(
      key: ValueKey(item.id),
      item: item,
      itemIndex: index,
      // Selection Props
      isSelectionMode: _isSelectionMode,
      isSelected: isSelected,
      onSelect: (val) {
        setState(() {
          if (val == true) {
            _selectedIds.add(item.id);
          } else {
            _selectedIds.remove(item.id);
          }
        });
      },
      onRemove: () => _removeItem(index),
      onClear: () {
        setState(() {
          _items[index].buyPrice = null;
          _items[index].costPrice = null;
          _items[index].weight = 1.0;
          _items[index].priceUpdateTime = null;
          _items[index].sourceName = null;
          _items[index].sourceType = null;
        });
        _saveItems(silent: true);
      },
      onFetchPrice: (_) => _showSourceSelector(index),
      onReload: () {
        final item = _items[index];
        if (item.sourceName != null && item.sourceType != null) {
          _fetchPriceFromSource(
            index,
            item.sourceName!,
            item.sourceType!,
            item.purity ?? '96.5%',
          );
        }
      },
      onUpdate: () {
        setState(() {});
        _saveItems(silent: true);
      },
    );
  }

  bool _hasValidShopData(ShopPrice shop) {
    return shop.goldBar965 != null ||
        shop.goldBar9999 != null ||
        shop.ornament965 != null ||
        shop.ornamentBuyBack != null;
  }

  Widget _buildChartSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Smooth Sliding Toggle
          if (_items.isNotEmpty) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: 44,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey[200],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        alignment: _chartMode == ChartMode.costVsProfit
                            ? Alignment.centerLeft
                            : Alignment.centerRight,
                        child: Container(
                          width:
                              (constraints.maxWidth - 8) / 2, // Dynamic width
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF444444)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _chartMode = ChartMode.costVsProfit;
                                  _touchedIndex = -1;
                                });
                              },
                              behavior: HitTestBehavior.translucent,
                              child: Center(
                                child: Text(
                                  'ภาพรวม',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: _chartMode == ChartMode.costVsProfit
                                        ? const Color(0xFFD4AF37)
                                        : (isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _chartMode = ChartMode.byShop;
                                  _touchedIndex = -1;
                                });
                              },
                              behavior: HitTestBehavior.translucent,
                              child: Center(
                                child: Text(
                                  'แยกตามร้าน',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: _chartMode == ChartMode.byShop
                                        ? const Color(0xFFD4AF37)
                                        : (isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[600]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],

          // Chart Display with Fade Transition
          // Chart Display with Fade Transition
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.topCenter,
                children: <Widget>[
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _chartMode == ChartMode.costVsProfit
                ? _buildCostVsProfitChart(key: const ValueKey('cost_chart'))
                : _buildShopBreakdownChart(key: const ValueKey('shop_chart')),
          ),
        ],
      ),
    );
  }

  Widget _buildCostVsProfitChart({Key? key}) {
    double totalCost = 0;
    double totalProfit = 0;

    for (var item in _items) {
      if (item.buyPrice != null && item.costPrice != null) {
        totalCost += item.costPrice! * item.weight;
        // totalBuyVal unused
        totalProfit += (item.buyPrice! - item.costPrice!) * item.weight;
      }
    }

    if (totalCost == 0) return const SizedBox.shrink();

    final isProfit = totalProfit >= 0;
    // Richer/Professional Colors
    final primaryGold = const Color(0xFFCBA135); // Metallic Gold
    final profitColor = const Color(0xFF4CAF50); // Professional Green
    final lossColor = const Color(0xFFEF5350); // Professional Red
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isTouched0 = _touchedIndex == 0;
    final isTouched1 = _touchedIndex == 1;

    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 10),
      height: 250,
      child: Stack(
        children: [
          Center(
            child: PieChart(
              swapAnimationDuration: const Duration(milliseconds: 400),
              swapAnimationCurve: Curves.easeInOutCubic,
              PieChartData(
                sectionsSpace: 4, // Clean separation
                centerSpaceRadius: 70, // Thicker ring
                centerSpaceColor: Colors.transparent, // Ensure clean hole
                startDegreeOffset: -90,
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sections: [
                  // Cost Segment
                  PieChartSectionData(
                    color: isDark ? primaryGold.withOpacity(0.35) : primaryGold,
                    value: totalCost,
                    title: '',
                    radius: isTouched0 ? 38 : 32,
                    showTitle: false,
                    borderSide: isDark
                        ? BorderSide(
                            color: primaryGold.withOpacity(0.5),
                            width: 1,
                          )
                        : BorderSide.none,
                    badgeWidget: isTouched0
                        ? _buildBadgeIcon(Icons.savings_outlined)
                        : null,
                    badgePositionPercentageOffset: 0.98,
                  ),
                  // Profit/Loss Segment
                  PieChartSectionData(
                    color: isDark
                        ? (isProfit ? profitColor : lossColor).withOpacity(0.35)
                        : (isProfit ? profitColor : lossColor),
                    value: isProfit ? totalProfit : (totalProfit.abs()),
                    title: '',
                    radius: isTouched1 ? 38 : 32, // Slightly larger
                    showTitle: false,
                    borderSide: isDark
                        ? BorderSide(
                            color: (isProfit ? profitColor : lossColor)
                                .withOpacity(0.5),
                            width: 1,
                          )
                        : BorderSide.none,
                    badgeWidget: isTouched1
                        ? _buildBadgeIcon(
                            isProfit ? Icons.trending_up : Icons.trending_down,
                          )
                        : null,
                    badgePositionPercentageOffset: 0.98,
                  ),
                ],
              ),
            ),
          ),
          // Background Circle and Center Text (Overlay Layer)
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? const Color(0xFF121212)
                        : Colors.white, // Opaque solid color
                    gradient: isDark
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.25),
                              Colors.white.withOpacity(0.1),
                            ],
                          )
                        : null,
                    border: isDark
                        ? Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 130,
                  height: 130,
                  child: Center(
                    child: _buildChartCenterText(
                      totalCost,
                      totalProfit,
                      isProfit,
                      isDark,
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

  // Small icon badge helper
  Widget _buildBadgeIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Icon(icon, size: 14, color: Colors.black87),
    );
  }

  Widget _buildChartCenterText(
    double totalCost,
    double totalProfit,
    bool isProfit,
    bool isDark,
  ) {
    final textColor = isDark ? Colors.white70 : Colors.black54;

    // 0 = Cost, 1 = Profit/Loss, -1 = Default (Profit)
    if (_touchedIndex == 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'ต้นทุนรวม',
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.w400,
              fontFamily: 'Roboto',
            ),
          ),
          const SizedBox(height: 4),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _currencyFormat.format(totalCost),
              style: const TextStyle(
                fontSize: 24, // Matched size
                fontWeight: FontWeight.w600,
                color: Color(0xFFD4AF37),
                fontFamily: 'Roboto',
                letterSpacing: -0.5,
              ),
            ),
          ),
          // Invisible Spacer to prevent jumping
          const SizedBox(height: 6),
          Opacity(
            opacity: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: const Text(
                '+0.0%',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }

    // Default or Profit Touched
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isProfit ? 'กำไรทั้งหมด' : 'ขาดทุนทั้งหมด',
          style: TextStyle(
            fontSize: 14,
            color: textColor,
            fontWeight: FontWeight.w400,
            fontFamily: 'Roboto',
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _currencyFormat.format(totalProfit),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: isProfit
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFEF5350),
              fontFamily: 'Roboto',
              letterSpacing: -0.5,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: (isProfit ? Colors.green : Colors.red).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${isProfit ? '+' : ''}${(totalProfit / totalCost * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isProfit
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFEF5350),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniLogo(String name, double size) {
    String? assetName;
    final lowerName = name.toLowerCase();

    if (name == 'สมาคมค้าทองคำ') {
      assetName = 'Gold_Traders_Association.png';
    } else if (lowerName.contains('aurora')) {
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
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset('assets/logos/$assetName', fit: BoxFit.cover),
      );
    }

    return Icon(Icons.link, size: size, color: const Color(0xFFD4AF37));
  }

  Widget _buildShopBreakdownChart({Key? key}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Group items by source
    Map<String, double> shopProfits = {};
    Map<String, double> shopCosts = {}; // Add costs map
    Map<String, Color> shopColors = {};

    // Custom color mapping for each shop
    Color _getShopColor(String shopName) {
      final lowerName = shopName.toLowerCase();
      if (lowerName.contains('สมาคม') || lowerName.contains('association')) {
        return const Color(0xFFFFD700); // Yellow
      } else if (lowerName.contains('aurora') ||
          lowerName.contains('ออโรร่า')) {
        return const Color(0xFFFFB347); // Orange-yellow
      } else if (lowerName.contains('mts')) {
        return const Color(0xFF2196F3); // Blue
      } else if (lowerName.contains('hua seng heng') ||
          lowerName.contains('ฮั่วเซ่งเฮง')) {
        return const Color(0xFFB71C1C); // Dark red
      } else if (lowerName.contains('chin hua heng') ||
          lowerName.contains('จินฮั้วเฮง')) {
        return const Color(0xFFF0E68C); // Pale yellow
      } else if (lowerName.contains('ausiris')) {
        return const Color(0xFF81D4FA); // Light blue
      } else {
        return Colors.grey; // Default for unknown shops
      }
    }

    for (var item in _items) {
      if (item.buyPrice != null && item.costPrice != null) {
        final sourceName = item.sourceName ?? 'ไม่ระบุ';
        final profit = (item.buyPrice! - item.costPrice!) * item.weight;
        final cost = item.costPrice! * item.weight;

        shopProfits[sourceName] = (shopProfits[sourceName] ?? 0) + profit;
        shopCosts[sourceName] = (shopCosts[sourceName] ?? 0) + cost;

        if (!shopColors.containsKey(sourceName)) {
          shopColors[sourceName] = _getShopColor(sourceName);
        }
      }
    }

    // Sort shopProfits (High Profit -> Low Profit) to sync with List and Chart Sections
    final sortedEntries = shopProfits.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedEntries.isEmpty) return const SizedBox.shrink();

    // Create pie sections using SORTED entries
    List<PieChartSectionData> sections = [];

    // Use asMap() to get correct index
    sortedEntries.asMap().forEach((index, entry) {
      final shop = entry.key;
      final profit = entry.value;
      final isTouched = _touchedIndex == index;

      sections.add(
        PieChartSectionData(
          color: isDark
              ? shopColors[shop]!.withOpacity(0.35)
              : shopColors[shop]!,
          value: profit.abs(),
          title: '',
          radius: isTouched ? 38 : 32,
          showTitle: false,
          borderSide: isDark
              ? BorderSide(color: shopColors[shop]!.withOpacity(0.5), width: 1)
              : BorderSide.none,
          badgeWidget: isTouched ? _buildShopBadge(shop) : null,
          badgePositionPercentageOffset: 0.98,
        ),
      );
    });

    return Column(
      key: key,
      children: [
        // Pie Chart Area
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          height: 250,
          child: Stack(
            children: [
              Center(
                child: PieChart(
                  swapAnimationDuration: const Duration(milliseconds: 400),
                  swapAnimationCurve: Curves.easeInOutCubic,
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 70,
                    centerSpaceColor: Colors.transparent, // Ensure clean hole
                    startDegreeOffset: -90,
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = pieTouchResponse
                              .touchedSection!
                              .touchedSectionIndex;
                        });
                      },
                    ),
                    sections: sections,
                  ),
                ),
              ),
              // Center Text and Background Circle (Overlay Layer)
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? null : Colors.white,
                        gradient: isDark
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.25),
                                  Colors.white.withOpacity(0.1),
                                ],
                              )
                            : null,
                        border: isDark
                            ? Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 1,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.2 : 0.05,
                            ),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: Center(
                        child: _buildShopCenterText(
                          sortedEntries,
                          shopCosts,
                          isDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Shop Breakdown List - Pass sorted list
        _buildShopBreakdownList(sortedEntries, shopCosts, shopColors),
      ],
    );
  }

  Widget _buildShopBreakdownList(
    List<MapEntry<String, double>> sortedEntries,
    Map<String, double> shopCosts,
    Map<String, Color> shopColors,
  ) {
    if (sortedEntries.isEmpty) return const SizedBox();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 20,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'รายละเอียดรายร้าน',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
        ),
        ...sortedEntries.asMap().entries.map((mapEntry) {
          final index = mapEntry.key;
          final entry = mapEntry.value;
          final shopName = entry.key;
          final profit = entry.value;
          final cost = shopCosts[shopName] ?? 1.0;
          final isProfit = profit >= 0;
          final roi = (profit / cost) * 100;

          // Theme colors
          final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
          final borderColor = isDark
              ? Colors.white10
              : Colors.grey.withOpacity(0.1);
          final profitColor = const Color(0xFF4CAF50);
          final lossColor = const Color(0xFFEF5350);
          final valueColor = isProfit ? profitColor : lossColor;

          final isSelected = _touchedIndex == index;

          return InkWell(
            onTap: () {
              setState(() {
                if (_touchedIndex == index) {
                  _touchedIndex = -1; // Deselect
                } else {
                  _touchedIndex = index; // Select
                }
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // Premium Selection: Tinted BG
                color: isSelected
                    ? valueColor.withOpacity(isDark ? 0.15 : 0.05)
                    : cardBg,
                borderRadius: BorderRadius.circular(20),
                // Premium Selection: Thicker Colored Border
                border: Border.all(
                  color: isSelected ? valueColor : borderColor,
                  width: isSelected ? 2.0 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    // Premium Selection: Colored Glow
                    color: isSelected
                        ? valueColor.withOpacity(isDark ? 0.3 : 0.2)
                        : Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                    blurRadius: isSelected ? 16 : 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 1. Logo Section
                  Container(
                    padding: const EdgeInsets.all(2), // White border effect
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: _buildMiniLogo(shopName, 40),
                  ),
                  const SizedBox(width: 16),

                  // 2. Shop Name (Flexible)
                  Expanded(
                    flex: 5, // Give name 55% of space
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shopName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // ROI Badge (Moved below name for clean look)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: valueColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isProfit
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                size: 14,
                                color: valueColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${roi.toStringAsFixed(2)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: valueColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Profit Value (Right Aligned)
                  Expanded(
                    flex:
                        4, // Give profit 45% of space (Constrained for FittedBox)
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${isProfit ? '+' : ''}${_currencyFormat.format(profit)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: valueColor,
                              letterSpacing: -0.5,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'กำไรสุทธิ',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildShopBadge(String shopName) {
    String? assetName;
    final lowerName = shopName.toLowerCase();

    if (shopName == 'สมาคมค้าทองคำ' || lowerName.contains('สมาคม')) {
      assetName = 'Gold_Traders_Association.png';
    } else if (lowerName.contains('aurora')) {
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
        width: 24, // Badge size
        height: 24,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset('assets/logos/$assetName', fit: BoxFit.cover),
      );
    }

    return _buildBadgeIcon(Icons.store);
  }

  Widget _buildShopCenterText(
    List<MapEntry<String, double>> sortedEntries, // Changed to List
    Map<String, double> shopCosts,
    bool isDark,
  ) {
    final textColor = isDark ? Colors.white70 : Colors.black54;

    if (_touchedIndex >= 0 && _touchedIndex < sortedEntries.length) {
      final shopName = sortedEntries[_touchedIndex].key; // Use List index
      final profit = sortedEntries[_touchedIndex].value;
      final cost = shopCosts[shopName]!;
      final isProfit = profit >= 0;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            shopName,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.w400,
              fontFamily: 'Roboto',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _currencyFormat.format(profit),
              style: TextStyle(
                fontSize: 24, // Matched size
                fontWeight: FontWeight.w600,
                color: isProfit
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFEF5350),
                fontFamily: 'Roboto',
                letterSpacing: -0.5,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Percentage Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (isProfit ? Colors.green : Colors.red).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${isProfit ? '+' : ''}${(profit / cost * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isProfit
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFEF5350),
              ),
            ),
          ),
        ],
      );
    }

    // Default: Show total
    double totalProfit = sortedEntries.fold(
      0,
      (sum, entry) => sum + entry.value,
    );
    double totalCost = shopCosts.values.fold(0, (sum, c) => sum + c);
    final isProfit = totalProfit >= 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'กำไรรวม',
          style: TextStyle(
            fontSize: 14,
            color: textColor,
            fontWeight: FontWeight.w400,
            fontFamily: 'Roboto',
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _currencyFormat.format(totalProfit),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: isProfit
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFEF5350),
              fontFamily: 'Roboto',
              letterSpacing: -0.5,
            ),
          ),
        ),
        if (totalCost > 0) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (isProfit ? Colors.green : Colors.red).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${isProfit ? '+' : ''}${(totalProfit / totalCost * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isProfit
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFEF5350),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTotalSummary() {
    final total = _totalProfitLoss;
    final isProfit = total >= 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgContainerColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final profitColor = const Color(0xFF81C784); // Soft Green
    final lossColor = const Color(0xFFE57373); // Soft Red
    final valueColor = isProfit ? profitColor : lossColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: bgContainerColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'สรุปผลกำไรสุทธิ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isProfit ? 'กำไร' : 'ขาดทุน',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${total > 0 ? "+" : ""}${_currencyFormat.format(total)} ฿',
                    style: TextStyle(
                      fontSize: 32, // Large and impressive
                      fontWeight: FontWeight.w300, // Thin
                      color: valueColor,
                      letterSpacing: -1.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CalculatorCard extends StatefulWidget {
  final CalculatorItem item;
  final int itemIndex;
  final VoidCallback onRemove;
  final VoidCallback onClear;
  final Function(bool) onFetchPrice;
  final VoidCallback onUpdate;
  final VoidCallback onReload;
  // Selection Props
  final bool isSelectionMode;
  final bool isSelected;
  final Function(bool?)? onSelect;

  const CalculatorCard({
    super.key,
    required this.item,
    required this.itemIndex,
    required this.onRemove,
    required this.onClear,
    required this.onFetchPrice,
    required this.onUpdate,
    required this.onReload,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelect,
  });

  @override
  State<CalculatorCard> createState() => _CalculatorCardState();
}

class _CalculatorCardState extends State<CalculatorCard> {
  late TextEditingController _buyController;
  late TextEditingController _costController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _buyController = TextEditingController(
      text: _formatNumber(widget.item.buyPrice),
    );
    _costController = TextEditingController(
      text: _formatNumber(widget.item.costPrice),
    );
    _weightController = TextEditingController(
      text: _formatNumber(widget.item.weight),
    );
  }

  @override
  void didUpdateWidget(covariant CalculatorCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncController(_buyController, widget.item.buyPrice);
    _syncController(_costController, widget.item.costPrice);
    _syncController(_weightController, widget.item.weight);
  }

  void _syncController(TextEditingController controller, double? value) {
    String currentText = controller.text;
    double? currentValue = double.tryParse(currentText.replaceAll(',', ''));
    if (currentValue == value) return;
    if (currentText == "" && value == null) return;
    // Fix: If text is empty and value is 0 (likely due to user clearing logic), don't force "0"
    if (currentText == "" && value == 0.0) return;

    if (value != null && currentText.endsWith('.')) {
      if (double.tryParse(currentText) == value) return;
    }
    String newText = _formatNumber(value);
    if (currentValue != value) {
      controller.text = newText;
    }
  }

  String _formatNumber(double? value) {
    if (value == null) return '';
    String s = value.toString();
    if (s.endsWith('.0')) return s.substring(0, s.length - 2);
    return s;
  }

  @override
  void dispose() {
    _buyController.dispose();
    _costController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _onBuyChanged(String val) {
    final value = double.tryParse(val);
    widget.item.buyPrice = value;
    widget.onUpdate();
  }

  void _onCostChanged(String val) {
    final value = double.tryParse(val);
    widget.item.costPrice = value;
    widget.onUpdate();
  }

  void _onWeightChanged(String val) {
    final value = double.tryParse(val) ?? 0.0;
    widget.item.weight = value;
    widget.onUpdate();
  }

  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCapturing = false;

  Future<void> _captureAndShare() async {
    if (_isCapturing) return;

    // Premium Check Removed
    // Captured features are now free for everyone.

    setState(() {
      _isCapturing = true; // Use to confirm capture
    });

    try {
      final image = await _screenshotController.capture(
        delay: const Duration(milliseconds: 10),
        pixelRatio: 3.0, // High res
      );

      if (image != null) {
        if (kIsWeb) {
          await saveImageWeb(image, 'gold_calc_${widget.itemIndex}.png');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ดาวน์โหลดรูปภาพเรียบร้อยแล้ว'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        } else {
          // 1. Save to Gallery
          await Gal.putImageBytes(image);

          // 2. Share
          final directory = await getTemporaryDirectory();
          final imagePath = await File(
            '${directory.path}/gold_calc_${widget.itemIndex}.png',
          ).create();
          await imagePath.writeAsBytes(image);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('บันทึกรูปภาพและเริ่มแชร์...')),
            );
          }

          // iPad share handling
          final box = context.findRenderObject() as RenderBox?;
          await Share.shareXFiles(
            [XFile(imagePath.path)],
            text: 'คำนวณราคาทอง - รายการที่ ${widget.itemIndex + 1}',
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
    final profit = widget.item.profitLoss;
    final isProfit = profit >= 0;
    final currencyFormat = NumberFormat("#,##0.00", "th_TH");

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryGold = const Color(0xFFD4AF37); // Premium Gold

    return Screenshot(
      controller: _screenshotController,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Minimal List Item Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left Side: Selection or Icon
                  Row(
                    children: [
                      if (widget.isSelectionMode)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Transform.scale(
                            scale: 1.2,
                            child: Checkbox(
                              value: widget.isSelected,
                              onChanged: widget.onSelect,
                              activeColor: primaryGold,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              side: BorderSide(color: primaryGold, width: 2),
                            ),
                          ),
                        )
                      else
                        Icon(
                          Icons.calculate_outlined,
                          size: 20,
                          color: primaryGold,
                        ),

                      if (!widget
                          .isSelectionMode) // Spacing if not selection mode (checkbox has padding)
                        const SizedBox(width: 8),

                      Text(
                        'รายการที่ ${widget.itemIndex + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryGold,
                        ),
                      ),
                    ],
                  ),

                  // Actions (Hide if in selection mode)
                  if (!widget.isSelectionMode)
                    Row(
                      children: [
                        if (!_isCapturing)
                          IconButton(
                            icon: Icon(
                              Icons.camera_alt_rounded,
                              size: 20,
                              color: Colors.grey[400],
                            ),
                            onPressed: _captureAndShare,
                            tooltip: 'บันทึกรูปภาพ',
                          ),
                        IconButton(
                          icon: Icon(
                            Icons.cleaning_services_outlined,
                            size: 18,
                            color: Colors.grey[400],
                          ),
                          onPressed: widget.onClear,
                          tooltip: 'ล้างค่า',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.grey[400],
                          ),
                          onPressed: widget.onRemove,
                          tooltip: 'ลบรายการ',
                        ),
                      ],
                    ),
                ],
              ),
            ),

            Divider(color: Theme.of(context).dividerColor.withOpacity(0.05)),

            // Inputs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMinimalField(
                              controller: _buyController,
                              label: 'ราคารับซื้อ',
                              suffix: '฿',
                              onChanged: _onBuyChanged,
                            ),
                            if (widget.item.priceUpdateTime != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6, left: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      'อัปเดต: ${widget.item.priceUpdateTime}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[400],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    if (widget.item.sourceName != null) ...[
                                      Text(
                                        ' • ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                      _buildMiniLogo(
                                        widget.item.sourceName!,
                                        14,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          '${widget.item.sourceName!} (${widget.item.purity ?? "96.5%"})',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[600],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: widget.onReload,
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Icon(
                                            Icons.refresh_rounded,
                                            size: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildSourceActions(primaryGold),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMinimalField(
                          controller: _costController,
                          label: 'ต้นทุนที่ซื้อ',
                          suffix: '฿',
                          onChanged: _onCostChanged,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildMinimalField(
                          controller: _weightController,
                          label: 'น้ำหนัก (บาท)',
                          onChanged: _onWeightChanged,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Result + Watermark Footer (Combined)
            Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: _isCapturing ? 12 : 20, // Adjust padding
              ),
              decoration: BoxDecoration(
                color: isProfit
                    ? Colors.green.withOpacity(0.02)
                    : Colors.red.withOpacity(0.02),
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.05),
                  ),
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Profit/Loss Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isProfit ? 'กำไรโดยประมาณ' : 'ขาดทุนโดยประมาณ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${profit > 0 ? "+" : ""}${currencyFormat.format(profit)}',
                              style: TextStyle(
                                color: isProfit
                                    ? const Color(0xFF81C784)
                                    : const Color(0xFFE57373),
                                fontWeight: FontWeight.w300,
                                fontSize: 24,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isCapturing) ...[
                    const SizedBox(height: 12),
                    // Watermark (Only visible when capturing)
                    const Text(
                      'Thai Gold View',
                      style: TextStyle(
                        fontFamily: 'Playfair Display',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Color(0xFFD4AF37), // Gold
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceActions(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(Icons.download_rounded, color: color),
        tooltip: 'เลือกแหล่งข้อมูล',
        onPressed: () => widget.onFetchPrice(true), // Trigger selector
      ),
    );
  }

  Widget _buildMiniLogo(String name, double size) {
    String? assetName;
    final lowerName = name.toLowerCase();

    if (name == 'สมาคมค้าทองคำ') {
      assetName = 'Gold_Traders_Association.png';
    } else if (lowerName.contains('aurora')) {
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
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset('assets/logos/$assetName', fit: BoxFit.cover),
      );
    }

    return Icon(Icons.link, size: size, color: const Color(0xFFD4AF37));
  }

  Widget _buildMinimalField({
    required TextEditingController controller,
    required String label,
    String? suffix,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: 0.5,
          ),
          decoration: InputDecoration(
            isDense: true,
            suffixText: suffix,
            suffixStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD4AF37), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

extension PopupExtension on Widget {
  Widget asPopupMenu(
    BuildContext context, {
    required Function(bool) onSelected,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<bool>(
      icon: this,
      tooltip: 'ดึงราคาปัจจุบัน',
      onSelected: onSelected,
      // Moved down further
      offset: const Offset(0, 60),
      // Background color matching the button style (Light Grey)
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: true,
          child: Row(
            children: [
              const Icon(Icons.crop_landscape_rounded, color: Colors.grey),
              const SizedBox(width: 12),
              Text(
                'ทองคำแท่ง',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: false,
          child: Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.grey),
              const SizedBox(width: 12),
              Text(
                'ทองรูปพรรณ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
