import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../../../app/utils/connectionstatuslistener.dart';
import '../../../../app/utils/nointernet_page.dart';
import '../../../../features/web_view_feature/presentation/webview/url_lists.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'handler/web_view_url_handler.dart';

class BrandColors {
  static const Color primaryYellow = Color(0xFFFEAA00);
  static const Color secondaryGray = Color(0xFFE6E6E6);
  static const Color darkGray = Color(0xFF333333);
}

class TrustKsaWebView extends StatefulWidget {
  const TrustKsaWebView({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _TrustKsaWebViewState createState() => _TrustKsaWebViewState();
}

class _TrustKsaWebViewState extends State<TrustKsaWebView> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _isInitialLoad = true;
  bool _isContentReady = false;
  final CacheManager _cacheManager = CacheManager();
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  double _progress = 0;
  Timer? _navigationDebouncer;
  int _currentIndex = 0;
  Timer? _configRefreshTimer;
  

  @override
  void initState() {
    super.initState();
    _initWebView();
    _setupConnectivity();
  }

  @override
  void dispose() {
    _navigationDebouncer?.cancel();
    _configRefreshTimer?.cancel();
    WebViewUrlHandler.setWebViewController(null);
    _connectivitySubscription.cancel();
    _webViewController?.dispose();
    super.dispose();
  }

  void _initWebView() async {
    if (Platform.isAndroid) {
      await InAppWebViewController.setWebContentsDebuggingEnabled(false);
    }
  }

  Future<void> _setupConnectivity() async {
    var connectionStatus = ConnectionStatusListener.getInstance();
    await connectionStatus.initialize();

    if (!connectionStatus.hasConnection) {
      _updateConnectionStatus(false, connectionStatus);
    }
    connectionStatus.connectionChange.listen((event) {
      _updateConnectionStatus(event, connectionStatus);
    });
  }



  late final InAppWebViewSettings _options = InAppWebViewSettings(
    useShouldOverrideUrlLoading: true,
    mediaPlaybackRequiresUserGesture: false,
    cacheEnabled: true,
    clearCache: false,
    preferredContentMode: UserPreferredContentMode.MOBILE,
    //allowsInlineMediaPlayback: true,
    javaScriptEnabled: true,
    transparentBackground: true,
    // Resource optimization
    resourceCustomSchemes: ['tel', 'mailto'],
    minimumFontSize: 10,
    useOnLoadResource: true,
    // Reduce memory usage
    incognito: false,
    supportZoom: false,

    // android: AndroidInAppWebViewOptions(
    useHybridComposition: true,
    //mixedContentMode: AndroidMixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
    safeBrowsingEnabled: false,
    // Cache optimization
    //cacheMode: AndroidCacheMode.LOAD_CACHE_ELSE_NETWORK,
    allowContentAccess: true,
    allowFileAccess: true,
    // Database optimization
    databaseEnabled: true,
    domStorageEnabled: true,
    // Layout optimization
    loadWithOverviewMode: true,
    useWideViewPort: true,
    // Performance optimization
    hardwareAcceleration: true,
    // ),
    // ios: IOSInAppWebViewOptions(
    allowsInlineMediaPlayback: true,
    allowsBackForwardNavigationGestures: true,
    // Cache optimization
    enableViewportScale: false,
    // Performance optimization
    isFraudulentWebsiteWarningEnabled: false,
    //isPrefetchingEnabled: true,
    // ),
  );

  List<BottomNavigationBarItem> get _navigationItems {
    List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'الرئيسيـة',
      ),
    ];

    items.add(const BottomNavigationBarItem(
      icon: Icon(Icons.phone_iphone),
      label: 'الهواتـف',
    ));

