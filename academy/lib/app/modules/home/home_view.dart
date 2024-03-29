import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Another WebView')),
      body: SafeArea(
        child: WebView(
          initialUrl: 'https://hnzaker.com/',
          javascriptMode: JavascriptMode.unrestricted,
          userAgent:
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.150 Safari/537.36',
        ),
      ),
    );
  }
}