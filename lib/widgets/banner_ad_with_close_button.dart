import 'package:flutter/material.dart';
import 'package:gold_app/widgets/banner_ad_widget.dart';

class BannerAdWithCloseButton extends StatelessWidget {
  final String? adUnitId;

  const BannerAdWithCloseButton({super.key, this.adUnitId});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Center(child: BannerAdWidget(adUnitId: adUnitId)),
    );
  }
}
