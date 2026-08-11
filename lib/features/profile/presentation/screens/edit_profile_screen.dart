import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../data/profile_repository.dart';
import '../../../auth/models/profile_model.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _profileRepository = ProfileRepository();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  
  Profile? _profile;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileRepository.getCurrentProfile();
      if (mounted && profile != null) {
        setState(() {
          _profile = profile;
          _nameController.text = profile.fullName ?? '';
          _usernameController.text = profile.username ?? '';
          _bioController.text = profile.bio ?? '';
          _phoneController.text = profile.phone ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_profile == null) return;

    setState(() => _isSaving = true);
    try {
      final updatedProfile = _profile!.copyWith(
        fullName: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim(),
        phone: _phoneController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await _profileRepository.updateProfile(updatedProfile);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  Hero(
                    tag: 'profile_avatar',
                    child: AppAvatar(
                      imageUrl: _profile?.avatarUrl,
                      initials: _profile?.fullName ?? 'H',
                      size: 100,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            AppTextField(
              label: 'Full Name',
              hint: 'e.g. Husnain Majid',
              controller: _nameController,
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Username',
              hint: 'e.g. husnain',
              controller: _usernameController,
              prefixIcon: const Icon(Icons.alternate_email_rounded),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Bio',
              hint: 'Tell us about yourself...',
              controller: _bioController,
              prefixIcon: const Icon(Icons.info_outline_rounded),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Phone',
              hint: 'e.g. +92 300 0000000',
              controller: _phoneController,
              prefixIcon: const Icon(Icons.phone_outlined),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 48),
            AppButton(
              text: 'Save Changes',
              type: AppButtonType.gradient,
              isLoading: _isSaving,
              onPressed: _saveProfile,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
