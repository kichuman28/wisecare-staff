import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:wisecare_staff/core/theme/app_theme.dart';
import 'package:wisecare_staff/ui/screens/auth/login_screen.dart';
import 'package:wisecare_staff/ui/screens/main_screen.dart';
import 'package:wisecare_staff/provider/auth_provider.dart';
import 'package:wisecare_staff/provider/task_provider.dart';
import 'package:wisecare_staff/provider/sos_alert_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => SOSAlertProvider()),
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
      home: const AuthCheckScreen(),
    );
  }
}

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  late Future<bool> _authCheckFuture;

  @override
  void initState() {
    super.initState();
    _authCheckFuture = _checkAuth();
  }

  Future<bool> _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return await authProvider.checkCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _authCheckFuture,
      builder: (context, snapshot) {
        // While checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // If authenticated, go to main screen
        if (snapshot.data == true) {
          return const MainScreen();
        }
        
        // Otherwise, show login screen
        return const LoginScreen();
      },
    );
  }
}
