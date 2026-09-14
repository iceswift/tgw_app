import 'package:flutter/material.dart';

import 'trading_view_stub.dart'
    if (dart.library.io) 'trading_view_mobile.dart'
    if (dart.library.html) 'trading_view_web.dart';

class TradingViewWidget extends StatelessWidget {
  final String htmlContent;
  final Color backgroundColor;

  const TradingViewWidget({
    super.key,
    required this.htmlContent,
    this.backgroundColor = const Color(0xFF0F0F0F),
  });

  @override
  Widget build(BuildContext context) {
    return NativeTradingViewWidget(
      htmlContent: htmlContent,
      backgroundColor: backgroundColor,
    );
  }
}
