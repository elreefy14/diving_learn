
import 'package:flutter/material.dart';
import 'app/utils/get_it_injection.dart';
import 'features/trust_ksa.dart';
void main() async{
  //* Widgets Binding Initialized
  final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  //1await EasyLocalization.ensureInitialized();
  await init();
  //* Preserve Native Splash Screen
  // FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  runApp(const TrustKsa(),);

}

