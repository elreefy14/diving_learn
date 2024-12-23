import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewUrlHandler {
  factory WebViewUrlHandler() => _singleton;
  WebViewUrlHandler._internal();
  static final WebViewUrlHandler _singleton = WebViewUrlHandler._internal();
  static String? webViewUrl;
  static InAppWebViewController? _webViewController;
  static InAppWebViewController? get webViewController =>_webViewController;
  static void setWebViewController(InAppWebViewController? webViewController) {
    _webViewController = webViewController;
  }

  static void loadUrl(Uri uri) {
    _webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri.uri(uri)));
  }

  static void evaluateJavaScrip(String  js)async {
    await _webViewController?.evaluateJavascript(source: js).then((value){
      debugPrint("value For evaluateJavaScrip ${value.toString()}");
    });
  }


}
