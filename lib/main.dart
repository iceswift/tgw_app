import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/foundation.dart';
import 'package:gold_app/utils/http_setup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gold_app/pages/pin_code_page.dart';
import 'dart:async';
import 'package:gold_app/pages/gold_price_page.dart';
import 'package:gold_app/pages/gold_history_page.dart'; // Import History Page
import 'package:gold_app/pages/graph_page.dart';
import 'package:gold_app/pages/calculator_page.dart';
import 'package:gold_app/pages/settings_page.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:gold_app/services/background_service.dart';
import 'package:gold_app/services/fcm_service.dart'; // FCM Service
import 'package:firebase_core/firebase_core.dart'; // Firebase Core
import 'package:firebase_messaging/firebase_messaging.dart'; // Firebase Messaging
import 'package:gold_app/config/firebase_web_config.dart';
import 'package:gold_app/pages/privacy_consent_page.dart';
import 'package:gold_app/repositories/gold_data_repository.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import for date formatting
import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    if (FirebaseWebConfig.firebaseReady) {
      await Firebase.initializeApp(options: FirebaseWebConfig.options);
      await FCMService.initialize();
    }
  } else {
    // Initialize Firebase
    await Firebase.initializeApp();

    // Set Background Message Handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initialize FCM (Permissions, Topics, etc.)
    await FCMService.initialize();

    // Initialize Mobile Ads
    MobileAds.instance.initialize();

    // Initialize Background Service (Fallback Polling)
    await BackgroundService.initialize();
    await BackgroundService.registerTask();
  }

  // Initialize Date Formatting for Thai
  await initializeDateFormatting('th', null);

  // Load Settings (Await for PIN state)
  await SettingsController().loadSettings();
  await GoldDataRepository.instance.initialize();

  // Check Terms Acceptance
  final prefs = await SharedPreferences.getInstance();
  final isTermsAccepted = prefs.getBool('is_terms_accepted') ?? false;

  // BYPASS SSL CERTIFICATE ERROR (FOR DEVELOPMENT ONLY)
  if (kDebugMode) {
    setupHttpOverrides();
  }

  runApp(MyApp(isTermsAccepted: isTermsAccepted));
}

class SettingsController with ChangeNotifier {
  static final SettingsController _instance = SettingsController._internal();
  factory SettingsController() => _instance;
  SettingsController._internal();

  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('th');

  // --- App Lock State ---
  bool _isAppLockEnabled = false;
  String? _pinCode;
  bool _isLocked = false;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get isAppLockEnabled => _isAppLockEnabled;

  bool get isLocked => _isLocked;
  String? get termsAcceptedDate => _termsAcceptedDate;

  String? get joinDate => _joinDate;

  String? _termsAcceptedDate;
  String? _joinDate;

  // Initialize from SharedPrefs
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load Local Preferences
    _isAppLockEnabled = prefs.getBool('isAppLockEnabled') ?? false;
    _pinCode = prefs.getString('pinCode');
    _termsAcceptedDate = prefs.getString('terms_accepted_date');
    _joinDate = prefs.getString('join_date');

    if (_joinDate == null) {
      _joinDate = DateTime.now().toIso8601String();
      await prefs.setString('join_date', _joinDate!);
    }

    if (_isAppLockEnabled) {
      _isLocked = true;
    }
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setLocale(Locale newLocale) {
    _locale = newLocale;
    notifyListeners();
  }

  // --- App Lock Methods ---
  Future<bool> setAppLock(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setBool('isAppLockEnabled', enabled);
    if (success) {
      _isAppLockEnabled = enabled;
      if (!enabled) {
        _isLocked = false;
      }
      notifyListeners();
    }
    return success;
  }

  Future<bool> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final success = await prefs.setString('pinCode', pin);
    if (success) {
      _pinCode = pin;
      notifyListeners();
    }
    return success;
  }

  bool verifyPin(String input) {
    return _pinCode == input;
  }

  void lockApp() {
    if (_isAppLockEnabled) {
      _isLocked = true;
      notifyListeners();
    }
  }

  void unlockApp() {
    _isLocked = false;
    notifyListeners();
  }
}

class MyApp extends StatefulWidget {
  final bool isTermsAccepted;
  const MyApp({super.key, required this.isTermsAccepted});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final SettingsController _settingsController = SettingsController();
  late bool _isTermsAccepted;

  @override
  void initState() {
    super.initState();
    _isTermsAccepted = widget.isTermsAccepted; // Initialize state from prop
    WidgetsBinding.instance.addObserver(this); // Observe App Lifecycle
    GoldDataRepository.instance.startPolling();
    _settingsController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    GoldDataRepository.instance.stopPolling();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Lock when app goes to background (paused)
    if (state == AppLifecycleState.paused) {
      _settingsController.lockApp();
    } else if (state == AppLifecycleState.resumed) {
      GoldDataRepository.instance.refreshIfStale(
        const Duration(minutes: 2),
        reason: GoldRefreshReason.resume,
      );
    }
  }

