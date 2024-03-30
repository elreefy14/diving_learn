import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/utils/get_it_injection.dart';
import '../../../../app/utils/ui_helpers.dart';
import '../../domain/usecase/on_route_change_usecase.dart';
import 'handler/web_view_url_handler.dart';
import 'webview_options.dart';

class TrustKsaWebView extends StatefulWidget {
  const TrustKsaWebView({Key? key,}) : super(key: key);
  @override
  State<TrustKsaWebView> createState() => _TrustKsaWebViewState();
}

class _TrustKsaWebViewState extends State<TrustKsaWebView> {
  static  InAppWebViewController? _webViewController;
  static  PullToRefreshController? _pullToRefreshController;

  @override
  void initState() {
    super.initState();
    _pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.deepOrangeAccent,
      ),
      onRefresh: _refresh,
    );
  }

  @override
  void dispose() {
    WebViewUrlHandler.setWebViewController(null);
    super.dispose();
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
                      "https://smartdriver.ae/login/?redirect_to=https%3A%2F%2Fsmartdriver.ae%2F"
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
        floatingActionButton: FloatingActionButton(
          onPressed: ()async{
            await launchUrl(Uri.parse("https://wa.me/+966508824777"));
          },
          backgroundColor: Colors.greenAccent,
          child: Icon(Icons.chat),
        ),
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
    if (progress > 70) {
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