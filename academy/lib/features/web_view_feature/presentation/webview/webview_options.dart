
import 'package:flutter_inappwebview/flutter_inappwebview.dart';


class TrustKsaWebViewOptions {
  factory TrustKsaWebViewOptions() {
    return _singleton;
  }
  TrustKsaWebViewOptions._internal();
  static final TrustKsaWebViewOptions _singleton =
      TrustKsaWebViewOptions._internal();

  final  _options = InAppWebViewSettings(
    // crossPlatform: InAppWebViewOptions(
      useOnDownloadStart: true,
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
      allowFileAccessFromFileURLs: true,
      allowUniversalAccessFromFileURLs: true,
      disableContextMenu: true,
      applicationNameForUserAgent: "TrustKsa",
      javaScriptCanOpenWindowsAutomatically: true,
      verticalScrollBarEnabled: false,
      horizontalScrollBarEnabled: false,
      preferredContentMode: UserPreferredContentMode.MOBILE,
      supportZoom: false,
      useShouldInterceptFetchRequest: true
      // disableHorizontalScroll: true,
      // clearCache: true,
    //),
    // android: AndroidInAppWebViewOptions(
    //   useHybridComposition: true,
    //   disableDefaultErrorPage: true,
    //   useShouldInterceptRequest: true,
    //   mixedContentMode: AndroidMixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,

    // ),
    // ios: IOSInAppWebViewOptions(
    //     allowsInlineMediaPlayback: true,
    //     alwaysBounceVertical: true,
    //     disableInputAccessoryView: true,
    //     automaticallyAdjustsScrollIndicatorInsets: true,
    //     suppressesIncrementalRendering: true,
    //     allowsLinkPreview: false,
    //     useOnNavigationResponse: true,
    //     sharedCookiesEnabled: true,
    //     disableLongPressContextMenuOnLinks: true,
    //     maximumZoomScale: 0.5,
    // ),
  );
  InAppWebViewSettings get options => _options;

}
