import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/colors.dart';
import '../../utils/custom_loading_indicator.dart';
import '../../utils/utils.dart';


class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  bool _isLoading = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 20000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));


    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
    _rotateController.repeat();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    return regex.hasMatch(email);
  }

  Future<void> _checkEmail(BuildContext context) async {
    String email = _emailController.text.trim();

    if (!_isValidEmail(email)) {
      showToast('Invalid email format', ZasicoColors.warning);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final userRef = firestore.collection('users');
      final querySnapshot = await userRef.where('email', isEqualTo: email).get();

      if (querySnapshot.docs.isNotEmpty) {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        showToast('Password reset email sent', ZasicoColors.success);
        Navigator.pop(context);
      } else {
        showToast('Email not found', ZasicoColors.error);
      }
    } catch (e) {
      showToast('Error: ${e.toString()}', ZasicoColors.error);
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
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0F0F), // Very dark black
              Color(0xFF1A0A0A), // Dark with red tint
              Color(0xFF2D1B1B), // Medium dark with red
              Color(0xFF1A0A0A), // Back to dark red
              Color(0xFF0F0F0F), // Very dark black
            ],
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
          ),
        ),
        child: Stack(
          children: [

            // Animated geometric shapes background
            ...List.generate(8, (index) => _buildFloatingShape(index)),


            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: ListView(
                      // crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAppBar(context),
                        const SizedBox(height: 20),
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildEmailForm(),
                        const SizedBox(height: 30),
                        _buildResetButton(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              padding: EdgeInsets.only(top: 70,left: 15),
              icon: Icon(Icons.arrow_back, color: ZasicoColors.primaryText),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),

      ),
    );
  }

  Widget _buildFloatingShape(int index) {
    return AnimatedBuilder(
      animation: _rotateAnimation,
      builder: (context, child) {
        final double offsetX = 30.0 + (index * 60.0) + (40 * _rotateAnimation.value);
        final double offsetY = 80.0 + (index * 100.0) + (50 * _rotateAnimation.value);

        return Positioned(
          left: offsetX,
          top: offsetY,
          child: Transform.rotate(
            angle: _rotateAnimation.value * 2 * 3.14159,
            child: Container(
              width: index.isEven ? 8 : 6,
              height: index.isEven ? 8 : 6,
              decoration: BoxDecoration(
                color: ZasicoColors.primaryRed.withOpacity(0.1 + (index * 0.05)),
                shape: index % 3 == 0 ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: index % 3 != 0 ? BorderRadius.circular(2) : null,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Image.asset(
            'assets/images/logo.png',
            width: 150,
            height: 150,
          ),
          // const SizedBox(width: 48), // For alignment
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Forgot Password',
          style: GoogleFonts.orbitron(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: ZasicoColors.primaryText,
            letterSpacing: 2.0,
            shadows: [
              Shadow(
                color: ZasicoColors.primaryRed.withOpacity(0.6),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your email to receive a password reset link',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            color: ZasicoColors.secondaryText,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A1A).withOpacity(0.9),
            Color(0xFF2D1B1B).withOpacity(0.8),
            Color(0xFF1A1A1A).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ZasicoColors.primaryRed.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: ZasicoColors.primaryRed.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTextField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            hintText: 'Email Address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            onSubmitted: (_) => _checkEmail(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    void Function(String)? onSubmitted,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ZasicoColors.primaryBackground.withOpacity(0.8),
            ZasicoColors.secondaryBackground.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: focusNode.hasFocus
              ? ZasicoColors.primaryRed
              : ZasicoColors.redOpacity30,
          width: 1.5,
        ),
        boxShadow: focusNode.hasFocus
            ? [
          BoxShadow(
            color: ZasicoColors.primaryRed.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        onSubmitted: onSubmitted,
        style: GoogleFonts.orbitron(
          color: ZasicoColors.primaryText,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.orbitron(
            color: ZasicoColors.hintText,
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            icon,
            color: ZasicoColors.whiteOpacity70,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildResetButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: _isLoading
          ? Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              ZasicoColors.primaryRed,
              ZasicoColors.darkRed,
              ZasicoColors.crimsonRed,
            ],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: ZasicoColors.primaryRed.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(child: CustomLoadingIndicator()),
      )
          : ElevatedButton(
        onPressed: () => _checkEmail(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ZasicoColors.primaryRed,
                ZasicoColors.darkRed,
                ZasicoColors.crimsonRed,
              ],
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: ZasicoColors.primaryRed.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Container(
            alignment: Alignment.center,
            child: Text(
              'RESET PASSWORD',
              style: GoogleFonts.orbitron(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ZasicoColors.primaryText,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}