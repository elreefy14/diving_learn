//[٦:٤٨ ص، ٢٠٢٤/٣/٣١] ahmed Elreefy: To handle the no internet connection case in your Flutter application, you can use the connectivity_plus package to check for internet connectivity and then display a screen with a message and a retry button if there's no connection. Here's how you can modify your TrustKsaWebView class to achieve this:
//
// First, add the connectivity_plus package to your pubspec.yaml:
//
// yaml
// dependencies:
//   flutter:
//     sdk: flutter
//   connectivity_plus: ^2.0.2 # Check for the latest version on pub.dev
//
//
// Then, import the necessary packages in your Dart file:
//
// dart
// import 'package:connectivity_plus/connectivity_plus.dart';
//
//
// Next, modify your _TrustKsaWebViewState class to check for internet connectivity:
//
// dart
// class _TrustKsaWebViewState extends State<TrustKsaWebView> {
//   InAppWe…
// [٦:٥١ ص، ٢٠٢٤/٣/٣١] ahmed Elreefy: To handle internet connection issues when using the InAppWebView in Flutter, you can use the connectivity_plus package to listen for internet connectivity changes and display a message or take action when there is no internet connection. Here's how you can modify your code to include internet connection handling:
//
// 1. Add connectivity_plus to your pubspec.yaml under dependencies:
//
// yaml
// dependencies:
//   flutter:
//     sdk: flutter
//   flutter_inappwebview:
//   connectivity_plus: ^2.0.2
//
//
// Remember to run flutter pub get to install the new package.
//
// 2. Import the connectivity_plus package in your Dart file:
//
// dart
// import 'package:connectivity_plus/connectivity_plus.dart';
//
//
// 3. Update your _TrustKsaWebViewState class to include a subscription to connectivity changes and to handle them:
//
// dart
// class _TrustKsaWebViewState extends State<TrustKsaWebView> {
//   InAppWebViewController? _webViewController;
//   PullToRefreshController? _pullToRefreshController;
//   final Connectivity _connectivity = Connectivity();
//   late StreamSubscription<ConnectivityResult> _connectivitySubscription;
//
//   @override
//   void initState() {
//     super.initState();
//     _pullToRefreshController = PullToRefreshController(
//       options: PullToRefreshOptions(
//         color: Colors.deepOrangeAccent,
//       ),
//       onRefresh: _refresh,
//     );
//     _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
//   }
//
//   @override
//   void dispose() {
//     WebViewUrlHandler.setWebViewController(null);
//     _connectivitySubscription.cancel();
//     super.dispose();
//   }
//
//   Future<void> _updateConnectionStatus(ConnectivityResult result) async {
//     if (result == ConnectivityResult.none) {
//       _showNoInternetDialog();
//     } else {
//       _hideNoInternetDialog();
//       // Optionally, refresh or reload the web view here
//     }
//   }
//
//   void _showNoInternetDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('No Internet Connection'),
//         content: Text('Please check your internet connection and try again.'),
//         actions: <Widget>[
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//             },
//             child: Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _hideNoInternetDialog() {
//     // If you showed a persistent dialog or widget when there's no internet,
//     // implement logic to hide it here when the connection is restored.
//   }
//
//   // The rest of your class remains unchanged...
// }
//
//
// In this updated version of your _TrustKsaWebViewState class, the _updateConnectionStatus method listens for changes in internet connectivity. When there's no internet connection (ConnectivityResult.none), it shows a dialog informing the user. You can customize the _showNoInternetDialog and _hideNoInternetDialog methods as needed, depending on how you wish to inform the user of connectivity issues or recover from them.
//
// Remember that handling connectivity changes this way provides a basic level of feedback to the user. Depending on your application's requirements, you might want to implement more sophisticated error handling or recovery mechanisms.
import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/utils/get_it_injection.dart';
import '../../../../app/utils/ui_helpers.dart';
import '../../domain/usecase/on_route_change_usecase.dart';
import 'handler/web_view_url_handler.dart';
import 'webview_options.dart';

class TrustKsaWebView extends StatefulWidget {
  const TrustKsaWebView({Key? key}) : super(key: key);

