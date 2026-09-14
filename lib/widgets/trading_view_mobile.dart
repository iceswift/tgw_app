import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class NativeTradingViewWidget extends StatefulWidget {
  final String htmlContent;
  final Color backgroundColor;

  const NativeTradingViewWidget({
    super.key,
    required this.htmlContent,
    this.backgroundColor = const Color(0xFF0F0F0F),
  });

  @override
  State<NativeTradingViewWidget> createState() =>
      _NativeTradingViewWidgetState();
}

class _NativeTradingViewWidgetState extends State<NativeTradingViewWidget> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(widget.backgroundColor)
      ..loadHtmlString(_buildHtml(widget.htmlContent));
  }

  String _buildHtml(String content) {
    // Convert Color to Hex String #RRGGBB
    final String hexColor =
        '#${widget.backgroundColor.value.toRadixString(16).substring(2)}';

    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { margin: 0; padding: 0; background-color: $hexColor; }
        .tradingview-widget-copyright { display: none !important; }
      </style>
    </head>
    <body style="height: 100vh; overflow: hidden;">
      $content
    </body>
    </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: WebViewWidget(controller: controller),
    );
  }
}
