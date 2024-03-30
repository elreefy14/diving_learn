import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class UIHelpers {
  static void init() {
    _initLoader();
  }

  // static void _initLoader() {
  //   EasyLoading.instance
  //     ..loadingStyle = EasyLoadingStyle.light
  //     ..backgroundColor = Color(0xff003049)
  //     ..indicatorSize = 45.0
  //     ..radius = 20.0
  //     ..maskType = EasyLoadingMaskType.clear
  //     ..progressColor = Colors.yellow
  //     ..indicatorColor = Colors.yellow
  //     ..textColor = Colors.yellow
  //     // ..boxShadow = <BoxShadow>[]
  //     ..maskColor = Color(0xff003049)
  //     ..userInteractions = false
  //     ..progressColor  = Colors.red
  //     ..dismissOnTap = false;
  // }
  static void _initLoader() {
    EasyLoading.instance
      ..loadingStyle = EasyLoadingStyle.light
      ..backgroundColor = Color(0xff003049)
      ..indicatorSize = 45.0
      ..radius = 20.0
      ..maskType = EasyLoadingMaskType.custom
      ..progressColor = Colors.yellow
      ..indicatorColor = Colors.yellow
      ..textColor = Colors.yellow
    // ..boxShadow = <BoxShadow>[]
      ..maskColor = Colors.black.withOpacity(0.5) // semi-transparent black color
      ..userInteractions = false
      ..progressColor  = Colors.red
      ..dismissOnTap = false;
  }

  static void showLoading() {
    if (!EasyLoading.isShow) {
      EasyLoading.show(
        // status: 'Loading'.tr(),
        indicator: const CircularProgressIndicator(
          color: Colors.grey,
        // backgroundColor: Colors.blue,
        ),
        maskType: EasyLoadingMaskType.black,
        //maskColor: Colors.black.withOpacity(0.5),
         dismissOnTap: false,

      );
    }
  }

  static void stopLoading() {
    if (EasyLoading.isShow) {
      EasyLoading.dismiss();
    }
  }

  static void removeKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }
}
