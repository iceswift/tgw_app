// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:math';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

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
  late final String viewType;

  @override
  void initState() {
    super.initState();
    viewType =
        'trading-view-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(10000)}';

    final String hexColor =
        '#${widget.backgroundColor.value.toRadixString(16).substring(2)}';

    final htmlString =
        '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        body { 
          margin: 0; 
          padding: 0; 
          background-color: $hexColor; 
          width: 100vw; 
          height: 100vh;
          overflow: hidden;
        }
        .tradingview-widget-copyright { display: none !important; }
      </style>
    </head>
    <body>
      ${widget.htmlContent}
    </body>
    </html>
    ''';

    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final iframe = html.IFrameElement()
        ..width = '100%'
        ..height = '100%'
        ..style.border = 'none'
        ..style.backgroundColor = hexColor
        ..srcdoc = htmlString;
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      child: HtmlElementView(viewType: viewType),
    );
  }
}
