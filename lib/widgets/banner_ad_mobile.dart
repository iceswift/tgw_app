import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:gold_app/utils/ad_config.dart';

class NativeBannerAdWidget extends StatefulWidget {
  final String? adUnitId;
  const NativeBannerAdWidget({super.key, this.adUnitId});

  @override
  State<NativeBannerAdWidget> createState() => _NativeBannerAdWidgetState();
}

class _NativeBannerAdWidgetState extends State<NativeBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  late String _adUnitId;

  @override
  void initState() {
    super.initState();
    if (!AdConfig.showAds) return;

    _adUnitId =
        widget.adUnitId ??
        (Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/6300978111'
            : 'ca-app-pub-3940256099942544/2934735716');
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdLoaded && _bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox.shrink();
  }
}
