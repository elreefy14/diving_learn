import 'dart:io';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:getx_skeleton/features/web_view_feature/presentation/webview/webview.dart';

import '../../../app/utils/ui_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class TrustKsa extends StatefulWidget {
  const TrustKsa({Key? key}) : super(key: key);

  @override
  State<TrustKsa> createState() => _TrustKsaState();
}

class _TrustKsaState extends State<TrustKsa> {
  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    //
    //* EasyLocalization
    //
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      //
      //* MaterialApp
      //
      builder: (context, child) => MaterialApp(
        //localizationsDelegates: context.localizationDelegates,
      //  supportedLocales: context.supportedLocales,
        // locale: CookieManagerService.getLocale,
       // locale: context.locale,
        title: 'ثقه العربية',
        debugShowCheckedModeBanner: false,
        // theme: Theme(),
        // navigatorKey: getIt<NavService>().navigatorKey,
        //
        //* EasyLoading
        //
        builder: EasyLoading.init(
          builder: (context, widget) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              child: widget!,
            );
          },
        ),
        home:  const TrustKsaWebView(),
      ),
    );
  }
}
