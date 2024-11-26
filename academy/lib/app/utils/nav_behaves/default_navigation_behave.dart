import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:getx_skeleton/app/utils/nav_behaves/rules/inavigation_rule.dart';
import 'package:getx_skeleton/app/utils/nav_behaves/rules/rule_for_call.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../features/web_view_feature/data/data_source/web_view_navigation_rule_evaluation_data_source.dart';
import 'navigation_delegate_repo.dart';

class DefaultNavigationBehave implements NavigationDelegateRepo {
  static const List<String> blackListedUrls = [
    "https://g.co/kgs/mzYosC",
    "https://api.whatsapp.com/",
    "whatsapp://",
    "https://www.youtube.com",
    "https://www.snapchat.com",
    "https://www.instagram.com",
    "https://play.google.com",
    "https://apps.apple.com",
    "https://appgallery.huawei.com",
    "tel:",
    "mailto:",
    "fb://",
    "intent://",
    "facebook://",
    "https://www.facebook.com"
  ];

  bool _checkIfUrlBlackListed(String url) {
    print('Checking URL: $url');
    for (var blacklisted in blackListedUrls) {
      if (url.toLowerCase().startsWith(blacklisted.toLowerCase())) {
        print('URL is blacklisted: $url matches $blacklisted');
        return true;
      }
    }
    return false;
  }

  Future<void> _launchURL(String url) async {
    debugPrint('Attempting to launch URL: $url');

    try {
      if (url.contains('api.whatsapp.com') || url.contains('whatsapp://')) {
        // Extract phone number and text
        final Uri uri = Uri.parse(url);
        final phone = uri.queryParameters['phone'] ?? '';
        final text = uri.queryParameters['text'] ?? '';

        // Construct WhatsApp URL
        String whatsappUrl = 'https://wa.me/$phone';
        if (text.isNotEmpty) {
          whatsappUrl += '?text=${Uri.encodeComponent(text)}';
        }

        debugPrint('Launching WhatsApp URL: $whatsappUrl');

        // Try to launch WhatsApp app first
        final whatsappAppUrl = Uri.parse('whatsapp://send?phone=$phone${text.isNotEmpty ? '&text=${Uri.encodeComponent(text)}' : ''}');
        if (await canLaunchUrl(whatsappAppUrl)) {
          await launchUrl(whatsappAppUrl, mode: LaunchMode.externalApplication);
        } else {
          // Fallback to web WhatsApp
          final webUrl = Uri.parse(whatsappUrl);
          if (await canLaunchUrl(webUrl)) {
            await launchUrl(webUrl, mode: LaunchMode.externalApplication);
          }
        }
        return;
      }

      // Handle regular URLs
      final uri = Uri.parse(url);
      debugPrint('Launching URL: $uri');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch URL: $uri');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Future<NavigationActionPolicy?> navigationAction(InAppWebViewController controller, NavigationAction navigationAction) async {
    final stringUrl = navigationAction.request.url.toString();
    log('URL intercepted: $stringUrl', name: "DefaultNavigationBehave");

    // Check for WhatsApp URLs specifically
    if (stringUrl.contains('api.whatsapp.com') || stringUrl.contains('whatsapp://')) {
      debugPrint('WhatsApp URL detected: $stringUrl');
      await _launchURL(stringUrl);
      return NavigationActionPolicy.CANCEL;
    }

    // Check other blacklisted URLs
    if (_checkIfUrlBlackListed(stringUrl)) {
      debugPrint('Blacklisted URL detected: $stringUrl');
      await _launchURL(stringUrl);
      return NavigationActionPolicy.CANCEL;
    }

    // Handle other special cases
    if (stringUrl.startsWith('app://') ||
        stringUrl.startsWith('about:blank') ||
        stringUrl.startsWith('awalmazad://') ||
        stringUrl.contains('/login') ||
        stringUrl.contains('/appbrowse?')) {
      return NavigationActionPolicy.CANCEL;
    }

    return NavigationActionPolicy.ALLOW;
  }
}

class INavigationEvaluatorDataSourceImpl implements INavigationEvaluatorDataSource {
  @override
  List<INavigationRule> rules = [
    RuleCallNavigation(),
  ];

  @override
  Future<NavigationActionPolicy?> evaluateRule(InAppWebViewController controller, NavigationAction navigationAction) async {
    final String urlString = navigationAction.request.url.toString();
    log('Evaluating URL: $urlString', name: "NavigationEvaluator");

    // Check specific rules first
    for (var rule in rules) {
      if (rule.isRuleApplicable(urlString)) {
        return await rule.executeNavigationRule(controller, navigationAction);
      }
    }

    // Use default navigation behavior
    return await DefaultNavigationBehave().navigationAction(controller, navigationAction);
  }
}