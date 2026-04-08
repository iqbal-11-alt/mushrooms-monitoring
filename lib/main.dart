import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:monitoring_jamur/core/constants/supabase_config.dart';
import 'package:monitoring_jamur/core/theme/app_theme.dart';
import 'package:monitoring_jamur/features/auth/presentation/pages/login_page.dart';
import 'package:monitoring_jamur/features/home/presentation/pages/main_screen.dart';
import 'package:monitoring_jamur/core/session/user_session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await UserSession.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mushroom Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: UserSession.isLoggedIn ? const MainScreen() : const LoginPage(),
    );
  }
}
