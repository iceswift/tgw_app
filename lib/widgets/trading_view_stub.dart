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
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F0F0F),
      body: Center(
        child: Text(
          'กราฟรองรับเฉพาะบนมือถือ (Android/iOS) หรือ Web',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
