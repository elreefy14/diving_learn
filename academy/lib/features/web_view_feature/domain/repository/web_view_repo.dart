import 'package:flutter_inappwebview/flutter_inappwebview.dart';

abstract class WebViewRepo{
  Future<NavigationActionPolicy?> onRouteChange(InAppWebViewController c, NavigationAction n);
}