import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';

import '../../../core/theme/app_theme.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  bool _showOtp = false;
  final _phoneCtrl = TextEditingController();
  String _phoneNumber = '';
  Timer? _resendTimer;
  int _resendCountdown = 30;
  bool _canResend = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _sendCode() {
    if (_phoneNumber.length < 10) return;
    setState(() => _showOtp = true);
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendCountdown = 30;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _resendCountdown--;
        if (_resendCountdown <= 0) {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  void _verifyOtp(String otp) {
    if (otp.length == 6) {
      // V1 prototype: accept any 6-digit code
      context.go('/auth/setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
              child: child,
            );
          },
          child: _showOtp
              ? _OtpView(
                  key: const ValueKey('otp'),
                  phone: _phoneNumber,
                  onVerify: _verifyOtp,
                  canResend: _canResend,
                  countdown: _resendCountdown,
                  onResend: () {
                    _startResendTimer();
                  },
                  onBack: () => setState(() => _showOtp = false),
                )
              : _PhoneView(
                  key: const ValueKey('phone'),
                  onPhoneChanged: (v) => setState(() => _phoneNumber = v),
                  onSend: _sendCode,
                  onBack: () => context.pop(),
                ),
        ),
      ),
    );
  }
}

class _PhoneView extends StatelessWidget {
  final ValueChanged<String> onPhoneChanged;
  final VoidCallback onSend;
  final VoidCallback onBack;

  const _PhoneView({
    super.key,
    required this.onPhoneChanged,
    required this.onSend,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: CR.text2, size: 18),
            onPressed: onBack,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 32),
          Text(
            'Enter your number',
            style: GoogleFonts.inter(
              color: CR.text1,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 8),
          Text(
            "We'll send a 6-digit code.",
            style: GoogleFonts.inter(color: CR.text2, fontSize: 14),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 40),
          // Phone input
          Container(
            decoration: BoxDecoration(
              color: CR.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Text(
                    '+81 🇯🇵',
                    style: GoogleFonts.inter(
                      color: CR.text1,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(width: 1, height: 24, color: CR.cardHigh),
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.spaceGrotesk(
                      color: CR.text1,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      hintText: '090 0000 0000',
                      hintStyle: TextStyle(color: CR.text3),
                    ),
                    onChanged: onPhoneChanged,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),
          const Spacer(),
          StatefulBuilder(
            builder: (context, setLocal) {
              return ValueListenableBuilder<TextEditingValue>(
                valueListenable: ctrl,
                builder: (_, val, __) {
                  final enabled = val.text.length >= 10;
                  return SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: enabled ? onSend : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: enabled ? CR.green : CR.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'SEND CODE',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 1,
                          color: enabled ? CR.textInv : CR.text3,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _OtpView extends StatelessWidget {
  final String phone;
  final ValueChanged<String> onVerify;
  final bool canResend;
  final int countdown;
  final VoidCallback onResend;
  final VoidCallback onBack;

  const _OtpView({
    super.key,
    required this.phone,
    required this.onVerify,
    required this.canResend,
    required this.countdown,
    required this.onResend,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final defaultTheme = PinTheme(
      width: 52,
      height: 52,
      textStyle: GoogleFonts.spaceGrotesk(
        color: CR.text1,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(10),
      ),
    );

    final focusedTheme = defaultTheme.copyWith(
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CR.green, width: 2),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: CR.text2, size: 18),
            onPressed: onBack,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 32),
          Text(
            'Check your phone',
            style: GoogleFonts.inter(
              color: CR.text1,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 8),
          Text(
            'Sent to +81 ${phone.isEmpty ? "XXXXX XXXXX" : phone}',
            style: GoogleFonts.inter(color: CR.text2, fontSize: 14),
          ),
          const SizedBox(height: 48),
          Center(
            child: Pinput(
              length: 6,
              defaultPinTheme: defaultTheme,
              focusedPinTheme: focusedTheme,
              onCompleted: onVerify,
              autofocus: true,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 32),
          Center(
            child: canResend
                ? GestureDetector(
                    onTap: onResend,
                    child: Text(
                      'Resend code',
                      style: GoogleFonts.inter(
                        color: CR.green,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : Text(
                    'Resend in ${countdown}s',
                    style: GoogleFonts.inter(
                      color: CR.text3,
                      fontSize: 14,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
