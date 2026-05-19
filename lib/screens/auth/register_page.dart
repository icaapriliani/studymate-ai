import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../utils/custom_textfield.dart';
import '../../providers/auth_provider.dart';
import '../home/home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide > 600;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.bgGradientStart,
              AppColors.bgGradientEnd,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 48.0 : 20.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(height: 10),

                          // Register Card
                          Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 420),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(36),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(10),
                                    blurRadius: 40.0,
                                    offset: const Offset(0, 20.0),
                                  ),
                                  BoxShadow(
                                    color: AppColors.primaryGradientStart
                                        .withAlpha(5),
                                    blurRadius: 20.0,
                                    offset: const Offset(0, 10.0),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding:
                                    EdgeInsets.all(isTablet ? 40.0 : 28.0),
                                child: Form(
                                  key: _formKey,
                                  child: Consumer<AuthProvider>(
                                    builder: (context, authProvider, child) {
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Graduation Cap Badge
                                          Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  AppColors.primaryGradientStart,
                                                  AppColors.primaryGradientEnd,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors
                                                      .primaryGradientStart
                                                      .withAlpha(51),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.school,
                                              color: Colors.white,
                                              size: 26,
                                            ),
                                          ),
                                          const SizedBox(height: 20),

                                          // Brand Text: StudyMate AI
                                          ShaderMask(
                                            shaderCallback: (bounds) =>
                                                const LinearGradient(
                                              colors: [
                                                AppColors.primaryGradientStart,
                                                AppColors.primaryGradientEnd,
                                              ],
                                            ).createShader(bounds),
                                            child: const Text(
                                              'StudyMate AI',
                                              style: TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12),

                                          // Subtitle
                                          const Text(
                                            'Create Account',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),

                                          const Text(
                                            'Mulai petualangan belajarmu sekarang!',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 28),

                                          // Name Textfield
                                          CustomTextField(
                                            labelText: 'Nama Lengkap',
                                            hintText: 'Masukkan nama lengkap Anda',
                                            controller: _nameController,
                                            prefixIcon: Icons.person_outline,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.trim().isEmpty) {
                                                return 'Please enter your full name';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 18),

                                          // Email Textfield
                                          CustomTextField(
                                            labelText: 'Email',
                                            hintText: 'Masukkan email Anda',
                                            controller: _emailController,
                                            prefixIcon: Icons.mail_outline,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.trim().isEmpty) {
                                                return 'Please enter your email';
                                              }
                                              if (!RegExp(
                                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                                  .hasMatch(value)) {
                                                return 'Please enter a valid email';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 18),

                                          // Password Textfield
                                          CustomTextField(
                                            labelText: 'Password',
                                            hintText: '••••••••',
                                            controller: _passwordController,
                                            prefixIcon: Icons.lock_outline,
                                            obscureText: _obscurePassword,
                                            suffixIcon: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _obscurePassword =
                                                      !_obscurePassword;
                                                });
                                              },
                                              child: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                color: AppColors.textLight,
                                                size: 20,
                                              ),
                                            ),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please enter your password';
                                              }
                                              if (value.length < 6) {
                                                return 'Password must be at least 6 characters';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 18),

                                          // Confirm Password Textfield
                                          CustomTextField(
                                            labelText: 'Konfirmasi Password',
                                            hintText: '••••••••',
                                            controller: _confirmPasswordController,
                                            prefixIcon: Icons.lock_outline,
                                            obscureText: _obscureConfirmPassword,
                                            suffixIcon: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _obscureConfirmPassword =
                                                      !_obscureConfirmPassword;
                                                });
                                              },
                                              child: Icon(
                                                _obscureConfirmPassword
                                                    ? Icons.visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                color: AppColors.textLight,
                                                size: 20,
                                              ),
                                            ),
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please confirm your password';
                                              }
                                              if (value != _passwordController.text) {
                                                return 'Passwords do not match';
                                              }
                                              return null;
                                            },
                                          ),
                                          const SizedBox(height: 18),

                                          // Agree to Terms Checkbox
                                          Row(
                                            children: [
                                              SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: Checkbox(
                                                  value: _agreeToTerms,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _agreeToTerms = value ?? false;
                                                    });
                                                  },
                                                  activeColor: AppColors
                                                      .primaryGradientStart,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(6),
                                                  ),
                                                  side: BorderSide(
                                                    color: Colors.grey.shade300,
                                                    width: 1.5,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              const Expanded(
                                                child: Text(
                                                  'Saya setuju dengan Ketentuan & Kebijakan Privasi',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 24),

                                          // Gradient Sign Up Button
                                          Container(
                                            width: double.infinity,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  AppColors.primaryGradientStart,
                                                  AppColors.primaryGradientEnd,
                                                ],
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors
                                                      .primaryGradientStart
                                                      .withAlpha(76),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: ElevatedButton(
                                              onPressed: authProvider.isLoading
                                                  ? null
                                                  : () async {
                                                      if (!_agreeToTerms) {
                                                        ScaffoldMessenger.of(context)
                                                            .showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                                'Anda harus menyetujui Ketentuan & Kebijakan Privasi.'),
                                                            backgroundColor:
                                                                Colors.orangeAccent,
                                                          ),
                                                        );
                                                        return;
                                                      }

                                                      if (_formKey.currentState!
                                                          .validate()) {
                                                        final success = await authProvider.signUp(
                                                          email: _emailController.text,
                                                          password: _passwordController.text,
                                                          displayName: _nameController.text,
                                                        );

                                                        if (!mounted) return;

                                                        if (success) {
                                                          ScaffoldMessenger.of(context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                  'Registrasi berhasil!'),
                                                              backgroundColor:
                                                                  Colors.green,
                                                            ),
                                                          );

                                                          Navigator.of(context)
                                                              .pushReplacement(
                                                            PageRouteBuilder(
                                                              pageBuilder: (context,
                                                                      animation,
                                                                      secondaryAnimation) =>
                                                                  const HomePage(),
                                                              transitionsBuilder:
                                                                  (context,
                                                                      animation,
                                                                      secondaryAnimation,
                                                                      child) {
                                                                return FadeTransition(
                                                                  opacity:
                                                                      animation,
                                                                  child: child,
                                                                );
                                                              },
                                                              transitionDuration:
                                                                  const Duration(
                                                                      milliseconds:
                                                                          500),
                                                            ),
                                                          );
                                                        } else {
                                                          ScaffoldMessenger.of(context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                  authProvider
                                                                          .errorMessage ??
                                                                      'Registrasi gagal.'),
                                                              backgroundColor:
                                                                  Colors.redAccent,
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                              ),
                                              child: authProvider.isLoading
                                                  ? const SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child:
                                                          CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2.5,
                                                      ),
                                                    )
                                                  : const Text(
                                                      'Sign Up',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w800,
                                                        color: Colors.white,
                                                        letterSpacing: 0.2,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Already have an account? Sign In
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Already have an account? ",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryGradientStart,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
