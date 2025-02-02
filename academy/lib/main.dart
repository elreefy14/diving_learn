// First, create a new file onboarding_screen.dart:
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/utils/get_it_injection.dart';
import 'features/web_view_feature/presentation/webview/webview.dart';
import 'firebase_options.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Brand colors based on the logo
  static const Color primaryYellow = Color(0xFFFEAA00);
  static const Color secondaryGray = Color(0xFFE6E6E6);
  static const Color darkGray = Color(0xFF333333);

  final List<Map<String, String>> _pages = [
    {
      'title': 'مرحباً بك في مركز جي فاير',
      'description': 'وجهتك المثالية لكل ما يتعلق بالموبايلات والاكسسوارات',
    },
    {
      'title': 'منتجات متنوعة',
      'description': 'نقدم مجموعة واسعة من الهواتف الذكية والاكسسوارات من أفضل العلامات التجارية',
    },
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  secondaryGray.withValues(alpha:  0.3),
                ],
              ),
            ),
          ),

          // Content
          PageView.builder(
            controller: _pageController,
            onPageChanged: (value) => setState(() => _currentPage = value),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo container with subtle shadow
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: primaryYellow.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        index == 0 ? Icons.store_outlined : Icons.phone_android_outlined,
                        size: 80,
                        color: primaryYellow,
                      ),
                    ),
                    const SizedBox(height: 60),

                    // Title with modern typography
                    Text(
                      _pages[index]['title']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: darkGray,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Description with improved readability
                    Text(
                      _pages[index]['description']!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: darkGray.withValues(alpha: 0.7),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Bottom navigation and indicators
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                // Page indicators with brand colors
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                        (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 12,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentPage == index
                            ? primaryYellow
                            : secondaryGray,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Modern button design
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _completeOnboarding(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryYellow,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentPage == _pages.length - 1 ? 'ابدأ' : 'التالي',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (_currentPage == _pages.length - 1) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _completeOnboarding(BuildContext context) async {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TrustKsaWebView()),
        );
      }
    }
  }
}


  Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    debugPrint("FCMMessage");
  // Handle background message
  AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      channelKey: 'basic_channel',
      title: message.notification?.title,
      body: message.notification?.body,
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init();
  await Firebase.initializeApp(
    name: 'Gi',
    options: DefaultFirebaseOptions.currentPlatform,
  );
   await Future.delayed(Duration(seconds: 1));
    AwesomeNotifications().initialize(
    null, // Set to null to use default icon
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic Notifications',
        channelDescription: 'Notification channel for basic tests',
        defaultColor: const Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
      ),
    ],
  );

  // Set up FCM background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final prefs = await SharedPreferences.getInstance();
  final showOnboarding = prefs.getBool('onboarding_complete')??true;
   prefs.setBool('onboarding_complete',false);

  runApp(TrustKsa(showOnboarding: showOnboarding));
}



  Future<void> setupNotifications() async {
    // Request permission for notifications
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else {
      debugPrint('User declined or has not granted permission');
    }

    // Get FCM token for debugging (optional)
    String? token = await messaging.getToken();
    debugPrint("FCM Token: $token");

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("FCMMessage");
      AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: 'basic_channel',
          title: message.notification?.title,
          body: message.notification?.body,
        ),
      );
    });
  }
  

// Update your TrustKsa class:

class TrustKsa extends StatefulWidget {
  final bool showOnboarding;

  const TrustKsa({super.key, this.showOnboarding = true});

  @override
  State<TrustKsa> createState() => _TrustKsaState();
}

class _TrustKsaState extends State<TrustKsa> {

  @override
  void initState(){
    super.initState();
    setupNotifications();
  }

  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      title: 'جي فاير للموبايل',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
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