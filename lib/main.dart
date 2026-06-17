import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'services/locale_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialize locale from saved preferences
  await LocaleService.instance.init();

  final prefs = await SharedPreferences.getInstance();
  final onboardingDone = prefs.getBool('onboarding_done') ?? false;
  final isLoggedIn = await ApiService.isLoggedIn();

  runApp(UztexConfApp(
    onboardingDone: onboardingDone,
    isLoggedIn: isLoggedIn,
  ));
}

class UztexConfApp extends StatelessWidget {
  final bool onboardingDone;
  final bool isLoggedIn;

  const UztexConfApp({
    super.key,
    required this.onboardingDone,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (!onboardingDone) {
      home = const OnboardingScreen();
    } else if (isLoggedIn) {
      home = const HomeScreen();
    } else {
      home = const LoginScreen();
    }

    return ValueListenableBuilder<String>(
      valueListenable: LocaleService.instance,
      builder: (_, __, ___) => MaterialApp(
        title: 'UztexConf',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
        home: home,
      ),
    );
  }
}
