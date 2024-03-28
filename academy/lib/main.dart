import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'app/data/local/shared_pref.dart';
import 'app/routes/app_routes.dart';
import 'config/theme/my_theme.dart';
import 'config/translations/localization_service.dart';
import 'utils/awesome_notifications_helper.dart';
import 'utils/fcm_helper.dart';

Future<void> main() async {
  // wait for bindings
  WidgetsFlutterBinding.ensureInitialized();

  // init shared preference
  await SharedPref.init();

  // inti fcm services
  await FcmHelper.initFcm();

  // initialize local notifications service
  await AwesomeNotificationsHelper.init();

  runApp(
    ScreenUtilInit(
      // todo add your (Xd / Figma) artboard size
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      rebuildFactor: (old, data) => true,
      builder: (context, widget) {
        return GetMaterialApp(
          // todo add your app name
          title: "GetXSkeleton",
          useInheritedMediaQuery: true,
          debugShowCheckedModeBanner: false,
          builder: (context, widget) {
            bool themeIsLight = SharedPref.getThemeIsLight();
            return Theme(
              data: MyTheme.getThemeData(isLight: themeIsLight),
              child: MediaQuery(
                // prevent font from scalling (some people use big/small device fonts)
                // but we want our app font to still the same and dont get affected
                data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
                child: widget!,
              ),
            );
          },
          initialRoute: AppPages.routes[0].name,
          // first screen to show when app is running
          getPages: AppPages.routes,
          // app screens
          locale: SharedPref.getCurrentLocal(),
          // app language
          translations: LocalizationService
              .getInstance(), // localization services in app (controller app language)
        );
      },
    ),
  );
}
