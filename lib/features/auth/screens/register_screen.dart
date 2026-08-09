import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _acceptTerms = false;

  String? _nameError;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  void _register() async {
    setState(() {
      _nameError = _nameController.text.isEmpty ? 'Full name is required' : null;
      _usernameError = _usernameController.text.isEmpty ? 'Username is required' : null;
      _emailError = _emailController.text.isEmpty ? 'Email is required' : null;
      if (_emailError == null && !_emailController.text.contains('@')) {
        _emailError = 'Enter a valid email address';
      }
      _passwordError = _passwordController.text.length < 8 ? 'Password must be at least 8 characters' : null;
      _confirmPasswordError = _confirmPasswordController.text != _passwordController.text ? 'Passwords do not match' : null;
    });

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms and Privacy Policy')),
      );
      return;
    }

    if (_nameError == null && _usernameError == null && _emailError == null && _passwordError == null && _confirmPasswordError == null) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() => _isLoading = false);
        context.push('/verification');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create your LinkUp',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  Gap.h8,
                  Text(
                    'Build your space for meaningful conversations.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  Gap.h32,
                  AppTextField(
                    label: 'Full Name',
                    hint: 'John Doe',
                    controller: _nameController,
                    errorText: _nameError,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  Gap.h20,
                  AppTextField(
                    label: 'Username',
                    hint: 'johndoe',
                    controller: _usernameController,
                    errorText: _usernameError,
                    prefixIcon: const Icon(Icons.alternate_email),
                  ),
                  Gap.h20,
                  AppTextField(
                    label: 'Email',
                    hint: 'name@example.com',
                    controller: _emailController,
                    errorText: _emailError,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  Gap.h20,
                  AppTextField(
                    label: 'Password',
                    hint: '••••••••',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    errorText: _passwordError,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  Gap.h20,
                  AppTextField(
                    label: 'Confirm Password',
                    hint: '••••••••',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    errorText: _confirmPasswordError,
                    prefixIcon: const Icon(Icons.lock_reset),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  Gap.h16,
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptTerms,
                        onChanged: (val) => setState(() => _acceptTerms = val ?? false),
                        activeColor: AppColors.primary,
                      ),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'By creating an account, you agree to our ',
                            style: Theme.of(context).textTheme.bodySmall,
                            children: const [
                              TextSpan(
                                text: 'Terms',
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Gap.h32,
                  AppButton(
                    text: 'Create Account',
                    isLoading: _isLoading,
                    onPressed: _register,
                  ),
                  Gap.h24,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account?",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      AppButton(
                        text: 'Log In',
                        type: AppButtonType.text,
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                  Gap.h24,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
