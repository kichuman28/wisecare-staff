import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wisecare_staff/core/theme/app_theme.dart';
import 'package:wisecare_staff/provider/auth_provider.dart';
import 'package:wisecare_staff/ui/screens/main_screen.dart';
import 'package:wisecare_staff/ui/widgets/custom_text_field.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyContactNameController = TextEditingController();
  final _experienceController = TextEditingController();
  String _selectedRole = 'responders';
  String _selectedShift = 'morning';

  final List<String> _shifts = ['morning', 'afternoon', 'night'];
  final Map<String, String> _shiftTimings = {
    'morning': '6:00 AM - 2:00 PM',
    'afternoon': '2:00 PM - 10:00 PM',
    'night': '10:00 PM - 6:00 AM',
  };

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _emergencyContactNameController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final authProvider = context.read<AuthProvider>();
        await authProvider.createUserProfile(
          userId: authProvider.userId!,
          name: _nameController.text.trim(),
          email: authProvider.userEmail!,
          role: _selectedRole,
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          emergencyContact: _emergencyContactController.text.trim(),
          emergencyContactName: _emergencyContactNameController.text.trim(),
          experience: _experienceController.text.trim(),
          preferredShift: _selectedShift,
          shiftTiming: _shiftTimings[_selectedShift]!,
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainScreen(),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to complete onboarding: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Complete Your Profile',
          style: theme.textTheme.titleLarge,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Picture Section
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Icon(
                          Icons.person_outline,
                          size: 50,
                          color: AppColors.primary,
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
                ),
                const SizedBox(height: 24),

                // Personal Information Section
                Text(
                  'Personal Information',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length < 10) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _addressController,
                  labelText: 'Address',
                  maxLines: 3,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Emergency Contact Section
                Text(
                  'Emergency Contact',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emergencyContactNameController,
                  labelText: 'Emergency Contact Name',
                  prefixIcon: const Icon(Icons.contact_emergency_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter emergency contact name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emergencyContactController,
                  labelText: 'Emergency Contact Number',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter emergency contact number';
                    }
                    if (value.length < 10) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Work Information Section
                Text(
                  'Work Information',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _experienceController,
                  labelText: 'Years of Experience',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.work_outline),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your experience';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Role Selection Section
                Text(
                  'Select Your Role',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _buildRoleSelector(
                  'Responder',
                  'Emergency response and medical assistance',
                  Icons.local_hospital_outlined,
                  'responders',
                ),
                const SizedBox(height: 12),
                _buildRoleSelector(
                  'Delivery',
                  'Medicine and equipment delivery',
                  Icons.delivery_dining_outlined,
                  'delivery',
                ),
                const SizedBox(height: 24),

                // Shift Preference Section
                Text(
                  'Preferred Shift',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Column(
                  children: _shifts.map((shift) => _buildShiftSelector(shift)).toList(),
                ),
                const SizedBox(height: 32),

                // Submit Button
                Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    return ElevatedButton(
                      onPressed: auth.isLoading ? null : _completeOnboarding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Complete Profile'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSelector(
    String title,
    String description,
    IconData icon,
    String role,
  ) {
    final isSelected = _selectedRole == role;

    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.textSecondary.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isSelected ? Colors.white : AppColors.text,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? Colors.white.withOpacity(0.8)
                              : AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Radio(
              value: role,
              groupValue: _selectedRole,
              onChanged: (value) => setState(() => _selectedRole = value!),
              fillColor: MaterialStateProperty.resolveWith(
                (states) => isSelected ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftSelector(String shift) {
    final isSelected = _selectedShift == shift;
    final timing = _shiftTimings[shift]!;
    final title = shift[0].toUpperCase() + shift.substring(1);

    return InkWell(
      onTap: () => setState(() => _selectedShift = shift),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.textSecondary.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                shift == 'morning'
                    ? Icons.wb_sunny_outlined
                    : shift == 'afternoon'
                        ? Icons.wb_cloudy_outlined
                        : Icons.nightlight_outlined,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$title Shift',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isSelected ? Colors.white : AppColors.text,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timing,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSelected
                              ? Colors.white.withOpacity(0.8)
                              : AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            Radio(
              value: shift,
              groupValue: _selectedShift,
              onChanged: (value) => setState(() => _selectedShift = value!),
              fillColor: MaterialStateProperty.resolveWith(
                (states) => isSelected ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 