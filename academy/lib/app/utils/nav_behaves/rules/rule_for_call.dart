import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../call_navigation_behave.dart';
import 'inavigation_rule.dart';

class RuleCallNavigation implements INavigationRule {
  @override
  Future<NavigationActionPolicy?> executeNavigationRule(InAppWebViewController controller, NavigationAction navigationAction) {
    return CallNavigationBehave().navigationAction(controller, navigationAction);
  }

  @override
  bool isRuleApplicable(String stringUrl) {
    return stringUrl.contains("tel:");
  }
}
