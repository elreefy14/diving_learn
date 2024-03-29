import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../domain/repository/web_view_repo.dart';
import '../data_source/web_view_navigation_rule_evaluation_data_source.dart';

class WebViewRepoImpl implements WebViewRepo{
  WebViewRepoImpl({required this.iNavigationEvaluatorDataSource,});
  INavigationEvaluatorDataSource iNavigationEvaluatorDataSource;

  @override
  Future<NavigationActionPolicy?> onRouteChange(InAppWebViewController c, NavigationAction n) {
    return iNavigationEvaluatorDataSource.evaluateRule(c, n);
  }
}