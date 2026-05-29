import 'package:flutter/material.dart';
import '../../utils/theme_context.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../utils/custom_textfield.dart';
import '../../providers/auth_provider.dart';
import '../home/home_page.dart';
import 'register_page.dart';
import '../../widgets/brand_header.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                          SizedBox(height: 20),

                          // Login Card
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
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const BrandHeader(logoWidth: 230),
                                      const SizedBox(height: 20),

                                      // Welcome Text
                                      Text(
                                        'Welcome Back',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: context.colors.textPrimary,
                                        ),
                                      ),
                                      SizedBox(height: 6),

                                      // Subtitle
                                      Text(
                                        'Elevate your learning with AI intelligence',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: context.colors.textSecondary,
                                        ),
                                      ),
                                      SizedBox(height: 32),

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
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                          ).hasMatch(value)) {
                                            return 'Please enter a valid email';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: 20),

                                      // Password Textfield
                                      CustomTextField(
                                        labelText: 'Password',
                                        hintText: '••••••••',
                                        controller: _passwordController,
                                        prefixIcon: Icons.lock_outline,
                                        obscureText: _obscurePassword,
                                        headerRightWidget: GestureDetector(
                                          onTap: () {
                                            // Handle forgot password action
                                          },
                                          child: Text(
                                            'Forgot?',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors
                                                  .primaryGradientStart,
                                            ),
                                          ),
                                        ),
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
                                            color: context.colors.textLight,
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
                                      SizedBox(height: 20),

                                      // Remember Me Checkbox Row
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: Checkbox(
                                              value: _rememberMe,
                                              onChanged: (value) {
                                                setState(() {
                                                  _rememberMe = value ?? false;
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
                                          SizedBox(width: 10),
                                          Text(
                                            'Remember for 30 days',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  context.colors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 32),

                                      // Gradient Sign In Button
                                      Consumer<AuthProvider>(
                                        builder: (context, authProvider, child) {
                                          return Container(
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
                                                            await authProvider.signIn(
                                                              email:
                                                                  _emailController
                                                                      .text,
                                                              password:
                                                                  _passwordController
                                                                      .text,
                                                            );

                                                        if (success) {
                                                          scaffoldMessenger
                                                              .showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                    'Login berhasil!',
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
                                                                    'Login gagal.',
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
                                                      'Sign In',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: Colors.white,
                                                        letterSpacing: 0.2,
                                                      ),
                                                    ),
                                            ),
                                          );
                                        },
                                      ),
                                      SizedBox(height: 24),

                                      // Don't have an account? Sign Up
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Don't have an account? ",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  context.colors.textSecondary,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const RegisterPage(),
                                                ),
                                              );
                                            },
                                            child: Text(
                                              'Sign Up',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors
                                                    .primaryGradientStart,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 24),

                          // Bottom Badges Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Badge 1: Secure AI Protocol
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 16,
                                    color: context.colors.textLight,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Secure AI Protocol',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: context.colors.textLight,
                                    ),
                                  ),
                                ],
                              ),

                              // Separation Dot
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                ),
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: context.colors.textLight,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),

                              // Badge 2: Academic Integrity
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_outlined,
                                    size: 16,
                                    color: context.colors.textLight,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Academic Integrity',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: context.colors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
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
