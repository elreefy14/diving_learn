  import 'dart:async';

  import 'package:connectivity_plus/connectivity_plus.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter_inappwebview/flutter_inappwebview.dart';
  import 'package:url_launcher/url_launcher.dart';
  import 'package:fluttertoast/fluttertoast.dart';

  import 'handler/web_view_url_handler.dart';
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
    bool _isShowingNoConnection = false;
    final Connectivity _connectivity = Connectivity();
    late StreamSubscription<ConnectivityResult> _connectivitySubscription;
    double _progress = 0;
    int _currentIndex = 0;
    void _injectRemovalScript(InAppWebViewController controller) async {
      await controller.evaluateJavascript(source: '''
    function removeUnwantedElements() {
      // Remove specific popup
      const popup = document.querySelector('.popup__message-container.relative.image-mobile-left.image-desktop-left');
      if (popup) {
        popup.remove();
      }

      // Header modifications
      const header = document.querySelector('header.header');
      if (header) {
        // Set header styles
        header.style.minHeight = '80px';
        header.style.maxHeight = '80px';
        header.style.height = '80px';
        header.style.padding = '10px 0';
        
        // Remove all menu/drawer buttons, preserve only search
        const menuSelectors = [
          '[class*="menu-button"]',
          '[class*="menu_button"]',
          '.drawer-trigger',
          '[class*="menu-icon"]',
          '[class*="hamburger"]',
          '[aria-label*="Menu"]',
          '[aria-label*="menu"]',
          '.menu-toggle',
          '.drawer-toggle',
          '[class*="drawer"]'
        ];
        
        menuSelectors.forEach(selector => {
          const elements = header.querySelectorAll(selector);
          elements.forEach(el => el.remove());
        });
        
        // Remove logo and its container
        const logoSelectors = [
          '.header__logo',
          '.header__logo-image',
          '.header__logo-link',
          '.header-logo',
          '.header-logo__link',
          '[class*="logo-container"]',
          '[class*="logo_wrapper"]'
        ];
        
        logoSelectors.forEach(selector => {
          const elements = header.querySelectorAll(selector);
          elements.forEach(element => {
            if (!element.innerHTML.includes('search') && 
                !element.classList.contains('search') && 
                !element.querySelector('[class*="search"]')) {
              element.remove();
            }
          });
        });

        // Preserve search while removing home links
        const homeLinks = header.querySelectorAll('a[href="/"]');
        homeLinks.forEach(link => {
          if (!link.innerHTML.includes('search') && 
              !link.classList.contains('search') && 
              !link.querySelector('[class*="search"]')) {
            const images = link.getElementsByTagName('img');
            if (images.length > 0) {
              link.remove();
            }
          }
        });

        // Hide announcement bar if exists
        const announcement = document.querySelector('.announcement-bar, [class*="announcement"]');
        if (announcement) {
          announcement.style.display = 'none';
        }
        
        // Adjust navigation layout and ensure search remains visible
        const nav = header.querySelector('nav, [class*="navigation"]');
        if (nav) {
          nav.style.padding = '0 15px';
          nav.style.margin = '0';
          
          // Ensure only search icon remains visible
          const searchElements = nav.querySelectorAll('[class*="search"]');
          searchElements.forEach(el => {
            el.style.display = 'block';
            el.style.opacity = '1';
            el.style.visibility = 'visible';
          });
        }
      }
      
      // Remove floating elements and popups
      const elementsToRemove = document.querySelectorAll(`
        .waba-floating-button,
        .wa-chat-box,
        .floating-whatsapp,
        [class*="float"],
        [class*="popup"],
        [id*="popup"],
        [class*="modal"]:not([class*="search"]),
        [id*="modal"]:not([id*="search"]),
        .announcement,
        .announcement-bar,
        [class*="promo-bar"],
        [class*="promotional"],
        [class*="drawer"],
        [class*="menu-drawer"]
      `);
      
      elementsToRemove.forEach(el => {
        if (!el.innerHTML.includes('search') && 
            !el.classList.contains('search') && 
            !el.querySelector('[class*="search"]')) {
          el.remove();
        }
      });
      
      // Remove fixed elements with high z-index while preserving search
      document.querySelectorAll('*').forEach(el => {
        const style = window.getComputedStyle(el);
        if (style.position === 'fixed' && parseInt(style.zIndex, 10) > 100) {
          if (!el.classList.contains('progress-bar') && 
              !el.classList.contains('navigation') &&
              !el.classList.contains('bottom-nav') &&
              !el.innerHTML.includes('search') &&
              !el.classList.contains('search') &&
              !el.querySelector('[class*="search"]')) {
            el.remove();
          }
        }
      });
    }

    removeUnwantedElements();
    setTimeout(removeUnwantedElements, 500);

    const observer = new MutationObserver(() => {
      removeUnwantedElements();
    });
    
    observer.observe(document.body, {
      childList: true,
      subtree: true,
      attributes: true,
      characterData: true,
      attributeFilter: ['style', 'class']
    });
    
    window.addEventListener('load', removeUnwantedElements);
    document.addEventListener('DOMContentLoaded', removeUnwantedElements);
    window.addEventListener('resize', removeUnwantedElements);
    document.addEventListener('scroll', () => {
      requestAnimationFrame(removeUnwantedElements);
    });
  ''');

      // Viewport adjustment
      await controller.evaluateJavascript(source: '''
    const viewport = document.querySelector('meta[name="viewport"]');
    if (viewport) {
      viewport.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');
    }
  ''');
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

      // Add handler for cart count
      controller.addJavaScriptHandler(
        handlerName: 'updateCartCount',
        callback: (args) {
          if (mounted) {
            setState(() {
              _cartCount = int.tryParse(args[0]?.toString() ?? '0') ?? 0;
            });
          }
          return null;
        },
      );

      // Inject script to hide only floating button
      controller.addJavaScriptHandler(
        handlerName: 'hideFloatingButton',
        callback: (args) async {
          await _injectHidingScript(controller);
          return null;
        },
      );
      _injectHidingScript(controller);
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


    void _onLoadStart(InAppWebViewController controller, Uri? url) {
      if (mounted) {
        setState(() => _isLoading = true);
        _injectRemovalScript(controller);
      }
    }

    void _onLoadStop(InAppWebViewController controller, Uri? url) {
      if (mounted) {
        setState(() => _isLoading = false);
        controller.evaluateJavascript(source: '''
      var cartCount = document.querySelector('.cart-count-bubble')?.textContent || '0';
      window.flutter_inappwebview.callHandler('updateCartCount', cartCount);
    ''');
        _injectHidingScript(controller);
      }
    }

    void _onProgressChanged(InAppWebViewController controller, int progress) {
      if (!mounted) return;
      setState(() => _progress = progress / 100);
      if (progress > 70) {
        _injectRemovalScript(controller);
      }
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

    // Update onBottomNavTapped to handle accessories tab
    void _onBottomNavTapped(int index) {
      setState(() {
        _currentIndex = index;
      });

      if (index == 1) { // Mobiles tab
        _showDeviceCategoriesBottomSheet();
      } else if (index == 5) { // Accessories tab
        _showAccessoriesBottomSheet();
      } else {
        _loadUrl(_urls[index]);
      }
    }

    final InAppWebViewGroupOptions _options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(

        verticalScrollBarEnabled: true,
        horizontalScrollBarEnabled: false,
        transparentBackground: true,
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
        useOnLoadResource: true,
        cacheEnabled: true,
        clearCache: false,
        preferredContentMode: UserPreferredContentMode.MOBILE,
        applicationNameForUserAgent: 'TrustKsa/1.0',
        javaScriptEnabled: true,
        disableHorizontalScroll: false,
        disableVerticalScroll: false,
        javaScriptCanOpenWindowsAutomatically: false, // Prevent window.open()
        supportZoom: false,
      ),
      android: AndroidInAppWebViewOptions(

        useWideViewPort: true,
        loadWithOverviewMode: true,
        displayZoomControls: false,
        builtInZoomControls: false,
        useHybridComposition: true,
        cacheMode: AndroidCacheMode.LOAD_CACHE_ELSE_NETWORK,
        supportMultipleWindows: false,

        databaseEnabled: true,
        domStorageEnabled: true,
        saveFormData: false,
        blockNetworkImage: false,
        blockNetworkLoads: false,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
        allowsLinkPreview: false,
        //enableViewportScale: false,
        suppressesIncrementalRendering: false,
        allowsBackForwardNavigationGestures: false,
        disableLongPressContextMenuOnLinks: true,
        enableViewportScale: true,
        automaticallyAdjustsScrollIndicatorInsets: true,
       // allowsPopups: false, // Prevent popups on iOS

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

    void _loadUrl(String url) {
      _webViewController?.loadUrl(
        urlRequest: URLRequest(
          url: Uri.parse(url),
          headers: {'Cache-Control': 'max-age=3600'},
        ),
      );
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




    @override
    Widget build(BuildContext context) {
      return WillPopScope(
        onWillPop: () async {
          if (await _webViewController?.canGoBack() ?? false) {
            await _webViewController?.goBack();
            return false;
          }
          return true;
        },
        child: Scaffold(

          drawer: Drawer(
            child: ListView(
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Color(0xFFFEAA00),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/logo.png', height: 80),
                      SizedBox(height: 10),
                      Text(
                        'جي فاير للموبايل',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.shield_outlined, color: Color(0xFFFEAA00)),
                  title: Text('سياسة الخصوصية'),
                  onTap: () {
                    Navigator.pop(context);
                    _loadUrl('https://jifirephone.com/policies/privacy-policy');
                  },
                ),
                ListTile(
                  leading: Icon(Icons.person_off_outlined, color: Color(0xFFFEAA00)),
                  title: Text('حذف الحساب'),
                  onTap: () {
                    Navigator.pop(context);
                    _loadUrl('https://jifirephone.com/pages/delete-account');
                  },
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: Stack(
              children: [
                InAppWebView(
                  key: const ValueKey('main_webview'),
                  initialUrlRequest: URLRequest(
                    url: Uri.parse(_urls[0]),
                    headers: {'Cache-Control': 'max-age=3600'},
                  ),
                  initialOptions: _options,
                  onWebViewCreated: _onWebViewCreated,
                  onLoadStart: _onLoadStart,
                  onProgressChanged: _onProgressChanged,
                  onLoadStop: _onLoadStop,
                  onLoadError: _onLoadError,
                  androidOnPermissionRequest: _handleAndroidPermissionRequest,
                ),
                if (_isLoading)
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onBottomNavTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'الرئيسية',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.phone_iphone),
                label: 'موبايلات',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.camera_alt),
                label: 'كاميرات',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.laptop),
                label: 'لابتوب',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.videogame_asset),
                label: 'ألعاب',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.headphones),
                label: 'اكسسوارات',
              ),
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
        await _launchUrl(url);

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
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showToast('Unable to open link');
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