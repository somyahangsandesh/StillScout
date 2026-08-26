import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 3) {
      setState(() => _step++);
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CrickRiseColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step indicator
              Row(
                children: List.generate(4, (i) => Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: i <= _step
                          ? CrickRiseColors.primary
                          : CrickRiseColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: _buildStep(),
              ),
              ElevatedButton(
                onPressed: _next,
                child: Text(_step < 3 ? 'Continue' : 'Get Started'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildPhoneStep();
      case 1:
        return _buildOtpStep();
      case 2:
        return _buildNameStep();
      case 3:
        return _buildCityStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildPhoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your phone number',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ll send you a verification code',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: CrickRiseColors.textSecondary,
              ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: CrickRiseColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Phone number',
            prefixText: '+81 ',
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter the code',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Sent to ${_phoneController.text}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: CrickRiseColors.textSecondary,
              ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            6,
            (i) => Container(
              width: 48,
              height: 56,
              decoration: BoxDecoration(
                color: CrickRiseColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CrickRiseColors.textMuted),
              ),
              child: const Center(
                child: Text(
                  '—',
                  style: TextStyle(
                    color: CrickRiseColors.textMuted,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s your name?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'This will appear on your player profile',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: CrickRiseColors.textSecondary,
              ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: CrickRiseColors.textPrimary),
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
      ],
    );
  }

  Widget _buildCityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where do you play?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Your city determines your league rankings',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: CrickRiseColors.textSecondary,
              ),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _cityController,
          style: const TextStyle(color: CrickRiseColors.textPrimary),
          decoration: const InputDecoration(labelText: 'City (e.g. Okinawa, Tokyo)'),
        ),
      ],
    );
  }
}
