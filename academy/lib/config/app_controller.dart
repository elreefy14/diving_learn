import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/data/local/shared_pref.dart';

class StartAppController extends GetxController {
  bool passOnBoarding = false, loginUser = false;
  Locale localLang = const Locale("en");
  ThemeMode themeMode = ThemeMode.light;

  // check if user pass on boarding
  passOnBoardingMethod() async {
    bool passOnBoarding = SharedPref.getOnBoarding();
    if (passOnBoarding) {
      this.passOnBoarding = true;
    } else {
      this.passOnBoarding = false;
    }
    update();
  }

  // check login user
  checkLoginUser() async {
    String? token = SharedPref.getAuthorizationToken();
    if (token != null) {
      loginUser = true;
    } else {
      loginUser = false;
    }
    update();
  }

  // get current locale
  getLang() async {
    localLang = SharedPref.getCurrentLocal();
    update();
  }

  // get current theme
  getTheme() async {
    themeMode = SharedPref.getThemeIsLight() ? ThemeMode.light : ThemeMode.dark;
    update();
  }
}
