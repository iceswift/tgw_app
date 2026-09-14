// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:math';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:gold_app/utils/ad_config.dart';

class NativeBannerAdWidget extends StatefulWidget {
  final String? adUnitId;
  const NativeBannerAdWidget({super.key, this.adUnitId});

  @override
  State<NativeBannerAdWidget> createState() => _NativeBannerAdWidgetState();
}

class _NativeBannerAdWidgetState extends State<NativeBannerAdWidget> {
  late String viewType;

  bool get _isIosStandalonePwa {
    final navigator = html.window.navigator as dynamic;
    final userAgent = navigator.userAgent as String? ?? '';
    final platform = navigator.platform as String? ?? '';
    final maxTouchPoints = navigator.maxTouchPoints as int? ?? 0;
    final isIos = RegExp(r'iPad|iPhone|iPod', caseSensitive: false)
            .hasMatch(userAgent) ||
        (platform == 'MacIntel' && maxTouchPoints > 1);
    final isStandalone =
        html.window.matchMedia('(display-mode: standalone)').matches ||
        navigator.standalone == true;

    return isIos && isStandalone;
  }

  @override
  void initState() {
    super.initState();
    // Default slot if none provided (using the user's provided slot)
    final String adSlot = widget.adUnitId ?? '5266631204';
    final String adClient = 'ca-pub-6833768369533754';

    viewType =
        'adsense-banner-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1000)}';

    // Register AdSense element
    // Note: We use a simple <div> container and append the ins tag + refresh script
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final container = html.DivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'flex'
        ..style.justifyContent = 'center'
        ..style.alignItems = 'center';

      final ins = html.Element.tag('ins')
        ..className = 'adsbygoogle'
        ..style.display = 'block'
        ..style.minWidth = '320px'
        ..style.height = '50px'
        ..setInnerHtml('')
        ..attributes['data-ad-client'] = adClient
        ..attributes['data-ad-slot'] = adSlot
        ..attributes['data-ad-format'] = 'auto'
        ..attributes['data-full-width-responsive'] = 'true';

      final script = html.ScriptElement()
        ..innerHtml = '(adsbygoogle = window.adsbygoogle || []).push({});';

      container.append(ins);
      container.append(script);

      return container;
    });
  }

  @override
  Widget build(BuildContext context) {
    // iOS standalone PWAs can route touches through an HtmlElementView instead
    // of Flutter's canvas. Keep the app responsive by omitting web ads there.
    if (!AdConfig.showAds || _isIosStandalonePwa) {
      return const SizedBox.shrink();
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 320,
          minHeight: 50,
          maxWidth: 600, // Reasonable max width for top banners
          maxHeight: 100,
        ),
        child: HtmlElementView(viewType: viewType),
      ),
    );
  }
}
