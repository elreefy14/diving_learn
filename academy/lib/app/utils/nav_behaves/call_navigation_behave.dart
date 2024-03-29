import 'dart:async';
import 'dart:developer';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'navigation_delegate_repo.dart';

class CallNavigationBehave implements NavigationDelegateRepo {
  @override
  Future<NavigationActionPolicy?> navigationAction(InAppWebViewController controller, NavigationAction navigationAction) async {
    log("CallNavigationBehave is Applicable",name: "CallNavigationBehave");
    return NavigationActionPolicy.CANCEL;
  }
}
