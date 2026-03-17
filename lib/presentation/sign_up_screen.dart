// lib/presentation/screens/sign_up_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:country_picker/country_picker.dart';
import 'package:test_task/auth_cubit.dart';
import '../core/adaptive_size_extension.dart';
import '../core/constants/base_colors.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _appBarOpacityAnimation1;
  late Animation<double> _appBarOpacityAnimation2;
  late Animation<double> _appBarOpacityAnimation3;

  // Phone input
  final TextEditingController _phoneController = TextEditingController();
  Country _selectedCountry = Country.parse('IT');

  // SMS code input
  final TextEditingController _codeController = TextEditingController();

  // Password input
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Auth modes: 'initial', 'sms_sent', 'password_login', 'password_register'
  String _authMode = 'initial';
  String _pendingPhone = '';

  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _appBarOpacityAnimation1 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeInOut),
      ),
    );
    _appBarOpacityAnimation2 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.6, curve: Curves.easeInOut),
      ),
    );
    _appBarOpacityAnimation3 = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String get _fullPhoneNumber {
    final phone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    return '+${_selectedCountry.phoneCode}$phone';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // ✅ Успешная авторизация
          context.go('/profile');
        } else if (state is AuthError) {
          // ❌ Ошибка
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
        // Можно добавить обработку других состояний если нужно
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  // Background image
                  Image.asset(
                    'assets/file/river.jpg',
                    height: context.adaptiveSize(300),
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  // Content card
                  Padding(
                    padding: EdgeInsets.only(top: context.adaptiveSize(250)),
                    child: Container(
                      decoration: BoxDecoration(
                        color: BaseColors.background,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(context.adaptiveSize(32)),
                          topRight: Radius.circular(context.adaptiveSize(32)),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(context.adaptiveSize(25)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Back button
                            FadeTransition(
                              opacity: _appBarOpacityAnimation1,
                              child: GestureDetector(
                                onTap: () {
                                  if (_authMode != 'initial') {
                                    setState(() {
                                      _authMode = 'initial';
                                      _codeController.clear();
                                      _passwordController.clear();
                                    });
                                  } else if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go("/home");
                                  }
                                },
                                child: Icon(
                                  Icons.arrow_back,
                                  size: context.adaptiveSize(24),
                                  color: const Color.fromARGB(
                                    255,
                                    109,
                                    109,
                                    109,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: context.adaptiveSize(17)),

                            // Title
                            FadeTransition(
                              opacity: _appBarOpacityAnimation1,
                              child: Text(
                                _getTitle(),
                                style: context.adaptiveTextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: const Color.fromARGB(
                                    255,
                                    109,
                                    109,
                                    109,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: context.adaptiveSize(8)),

                            // Subtitle
                            if (_authMode != 'initial')
                              FadeTransition(
                                opacity: _appBarOpacityAnimation1,
                                child: Text(
                                  _getSubtitle(),
                                  style: context.adaptiveTextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),

                            SizedBox(height: context.adaptiveSize(24)),

                            // Content based on mode
                            _buildContent(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (_authMode) {
      case 'sms_sent':
        return 'Enter Code';
      case 'password_login':
        return 'Log In';
      case 'password_register':
        return 'Create Account';
      default:
        return 'Sign Up';
    }
  }

  String _getSubtitle() {
    switch (_authMode) {
      case 'sms_sent':
        return 'We sent a code to $_pendingPhone';
      case 'password_login':
        return 'Enter your phone and password';
      case 'password_register':
        return 'Create your account with phone and password';
      default:
        return '';
    }
  }

  Widget _buildContent(BuildContext context) {
    switch (_authMode) {
      case 'sms_sent':
        return _buildSmsCodeInput(context);
      case 'password_login':
        return _buildPasswordLogin(context);
      case 'password_register':
        return _buildPasswordRegister(context);
      default:
        return _buildInitialContent(context);
    }
  }

  // =============================================
  // INITIAL CONTENT (Social + Phone)
  // =============================================

  Widget _buildInitialContent(BuildContext context) {
    return Column(
      children: [
        // Social buttons
        FadeTransition(
          opacity: _appBarOpacityAnimation2,
          child: Column(
            children: [
              // Google
              _buildSocialButton(
                context,
                icon: 'assets/file/google.png',
                label: 'Continue with Google',
                onTap: () => context.read<AuthCubit>().signInWithGoogle(),
              ),

              SizedBox(height: context.adaptiveSize(12)),

              // Apple (только iOS)
              if (Platform.isIOS)
                _buildSocialButton(
                  context,
                  icon: 'assets/file/apple.png',
                  label: 'Continue with Apple',
                  onTap: () => context.read<AuthCubit>().signInWithApple(),
                  isApple: true,
                ),

              if (Platform.isIOS) SizedBox(height: context.adaptiveSize(12)),
            ],
          ),
        ),

        // Divider
        FadeTransition(
          opacity: _appBarOpacityAnimation2,
          child: _buildDivider(context, 'or continue with phone'),
        ),

        SizedBox(height: context.adaptiveSize(20)),

        // Phone input
        FadeTransition(
          opacity: _appBarOpacityAnimation3,
          child: _buildPhoneInput(context),
        ),

        SizedBox(height: context.adaptiveSize(20)),

        // Send SMS button
        FadeTransition(
          opacity: _appBarOpacityAnimation3,
          child: _buildPrimaryButton(
            context,
            label: 'Send SMS Code',
            onTap: _sendSmsCode,
          ),
        ),

        SizedBox(height: context.adaptiveSize(16)),

        // Alternative: Password login
        FadeTransition(
          opacity: _appBarOpacityAnimation3,
          child: TextButton(
            onPressed: () => setState(() => _authMode = 'password_login'),
            child: Text(
              'Use password instead',
              style: context.adaptiveTextStyle(
                fontSize: 14,
                color: BaseColors.accent,
              ),
            ),
          ),
        ),

        // Loading
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return Padding(
                padding: EdgeInsets.only(top: context.adaptiveSize(20)),
                child: const CircularProgressIndicator(),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  // =============================================
  // SMS CODE INPUT
  // =============================================

  Widget _buildSmsCodeInput(BuildContext context) {
    return Column(
      children: [
        // Code input
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.adaptiveSize(16)),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: context.adaptiveTextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: '000000',
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(context.adaptiveSize(20)),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),

        SizedBox(height: context.adaptiveSize(24)),

        // Verify button
        _buildPrimaryButton(
          context,
          label: 'Verify Code',
          onTap: _verifySmsCode,
        ),

        SizedBox(height: context.adaptiveSize(16)),

        // Resend code
        TextButton(
          onPressed: () {
            context.read<AuthCubit>().signInWithPhone(_pendingPhone);
          },
          child: Text(
            'Resend code',
            style: context.adaptiveTextStyle(
              fontSize: 14,
              color: BaseColors.accent,
            ),
          ),
        ),

        // Loading
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return Padding(
                padding: EdgeInsets.only(top: context.adaptiveSize(20)),
                child: const CircularProgressIndicator(),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  // =============================================
  // PASSWORD LOGIN
  // =============================================

  Widget _buildPasswordLogin(BuildContext context) {
    return Column(
      children: [
        // Phone input
        _buildPhoneInput(context),

        SizedBox(height: context.adaptiveSize(16)),

        // Password input
        _buildPasswordInput(context),

        SizedBox(height: context.adaptiveSize(24)),

        // Login button
        _buildPrimaryButton(
          context,
          label: 'Log In',
          onTap: _loginWithPassword,
        ),

        SizedBox(height: context.adaptiveSize(16)),

        // Create account link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account? ",
              style: context.adaptiveTextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _authMode = 'password_register'),
              child: Text(
                'Sign Up',
                style: context.adaptiveTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: BaseColors.accent,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: context.adaptiveSize(16)),

        // Back to SMS
        TextButton(
          onPressed: () => setState(() => _authMode = 'initial'),
          child: Text(
            'Use SMS code instead',
            style: context.adaptiveTextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),

        // Loading
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return Padding(
                padding: EdgeInsets.only(top: context.adaptiveSize(20)),
                child: const CircularProgressIndicator(),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  // =============================================
  // PASSWORD REGISTER
  // =============================================

  Widget _buildPasswordRegister(BuildContext context) {
    return Column(
      children: [
        // Name input
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.adaptiveSize(16)),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Your name',
              prefixIcon: const Icon(Icons.person_outline),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(context.adaptiveSize(16)),
            ),
          ),
        ),

        SizedBox(height: context.adaptiveSize(16)),

        // Email input
        _buildEmailInput(context),

        SizedBox(height: context.adaptiveSize(16)),

        // Phone input
        _buildPhoneInput(context),

        SizedBox(height: context.adaptiveSize(16)),

        // Password input
        _buildPasswordInput(context),

        SizedBox(height: context.adaptiveSize(24)),

        // Register button
        _buildPrimaryButton(
          context,
          label: 'Create Account',
          onTap: _registerWithPassword,
        ),

        SizedBox(height: context.adaptiveSize(16)),

        // Login link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account? ',
              style: context.adaptiveTextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _authMode = 'password_login'),
              child: Text(
                'Log In',
                style: context.adaptiveTextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: BaseColors.accent,
                ),
              ),
            ),
          ],
        ),

        // Loading
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return Padding(
                padding: EdgeInsets.only(top: context.adaptiveSize(20)),
                child: const CircularProgressIndicator(),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  // =============================================
  // COMMON WIDGETS
  // =============================================

  Widget _buildEmailInput(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.adaptiveSize(16)),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Email icon prefix
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: context.adaptiveSize(16),
              vertical: context.adaptiveSize(16),
            ),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(context.adaptiveSize(16)),
                bottomLeft: Radius.circular(context.adaptiveSize(16)),
              ),
            ),
            child: Icon(
              Icons.email_outlined,
              size: context.adaptiveSize(24),
              color: Colors.grey[600],
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: context.adaptiveSize(50),
            color: Colors.grey[300],
          ),

          // Email input field
          Expanded(
            child: TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: 'Email address',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.adaptiveSize(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInput(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.adaptiveSize(16)),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Country code
          GestureDetector(
            onTap: _showCountryPicker,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: context.adaptiveSize(16),
                vertical: context.adaptiveSize(16),
              ),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(context.adaptiveSize(16)),
                  bottomLeft: Radius.circular(context.adaptiveSize(16)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedCountry.flagEmoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  SizedBox(width: context.adaptiveSize(8)),
                  Text(
                    '+${_selectedCountry.phoneCode}',
                    style: context.adaptiveTextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: context.adaptiveSize(20),
                  ),
                ],
              ),
            ),
          ),

          // Divider
          Container(
            width: 1,
            height: context.adaptiveSize(50),
            color: Colors.grey[300],
          ),

          // Phone number
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Phone number',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: context.adaptiveSize(16),
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _PhoneInputFormatter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordInput(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(context.adaptiveSize(16)),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        decoration: InputDecoration(
          hintText: 'Password',
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: () {
              setState(() => _isPasswordVisible = !_isPasswordVisible);
            },
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(context.adaptiveSize(16)),
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    BuildContext context, {
    required String icon,
    required String label,
    required VoidCallback onTap,
    bool isApple = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: context.adaptiveSize(56),
        decoration: BoxDecoration(
          color: isApple ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(context.adaptiveSize(16)),
          border: Border.all(color: isApple ? Colors.black : Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              icon,
              width: context.adaptiveSize(24),
              height: context.adaptiveSize(24),
              color: isApple ? Colors.white : null,
            ),
            SizedBox(width: context.adaptiveSize(12)),
            Text(
              label,
              style: context.adaptiveTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isApple ? Colors.white : BaseColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: context.adaptiveSize(56),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [BaseColors.accent, Color(0xFF5B86E5)],
          ),
          borderRadius: BorderRadius.circular(context.adaptiveSize(16)),
        ),
        child: Center(
          child: Text(
            label,
            style: context.adaptiveTextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: context.adaptiveSize(16)),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300])),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.adaptiveSize(16)),
            child: Text(
              text,
              style: context.adaptiveTextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300])),
        ],
      ),
    );
  }

  // =============================================
  // ACTIONS
  // =============================================

  void _showCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        flagSize: 25,
        backgroundColor: Colors.white,
        bottomSheetHeight: 500,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        inputDecoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Enter country name',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
      onSelect: (Country country) {
        setState(() => _selectedCountry = country);
      },
    );
  }

  void _sendSmsCode() {
    final phone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ Вызываем метод репозитория через Cubit
    context.read<AuthCubit>().signInWithPhone(_fullPhoneNumber);

    // Переключаем режим на ввод кода
    setState(() {
      _authMode = 'sms_sent';
      _pendingPhone = _fullPhoneNumber;
    });
  }

  void _verifySmsCode() {
    final code = _codeController.text;
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter 6-digit code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ Верифицируем код через Cubit
    context.read<AuthCubit>().verifyPhoneCode(_pendingPhone, code);
  }

  void _loginWithPassword() {
    final phone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    final password = _passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<AuthCubit>().loginWithPassword(
      phone: _fullPhoneNumber,
      password: password,
    );
  }

  void _registerWithPassword() {
    final name = _nameController.text;
    final email = _emailController.text;
    final phone = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    final password = _passwordController.text;

    if (name.isEmpty || phone.isEmpty || password.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Валидация email
    if (_validateEmail(email) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_validateEmail(email)!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ Теперь работает!
    context.read<AuthCubit>().register(
      name: name,
      email: email,
      phone: _fullPhoneNumber,
      password: password,
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }

    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }
}

// =============================================
// PHONE INPUT FORMATTER
// =============================================

class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.isEmpty) return newValue;

    // Ограничиваем до 10 цифр
    if (text.length > 10) {
      return oldValue;
    }

    // Форматируем: (000) 000-00-00
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i == 0) buffer.write('(');
      if (i == 3) buffer.write(') ');
      if (i == 6) buffer.write('-');
      if (i == 8) buffer.write('-');
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
