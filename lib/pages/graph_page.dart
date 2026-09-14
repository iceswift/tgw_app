import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gold_app/widgets/trading_view_widget.dart';
import 'package:gold_app/widgets/main_layout_scaffold.dart';
import 'package:gold_app/utils/ad_config.dart';

class GraphPage extends StatefulWidget {
  const GraphPage({super.key});

  @override
  State<GraphPage> createState() => GraphPageState();
}

class GraphPageState extends State<GraphPage> {
  int _reloadKey = 0;

  void scrollToTop() {
    setState(() {
      _reloadKey++;
    });
  }

  static const String _goldChartHtmlDark = '''
  <!-- TradingView Widget BEGIN -->
  <div class="tradingview-widget-container" style="height:100%;width:100%">
    <div class="tradingview-widget-container__widget" style="height:calc(100% - 32px);width:100%"></div>
    <div class="tradingview-widget-copyright"><a href="https://www.tradingview.com/symbols/GOLD/?exchange=TVC" rel="noopener nofollow" target="_blank"><span class="blue-text">GOLD chart</span></a><span class="trademark"> by TradingView</span></div>
    <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-advanced-chart.js" async>
    {
    "allow_symbol_change": true,
    "calendar": false,
    "details": false,
    "hide_side_toolbar": false,
    "hide_top_toolbar": false,
    "hide_legend": false,
    "hide_volume": false,
    "hotlist": false,
    "interval": "1",
    "locale": "en",
    "save_image": true,
    "style": "1",
    "symbol": "TVC:GOLD",
    "theme": "dark",
    "timezone": "Asia/Bangkok",
    "backgroundColor": "#0F0F0F",
    "gridColor": "rgba(242, 242, 242, 0.06)",
    "watchlist": [],
    "withdateranges": true,
    "compareSymbols": [],
    "studies": [],
    "autosize": true
  }
    </script>
  </div>
  <!-- TradingView Widget END -->
  ''';

  static const String _goldChartHtmlLight = '''
  <!-- TradingView Widget BEGIN -->
  <div class="tradingview-widget-container" style="height:100%;width:100%">
    <div class="tradingview-widget-container__widget" style="height:calc(100% - 32px);width:100%"></div>
    <div class="tradingview-widget-copyright"><a href="https://www.tradingview.com/symbols/GOLD/?exchange=TVC" rel="noopener nofollow" target="_blank"><span class="blue-text">GOLD chart</span></a><span class="trademark"> by TradingView</span></div>
    <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-advanced-chart.js" async>
    {
    "allow_symbol_change": true,
    "calendar": false,
    "details": false,
    "hide_side_toolbar": false,
    "hide_top_toolbar": false,
    "hide_legend": false,
    "hide_volume": false,
    "hotlist": false,
    "interval": "D",
    "locale": "en",
    "save_image": true,
    "style": "1",
    "symbol": "TVC:GOLD",
    "theme": "light",
    "timezone": "Etc/UTC",
    "backgroundColor": "#ffffff",
    "gridColor": "rgba(46, 46, 46, 0.06)",
    "watchlist": [],
    "withdateranges": true,
    "compareSymbols": [],
    "studies": [],
    "autosize": true
  }
    </script>
  </div>
  <!-- TradingView Widget END -->
  ''';

  static const String _usdChartHtmlDark = '''
  <!-- TradingView Widget BEGIN -->
  <div class="tradingview-widget-container">
    <div class="tradingview-widget-container__widget"></div>
    <div class="tradingview-widget-copyright"><a href="https://www.tradingview.com/symbols/USDTHB/?exchange=FX_IDC" rel="noopener nofollow" target="_blank"><span class="blue-text">USDTHB rate</span></a><span class="trademark">&nbsp;by TradingView</span></div>
    <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-symbol-overview.js" async>
    {
    "lineWidth": 2,
    "lineType": 0,
    "chartType": "area",
    "fontColor": "rgba(219, 219, 219, 1)",
    "gridLineColor": "rgba(242, 242, 242, 0.06)",
    "volumeUpColor": "rgba(34, 171, 148, 0.5)",
    "volumeDownColor": "rgba(247, 82, 95, 0.5)",
    "backgroundColor": "#0F0F0F",
    "widgetFontColor": "rgba(255, 255, 255, 1)",
    "upColor": "#22ab94",
    "downColor": "#f7525f",
    "borderUpColor": "#22ab94",
    "borderDownColor": "#f7525f",
    "wickUpColor": "#22ab94",
    "wickDownColor": "#f7525f",
    "colorTheme": "dark",
    "isTransparent": false,
    "locale": "en",
    "chartOnly": false,
    "scalePosition": "right",
    "scaleMode": "Normal",
    "fontFamily": "-apple-system, BlinkMacSystemFont, Trebuchet MS, Roboto, Ubuntu, sans-serif",
    "valuesTracking": "1",
    "changeMode": "price-and-percent",
    "symbols": [
      [
        "FX_IDC:USDTHB|1M"
      ]
    ],
    "dateRanges": [
      "1d|1",
      "1w|15",
      "1m|30",
      "3m|60",
      "12m|1D",
      "60m|1W",
      "all|1M"
    ],
    "fontSize": "16",
    "headerFontSize": "large",
    "autosize": true,
    "width": "100%",
    "height": "100%",
    "noTimeScale": false,
    "hideDateRanges": false,
    "hideMarketStatus": false,
    "hideSymbolLogo": false
  }
    </script>
  </div>
  <!-- TradingView Widget END -->
  ''';

