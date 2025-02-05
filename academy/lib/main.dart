import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/utils/get_it_injection.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import '../features/web_view_feature/presentation/webview/webview.dart';
import '../onboard_page.dart';
import '../app/utils/notification_init.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      name: 'Gi',
      options: DefaultFirebaseOptions.currentPlatform,
  );
  await init();
  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = prefs.getBool('onboarding_complete') ?? true;
  runApp(MainPage(showOnboarding: showOnboarding));
}


class MainPage extends StatefulWidget {
  final bool showOnboarding;

  const MainPage({super.key,required this.showOnboarding});
  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {

  @override
  void initState() {
    super.initState();
    NotificationInit().setupNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'جي فاير للموبايل',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Cairo',
      ),
      builder: EasyLoading.init(
        builder: (context, widget) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
            child: widget!,
          );
        },
      ),
      home: widget.showOnboarding ? const OnboardingScreen() : const TrustKsaWebView(),
    );
  }
}