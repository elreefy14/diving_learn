import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: const Text('Another WebView')),
      body: SafeArea(
        child: WebView(
          initialUrl: 'https://hnzaker.com/',
          javascriptMode: JavascriptMode.unrestricted,
        ),
      ),
    );
  }
}