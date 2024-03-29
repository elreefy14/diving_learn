import 'package:flutter_inappwebview/flutter_inappwebview.dart';

abstract class NavigationDelegateRepo {
  Future<NavigationActionPolicy?> navigationAction(InAppWebViewController c, NavigationAction n);
}
