import 'package:flutter/material.dart';
import '../../utils/theme_context.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../utils/custom_textfield.dart';
import '../../providers/auth_provider.dart';
import '../home/home_page.dart';
import '../../widgets/brand_header.dart';

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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.colors.bgGradientStart,
              context.colors.bgGradientEnd,
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
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 48.0 : 20.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(height: 10),

                          // Register Card
                          Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 420),
                              decoration: BoxDecoration(
                                color: context.colors.cardBg,
                                borderRadius: BorderRadius.circular(36),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(10),
                                    blurRadius: 40.0,
                                    offset: const Offset(0, 20.0),
                                  ),
                                  BoxShadow(
                                    color: context.colors.primaryGradientStart
                                        .withAlpha(5),
                                    blurRadius: 20.0,
                                    offset: const Offset(0, 10.0),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(isTablet ? 40.0 : 28.0),
                                child: Form(
                                  key: _formKey,
                                  child: Consumer<AuthProvider>(
                                    builder: (context, authProvider, child) {
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const BrandHeader(logoWidth: 230),
                                          const SizedBox(height: 20),

                                          // Subtitle
                                          Text(
                                            'Create Account',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: context.colors.textPrimary,
                                            ),
                                          ),
                                          SizedBox(height: 6),

                                          Text(
                                            'Mulai petualangan belajarmu sekarang!',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  context.colors.textSecondary,
                                            ),
                                          ),
                                          SizedBox(height: 28),

                                          // Name Textfield
                                          CustomTextField(
                                            labelText: 'Nama Lengkap',
                                            hintText:
                                                'Masukkan nama lengkap Anda',
                                            controller: _nameController,
                                            prefixIcon: Icons.person_outline,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.trim().isEmpty) {
                                                return 'Silakan masukkan nama lengkap Anda';
                                              }
                                              return null;
                                            },
                                          ),
                                          SizedBox(height: 18),

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
                                                return 'Silakan masukkan alamat email Anda';
                                              }
                                              if (!RegExp(
                                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                              ).hasMatch(value)) {
                                                return 'Silakan masukkan format alamat email yang valid';
                                              }
                                              return null;
                                            },
                                          ),
                                          SizedBox(height: 18),

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
                                                    ? Icons
                                                          .visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                color: context.colors.textLight,
                                                size: 20,
                                              ),
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Silakan masukkan kata sandi Anda';
                                              }
                                              if (value.length < 6) {
                                                return 'Kata sandi harus terdiri dari minimal 6 karakter';
                                              }
                                              return null;
                                            },
                                          ),
                                          SizedBox(height: 18),

                                          // Confirm Password Textfield
                                          CustomTextField(
                                            labelText: 'Konfirmasi Password',
                                            hintText: '••••••••',
                                            controller:
                                                _confirmPasswordController,
                                            prefixIcon: Icons.lock_outline,
                                            obscureText:
                                                _obscureConfirmPassword,
                                            suffixIcon: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _obscureConfirmPassword =
                                                      !_obscureConfirmPassword;
                                                });
                                              },
                                              child: Icon(
                                                _obscureConfirmPassword
                                                    ? Icons
                                                          .visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                color: context.colors.textLight,
                                                size: 20,
                                              ),
                                            ),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Silakan konfirmasi kata sandi Anda';
                                              }
                                              if (value !=
                                                  _passwordController.text) {
                                                return 'Konfirmasi kata sandi tidak cocok dengan kata sandi di atas';
                                              }
                                              return null;
                                            },
                                          ),
                                          SizedBox(height: 18),

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
                                                      _agreeToTerms =
                                                          value ?? false;
                                                    });
                                                  },
                                                  activeColor: AppColors
                                                      .primaryGradientStart,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  side: BorderSide(
                                                    color: Colors.grey.shade300,
                                                    width: 1.5,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  'Saya setuju dengan Ketentuan & Kebijakan Privasi',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: context
                                                        .colors
                                                        .textSecondary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 24),

                                          // Gradient Sign Up Button
                                          Container(
                                            width: double.infinity,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  context
                                                      .colors
                                                      .primaryGradientStart,
                                                  context
                                                      .colors
                                                      .primaryGradientEnd,
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
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Anda harus menyetujui Ketentuan & Kebijakan Privasi.',
                                                            ),
                                                            backgroundColor:
                                                                Colors
                                                                    .orangeAccent,
                                                          ),
                                                        );
                                                        return;
                                                      }

                                                      if (_formKey.currentState!
                                                          .validate()) {
                                                        final navigator =
                                                            Navigator.of(
                                                              context,
                                                            );
                                                        final scaffoldMessenger =
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            );

                                                        final success =
                                                            await authProvider.signUp(
                                                              email:
                                                                  _emailController
                                                                      .text,
                                                              password:
                                                                  _passwordController
                                                                      .text,
                                                              displayName:
                                                                  _nameController
                                                                      .text,
                                                            );

                                                        if (success) {
                                                          scaffoldMessenger
                                                              .showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                    'Registrasi berhasil!',
                                                                  ),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .green,
                                                                ),
                                                              );

                                                          navigator.pushReplacement(
                                                            PageRouteBuilder(
                                                              pageBuilder:
                                                                  (
                                                                    context,
                                                                    animation,
                                                                    secondaryAnimation,
                                                                  ) =>
                                                                      const HomePage(),
                                                              transitionsBuilder:
                                                                  (
                                                                    context,
                                                                    animation,
                                                                    secondaryAnimation,
                                                                    child,
                                                                  ) {
                                                                    return FadeTransition(
                                                                      opacity:
                                                                          animation,
                                                                      child:
                                                                          child,
                                                                    );
                                                                  },
                                                              transitionDuration:
                                                                  const Duration(
                                                                    milliseconds:
                                                                        500,
                                                                  ),
                                                            ),
                                                          );
                                                        } else {
                                                          scaffoldMessenger.showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                authProvider
                                                                        .errorMessage ??
                                                                    'Registrasi gagal.',
                                                              ),
                                                              backgroundColor:
                                                                  Colors
                                                                      .redAccent,
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                ),
                                              ),
                                              child: authProvider.isLoading
                                                  ? SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child:
                                                          CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2.5,
                                                          ),
                                                    )
                                                  : Text(
                                                      'Sign Up',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w800,
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

                          SizedBox(height: 24),

                          // Already have an account? Sign In
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.textSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: context.colors.primaryGradientStart,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
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
