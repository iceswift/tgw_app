import 'package:flutter/material.dart';

import 'banner_ad_stub.dart'
    if (dart.library.io) 'banner_ad_mobile.dart'
    if (dart.library.html) 'banner_ad_web.dart';

class BannerAdWidget extends StatefulWidget {
  final String? adUnitId;

  const BannerAdWidget({super.key, this.adUnitId});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  @override
  Widget build(BuildContext context) {
    return NativeBannerAdWidget(adUnitId: widget.adUnitId);
  }
}
