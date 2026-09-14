import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gold_app/models/gold_board_model.dart';
import 'package:gold_app/models/gold_price_latest_model.dart';
import 'package:gold_app/repositories/gold_data_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('GoldBoard parses optional numeric and string revisions', () {
    expect(_boardFromJson(12).revision, 12);
    expect(_boardFromJson('13').revision, 13);
    expect(_boardFromJson(null).revision, isNull);
  });

  test('repository deduplicates concurrent refresh requests', () async {
    final completer = Completer<GoldBoard>();
    var calls = 0;
    final repository = GoldDataRepository(
      enableCache: false,
      boardLoader: () {
        calls++;
        return completer.future;
      },
    );

    final first = repository.refresh();
    final second = repository.refresh();
    expect(identical(first, second), isTrue);
    expect(calls, 1);

    final board = _board();
    completer.complete(board);
    expect(await first, same(board));
    await pumpEventQueue();
    expect(repository.snapshot, same(board));
    expect(repository.isRefreshing, isFalse);
  });

  test('repository persists and restores the latest snapshot', () async {
    SharedPreferences.setMockInitialValues({});
    final board = _board();
    final writer = GoldDataRepository(boardLoader: () async => board);
    await writer.refresh();

    final reader = GoldDataRepository(
      boardLoader: () => throw StateError('cache should load without network'),
    );
    await reader.initialize();

    expect(reader.snapshot?.revision, 1);
    expect(reader.snapshot?.latest.bullionBuy, '60000');
    expect(reader.snapshot?.updatedAt, '2026-09-14T13:30:00+07:00');
  });
}

GoldBoard _boardFromJson(dynamic revision) => GoldBoard.fromJson({
  if (revision != null) 'revision': revision,
  'latest': <String, dynamic>{},
});

GoldBoard _board() => GoldBoard(
  revision: 1,
  status: 'ok',
  source: 'test',
  marketStatus: 'open',
  updatedAt: '2026-09-14T13:30:00+07:00',
  stale: false,
  ageSeconds: 0,
  latest: GoldPriceLatest(
    date: '2026-09-14',
    time: '13:30',
    round: '1',
    marketStatus: 'open',
    bullionBuy: '60000',
    bullionSell: '60100',
    ornamentBuy: '59000',
    ornamentSell: '60500',
    spot: '2500',
    thb: '32',
    change: '100',
  ),
  history: const [],
  jewelry: const [],
  shops: const [],
);
