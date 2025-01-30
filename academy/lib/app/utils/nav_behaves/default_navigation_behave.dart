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
    "https://wa.me/",
    "https://www.youtube.com",
    "https://www.snapchat.com",
    "https://www.instagram.com",
    "instagram://",
    "https://www.tiktok.com",
    "tiktok://",
    "https://play.google.com",
    "https://apps.apple.com",
    "https://appgallery.huawei.com",
    "tel:",
    "mailto:",
    "fb://",
    "intent://",
    "facebook://",
    "https://www.facebook.com",
    "https://fb.me/",
    "https://fb.watch/",
    "https://m.facebook.com"
  ];

  bool _checkIfUrlBlackListed(String url) {
    debugPrint('Checking URL: $url');
    for (var blacklisted in blackListedUrls) {
      if (url.toLowerCase().startsWith(blacklisted.toLowerCase())) {
        debugPrint('URL is blacklisted: $url matches $blacklisted');
        return true;
      }
    }
    return false;
  }

  Future<void> _launchURL(String url) async {
    debugPrint('Attempting to launch URL: $url');

    try {
      // Handle WhatsApp URLs
      if (url.contains('api.whatsapp.com') || url.contains('whatsapp://') || url.contains('wa.me')) {
        final Uri uri = Uri.parse(url);
        String phone = '';
        String text = '';

        // Extract phone and text based on URL format
        if (url.contains('wa.me')) {
          final parts = uri.path.replaceAll('/', '').split('?');
          phone = parts[0];
          if (uri.queryParameters.containsKey('text')) {
            text = uri.queryParameters['text']!;
          }
        } else {
          phone = uri.queryParameters['phone'] ?? '';
          text = uri.queryParameters['text'] ?? '';
        }

        final whatsappAppUrl = Uri.parse('whatsapp://send?phone=$phone${text.isNotEmpty ? '&text=${Uri.encodeComponent(text)}' : ''}');
        final webUrl = Uri.parse('https://wa.me/$phone${text.isNotEmpty ? '?text=${Uri.encodeComponent(text)}' : ''}');

        if (await canLaunchUrl(whatsappAppUrl)) {
          await launchUrl(whatsappAppUrl, mode: LaunchMode.externalApplication);
        } else if (await canLaunchUrl(webUrl)) {
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        }
        return;
      }

      // Handle Instagram URLs
      if (url.contains('instagram.com')) {
        final instagramAppUrl = Uri.parse('instagram://user?username=${Uri.parse(url).pathSegments.last}');
        if (await canLaunchUrl(instagramAppUrl)) {
          await launchUrl(instagramAppUrl, mode: LaunchMode.externalApplication);
        } else {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
        return;
      }

      // Handle TikTok URLs
      if (url.contains('tiktok.com')) {
        final tiktokAppUrl = Uri.parse('tiktok://user?username=${Uri.parse(url).pathSegments.last}');
        if (await canLaunchUrl(tiktokAppUrl)) {
          await launchUrl(tiktokAppUrl, mode: LaunchMode.externalApplication);
        } else {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
        return;
      }

      // Handle Facebook URLs
      if (url.contains('facebook.com') || url.contains('fb.me') || url.contains('fb.watch')) {
        final fbAppUrl = Uri.parse('fb://${Uri.parse(url).path}');
        if (await canLaunchUrl(fbAppUrl)) {
          await launchUrl(fbAppUrl, mode: LaunchMode.externalApplication);
        } else {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        }
        return;
      }

      // Handle all other URLs
      final uri = Uri.parse(url);
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