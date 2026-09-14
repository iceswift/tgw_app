import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gold_app/widgets/banner_ad_with_close_button.dart';

class MainLayoutScaffold extends StatefulWidget {
  final Widget header;
  final Widget body;
  final Widget? bottomWidget;
  final ScrollPhysics? physics;
  final Color backgroundColor;
  final RefreshCallback? onRefresh;
  final bool useScrollView;
  final ScrollController? controller;
  final bool showScrollToTop;
  final GlobalKey? scrollDownTarget;
  final IconData? scrollDownIcon; // Custom icon for down state
  final double headerHeight;
  final String? adUnitId;

  const MainLayoutScaffold({
    super.key,
    required this.header,
    required this.body,
    this.bottomWidget,
    this.physics,
    this.backgroundColor = const Color(0xFF18181A), // Premium Charcoal
    this.onRefresh,
    this.useScrollView = true,
    this.controller,
    this.showScrollToTop = false,
    this.scrollDownTarget,
    this.scrollDownIcon,
    this.headerHeight = 160.0,
    this.adUnitId,
  });

  @override
  State<MainLayoutScaffold> createState() => _MainLayoutScaffoldState();
}

class _MainLayoutScaffoldState extends State<MainLayoutScaffold> {
  late ScrollController _internalController;
  bool _showScrollButton = false;

  @override
  void initState() {
    super.initState();
    // Use the provided controller or create a local one if scroll view is used
    _internalController = widget.controller ?? ScrollController();

    if (widget.useScrollView && widget.showScrollToTop) {
      _internalController.addListener(_scrollListener);
    }
  }

  @override
  void dispose() {
    if (widget.showScrollToTop) {
      _internalController.removeListener(_scrollListener);
    }
    // Only dispose if we created it locally
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  void _scrollListener() {
    if (!mounted) return;
    final isScrolledDown = _internalController.offset > 300;
    if (isScrolledDown != _showScrollButton) {
      setState(() {
        _showScrollButton = isScrolledDown;
      });
    }
  }

  void _scrollToTop() {
    _internalController.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

  // --- Helper to build the fixed/sticky header ---
  Widget _buildStickyHeader(double headerHeight) {
    return AnimatedBuilder(
      animation: _internalController,
      builder: (context, child) {
        double offset = 0;
        if (_internalController.hasClients) {
          offset = _internalController.offset;
        }
        // Ensure the header stays at the top of the screen (counter-act scroll)
        // But do not go below 0 (if overscrolling at top)
        // Actually, just offset is fine for simple sticky.
        // If we want it to bounce with iOS scroll, just use offset.

        return Transform.translate(offset: Offset(0, offset), child: child);
      },
      child: SizedBox(
        height: headerHeight + 50, // Match original fixed height
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: widget.header,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine Ad Visibility
    final showAd = widget.adUnitId != null;
    final double adHeight = showAd ? 60.0 : 0.0;

    final double headerHeight = widget.headerHeight;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // The "Paper Sheet" Decoration
    final sheetDecoration = BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5)),
      ],
    );

    // Common padding
    const sheetPadding = EdgeInsets.only(
      left: 20,
      right: 20,
      top: 32,
      bottom: 20,
    );

    Widget content;

    if (widget.useScrollView) {
      // Scrollable Layout (Default)
      content = SingleChildScrollView(
        controller: _internalController, // Use the managed controller
        physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
        child: Stack(
          children: [
            // 1. Sticky Header (Inside ScrollView to capture touches, translated to stay fixed)
            _buildStickyHeader(headerHeight),

            // 2. Scrollable Content (Paper)
            Column(
              children: [
                // Transparent Spacer to show header
                SizedBox(height: headerHeight),

                // The "Paper Sheet"
                Container(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height - headerHeight,
                  ),
                  width: double.infinity,
                  decoration: sheetDecoration,
                  padding: sheetPadding.copyWith(
                    bottom:
                        (widget.bottomWidget != null ? 100.0 : 80.0) + adHeight,
                  ), // Extra padding for bottom nav/sticky footer
                  child: widget.body,
                ),
              ],
            ),
          ],
        ),
      );

      // Add RefreshIndicator if callback provided
      if (widget.onRefresh != null) {
        content = RefreshIndicator(
          onRefresh: widget.onRefresh!,
          color: const Color(0xFFD4AF37), // Premium Gold
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          child: content,
        );
      }

      content = Positioned.fill(child: content);
    } else {
      // Non-Scrollable Layout (For TabBarView etc.) uses global Stack
      content = Stack(
        children: [
          // Fixed Header (Background)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerHeight + 50,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: widget.header,
              ),
            ),
          ),
          // Content
          Positioned(
            top: headerHeight,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: sheetDecoration,
              padding: sheetPadding, // Adjust padding as needed
              child: widget.body,
            ),
          ),
        ],
      );
      content = Positioned.fill(child: content);
    }

    // Determine FAB color based on Theme
    final fabColor = const Color(0xFFD4AF37); // Gold

    Widget? fab;
    if (_showScrollButton && widget.showScrollToTop) {
      fab = FloatingActionButton(
        key: const ValueKey('scroll_up'),
        heroTag: null,
        onPressed: _scrollToTop,
        backgroundColor: isDark ? const Color(0xFF333333) : Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        mini: true,
        child: Icon(Icons.keyboard_arrow_up_rounded, color: fabColor, size: 24),
      );
    } else if (!_showScrollButton && widget.scrollDownTarget != null) {
      fab = FloatingActionButton(
        key: const ValueKey('scroll_down'),
        heroTag: null,
        onPressed: () {
          if (widget.scrollDownTarget?.currentContext != null) {
            Scrollable.ensureVisible(
              widget.scrollDownTarget!.currentContext!,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOutCubic,
              alignment: 0.1, // Offset slightly
            );
          }
        },
        backgroundColor: isDark ? const Color(0xFF333333) : Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        mini: true,
        child: Icon(
          widget.scrollDownIcon ?? Icons.keyboard_arrow_down_rounded,
          color: fabColor,
          size: 24,
        ),
      );
    }

    final scaffold = Scaffold(
      backgroundColor: widget.backgroundColor,
      resizeToAvoidBottomInset: false,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: (widget.bottomWidget != null ? 100.0 : 0.0) + adHeight,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: fab,
        ),
      ),
      body: Stack(
        children: [
          // Content Layer (Includes Header if ScrollView)
          content,

          // 3. Sticky Bottom Widget (if any)
          if (widget.bottomWidget != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: adHeight, // Smart Stacking: Sit on top of Ad
              child: widget.bottomWidget!,
            ),

          // 4. Banner Ad
          if (showAd)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 60,
              child: BannerAdWithCloseButton(adUnitId: widget.adUnitId),
            ),
        ],
      ),
    );

    if (kIsWeb) {
      return Container(
        color: isDark ? Colors.black : Colors.grey[200],
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ClipRect(child: scaffold),
          ),
        ),
      );
    }
    return scaffold;
  }
}
