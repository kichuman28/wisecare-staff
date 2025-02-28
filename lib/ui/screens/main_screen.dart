import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wisecare_staff/core/routing/role_based_router.dart';
import 'package:wisecare_staff/provider/auth_provider.dart';
import 'package:wisecare_staff/ui/screens/auth/login_screen.dart';
import 'package:wisecare_staff/ui/screens/staff_profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure we don't update state during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserProfile();
    });
  }

  Future<void> _fetchUserProfile() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.fetchUserProfile();
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final role = authProvider.userRole?.toLowerCase() ?? '';

    // If not authenticated, redirect to login
    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    // Get the appropriate home screen based on role
    final homeScreen = RoleBasedRouter.getHomeScreenForRole(role);

    final List<Widget> screens = [
      homeScreen,
      const StaffProfileScreen(),
    ];

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              role == 'responders' ? Icons.local_hospital_outlined : Icons.delivery_dining_outlined,
            ),
            label: role == 'responders' ? 'Emergencies' : 'Deliveries',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
