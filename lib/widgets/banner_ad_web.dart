import 'dart:async';

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
  static const double _bannerHeight = 100;
  static const double _minimumBannerWidth = 320;
  late String viewType;
  html.MutationObserver? _adStatusObserver;
  Timer? _sizeProbe;
  Timer? _loadTimeout;
  bool _isVisible = true;
  bool _hasResolvedStatus = false;
  bool _hasRequestedAd = false;

  bool get _isIosStandalonePwa {
    final navigator = html.window.navigator as dynamic;
    final userAgent = navigator.userAgent as String? ?? '';
    final platform = navigator.platform as String? ?? '';
    final maxTouchPoints = navigator.maxTouchPoints as int? ?? 0;
    final isIos =
        RegExp(r'iPad|iPhone|iPod', caseSensitive: false).hasMatch(userAgent) ||
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
        ..style.height = '${_bannerHeight}px'
        ..style.overflow = 'hidden'
        // A platform view paints as an opaque grey surface while AdSense is
        // still resolving the slot. Keep that surface transparent until an
        // actual creative has been filled.
        ..style.opacity = '0'
        ..style.pointerEvents = 'none'
        ..style.backgroundColor = 'transparent'
        ..style.display = 'flex'
        ..style.justifyContent = 'center'
        ..style.alignItems = 'center';

      final ins = html.Element.tag('ins')
        ..className = 'adsbygoogle'
        ..style.display = 'block'
        ..style.width = '100%'
        ..style.minWidth = '${_minimumBannerWidth}px'
        ..style.height = '${_bannerHeight}px'
        ..style.backgroundColor = 'transparent'
        ..setInnerHtml('')
        ..attributes['data-ad-client'] = adClient
        ..attributes['data-ad-slot'] = adSlot
        ..attributes['data-ad-format'] = 'auto'
        ..attributes['data-full-width-responsive'] = 'true';

      _adStatusObserver =
          html.MutationObserver((mutations, observer) {
            final status = ins.attributes['data-ad-status'];
            if (status == null) return;
            _hasResolvedStatus = true;
            if (status == 'filled') {
              container.style
                ..opacity = '1'
                ..pointerEvents = 'auto';
            } else if (status == 'unfilled') {
              _hideBanner();
            }
          })..observe(
            ins,
            attributes: true,
            attributeFilter: const ['data-ad-status'],
          );

      container.append(ins);

      void requestAdWhenSized() {
        if (_hasRequestedAd || container.clientWidth < _minimumBannerWidth) {
          return;
        }
        _hasRequestedAd = true;
        _sizeProbe?.cancel();

        // AdSense must only be requested after Flutter has attached and sized
        // the platform view. Hidden IndexedStack children have width 0.
        container.append(
          html.ScriptElement()
            ..innerHtml = '(adsbygoogle = window.adsbygoogle || []).push({});',
        );

        _loadTimeout = Timer(const Duration(seconds: 12), () {
          if (!_hasResolvedStatus) _hideBanner();
        });
      }

      _sizeProbe = Timer.periodic(
        const Duration(milliseconds: 250),
        (_) => requestAdWhenSized(),
      );
      requestAdWhenSized();

      return container;
    });
  }

  void _hideBanner() {
    if (!mounted || !_isVisible) return;
    setState(() => _isVisible = false);
  }

  @override
  void dispose() {
    _loadTimeout?.cancel();
    _sizeProbe?.cancel();
    _adStatusObserver?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // iOS standalone PWAs can route touches through an HtmlElementView instead
    // of Flutter's canvas. Keep the app responsive by omitting web ads there.
    if (!AdConfig.showAds || _isIosStandalonePwa || !_isVisible) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: _bannerHeight,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: _minimumBannerWidth,
            maxWidth: 600,
          ),
          child: SizedBox.expand(child: HtmlElementView(viewType: viewType)),
        ),
      ),
    );
  }
}
