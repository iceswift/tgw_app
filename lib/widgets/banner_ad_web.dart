import 'package:flutter/material.dart';

/// Web ads are intentionally disabled.
///
/// AdSense inside Flutter's [HtmlElementView] creates an opaque platform-view
/// surface in regular browsers, which can cover page content even when the ad
/// itself is empty or hidden. Mobile builds use banner_ad_mobile.dart and are
/// unaffected by this web-only implementation.
class NativeBannerAdWidget extends StatelessWidget {
  final String? adUnitId;

  const NativeBannerAdWidget({super.key, this.adUnitId});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
