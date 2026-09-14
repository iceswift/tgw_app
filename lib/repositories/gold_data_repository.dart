import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gold_app/models/gold_board_model.dart';
import 'package:gold_app/services/gold_api_service.dart';
import 'package:gold_app/services/widget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef GoldBoardLoader = Future<GoldBoard> Function();

/// Single source of truth for the current gold-data snapshot.
///
/// The repository prefers `/api/board`, deduplicates concurrent refreshes and
/// keeps compatibility with the current server contract where `revision` may
/// be absent. Cache persistence and lifecycle/FCM wiring are added in later
/// phases.
class GoldDataRepository extends ChangeNotifier {
  GoldDataRepository({
    GoldApiService? apiService,
    GoldBoardLoader? boardLoader,
    bool enableCache = true,
    bool updateHomeWidget = true,
  }) : _apiService = apiService ?? GoldApiService(),
       _boardLoader = boardLoader,
       _enableCache = enableCache,
       _updateHomeWidget = updateHomeWidget;

  static final GoldDataRepository instance = GoldDataRepository();

  final GoldApiService _apiService;
  final GoldBoardLoader? _boardLoader;
  final bool _enableCache;
  final bool _updateHomeWidget;

  static const String _cacheKey = 'gold_board_snapshot_v1';
  static const String _cacheSavedAtKey = 'gold_board_snapshot_saved_at_v1';

  GoldBoard? _snapshot;
  Future<GoldBoard>? _refreshInFlight;
  Object? _lastError;
  bool _isRefreshing = false;
  DateTime? _lastSuccessfulRefreshAt;
  Timer? _pollingTimer;

  GoldBoard? get snapshot => _snapshot;
  Object? get lastError => _lastError;
  bool get isRefreshing => _isRefreshing;
  DateTime? get lastSuccessfulRefreshAt => _lastSuccessfulRefreshAt;

  Future<void> initialize() async {
    if (!_enableCache || _snapshot != null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      if (cachedJson == null) return;
      _snapshot = GoldBoard.fromJson(
        jsonDecode(cachedJson) as Map<String, dynamic>,
      );
      _lastSuccessfulRefreshAt = DateTime.tryParse(
        prefs.getString(_cacheSavedAtKey) ?? '',
      );
      notifyListeners();
    } catch (error) {
      debugPrint('Unable to restore gold snapshot cache: $error');
    }
  }

  void startPolling({Duration interval = const Duration(minutes: 15)}) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) {
      unawaited(refreshIfStale(interval));
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<bool> refreshIfStale(Duration maxAge) async {
    final refreshedAt = _lastSuccessfulRefreshAt;
    if (refreshedAt != null &&
        DateTime.now().difference(refreshedAt) < maxAge) {
      return false;
    }
    await refresh();
    return true;
  }

  Future<bool> refreshForRevision(int? incomingRevision) async {
    final currentRevision = _snapshot?.revision;
    if (incomingRevision != null &&
        currentRevision != null &&
        incomingRevision <= currentRevision) {
      return false;
    }
    await refresh();
    return true;
  }

  Future<GoldBoard> refresh() {
    final activeRefresh = _refreshInFlight;
    if (activeRefresh != null) return activeRefresh;

    _isRefreshing = true;
    _lastError = null;
    notifyListeners();

    final refresh = _refreshAndCache();
    _refreshInFlight = refresh;

    refresh
        .then((board) {
          _snapshot = board;
        })
        .catchError((Object error) {
          _lastError = error;
        })
        .whenComplete(() {
          _isRefreshing = false;
          _refreshInFlight = null;
          notifyListeners();
        });

    return refresh;
  }

  Future<GoldBoard> _refreshAndCache() async {
    final board = await _loadSnapshot();
    _snapshot = board;
    _lastSuccessfulRefreshAt = DateTime.now();
    if (_updateHomeWidget) {
      try {
        await WidgetService().updateWidget(board.latest);
      } catch (error) {
        debugPrint('Unable to update home widget: $error');
      }
    }
    if (_enableCache) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cacheKey, jsonEncode(board.toJson()));
        await prefs.setString(
          _cacheSavedAtKey,
          _lastSuccessfulRefreshAt!.toIso8601String(),
        );
      } catch (error) {
        debugPrint('Unable to persist gold snapshot cache: $error');
      }
    }
    return board;
  }

  Future<bool> refreshIfChanged() async {
    final latest = await _apiService.getLatestPrice();
    final current = _snapshot?.latest;
    if (current == null) {
      await refresh();
      return true;
    }

    final changed =
        latest.date != current.date ||
        latest.time != current.time ||
        latest.bullionBuy != current.bullionBuy ||
        latest.bullionSell != current.bullionSell;

    if (changed) await refresh();
    return changed;
  }

  Future<GoldBoard> _loadSnapshot() async {
    if (_boardLoader != null) return _boardLoader();

    try {
      return await _apiService.getBoard();
    } catch (boardError) {
      debugPrint(
        'Board loading failed, falling back to individual endpoints: '
        '$boardError',
      );

      final results = await Future.wait<dynamic>([
        _apiService.getLatestPrice(),
        _apiService.getLatestPrices(),
        _apiService.getJewelryPrices(),
        _apiService.getShopPrices(),
      ]);
      final latest = results[0];

      return GoldBoard(
        status: 'fallback',
        source: 'individual_endpoints',
        marketStatus: latest.marketStatus,
        updatedAt: '${latest.date} ${latest.time}'.trim(),
        stale: false,
        ageSeconds: 0,
        latest: latest,
        history: results[1],
        jewelry: results[2],
        shops: results[3],
      );
    }
  }
}
