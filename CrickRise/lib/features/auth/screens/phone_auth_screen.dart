import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/cr_matchday.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  bool _otp = false;
  String _phone = '';
  Timer? _timer;
  int _count = 30;
  bool _canResend = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _send(String phone) {
    if (phone.trim().isEmpty) return;
    _phone = phone.trim();
    setState(() => _otp = true);
    _count = 30;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _count--;
        if (_count <= 0) {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CR.bg,
      body: CRProgrammeBg(
        child: SafeArea(
          child: _otp
              ? _OtpView(
                  phone: _phone,
                  count: _count,
                  canResend: _canResend,
                  onResend: () => _send(_phone),
                  onBack: () => setState(() => _otp = false),
                  onDone: (c) {
                    if (c.length == 6) context.go('/auth/setup');
                  },
                )
              : _PhoneView(
                  onSend: _send,
                  onBack: () => context.pop(),
                  onSkip: () => context.go('/auth/setup'),
                ),
        ),
      ),
    );
  }
}

class _PhoneView extends StatefulWidget {
  final ValueChanged<String> onSend;
  final VoidCallback onBack;
  final VoidCallback onSkip;
  const _PhoneView({required this.onSend, required this.onBack, required this.onSkip});

  @override
  State<_PhoneView> createState() => _PhoneViewState();
}

class _PhoneViewState extends State<_PhoneView> {
  final _c = TextEditingController();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back, color: CR.ink)),
          const SizedBox(height: 24),
          Text('Your number', style: CRType.display(size: 32)),
          const SizedBox(height: 8),
          Text('We\'ll send a 6-digit code.', style: CRType.caption()),
          const SizedBox(height: 32),
          CRPaper(
            padding: EdgeInsets.zero,
            child: TextField(
              controller: _c,
              keyboardType: TextInputType.phone,
              autofocus: true,
              style: CRType.score(size: 18, color: CR.chalk),
              decoration: InputDecoration(
                prefixText: '+81  ',
                prefixStyle: CRType.body(color: CR.ink),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                hintText: '090 0000 0000',
                hintStyle: CRType.caption(color: CR.fog),
              ),
            ),
          ),
          const Spacer(),
          ValueListenableBuilder(
            valueListenable: _c,
            builder: (_, v, __) => CRProgrammeButton(
              label: 'Send code',
              onTap: v.text.isNotEmpty ? () => widget.onSend(v.text) : null,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(onPressed: widget.onSkip, child: Text('Skip for now', style: CRType.caption())),
          ),
        ],
      ),
    );
  }
}

class _OtpView extends StatelessWidget {
  final String phone;
  final int count;
  final bool canResend;
  final VoidCallback onResend;
  final VoidCallback onBack;
  final ValueChanged<String> onDone;

  const _OtpView({
    required this.phone,
    required this.count,
    required this.canResend,
    required this.onResend,
    required this.onBack,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = PinTheme(
      width: 46,
      height: 50,
      textStyle: CRType.score(size: 18, color: CR.chalk),
      decoration: BoxDecoration(
        color: CR.card,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: CR.chalk.withValues(alpha: 0.1)),
      ),
    );
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back, color: CR.ink)),
          const SizedBox(height: 24),
          Text('Enter code', style: CRType.display(size: 32)),
          Text('Sent to +81 $phone', style: CRType.caption()),
          const SizedBox(height: 36),
          Pinput(
            length: 6,
            defaultPinTheme: theme,
            focusedPinTheme: theme.copyWith(
              decoration: theme.decoration?.copyWith(
                border: Border.all(color: CR.brass, width: 1.5),
              ),
            ),
            onCompleted: onDone,
            autofocus: true,
          ),
          const SizedBox(height: 24),
          Center(
            child: canResend
                ? GestureDetector(onTap: onResend, child: Text('Resend', style: CRType.body(color: CR.brass)))
                : Text('Resend in ${count}s', style: CRType.caption()),
          ),
        ],
      ),
    );
  }
}