    items.addAll([
      const BottomNavigationBarItem(
        icon: Icon(Icons.laptop),
        label: 'اللابتـوبات',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.important_devices),
        label: 'منتجـات',
      ),
    ]);

    return items;
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (await _webViewController!.canGoBack()) {
          await _webViewController!.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Opacity(
                opacity: _isContentReady ? 1.0 : 0.0,
                child: InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri.uri(Uri.parse(UrlLists().urls[0])),
                    headers: {
                      'Cache-Control': 'max-age=3600',
                      'Accept': 'text/html,application/json',
                      'Accept-Encoding': 'gzip, deflate',
                    },
                  ),
                  initialSettings: _options,
                  onWebViewCreated: (InAppWebViewController controller) async {
                    _webViewController = controller;
                    controller.addJavaScriptHandler(
                      handlerName: 'handleUrl',
                      callback: (args) async {
                        if (args.isNotEmpty) {
                          final url = args[0].toString();
                          await _handleExternalUrl(url);
                        }
                      },
                    );
                  },
                  onLoadStart: (controller, url) {
                    setState(() {
                      _isLoading = true;
                      _progress = 0;
                      _isContentReady = false;
                    });
                  },
                  onProgressChanged: _onProgressChanged,
                  onLoadStop: (controller, url) async {
                    await controller.evaluateJavascript(
                        source: _injectedScript);
                    await _injectCustomCSS(controller);

                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        setState(() {
                          _isContentReady = true;
                          _isInitialLoad = false;
                          _isLoading = false;
                        });
                      }
                    });
                  },
                  onReceivedError: (controller, request, error) {
                    debugPrint(
                        'WebView Error: Code: ${error.type}, Message: ${error.description}, URL: ${request.url}');
                    if (mounted) setState(() => _isLoading = false);
                  },
                  // onLoadError: _onLoadError,
                  onLoadResource: (controller, resource) async {
                    final url = resource.url.toString();
                    if (_CacheableResource.isCacheable(url)) {
                      await _injectCustomCSS(controller);
                      try {
                        final content =
                            await controller.evaluateJavascript(source: '''
                            (function() {
                              const element = document.querySelector('[src="$url"]');
                              return element ? element.outerHTML : null;
                            })()
                          ''');

                        if (content != null) {
                          await _cacheManager.cacheResource(
                              url, content.toString());
                        }
                      } catch (e) {
                        debugPrint('Error caching resource: $e');
                      }
                    }
                  },
                  shouldOverrideUrlLoading:
                      (controller, navigationAction) async {
                    final url = navigationAction.request.url?.toString() ?? '';
                    if (_shouldHandleExternally(url)) {
                      await _handleExternalUrl(url);
                      return NavigationActionPolicy.CANCEL;
                    }
                    return NavigationActionPolicy.ALLOW;
                  },
                ),
              ),
              if (!_isContentReady || _isLoading)
                Container(
                  color: Colors.white,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LoadingAnimationWidget.staggeredDotsWave(
                          color: Colors.blue,
                          size: 50,
                        ),
                        const SizedBox(height: 20),
                        if (_isInitialLoad)
                          const Text(
                            'جاري التحميل...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        if (_isLoading && !_isInitialLoad)
                          LinearProgressIndicator(
                            value: _progress,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.blue),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.grey.shade300,
                width: 1.0,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onBottomNavTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.blue.shade700,
            unselectedItemColor: Colors.grey.shade600,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            items: _navigationItems,
          ),
        ),
      ),
    );
  }

  Future<bool> _injectCustomCSS(InAppWebViewController controller) async {
    try {
      const String customCSS = '''
    /* Explicitly show Slideshow */
    .slideshow,
    .slideshow-wrapper,
    [class*="slideshow"],
    [data-section-type="slideshow"],
    .shopify-section-slideshow,
    .slideshow-section,
    [class*="slideshow_"] {
      display: block !important;
      visibility: visible !important;
      opacity: 1 !important;
      height: auto !important;
      min-height: auto !important;
      overflow: visible !important;
      pointer-events: auto !important;
    }

    /* Hide footer */
    footer,
    .footer,
    .footer-wrapper,
    [class="footer"],
    [class*="Footer"] {
      display: none !important;
    }
    
    /* Hide Section tabs - Comprehensive */
    .section-tabs,
    [class="section*tabs_"],
    [class*="section-tabs"],
    .section_tabs_qdCwfH,
    .section_tabs_FyqqtV,
    .section_tabs_mcbiHD,
    .tab-content,
    .tab-panel,
    [class*="tab-"],
    [data-section-type*="section-tabs"],
    [data-section-id*="section-tabs"],
    .tabs-wrapper,
    .tabs-container,
    .tab-navigation,
    .tab-header,
    .tab-list,
    .tab-panels,
    [class*="tab_content"],
    [class*="TabContent"],
    [class*="tabpanel"],
    .section-tab-container,
    [class*="section-tab"],
    [role="tablist"],
    [role="tab"],
    [role="tabpanel"] {
      display: none !important;
      height: 0 !important;
      min-height: 0 !important;
      overflow: hidden !important;
      visibility: hidden !important;
      opacity: 0 !important;
      pointer-events: none !important;
      margin: 0 !important;
      padding: 0 !important;
    }

    /* Hide Collection banners and split banners */
    .collection-banner,
    .main-collection-banner,
    .main-collection-split-banner,
    [class*="collection-banner"],
    [class*="collection_banner"],
    [class*="collection-split"],
    [class*="split-banner"],
    [data-section-type="collection-banner"],
    [data-section-type="main-collection-banner"],
    [data-section-type="main-collection-split-banner"],
    .collection-hero,
    .collection-header,
    .banner-split,
    .collection-split-banner,
    .split-banner-section,
    [class*="split-collection"],
    [class*="collection-split-banner"],
    [class*="banner-split"],
    .banner__box.banner-split,
    .collection__banner.split,
    .banner.split-style,
    .collection-split {
      display: none !important;
      height: 0 !important;
      min-height: 0 !important;
      visibility: hidden !important;
      opacity: 0 !important;
      pointer-events: none !important;
      margin: 0 !important;
      padding: 0 !important;
    }
    
    /* Hide Stats counter */
    .stats,
    [class*="stats_"],
    .stats_AhFJcf,
    .stats-counter,
    .stat-block,
    [class*="stat-"] {
      display: none !important;
    }
    
    /* Hide Email signup sections */
    .newsletter,
    [class*="newsletter_"],
    .email-signup,
    .newsletter_JjUqmd,
    .subscription-form,
    [class*="signup-"],
    [class*="subscribe-"] {
      display: none !important;
    }
    
    /* Hide Icons with text */
    .icons-with-text,
    [class*="icons_with_text_"],
    .icons_with_text_A8P3h4,
    .icons_with_text_74BKWK,
    .icon-blocks,
    [class*="icon-with-"] {
      display: none !important;
    }

    /* Hide Ribbon banners */
    .ribbon-banner,
    .section-ribbon-banner,
    [class*="ribbon_banner_"],
    [class*="ribbon-banner"],
    .ribbon_banner_ULeYX9,
    .ribbon_banner_kAqDx9,
    .ribbon_banner_JefMbE,
    .ribbon_banner_zkP4Bb,
    .announcement-bar,
    [class*="banner-"]:not([class*="slideshow"]),
    [class*="ribbon-"],
    .promotional-banner,
    [data-section-type*="ribbon"],
    [data-section-id*="ribbon"] {
      display: none !important;
      height: 0 !important;
      min-height: 0 !important;
      overflow: hidden !important;
      visibility: hidden !important;
      opacity: 0 !important;
      pointer-events: none !important;
    }

    /* Fix layout spacing after hiding elements */
    .main-content {
      padding-top: 0 !important;
    }

    body {
      padding-top: 0 !important;
      margin-top: 0 !important;
    }

    /* Hide related spacing elements except for slideshow */
    [class*="spacer_"]:not([class*="slideshow"]),
    .spacer:not(.slideshow-spacer),
    .divider:not(.slideshow-divider),
    [class*="section-spacing"]:not([class*="slideshow"]) {
      display: none !important;
    }

    /* Fix any remaining spacing issues while preserving slideshow */
    .section-content:not(.slideshow-content) {
      margin-top: 0 !important;
      padding-top: 0 !important;
    }

    /* Preserve slideshow spacing */
    .slideshow-section,
    .slideshow-wrapper,
    .slideshow-container {
      margin: 0 !important;
      padding: 0 !important;
      height: auto !important;
      min-height: auto !important;
      display: block !important;
    }
    ''';

      // Inject the CSS
      await controller.injectCSSCode(source: customCSS);

      // Verify CSS injection with updated selectors including slideshow check
      final verified = await controller.evaluateJavascript(source: '''
    (function() {
      const selectorsToHide = [
        '.footer',
        '.section-tabs',
        '.ribbon-banner',
        '.collection-banner',
        '.stats',
        '.newsletter',
        '.icons-with-text'
      ];
      
      const selectorsToShow = [
        '.slideshow',
        '[class*="slideshow"]',
        '[data-section-type="slideshow"]'
      ];
      
      const hiddenElements = document.querySelectorAll(selectorsToHide.join(','));
      const slideshowElements = document.querySelectorAll(selectorsToShow.join(','));
      
      const areElementsHidden = hiddenElements.length > 0 && 
             Array.from(hiddenElements).every(el => 
               window.getComputedStyle(el).display === 'none' ||
               window.getComputedStyle(el).visibility === 'hidden'
             );
             
      const isSlideshowVisible = slideshowElements.length === 0 || 
             Array.from(slideshowElements).every(el =>
               window.getComputedStyle(el).display !== 'none' &&
               window.getComputedStyle(el).visibility !== 'hidden'
             );
             
      return areElementsHidden && isSlideshowVisible;
    })()
    ''');
      return verified == true;
    } catch (e) {
      debugPrint('Error injecting CSS: $e');
      return false;
    }
  }

  void _onProgressChanged(InAppWebViewController controller, int progress) {
    if (!mounted) return;

    setState(() {
      _progress = progress / 100;
      _isLoading = _progress < 0.9;
    });
  }
  // Optimize script injection timing
 



  void _showNoInternetDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoConnectionScreen(
          onRetry: () async {
            var connectivityResult = await _connectivity.checkConnectivity();
            if (connectivityResult[0] != ConnectivityResult.none) {
              // ignore: use_build_context_synchronously
              Navigator.of(context).pop();
              await _reloadWebView();
            } else {
              Fluttertoast.showToast(
                msg:
                    "لا يوجد اتصال بالإنترنت \n يرجى التحقق من اتصالك بالإنترنت",
                backgroundColor: Colors.red,
                textColor: Colors.white,
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 5,
              );
            }
          },
        ),
      ),
    );
  }

  _updateConnectionStatus(dynamic hasConnection, ConnectionStatusListener connectionStatus) async {
    if (!mounted) return;
    if (!hasConnection) {
      _showNoInternetDialog();
    } else {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      await _reloadWebView();
    }
  }

  Future<void> _reloadWebView() async {
    try {
      await _webViewController?.reload();
    } catch (e) {
      debugPrint('Error reloading WebView: $e');
    }
  }

  void _showAccessoriesBottomSheet() {
  final isTablet = MediaQuery.of(context).size.width >= 768;
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    constraints: BoxConstraints(
      maxHeight: screenHeight * 0.8,
      maxWidth: isTablet ? screenWidth * 0.8 : screenWidth,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.headset), text: 'اكسسوارات'),
              Tab(icon: Icon(Icons.devices), text: 'منتجات عالمية'),
            ],
            indicatorColor: Colors.blue,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
          ),
          Expanded(
            child: TabBarView(
              children: [
                _accessoriesTab(),
                _moreTab(),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _accessoriesTab() {
  final isTablet = MediaQuery.of(context).size.width >= 768;
  final screenWidth = MediaQuery.of(context).size.width;
  return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: 20,
              horizontal: isTablet ? 40 : 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    'اختر نوع الاكسسوار',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 20,
                  runSpacing: 20,
                  children: UrlLists().accessoryCategories.map((category) {
                    final itemWidth =
                        isTablet ? screenWidth * 0.2 : (screenWidth / 3) - 30;

                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _loadUrl(category.url);
                      },
                      child: Container(
                        width: itemWidth,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Icon(
                              category.icon,
                              size: isTablet ? 48 : 32,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              category.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: isTablet ? 16 : 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
}


Widget _moreTab() {
  final isTablet = MediaQuery.of(context).size.width >= 768;
  final screenWidth = MediaQuery.of(context).size.width;
  return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: 20,
              horizontal: isTablet ? 40 : 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    'اختر نوع الاكسسوار',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 20,
                  runSpacing: 20,
                  children: UrlLists().moreCategories.map((category) {
                    final itemWidth =
                        isTablet ? screenWidth * 0.2 : (screenWidth / 3) - 30;

                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _loadUrl(category.url);
                      },
                      child: Container(
                        width: itemWidth,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Icon(
                              category.icon,
                              size: isTablet ? 48 : 32,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              category.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: isTablet ? 16 : 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
}
  // URLs for different sections
  // ignore: unused_element
  void _showAccessoriesBottomSheett() {
    final isTablet = MediaQuery.of(context).size.width >= 768;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.8,
        maxWidth: isTablet ? screenWidth * 0.8 : screenWidth,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Center(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: 20,
              horizontal: isTablet ? 40 : 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    'اختر نوع الاكسسوار',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 20,
                  runSpacing: 20,
                  children: UrlLists().accessoryCategories.map((category) {
                    final itemWidth =
                        isTablet ? screenWidth * 0.2 : (screenWidth / 3) - 30;

                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _loadUrl(category.url);
                      },
                      child: Container(
                        width: itemWidth,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Icon(
                              category.icon,
                              size: isTablet ? 48 : 32,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              category.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: isTablet ? 16 : 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Update bottom navigation handler
  void _onBottomNavTapped(int index) async {
    // Always update the current index first
    setState(() {
      _currentIndex = index;
    });

    // For device categories (index 1) and accessories (index 5), show bottom sheets
    if (index == 1) {
      _showDeviceCategoriesBottomSheet();
      return;
    } else if (index == 3) {
      _showAccessoriesBottomSheet();
      return;
    }

    // Force navigation to the new URL
    final String targetUrl = UrlLists().urls[index];
    if (targetUrl.isNotEmpty) {
      try {
        // Stop any current loading
        await _webViewController?.stopLoading();

        // Clear current page
        await _webViewController?.loadUrl(
          urlRequest: URLRequest(
            url: WebUri.uri(Uri.parse('about:blank')),
          ),
        );

        // Force load new URL with cache headers
        await _webViewController?.loadUrl(
          urlRequest: URLRequest(
            url: WebUri.uri(Uri.parse(targetUrl)),
            headers: {
              'Cache-Control': 'no-cache, no-store, must-revalidate',
              'Pragma': 'no-cache',
              'Expires': '0',
              'Accept': 'text/html,application/json',
              'Accept-Encoding': 'gzip, deflate',
            },
          ),
        );

        // Update current URL
        setState(() {
          // _currentUrl = targetUrl;
          _isLoading = true;
          _progress = 0;
        });
      } catch (e) {
        debugPrint('Navigation error: $e');
        setState(() {
          _isLoading = false;
        });

        // Show error toast
        Fluttertoast.showToast(
          msg: "حدث خطأ في التنقل",
          backgroundColor: Colors.red,
          textColor: Colors.white,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 5,
        );
      }
    }
  }

  void _showDeviceCategoriesBottomSheet() {
    final isTablet = MediaQuery.of(context).size.width >= 768;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.8,
        maxWidth: isTablet ? screenWidth * 0.8 : screenWidth,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Center(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: 20,
              horizontal: isTablet ? 40 : 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    'اختر نوع الجهاز',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 20,
                  runSpacing: 20,
                  children: UrlLists().deviceCategories.map((category) {
                    final itemWidth =
                        isTablet ? screenWidth * 0.2 : (screenWidth / 3) - 30;

                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _loadUrl(category.url);
                      },
                      child: Container(
                        width: itemWidth,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Icon(
                              category.icon,
                              size: isTablet ? 48 : 32,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              category.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: isTablet ? 16 : 14),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Optimize page loading
  void _loadUrl(String url) async {
    if (url.isEmpty) return;

    try {
      // Stop current loading
      await _webViewController?.stopLoading();

      // Clear current page
      await _webViewController?.loadUrl(
        urlRequest: URLRequest(
          url: WebUri.uri(Uri.parse('about:blank')),
        ),
      );

      // Force load new URL with cache headers
      await _webViewController?.loadUrl(
        urlRequest: URLRequest(
          url: WebUri.uri(Uri.parse(url)),
          headers: {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
            'Accept': 'text/html,application/json',
            'Accept-Encoding': 'gzip, deflate',
          },
        ),
      );

      setState(() {
        // _currentUrl = url;
        _isLoading = true;
        _progress = 0;
      });
    } catch (e) {
      debugPrint('URL loading error: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error toast
      Fluttertoast.showToast(
        msg: "حدث خطأ في تحميل الصفحة",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 5,
      );
    }
  }

  // Updated JavaScript code to include TikTok
  final String _injectedScript = '''
        document.addEventListener('click', function(e) {
          var target = e.target;
          while (target != null) {
            if (target.tagName === 'A') {
              var href = target.getAttribute('href');
              if (href && (href.startsWith('whatsapp://') || 
                           href.startsWith('intent://') || 
                           href.startsWith('fb://') ||
                           href.includes('api.whatsapp.com') ||
                           href.includes('facebook.com') ||
                           href.includes('tiktok.com') ||
                           href.startsWith('snssdk1233://') ||
                           href.startsWith('tiktoken://'))) {
                e.preventDefault();
                window.flutter_inappwebview.callHandler('handleUrl', href);
                return false;
              }
            }
            target = target.parentElement;
          }
        }, true);
      ''';

  bool _shouldHandleExternally(String url) {
    return url.startsWith('whatsapp://') ||
        url.startsWith('intent://') ||
        url.startsWith('fb://') ||
        url.contains('api.whatsapp.com') ||
        //instagram
        url.contains('instagram.com') ||
        url.contains('facebook.com') ||
        url.contains('messenger.com') ||
        url.contains('tiktok.com') ||
        url.startsWith('snssdk1233://') || // TikTok app scheme
        url.startsWith('tiktoken://'); // Alternative TikTok app scheme
  }

  Future<void> _handleExternalUrl(String url) async {
    try {
      debugPrint('Handling external URL: $url');

      // Handle TikTok URLs
      if (url.contains('tiktok.com') ||
          url.startsWith('snssdk1233://') ||
          url.startsWith('tiktoken://')) {
        final tiktokUrl = _processTikTokUrl(url);
        debugPrint('Using TikTok URL: $tiktokUrl');
        await _launchUrl(tiktokUrl);
        return;
      }

      // Handle Facebook intent URLs
      if (url.startsWith('intent://')) {
        if (url.contains('browser_fallback_url=')) {
          final fallbackUrl = Uri.decodeFull(
              url.split('browser_fallback_url=')[1].split(';')[0]);
          debugPrint('Using Facebook fallback URL: $fallbackUrl');
          await _launchUrl(fallbackUrl);
          return;
        }
      }

      // Handle WhatsApp URLs
      if (url.contains('whatsapp') || url.contains('wa.me')) {
        final whatsappUrl = url
            .replaceAll('whatsapp://', 'https://api.whatsapp.com/')
            .replaceAll('send/?', 'send?');
        debugPrint('Using WhatsApp URL: $whatsappUrl');
        await _launchUrl(whatsappUrl);
        return;
      }

      // Handle all other URLs
      if (_shouldHandleExternally(url)) {
        await _launchUrl(url);
      } else {
        // Handle internally if needed
        debugPrint('Handling URL internally: $url');
        // Add your internal handling logic here
      }
    } catch (e) {
      debugPrint('Error handling URL: $e');
      _showToast('Unable to open link');
    }
  }

  String _processTikTokUrl(String url) {
    // Handle various TikTok URL formats
    if (url.startsWith('snssdk1233://') || url.startsWith('tiktoken://')) {
      // Convert app scheme to https
      return url.replaceFirst(
          RegExp(r'(snssdk1233|tiktoken)://'), 'https://www.tiktok.com/');
    }

    // If it's already a web URL, ensure it's using https
    if (url.contains('tiktok.com')) {
      if (url.startsWith('http://')) {
        return url.replaceFirst('http://', 'https://');
      }
      if (!url.startsWith('https://')) {
        return 'https://$url';
      }
    }

    return url;
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);

      // Check if the URL should be handled externally
      if (url.contains('tiktok.com') ||
          url.contains('instagram.com') ||
          url.contains('whatsapp.com') ||
          url.contains('facebook.com') ||
          url.startsWith('whatsapp://') ||
          url.startsWith('instagram://') ||
          url.startsWith('fb://') ||
          url.startsWith('whatsapp://') ||
          url.startsWith('intent://') ||
          url.startsWith('fb://') ||
          url.contains('api.whatsapp.com') ||
          url.contains('facebook.com') ||
          url.contains('messenger.com') ||
          url.contains('tiktok.com') ||
          url.startsWith('snssdk1233://') || // TikTok app scheme
          url.startsWith('tiktoken://') || // Alternative TikTok app scheme
          url.startsWith('tiktok://')) {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showToast('Unable to open link');
        }
      } else {
        // Handle internally if needed
        debugPrint('Handling URL internally: $url');
        // Add your internal handling logic here
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      _showToast('Unable to open link');
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      timeInSecForIosWeb: 5,
    );
  }
}

// Cache manager for optimized resource handling
class CacheManager {
  final Map<String, String> _cache = {};
  final int _maxCacheSize = 100;

  Future<String?> getCachedResource(String url) async {
    return _cache[url];
  }

  Future<void> cacheResource(String url, String content) async {
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[url] = content;
  }

  bool hasCachedResource(String url) {
    return _cache.containsKey(url);
  }

  void dispose() {
    _cache.clear();
  }
}

// Helper class for determining cacheable resources
class _CacheableResource {
  static bool isCacheable(String url) {
    final cacheableExtensions = [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.css',
      '.js'
    ];
    return cacheableExtensions.any((ext) => url.toLowerCase().endsWith(ext));
  }
}
