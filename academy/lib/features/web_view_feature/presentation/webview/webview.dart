import 'dart:async';
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