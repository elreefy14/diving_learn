  import 'dart:async';

  import 'package:connectivity_plus/connectivity_plus.dart';
  import 'package:curved_navigation_bar/curved_navigation_bar.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_inappwebview/flutter_inappwebview.dart';
  import 'package:loading_animation_widget/loading_animation_widget.dart';
  import 'package:url_launcher/url_launcher.dart';
  import 'package:fluttertoast/fluttertoast.dart';

  import 'handler/web_view_url_handler.dart';
  class BrandColors {
    static const Color primaryYellow = Color(0xFFFEAA00);
    static const Color secondaryGray = Color(0xFFE6E6E6);
    static const Color darkGray = Color(0xFF333333);
  }
  class AccessoryCategory {
    final String name;
    final String url;
    final IconData icon;

    AccessoryCategory({required this.name, required this.url, required this.icon});
  }

  class DeviceCategory {
    final String name;
    final String url;
    final IconData icon;

    DeviceCategory({required this.name, required this.url, required this.icon});
  }
  class TrustKsaWebView extends StatefulWidget {
    const TrustKsaWebView({Key? key}) : super(key: key);

    @override
    _TrustKsaWebViewState createState() => _TrustKsaWebViewState();
  }
  class _TrustKsaWebViewState extends State<TrustKsaWebView> {
    InAppWebViewController? _webViewController;
    bool _isLoading = true;
    int _cartCount = 0;
    final CacheManager _cacheManager = CacheManager();
    bool _isShowingNoConnection = false;
    final Connectivity _connectivity = Connectivity();
    late StreamSubscription<ConnectivityResult> _connectivitySubscription;
    double _progress = 0;
    bool _isNavigating = false;
    Timer? _navigationDebouncer;
    String _currentUrl = '';
    bool _isInitialLoad = true;
    int _currentIndex = 0;
    // Optimize script injection timing
    void _injectRemovalScript(InAppWebViewController controller) async {
      if (!mounted) return;

      // Debounce script injection
      _navigationDebouncer?.cancel();
      _navigationDebouncer = Timer(const Duration(milliseconds: 100), () async {
        await controller.evaluateJavascript(source: _hideElementsScript);
      });
    }
    final String _hideElementsScript = '''
      (function() {
        function hideElements() {
          // Hide WhatsApp floating button
          var whatsappButton = document.querySelector('.waba-floating-button');
          if (whatsappButton) {
            whatsappButton.style.display = 'none';
          }
  
          // Hide any general floating buttons
          var floatingButtons = document.querySelectorAll('.floating-button, .float-button, .fixed-button, [class*="float"], [class*="popup"], [class*="modal"]');
          floatingButtons.forEach(function(button) {
            button.style.display = 'none';
          });
  
          // Remove fixed positions that might be used for popups
          var fixedElements = document.querySelectorAll('[style*="position: fixed"]');
          fixedElements.forEach(function(element) {
            if (element.style.zIndex > 100) {
              element.style.display = 'none';
            }
          });
        }
        
        // Run initially
        hideElements();
        
        // Create an observer for dynamic content
        var observer = new MutationObserver(function(mutations) {
          hideElements();
        });
        
        // Start observing
        observer.observe(document.body, {
          childList: true,
          subtree: true,
          attributes: true,
          attributeFilter: ['style', 'class']
        });
  
        // Additional cleanup
        window.onload = function() {
          hideElements();
        };
      })();
    ''';

    // Update _onWebViewCreated to inject the script
    void _onWebViewCreated(InAppWebViewController controller) {
      _webViewController = controller;
      WebViewUrlHandler.setWebViewController(controller);

      // Add single handler for all events
      controller.addJavaScriptHandler(
        handlerName: 'webviewHandler',
        callback: (args) async {
          if (!mounted) return;

          final String type = args[0];
          switch(type) {
            case 'cartCount':
              setState(() {
                _cartCount = int.tryParse(args[1]?.toString() ?? '0') ?? 0;
              });
              break;
            case 'hideFloating':
           //   await _injectHidingScript(controller);
              break;
          }
          return null;
        },
      );

      // Initial script injection
    //  _injectHidingScript(controller);
    }

    Future<void> _injectHidingScript(InAppWebViewController controller) async {
      await controller.evaluateJavascript(source: '''
      function hideFloatingButton() {
        const elements = document.querySelectorAll('.waba-floating-button, .wa-chat-box, .floating-whatsapp');
        elements.forEach(el => el.style.display = 'none');
      }
      hideFloatingButton();
      new MutationObserver(hideFloatingButton).observe(document.body, {
        childList: true, subtree: true
      });
    ''');
    }






// Update onLoadStop for better transition
    // Update onLoadStop to properly handle loading states
    void _onLoadStop(InAppWebViewController controller, Uri? url) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isNavigating = false;
        _isInitialLoad = false;
        _progress = 1.0;
      });

      // No delay needed here - we want to hide loading immediately
      controller.evaluateJavascript(source: '''
    var cartCount = document.querySelector('.cart-count-bubble')?.textContent || '0';
    window.flutter_inappwebview.callHandler('updateCartCount', cartCount);
  ''');
   //   _injectHidingScript(controller);
    }





    final List<AccessoryCategory> accessoryCategories = [
      AccessoryCategory(
        name: 'ساعات',
        url: 'https://jifirephone.com/collections/%D8%B3%D8%A7%D8%B9%D8%A7%D8%AA',
        icon: Icons.watch,
      ),
      AccessoryCategory(
        name: 'سماعات وايربود',
        url: 'https://jifirephone.com/collections/%D8%A7%D9%84%D8%B3%D9%85%D8%A7%D8%B9%D8%A7%D8%AA-%D8%A8%D9%84%D9%88%D8%AA%D9%88%D8%AB-%D9%88%D8%A7%D9%84%D8%A7%D9%8A%D8%B1%D8%A8%D9%88%D8%AF',
        icon: Icons.headphones,
      ),
    ];

    final List<DeviceCategory> deviceCategories = [
      DeviceCategory(
        name: 'ايفون',
        url: 'https://jifirephone.com/collections/%D8%A7%D9%8A%D9%81%D9%88%D9%86',
        icon: Icons.apple,
      ),
      DeviceCategory(
        name: 'سامسونج',
        url: 'https://jifirephone.com/collections/%D8%A7%D8%AC%D9%87%D8%B2%D8%A9-%D9%87%D9%88%D8%A7%D8%AA%D9%81-%D9%85%D8%AD%D9%85%D9%88%D9%84%D8%A9',
        icon: Icons.phone_android,
      ),
      DeviceCategory(
        name: 'ريلمي وشاومي',
        url: 'https://jifirephone.com/collections/%D8%B1%D9%8A%D9%84%D9%85%D9%8A-%D8%B4%D8%A7%D9%88%D9%85%D9%8A',
        icon: Icons.smartphone,
      ),
      DeviceCategory(
        name: 'هونر',
        url: 'https://jifirephone.com/collections/%D9%87%D9%88%D9%86%D8%B1',
        icon: Icons.phone_android,
      ),
      DeviceCategory(
        name: 'تابلت',
        url: 'https://jifirephone.com/collections/%D8%AA%D8%A7%D8%A8%D8%A7%D8%AA',
        icon: Icons.tablet_android,
      ),
      DeviceCategory(
        name: 'تكنو وانفنكس',
        url: 'https://jifirephone.com/collections/%D8%AA%D9%83%D9%86%D9%88-%D8%A7%D9%86%D9%81%D9%86%D9%83%D8%B3',
        icon: Icons.phone_android,
      ),
    ];

    Future<void> _checkInitialConnectivity() async {
      final result = await _connectivity.checkConnectivity();
      if (result == ConnectivityResult.none) {
        if (mounted) _showNoInternetDialog();
      }
    }

    void _showNoInternetDialog() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NoConnectionScreen(
            onRetry: () async {
              var connectivityResult = await _connectivity.checkConnectivity();
              if (connectivityResult != ConnectivityResult.none) {
                Navigator.of(context).pop();
                await _reloadWebView();
              } else {
                _showNoInternetToast();
              }
            },
          ),
        ),
      );
    }

    void _showNoInternetToast() {
      Fluttertoast.showToast(
        msg: "لا يوجد اتصال بالإنترنت \n يرجى التحقق من اتصالك بالإنترنت",
        backgroundColor: Colors.red,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }

    Future<void> _updateConnectionStatus(ConnectivityResult result) async {
      if (!mounted) return;

      if (result == ConnectivityResult.none) {
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
    // URLs for different sections
    final List<String> _urls = [
      'https://jifirephone.com/',
      '', // Mobiles (handled by category selection)
      'https://jifirephone.com/collections/%D9%83%D8%A7%D9%85%D9%8A%D8%B1%D8%A7%D8%AA-%D9%85%D8%B1%D8%A7%D9%82%D8%A8%D8%A9',
      'https://jifirephone.com/collections/%D8%A7%D8%AC%D9%87%D8%B2%D8%A9-%D8%AD%D8%A7%D8%B3%D9%88%D8%A8',
      'https://jifirephone.com/collections/%D8%A7%D8%AC%D9%87%D8%B2%D8%A9-%D8%A7%D9%84%D8%B9%D8%A7%D8%A8-%D9%88%D8%AA%D8%B1%D9%81%D9%8A%D9%87',
      '', // Accessories (handled by category selection)
    ];
    void _showAccessoriesBottomSheet() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: accessoryCategories.map((category) {
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _loadUrl(category.url);
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 3 - 30,
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Icon(
                            category.icon,
                            size: 32,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
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
     _handleNavigation(String newUrl) async {
      if (newUrl.isEmpty || newUrl == _currentUrl) return;

      try {
        // Cancel any pending navigation
        _navigationDebouncer?.cancel();

        setState(() {
          _isLoading = true;
          _progress = 0;
          _isNavigating = true;
        });

        // Clear current page if any
        await _webViewController?.stopLoading();

        // Load new URL
        await _webViewController?.loadUrl(
          urlRequest: URLRequest(
            url: Uri.parse(newUrl),
            headers: {
              'Cache-Control': 'max-age=3600',
              'Accept': 'text/html,application/json',
              'Accept-Encoding': 'gzip, deflate',
            },
          ),
        );

        _currentUrl = newUrl; // Update the current URL
      } catch (e) {
        debugPrint('Error during navigation: $e');
        setState(() {
          _isLoading = false;
          _isNavigating = false;
        });
      }
    }

// Update bottom navigation handler


    void _onBottomNavTapped(int index) async {
      // Prevent navigation while already navigating
      if (_isNavigating) return;

      setState(() {
        _currentIndex = index;
      });

      if (index == 1) { // Mobiles tab
        _showDeviceCategoriesBottomSheet();
      } else if (index == 5) { // Accessories tab
        _showAccessoriesBottomSheet();
      } else {
        await _handleNavigation(_urls[index]);
      }
    }


    late final InAppWebViewGroupOptions _options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
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
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
        mixedContentMode: AndroidMixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
        safeBrowsingEnabled: false,
        // Cache optimization
        cacheMode: AndroidCacheMode.LOAD_CACHE_ELSE_NETWORK,
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
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
        allowsBackForwardNavigationGestures: true,
        // Cache optimization
        enableViewportScale: false,
        // Performance optimization
        isFraudulentWebsiteWarningEnabled: false,
        //isPrefetchingEnabled: true,
      ),
    );

    @override
    void initState() {
      super.initState();
      _initWebView();
      _setupConnectivity();
    }

    void _showDeviceCategoriesBottomSheet() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
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
                children: deviceCategories.map((category) {
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _loadUrl(category.url);
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 3 - 30,
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          Icon(
                            category.icon,
                            size: 32,
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
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


// Optimize page loading
    void _loadUrl(String url) async {
      if (url.isEmpty) return;

      // Cancel any pending operations
      _navigationDebouncer?.cancel();

      setState(() {
        _isLoading = true;
        _progress = 0;
        _isNavigating = true;
      });

      try {
        if (_webViewController != null) {
          await _webViewController!.loadUrl(
            urlRequest: URLRequest(
              url: Uri.parse(url),
              headers: {
                'Cache-Control': 'max-age=3600',
                'Accept': 'text/html,application/json',
                'Accept-Encoding': 'gzip, deflate',
              },
            ),
          );
        }
      } catch (e) {
        debugPrint('Error loading URL: $e');
        setState(() {
          _isLoading = false;
          _isNavigating = false;
        });
      }
    }




    void _initWebView() async {
      //if (Platform.isAndroid) {
      await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(false);
      // }
    }

    void _setupConnectivity() {
      _connectivitySubscription =
          _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
      _checkInitialConnectivity();
    }



    @override
    void dispose() {
      _navigationDebouncer?.cancel();
      WebViewUrlHandler.setWebViewController(null);
      _connectivitySubscription.cancel();
      super.dispose();
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




    void _showNoConnectionScreen() {
      _isShowingNoConnection = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => NoConnectionScreen(
            onRetry: () async {
              ConnectivityResult result = await _connectivity.checkConnectivity();
              if (result != ConnectivityResult.none) {
                if (mounted) {
                  _isShowingNoConnection = false;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TrustKsaWebView(),
                    ),
                  );
                }
              } else {
                Fluttertoast.showToast(
                  msg: "لا يوجد اتصال بالإنترنت",
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                );
              }
            },
          ),
        ),
      );
    }



    Future<void> _initConnectivity() async {
      ConnectivityResult result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    }




    // Update onLoadStart for better state management
    void _onLoadStart(InAppWebViewController controller, Uri? url) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _progress = 0;
        });
      //  _injectRemovalScript(controller);
      }
    }

