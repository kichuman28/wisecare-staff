import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wisecare_staff/core/theme/app_theme.dart';
import 'package:wisecare_staff/provider/auth_provider.dart';
import 'package:wisecare_staff/ui/screens/auth/login_screen.dart';
import 'package:wisecare_staff/ui/screens/edit_profile_screen.dart';
import 'package:wisecare_staff/ui/widgets/custom_card.dart';

class StaffProfileScreen extends StatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );

    // If profile was updated, refresh the profile data
    if (result == true) {
      _fetchUserProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;
    final userProfile = authProvider.userProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _fetchUserProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Profile Header Section
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 16,
                        bottom: 32,
                        left: 24,
                        right: 24,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // App Bar Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Profile',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  color: AppColors.primary,
                                  onPressed: _navigateToEditProfile,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Profile Picture and Info
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: Text(
                                  authProvider.userName?.isNotEmpty == true
                                      ? authProvider.userName!.substring(0, 1).toUpperCase()
                                      : 'N',
                                  style: theme.textTheme.displayLarge?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.cardBackground,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            authProvider.userName ?? 'Staff Member',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              authProvider.userRole?.toUpperCase() ?? 'STAFF',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Profile Sections
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildProfileSection(
                            context,
                            'Personal Information',
                            [
                              _buildInfoItem(
                                context,
                                'Email',
                                Icons.email_outlined,
                                authProvider.userEmail ?? 'Not available',
                                onTap: () => _navigateToEditProfile(),
                              ),
                              _buildInfoItem(
                                context,
                                'Phone',
                                Icons.phone_outlined,
                                userProfile?['phone'] ?? 'Not available',
                                onTap: () => _navigateToEditProfile(),
                              ),
                              _buildInfoItem(
                                context,
                                'Address',
                                Icons.home_outlined,
                                userProfile?['address'] ?? 'Not available',
                                onTap: () => _navigateToEditProfile(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildProfileSection(
                            context,
                            'Work Information',
                            [
                              _buildInfoItem(
                                context,
                                'Experience',
                                Icons.work_outline,
                                userProfile?['experience'] ?? 'Not available',
                                onTap: () => _navigateToEditProfile(),
                              ),
                              _buildInfoItem(
                                context,
                                'Preferred Shift',
                                Icons.schedule_outlined,
                                userProfile?['preferred_shift'] ?? 'Not available',
                                onTap: () => _navigateToEditProfile(),
                              ),
                              _buildInfoItem(
                                context,
                                'Shift Timing',
                                Icons.access_time_outlined,
                                userProfile?['shift_timing'] ?? 'Not available',
                                onTap: () => _navigateToEditProfile(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildProfileSection(
                            context,
                            'Emergency Contact',
                            [
                              _buildInfoItem(
                                context,
                                'Contact Name',
                                Icons.person_outline,
                                userProfile?['emergency_contact_name'] ?? 'Not available',
                                onTap: () => _navigateToEditProfile(),
                              ),
                              _buildInfoItem(
                                context,
                                'Contact Number',
                                Icons.phone_outlined,
                                userProfile?['emergency_contact'] ?? 'Not available',
                                showDivider: false,
                                onTap: () => _navigateToEditProfile(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildProfileSection(
                            context,
                            'App Settings',
                            [
                              _buildInfoItem(
                                context,
                                'Notifications',
                                Icons.notifications_outlined,
                                'Manage notifications',
                                showDivider: false,
                                onTap: () {
                                  // Handle notifications settings
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Logout Button
                          Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.error.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await authProvider.logout();
                                  if (context.mounted) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const LoginScreen(),
                                      ),
                                      (route) => false,
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to logout: ${e.toString()}'),
                                        backgroundColor: Theme.of(context).colorScheme.error,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.logout),
                              label: const Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.error,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String title,
    IconData icon,
    String value, {
    bool showDivider = true,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.text,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
          if (showDivider) const Divider(height: 1),
        ],
      ),
    );
  }
}
