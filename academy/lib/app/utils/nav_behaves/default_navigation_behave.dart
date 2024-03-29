import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'navigation_delegate_repo.dart';
import 'package:url_launcher/url_launcher.dart';

class DefaultNavigationBehave implements NavigationDelegateRepo {
  static const List<String> blackListedUrls = [
    "https://g.co/kgs/mzYosC",
    "https://api.whatsapp.com/",
    //"https://www.youtube.com",
    "https://www.snapchat.com",
    "https://www.instagram.com",
    "https://play.google.com",
    "https://apps.apple.com",
    "https://appgallery.huawei.com",
    "tel:",
    "mailto:",
  ];

  bool _checkIfUrlBlackListed(String url) {
    if (blackListedUrls.any((element) => url.startsWith(element))) {
      return true;
    }
    return false;
  }
  void _launchURL(String url) async {
    Uri uri = Uri.parse(url);
    debugPrint("aaa $url");
    if(url.startsWith("tel:")){
      uri = Uri.parse(url.replaceFirst("tel:", "tel://").replaceAll(" ", "").replaceAll("%20", ""));
      debugPrint("aaa $uri");
    }

    if (await canLaunchUrl(uri)) {
      try {
        await launchUrl(uri,mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint(e.toString());
      }
    } else {
      debugPrint('could not launch url! $uri');
    }
  }

  @override
  Future<NavigationActionPolicy?> navigationAction(InAppWebViewController controller, NavigationAction navigationAction) async {
    final stringUrl = navigationAction.request.url.toString();
    log(stringUrl,name: "from DefaultNavigationBehave");
    if (_checkIfUrlBlackListed(stringUrl)) {
      debugPrint("The MimeType");
      debugPrint(navigationAction.request.url?.data?.mimeType);
      _launchURL(stringUrl);
      return NavigationActionPolicy.CANCEL;
    } else if (stringUrl.startsWith('app://')) {
      debugPrint('This action not handled $stringUrl');
      return NavigationActionPolicy.CANCEL;
    }
    else
      return NavigationActionPolicy.ALLOW;
  }
}

