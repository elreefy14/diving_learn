import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';

class TrustKsaWebView extends StatefulWidget {
  const TrustKsaWebView({Key? key}) : super(key: key);

  @override
  _TrustKsaWebViewState createState() => _TrustKsaWebViewState();
}

class _TrustKsaWebViewState extends State<TrustKsaWebView> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _isShowingNoConnection = false;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;


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

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    if (result == ConnectivityResult.none) {
      if (!_isShowingNoConnection) {
        _showNoConnectionScreen();
      }
    } else {
      if (_isShowingNoConnection && mounted) {
        // Return to WebView and reload
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const TrustKsaWebView(),
          ),
        );
      }
    }
  }

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

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }


  Future<void> _initConnectivity() async {
    ConnectivityResult result = await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            url: Uri.parse("https://jifirephone.com/"),
          ),
          initialOptions: InAppWebViewGroupOptions(
            crossPlatform: InAppWebViewOptions(
                useShouldOverrideUrlLoading: true,
                javaScriptEnabled: true,
                userAgent: 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36'
            ),
          ),
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
          onLoadStop: (controller, url) async {
            await controller.evaluateJavascript(source: _injectedScript);
          },
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            final url = navigationAction.request.url?.toString() ?? '';

            if (_shouldHandleExternally(url)) {
              await _handleExternalUrl(url);
              return NavigationActionPolicy.CANCEL;
            }

            return NavigationActionPolicy.ALLOW;
          },
          onLoadError: (controller, url, code, message) {
            debugPrint('WebView Error: $code - $message');
          },
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