  static const String _usdChartHtmlLight = '''
  <!-- TradingView Widget BEGIN -->
  <div class="tradingview-widget-container">
    <div class="tradingview-widget-container__widget"></div>
    <div class="tradingview-widget-copyright"><a href="https://www.tradingview.com/symbols/USDTHB/?exchange=FX_IDC" rel="noopener nofollow" target="_blank"><span class="blue-text">USDTHB rate</span></a><span class="trademark">&nbsp;by TradingView</span></div>
    <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-symbol-overview.js" async>
    {
    "lineWidth": 2,
    "lineType": 0,
    "chartType": "area",
    "fontColor": "rgba(74, 74, 74, 1)",
    "gridLineColor": "rgba(46, 46, 46, 0.06)",
    "volumeUpColor": "rgba(34, 171, 148, 0.5)",
    "volumeDownColor": "rgba(247, 82, 95, 0.5)",
    "backgroundColor": "#ffffff",
    "widgetFontColor": "rgba(0, 0, 0, 1)",
    "upColor": "#22ab94",
    "downColor": "#f7525f",
    "borderUpColor": "#22ab94",
    "borderDownColor": "#f7525f",
    "wickUpColor": "#22ab94",
    "wickDownColor": "#f7525f",
    "colorTheme": "light",
    "isTransparent": false,
    "locale": "en",
    "chartOnly": false,
    "scalePosition": "right",
    "scaleMode": "Normal",
    "fontFamily": "-apple-system, BlinkMacSystemFont, Trebuchet MS, Roboto, Ubuntu, sans-serif",
    "valuesTracking": "1",
    "changeMode": "price-and-percent",
    "symbols": [
      [
        "FX_IDC:USDTHB|1M"
      ]
    ],
    "dateRanges": [
      "1d|1",
      "1w|15",
      "1m|30",
      "3m|60",
      "12m|1D",
      "60m|1W",
      "all|1M"
    ],
    "fontSize": "18",
    "headerFontSize": "large",
    "autosize": true,
    "width": "100%",
    "height": "100%",
    "noTimeScale": false,
    "hideDateRanges": false,
    "hideMarketStatus": false,
    "hideSymbolLogo": false
  }
    </script>
  </div>
  <!-- TradingView Widget END -->
  ''';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      key: ValueKey('tab_$_reloadKey'), // Force rebuild on reload
      length: 2,
      child: OrientationBuilder(
        builder: (context, orientation) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          // LAYOUT 1: Landscape (Fullscreen) - Skip on Web to keep Tabs
          if (orientation == Orientation.landscape && !kIsWeb) {
            return Scaffold(
              body: TabBarView(
                children: [
                  TradingViewWidget(
                    htmlContent: isDark
                        ? _goldChartHtmlDark
                        : _goldChartHtmlLight,
                    backgroundColor: isDark
                        ? const Color(0xFF0F0F0F)
                        : Colors.white,
                  ),
                  TradingViewWidget(
                    htmlContent: isDark
                        ? _usdChartHtmlDark
                        : _usdChartHtmlLight,
                    backgroundColor: isDark
                        ? const Color(0xFF0F0F0F)
                        : Colors.white,
                  ),
                ],
              ),
            );
          }

          // LAYOUT 2: Portrait (Paper Sheet)
          return MainLayoutScaffold(
            adUnitId: AdConfig.graphPageBanner,
            useScrollView: false, // Allow TabBarView to fill the sheet
            header: Column(
              children: [
                Center(
                  child: Transform.translate(
                    offset: const Offset(0, -20),
                    child: const Text(
                      'กราฟ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  height: 45,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: isDark
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white,
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: isDark ? Colors.white : Colors.black,
                    unselectedLabelColor: Colors.white,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'ทองคำ'),
                      Tab(text: 'USD/THB'),
                    ],
                  ),
                ),
              ],
            ),
            body: TabBarView(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: TradingViewWidget(
                    htmlContent: isDark
                        ? _goldChartHtmlDark
                        : _goldChartHtmlLight,
                    backgroundColor: isDark
                        ? const Color(0xFF0F0F0F)
                        : Colors.white,
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: TradingViewWidget(
                    htmlContent: isDark
                        ? _usdChartHtmlDark
                        : _usdChartHtmlLight,
                    backgroundColor: isDark
                        ? const Color(0xFF0F0F0F)
                        : Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