  @override
  _TrustKsaWebViewState createState() => _TrustKsaWebViewState();
}
class _TrustKsaWebViewState extends State<TrustKsaWebView> {
  InAppWebViewController? _webViewController;
  PullToRefreshController? _pullToRefreshController;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.deepOrangeAccent,
      ),
      onRefresh: _refresh,
    );
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _connectivity.checkConnectivity().then((result) {
    if (result == ConnectivityResult.none) {
      _showNoInternetDialog();
    }
  });
  }

  @override
  void dispose() {
    WebViewUrlHandler.setWebViewController(null);
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result
      ,
      {     bool? isReloadTheWebsite = false
}
      ) async {
    if (result == ConnectivityResult.none) {
      _showNoInternetDialog();
    } else {
      _hideNoInternetDialog();
   if(
  // isReloadTheWebsite == true
  true
   ) {
     _webViewController?.loadUrl(
        urlRequest: URLRequest(
          url: Uri.parse(
              WebViewUrlHandler.webViewUrl ?? "https://smartdriver.ae/"
          ),
        ),
      );
   }
    }
  }

  void _showNoInternetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('لا يوجد اتصال بالإنترنت'),
        content: const Text('يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى'),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              var connectivityResult = await _connectivity.checkConnectivity();
              if (connectivityResult != ConnectivityResult.none) {
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(' لا يوجد اتصال بالإنترنت '
                        'يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى')));
              }
            },
            child: const Text('اعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  void _hideNoInternetDialog() {
    //pop dialog
    // If you showed a persistent dialog or widget when there's no internet,
    // implement logic to hide it here when the connection is restored.
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {

    return  WillPopScope(
      onWillPop: () async {

        _webViewController?.goBack();
        return Future.value(false);
      },

      child: Scaffold(
        body: SafeArea(
          child: InAppWebView(
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              Uri url = navigationAction.request.url!;
              if (url.toString() == 'https://themeholy.com/wordpress/dride/') {
                return NavigationActionPolicy.CANCEL;
              }
              return getIt<OnRouteChangeUseCase>()(OnRouteChangeUseCaseParams(controller: controller, navigationAction: navigationAction));
            },
            pullToRefreshController: _pullToRefreshController,
            androidOnGeolocationPermissionsShowPrompt: _androidOnGeolocationPermissionsShowPrompt,
            initialUrlRequest: URLRequest(
              url: Uri.parse(
                  WebViewUrlHandler.webViewUrl ??
                      "https://smartdriver.ae/"
              ),
            ),
            initialOptions: TrustKsaWebViewOptions().options,
            onProgressChanged: _onProgressChanged,
            onLoadError: _onError,
            onJsPrompt: (controller, jsPromptRequest) async {
              return Future.value(JsPromptResponse(handledByClient: true));
            },
            //
            androidOnPermissionRequest: _androidOnPermissionRequest,
            onWebViewCreated: _onWebViewCreated,
            onConsoleMessage: _onConsoleMessage,
            onLoadStop: _onLoadStop,
          ),
        ),
  //      floatingActionButton: FloatingActionButton(
  //        onPressed: ()async{
  //          await launchUrl(Uri.parse("https://wa.me/+966508824777"));
  //        },
  //        backgroundColor: Colors.greenAccent,
  //        child: const Icon(Icons.chat),
        //     ),
      ),
    );
  }

  void _onError(InAppWebViewController controller, Uri? uri, int code, String description) async {
    log("$code / $description / ${uri}",name: "_onError");
  }


  void _refresh() async {
    if (Platform.isAndroid) {
      _webViewController?.reload();
    } else if (Platform.isIOS) {
      _webViewController?.loadUrl(
          urlRequest: URLRequest(url: await _webViewController?.getUrl()));
    }
  }

  void _endRefresh() {
    _pullToRefreshController?.endRefreshing();
  }

  void _onProgressChanged(InAppWebViewController controller, int progress) {
    //hwa 3amalha 70
    //20 7lwa
    if (progress > 50) {
      UIHelpers.stopLoading();
      _pullToRefreshController?.endRefreshing();
    } else {
      UIHelpers.showLoading();
    }
  }


  void _onWebViewCreated(InAppWebViewController controller) async{
    _webViewController = controller;
    WebViewUrlHandler.setWebViewController(controller);
  }

  void _onConsoleMessage(InAppWebViewController controller, ConsoleMessage consoleMessage) async{
    log(consoleMessage.toMap().toString(),name:"consoleMessage");
  }

  void _onLoadStop(InAppWebViewController controller, Uri? url) async {
    _endRefresh();
    // used to close splashscreen after initial url is loading so that application opened on loaded UI
    // FlutterNativeSplash.remove();
  }

  Future<GeolocationPermissionShowPromptResponse?> _androidOnGeolocationPermissionsShowPrompt(InAppWebViewController controller, String origin) async {
    return GeolocationPermissionShowPromptResponse(
      allow: true,
      origin: origin,
      retain: false,
    );
  }

  Future<PermissionRequestResponse?> _androidOnPermissionRequest(InAppWebViewController controller, String origin, List<String> resources) async {
    return PermissionRequestResponse(
      resources: resources,
      action: PermissionRequestResponseAction.GRANT,
    );
  }
}