// Update onProgressChanged for smoother loading feedback
    void _onProgressChanged(InAppWebViewController controller, int progress) {
      if (!mounted) return;

      final newProgress = progress / 100;
    //  if ((newProgress - _progress).abs() > 0.1) {
        setState(() {
          _progress = newProgress;
          _isLoading = _progress < 0.9; // Change threshold
        });
    //  }
    }


    // Update build method to show better loading state
    // Future<Resource?> _resourceInterceptor(Resource resource) async {
    //   if (!_CacheableResource.isCacheable(resource.url.toString())) {
    //     return resource;
    //   }
    //
    //   final cachedResource = await _cacheManager.getCachedResource(resource);
    //   if (cachedResource != null) {
    //     return cachedResource;
    //   }
    //
    //   await _cacheManager.cacheResource(resource);
    //   return resource;
    // }

    // Optimize page loading

    // Progressive loading indicator

    // Optimized load completion handler

    // Performance optimization scripts
    Future<void> _injectOptimizationScripts(InAppWebViewController controller) async {
      const optimizationScript = '''
      // Lazy load images
      document.addEventListener('DOMContentLoaded', function() {
        var lazyImages = [].slice.call(document.querySelectorAll('img[data-src]'));
        
        if ('IntersectionObserver' in window) {
          let lazyImageObserver = new IntersectionObserver(function(entries, observer) {
            entries.forEach(function(entry) {
              if (entry.isIntersecting) {
                let lazyImage = entry.target;
                lazyImage.src = lazyImage.dataset.src;
                lazyImage.removeAttribute('data-src');
                lazyImageObserver.unobserve(lazyImage);
              }
            });
          });

          lazyImages.forEach(function(lazyImage) {
            lazyImageObserver.observe(lazyImage);
          });
        }
      });

      // Defer non-critical resources
      window.addEventListener('load', function() {
        const deferredElements = document.querySelectorAll('[data-defer]');
        deferredElements.forEach(element => {
          setTimeout(() => {
            if (element.tagName === 'SCRIPT') {
              const script = document.createElement('script');
              script.src = element.getAttribute('data-defer');
              document.body.appendChild(script);
            } else if (element.tagName === 'LINK') {
              element.href = element.getAttribute('data-defer');
            }
          }, 100);
        });
      });
    ''';

      await controller.evaluateJavascript(source: optimizationScript);
    }

    @override