  void _onTermsAccepted() {
    setState(() {
      _isTermsAccepted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: AppScrollBehavior(),
      title: 'Gold Price App',
      locale: _settingsController.locale,
      themeMode: _settingsController.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA), // Off-White
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFFF5BF03),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000), // Pure Black
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFFDA9100),
        ),
      ),
      home: Stack(
        children: [
          // If NOT accepted -> Show Consent Page
          // If Accepted -> Show Home Page
          if (!_isTermsAccepted)
            PrivacyConsentPage(onAccepted: _onTermsAccepted)
          else
            GoldHomePage(settingsController: _settingsController),

          // App Lock Overlay (Only shows if Locked AND Terms Accepted? Or always?)
          // Usually we want lock to work always.
          // Note: If on Consent Page, maybe we don't enforce lock yet?
          // But strict security says lock everything.
          // Let's keep it global.
          if (_settingsController.isLocked &&
              _settingsController.isAppLockEnabled)
            const Positioned.fill(
              child: PinCodePage(initialMode: PinMode.verify),
            ),
        ],
      ),
    );
  }
}

class GoldHomePage extends StatefulWidget {
  final SettingsController settingsController;

  const GoldHomePage({super.key, required this.settingsController});

  @override
  State<GoldHomePage> createState() => _GoldHomePageState();
}

class _GoldHomePageState extends State<GoldHomePage> {
  int _currentIndex = 0;

  // 1. Define Global Keys for each page to access their state
  final GlobalKey<GoldPricePageState> _goldPriceKey = GlobalKey();
  final GlobalKey<GoldHistoryPageState> _historyKey = GlobalKey();
  final GlobalKey<GraphPageState> _graphKey = GlobalKey();
  final GlobalKey<CalculatorPageState> _calculatorKey = GlobalKey();

  bool _isFirstCalcVisit = true;
  int _shimmerIndex = -1;
  Timer? _shimmerTimer;

  Future<void> _checkAndShowCalcHelp() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool('has_shown_calc_help') ?? false;

    if (!hasShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculatorKey.currentState?.showHelpDialog();
      });
      await prefs.setBool('has_shown_calc_help', true);
    }
  }

  @override
  void dispose() {
    _shimmerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 2. Pass keys to pages
    final List<Widget> pages = [
      GoldPricePage(key: _goldPriceKey),
      GoldHistoryPage(key: _historyKey),
      GraphPage(key: _graphKey),
      CalculatorPage(key: _calculatorKey),
      SettingsPage(controller: widget.settingsController),
    ];

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(index: _currentIndex, children: pages),
          ),
        ],
      ),
      bottomNavigationBar: _buildCustomBottomNavBar(context),
    );
  }

  Widget _buildCustomBottomNavBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    const int itemCount = 5;

    // Active Color sharing logic with _buildNavItem
    final activeColor = isDark
        ? const Color(0xFFFFD700)
        : const Color(0xFFF5BF03);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double itemWidth = constraints.maxWidth / itemCount;

            return SizedBox(
              height: 60,
              child: Stack(
                children: [
                  // 1. Sliding Line Indicator
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                    top: 0,
                    left: _currentIndex * itemWidth,
                    width: itemWidth,
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: activeColor,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: activeColor.withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. Navigation Items
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(0, Icons.monetization_on, 'ราคาทอง'),
                        _buildNavItem(1, Icons.history, 'ประวัติ'),
                        _buildNavItem(2, Icons.show_chart, 'กราฟ'),
                        _buildNavItem(3, Icons.calculate, 'คำนวณ'),
                        _buildNavItem(4, Icons.settings, 'ตั้งค่า'),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final isShimmering = _shimmerIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Unselected Color
    final unselectedColor = isDark ? Colors.grey[600] : Colors.grey[400];

    // Base Color (Static Gold)
    final baseColor = isDark
        ? const Color(0xFFFFD700)
        : const Color(0xFFF5BF03);

    // Highlight Color (White/Pale Gold for Shimmer)
    final highlightColor = isDark ? Colors.white : Colors.white;

    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isSelected ? baseColor : unselectedColor, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? baseColor : unselectedColor,
          ),
        ),
      ],
    );

    // Only apply shimmer if explicitly triggered and item is selected
    if (isSelected && isShimmering) {
      content = Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        period: const Duration(milliseconds: 1500),
        child: content,
      );
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          // 3. Scroll to Top Logic
          if (_currentIndex == index) {
            switch (index) {
              case 0:
                _goldPriceKey.currentState?.scrollToTop();
                break;
              case 1:
                _historyKey.currentState?.scrollToTop();
                break;
              case 2:
                _graphKey.currentState?.scrollToTop();
                break;
              case 3:
                _calculatorKey.currentState?.scrollToTop();
                break;
            }
            return;
          }

          // Reset any existing timer
          _shimmerTimer?.cancel();

          setState(() {
            _currentIndex = index;
            _shimmerIndex = index; // Start shimmer
          });

          // Stop shimmer after 1.5 seconds
          _shimmerTimer = Timer(const Duration(milliseconds: 1500), () {
            if (mounted) {
              setState(() {
                _shimmerIndex = -1;
              });
            }
          });

          if (index == 3 && _isFirstCalcVisit) {
            _isFirstCalcVisit = false;
            _checkAndShowCalcHelp();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: content,
      ),
    );
  }
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}
