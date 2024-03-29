import 'package:flutter_inappwebview/flutter_inappwebview.dart';

abstract class INavigationRule {
  bool isRuleApplicable(String stringUrl);
  Future<NavigationActionPolicy?> executeNavigationRule(
      InAppWebViewController controller, NavigationAction navigationAction);
}
