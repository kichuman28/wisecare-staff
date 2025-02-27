import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wisecare_staff/core/theme/app_theme.dart';
import 'package:wisecare_staff/ui/screens/auth/login_screen.dart';
import 'package:wisecare_staff/provider/auth_provider.dart';
import 'package:wisecare_staff/provider/task_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: const WiseCareStaffApp(),
    ),
  );
}

class WiseCareStaffApp extends StatelessWidget {
  const WiseCareStaffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wise Care Staff',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}
