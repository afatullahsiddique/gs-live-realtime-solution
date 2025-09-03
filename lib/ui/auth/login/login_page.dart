import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'login_cubit.dart';
import 'login_state.dart';

import '../../../navigation/routes.dart';
import '../../../theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
            child: SafeArea(
              child: BlocConsumer<LoginCubit, LoginState>(
                listener: (context, state) {
                  if (state.error.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.error),
                        backgroundColor: Colors.red.shade400,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                  if (state.isSuccess) {
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   SnackBar(
                    //     content: const Text('Login Successful!'),
                    //     backgroundColor: Colors.green.shade400,
                    //     behavior: SnackBarBehavior.floating,
                    //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    //   ),
                    // );
                    context.go(Routes.home.path);
                  }
                },
                builder: (context, state) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildLogo(),
                        const SizedBox(height: 40),
                        _buildWelcomeText(),
                        const SizedBox(height: 40),
                        _buildTabBar(),
                        const SizedBox(height: 30),
                        Expanded(
                          child: TabBarView(controller: _tabController, children: [_buildPhoneTab(context, state), _buildUserIdTab(context, state)]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: AppColors.logoGradient, boxShadow: AppColors.logoShadow),
      child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.asset('assets/images/logo.png')),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => AppColors.textGradientShader(bounds),
          child: const Text(
            'Welcome to CUTE LIVE',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Connect, Stream, and Have Fun!',
          style: TextStyle(fontSize: 16, color: AppColors.white.withOpacity(0.8), fontWeight: FontWeight.w300),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: AppColors.black.withOpacity(0.3),
        border: Border.all(color: AppColors.inputBorderColor, width: 1),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(borderRadius: BorderRadius.circular(25), gradient: AppColors.tabIndicatorGradient),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.white.withOpacity(0.6),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        tabs: const [
          Tab(text: 'Phone Number'),
          Tab(text: 'User ID'),
        ],
      ),
    );
  }

  Widget _buildPhoneTab(BuildContext context, LoginState state) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildInputField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: '01XXXXXXXXX',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 30),
          _buildLoginButton(
            context,
            'Sign In with Phone',
            state.isLoading && state.method == LoginMethod.phone,
            () => context.read<LoginCubit>().loginWithPhone(_phoneController.text),
          ),
          const SizedBox(height: 30),
          _buildSocialButtons(context, state),
        ],
      ),
    );
  }

  Widget _buildUserIdTab(BuildContext context, LoginState state) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildInputField(controller: _userIdController, label: 'User ID', hint: 'Enter your user ID', icon: Icons.person_rounded),
          const SizedBox(height: 20),
          _buildInputField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            icon: Icons.lock_rounded,
            isPassword: true,
          ),
          const SizedBox(height: 30),
          _buildLoginButton(
            context,
            'Sign In',
            state.isLoading && state.method == LoginMethod.credentials,
            () => context.read<LoginCubit>().loginWithCredentials(_userIdController.text, _passwordController.text),
          ),
          const SizedBox(height: 30),
          _buildSocialButtons(context, state),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppColors.inputBackground,
        border: Border.all(color: AppColors.inputBorderColor, width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: AppColors.pinkLight),
          hintStyle: TextStyle(color: AppColors.white.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: AppColors.pinkLight),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, String text, bool isLoading, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: AppColors.buttonGradient, boxShadow: AppColors.buttonShadow),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLoading ? null : onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    text,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButtons(BuildContext context, LoginState state) {
    return Column(
      children: [
        _buildDivider(),
        const SizedBox(height: 20),
        _buildSocialButton(
          'Continue with Google',
          AppColors.white,
          Colors.black87,
          () => context.read<LoginCubit>().loginWithGoogle(),
          state.isLoading && state.method == LoginMethod.google,
          iconPath: 'assets/icons/ic_google.svg',
        ),
        const SizedBox(height: 16),
        _buildSocialButton(
          'Continue with Facebook',
          const Color(0xFF1877F2),
          AppColors.white,
          () => context.read<LoginCubit>().loginWithFacebook(),
          state.isLoading && state.method == LoginMethod.facebook,
          icon: Icons.facebook_rounded,
        ),
        const SizedBox(height: 40),
        _buildSignUpText(),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, decoration: BoxDecoration(gradient: AppColors.dividerLeft)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(color: AppColors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Container(height: 1, decoration: BoxDecoration(gradient: AppColors.dividerRight)),
        ),
      ],
    );
  }

  Widget _buildSocialButton(
    String text,
    Color backgroundColor,
    Color textColor,
    VoidCallback onPressed,
    bool isLoading, {
    IconData? icon,
    String? iconPath,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isLoading ? backgroundColor.withOpacity(.5) : backgroundColor,
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [BoxShadow(color: backgroundColor.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLoading ? null : onPressed,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon != null ? Icon(icon, color: textColor, size: 28) : SvgPicture.asset(iconPath!, width: 28, height: 28),
                  const SizedBox(width: 12),
                  Text(
                    text,
                    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (isLoading)
                const Center(
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.pink)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account? ", style: TextStyle(color: AppColors.white.withOpacity(0.7), fontSize: 14)),
        GestureDetector(
          onTap: () {},
          child: ShaderMask(
            shaderCallback: (bounds) => AppColors.textGradientShader(bounds),
            child: const Text(
              'Sign Up',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
