import 'package:flutter/foundation.dart';
import 'package:gold_app/models/gold_board_model.dart';
import 'package:gold_app/services/gold_api_service.dart';

typedef GoldBoardLoader = Future<GoldBoard> Function();

/// Single source of truth for the current gold-data snapshot.
///
/// The repository prefers `/api/board`, deduplicates concurrent refreshes and
/// keeps compatibility with the current server contract where `revision` may
/// be absent. Cache persistence and lifecycle/FCM wiring are added in later
/// phases.
class GoldDataRepository extends ChangeNotifier {
  GoldDataRepository({GoldApiService? apiService, GoldBoardLoader? boardLoader})
    : _apiService = apiService ?? GoldApiService(),
      _boardLoader = boardLoader;

  static final GoldDataRepository instance = GoldDataRepository();

  final GoldApiService _apiService;
  final GoldBoardLoader? _boardLoader;

  GoldBoard? _snapshot;
  Future<GoldBoard>? _refreshInFlight;
  Object? _lastError;
  bool _isRefreshing = false;

  GoldBoard? get snapshot => _snapshot;
  Object? get lastError => _lastError;
  bool get isRefreshing => _isRefreshing;

  Future<GoldBoard> refresh() {
    final activeRefresh = _refreshInFlight;
    if (activeRefresh != null) return activeRefresh;

    _isRefreshing = true;
    _lastError = null;
    notifyListeners();

    final refresh = _loadSnapshot();
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
