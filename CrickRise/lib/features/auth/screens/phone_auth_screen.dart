import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/cr_atmosphere.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  bool _showOtp = false;
  String _phoneNumber = '';
  Timer? _resendTimer;
  int _resendCountdown = 30;
  bool _canResend = false;

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  void _sendCode(String phone) {
    if (phone.trim().isEmpty) return;
    _phoneNumber = phone.trim();
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
    if (otp.length == 6) context.go('/auth/setup');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      body: CRAtmosphere(
        showPitch: false,
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _showOtp
                ? _OtpView(
                    key: const ValueKey('otp'),
                    phone: _phoneNumber,
                    onVerify: _verifyOtp,
                    canResend: _canResend,
                    countdown: _resendCountdown,
                    onResend: _startResendTimer,
                    onBack: () => setState(() => _showOtp = false),
                  )
                : _PhoneView(
                    key: const ValueKey('phone'),
                    onSend: _sendCode,
                    onBack: () => context.pop(),
                  ),
          ),
        ),
      ),
    );
  }
}

class _PhoneView extends StatefulWidget {
  final ValueChanged<String> onSend;
  final VoidCallback onBack;

  const _PhoneView({super.key, required this.onSend, required this.onBack});

  @override
  State<_PhoneView> createState() => _PhoneViewState();
}

class _PhoneViewState extends State<_PhoneView> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: CR.mist, size: 18),
            onPressed: widget.onBack,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 40),
          Text('YOUR NUMBER', style: CRType.label(color: CR.flood)),
          const SizedBox(height: 8),
          Text('We\'ll text a code.', style: CRType.headline(size: 32)),
          const SizedBox(height: 36),
          CRGlassPanel(
            padding: EdgeInsets.zero,
            radius: 14,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Text('+81', style: CRType.body(weight: FontWeight.w600)),
                ),
                Container(width: 1, height: 24, color: CR.cream.withValues(alpha: 0.08)),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    style: CRType.score(size: 18, color: CR.cream),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      hintText: '090 0000 0000',
                      hintStyle: CRType.caption(color: CR.fog),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _ctrl,
            builder: (_, val, __) {
              final enabled = val.text.isNotEmpty;
              return GestureDetector(
                onTap: enabled ? () => widget.onSend(val.text) : null,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: enabled ? const LinearGradient(colors: CR.floodGradient) : null,
                    color: enabled ? null : CR.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'SEND CODE',
                      style: CRType.headline(
                        size: 20,
                        color: enabled ? CR.inv : CR.fog,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => context.go('/auth/setup'),
              child: Text(
                'Skip for now',
                style: CRType.caption(color: CR.fog),
              ),
            ),
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
    final pinTheme = PinTheme(
      width: 48,
      height: 52,
      textStyle: CRType.score(size: 20, color: CR.cream),
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CR.cream.withValues(alpha: 0.08)),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: CR.mist, size: 18),
            onPressed: onBack,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 40),
          Text('CHECK YOUR PHONE', style: CRType.label(color: CR.flood)),
          const SizedBox(height: 8),
          Text('Enter the code.', style: CRType.headline(size: 32)),
          const SizedBox(height: 8),
          Text('+81 $phone', style: CRType.caption()),
          const SizedBox(height: 40),
          Center(
            child: Pinput(
              length: 6,
              defaultPinTheme: pinTheme,
              focusedPinTheme: pinTheme.copyWith(
                decoration: pinTheme.decoration?.copyWith(
                  border: Border.all(color: CR.flood, width: 2),
                ),
              ),
              onCompleted: onVerify,
              autofocus: true,
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: canResend
                ? GestureDetector(
                    onTap: onResend,
                    child: Text('Resend code', style: CRType.body(color: CR.flood, weight: FontWeight.w600)),
                  )
                : Text('Resend in ${countdown}s', style: CRType.caption()),
          ),
        ],
      ),
    );
  }
}