@override
Widget build(BuildContext context) {
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
            InAppWebView(
              initialUrlRequest: URLRequest(
                url: Uri.parse(_urls[0]),
                headers: {
                  'Cache-Control': 'max-age=3600',
                  'Accept': 'text/html,application/json',
                  'Accept-Encoding': 'gzip, deflate',
                },
              ),
              initialOptions: _options,
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
              onLoadStart: _onLoadStart,
              onProgressChanged: _onProgressChanged,
              onLoadStop: (controller, url) async {
                await controller.evaluateJavascript(source: _injectedScript);
              },
              onLoadError: _onLoadError,
              onLoadResource: (controller, resource) async {
                final url = resource.url.toString();
                if (_CacheableResource.isCacheable(url)) {
                  try {
                    final content = await controller.evaluateJavascript(
                        source: '''
                    (function() {
                      const element = document.querySelector('[src="${url}"]');
                      return element ? element.outerHTML : null;
                    })()
                  '''
                    );

                    if (content != null) {
                      await _cacheManager.cacheResource(url, content.toString());
                    }
                  } catch (e) {
                    debugPrint('Error caching resource: $e');
                  }
                }
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                final url = navigationAction.request.url?.toString() ?? '';

                if (_shouldHandleExternally(url)) {
                  await _handleExternalUrl(url);
                  return NavigationActionPolicy.CANCEL;
                }

                return NavigationActionPolicy.ALLOW;
              },
            ),
            if (_isLoading)
              Container(
                color: Colors.white.withOpacity(0.8),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.white,
        color: Colors.blue,
        buttonBackgroundColor: Colors.blue,
        height: 60,
        index: _currentIndex,
        onTap: _onBottomNavTapped,
        items: const [
          Icon(Icons.home, color: Colors.white),
          Icon(Icons.phone_iphone, color: Colors.white),
          Icon(Icons.camera_alt, color: Colors.white),
          Icon(Icons.laptop, color: Colors.white),
          Icon(Icons.videogame_asset, color: Colors.white),
          Icon(Icons.headphones, color: Colors.white),
        ],
      ),
    ),
  );
}



    bool _shouldHandleExternally(String url) {
      return url.startsWith('whatsapp://') ||
          url.startsWith('intent://') ||
          url.startsWith('fb://') ||
          url.contains('api.whatsapp.com') ||
          //instagram
          url.contains('instagram.com')||

          url.contains('facebook.com') ||
          url.contains('messenger.com') ||
          url.contains('tiktok.com') ||
          url.startsWith('snssdk1233://') ||  // TikTok app scheme
          url.startsWith('tiktoken://');       // Alternative TikTok app scheme
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
            url.split('browser_fallback_url=')[1].split(';')[0]
        );
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
        return url.replaceFirst(RegExp(r'(snssdk1233|tiktoken)://'), 'https://www.tiktok.com/');
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
        url.startsWith('snssdk1233://') ||  // TikTok app scheme
        url.startsWith('tiktoken://')||       // Alternative TikTok app scheme
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
      );
    }







    void _onLoadError(InAppWebViewController controller, Uri? url, int code,
        String message) {
      debugPrint('WebView Error: Code: $code, Message: $message, URL: $url');
      if (mounted) setState(() => _isLoading = false);
    }

    Future<PermissionRequestResponse> _handleAndroidPermissionRequest(
        InAppWebViewController controller,
        String origin,
        List<String> resources,) async {
      return PermissionRequestResponse(
        resources: resources,
        action: PermissionRequestResponseAction.GRANT,
      );
    }


  // Add search dialog implementation
    Future<void> _showSearchDialog(BuildContext context) async {
      final TextEditingController searchController = TextEditingController();

      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text('بحث', style: TextStyle(color: Color(0xFFFEAA00))),
          content: TextField(
            controller: searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'ابحث عن منتج...',
              hintStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFEAA00)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFFEAA00), width: 2),
              ),
            ),
            onSubmitted: (value) {
              Navigator.pop(context);
              if (value.isNotEmpty) {
                _loadUrl('https://jifirephone.com/search?options%5Bprefix%5D=last&q=${Uri.encodeComponent(value)}');
              }
            },
          ),
          actions: [
            TextButton(
              child: Text('إلغاء', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('بحث', style: TextStyle(color: Color(0xFFFEAA00))),
              onPressed: () {
                Navigator.pop(context);
                if (searchController.text.isNotEmpty) {
                  _loadUrl('https://jifirephone.com/search?options%5Bprefix%5D=last&q=${Uri.encodeComponent(searchController.text)}');
                }
              },
            ),
          ],
        ),
      );
    }

  }
  class NoConnectionScreen extends StatelessWidget {
    final VoidCallback onRetry;

    const NoConnectionScreen({Key? key, required this.onRetry}) : super(key: key);

    // Brand colors
    static const Color primaryYellow = Color(0xFFFEAA00);
    static const Color secondaryGray = Color(0xFFE6E6E6);
    static const Color darkGray = Color(0xFF333333);

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                secondaryGray.withOpacity(0.3),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Icon with animation
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: primaryYellow.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    size: 60,
                    color: primaryYellow,
                  ),
                ),

                const SizedBox(height: 40),

                // Main error message
                Text(
                  'لا يوجد اتصال بالإنترنت',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    color: darkGray,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 16),

                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'يرجى التحقق من اتصالك بالإنترنت',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: darkGray.withOpacity(0.7),
                      height: 1.6,
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Retry button with modern design
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryYellow,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'إعادة المحاولة',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Additional help text
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: TextButton(
                    onPressed: () {
                      // Optional: Add additional help or troubleshooting steps
                    },
                    child: Text(
                      'تحتاج مساعدة؟',
                      style: TextStyle(
                        color: darkGray.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
      final cacheableExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.css', '.js'];
      return cacheableExtensions.any((ext) => url.toLowerCase().endsWith(ext));
    }
  }