import 'dart:developer';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../../app/utils/nav_behaves/default_navigation_behave.dart';
import '../../../../app/utils/nav_behaves/rules/inavigation_rule.dart';
import '../../../../app/utils/nav_behaves/rules/rule_for_call.dart';


abstract class INavigationEvaluatorDataSource {
  List<INavigationRule> rules = [];
  Future<NavigationActionPolicy?> evaluateRule(InAppWebViewController c, NavigationAction n);
}

class INavigationEvaluatorDataSourceImpl implements INavigationEvaluatorDataSource {
  @override
  List<INavigationRule> rules = [
    RuleCallNavigation(),
  ];

  @override
  Future<NavigationActionPolicy?> evaluateRule(InAppWebViewController controller, NavigationAction navigationAction) {
    final String urlString = navigationAction.request.url.toString();
    log(urlString,name:"url has changed to");

    //
    //** Assign the default role (ELSE Case)*/
    //
    Future<NavigationActionPolicy?> navigationActionPolicy =
    DefaultNavigationBehave().navigationAction(controller, navigationAction);

    //
    //** Check if there is applicable rule */
    //
    for (var rule in rules) {
      if (rule.isRuleApplicable(urlString)) {
        navigationActionPolicy = rule.executeNavigationRule(controller, navigationAction);
      }
    }

    return navigationActionPolicy;
  }
}