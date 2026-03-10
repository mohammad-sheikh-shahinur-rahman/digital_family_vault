import 'package:digital_family_vault/core/security/local_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const LockScreen({super.key, required this.onAuthenticated});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with SingleTickerProviderStateMixin {
  final LocalAuthService _authService = LocalAuthService();
  bool _isAuthenticating = false;
  bool _canAuthenticate = false;
  String _authMessage = 'Please authenticate to continue';
  List<BiometricType> _availableBiometrics = [];

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
    _checkAuthCapabilities();
  }

  Future<void> _checkAuthCapabilities() async {
    final canAuth = await _authService.isBiometricAvailable();
    final biometrics = await _authService.getAvailableBiometrics();
    if (mounted) {
      setState(() {
        _canAuthenticate = canAuth;
        _availableBiometrics = biometrics;
        if (!canAuth) {
          _authMessage = 'Device lock not set. Please set a PIN, Pattern, or Fingerprint.';
        } else {
          // Temporary diagnostic message, will be removed later
          print("Available Biometrics: ${_availableBiometrics.map((e) => e.toString().split('.').last).join(', ')}");
        }
      });
      if (canAuth) {
        _authenticate();
      }
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating || !_canAuthenticate) return;
    setState(() => _isAuthenticating = true);

    final success = await _authService.authenticate(biometricOnly: _availableBiometrics.isNotEmpty);

    if (mounted) {
      setState(() => _isAuthenticating = false);
      if (success) {
        widget.onAuthenticated();
      } else {
        _shakeController.forward(from: 0);
        setState(() => _authMessage = 'Authentication failed. Please try again.');
      }
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          final sineValue = 24 * (0.5 - (0.5 - _shakeAnimation.value).abs());
          return Transform.translate(
            offset: Offset(sineValue, 0),
            child: child,
          );
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.9),
                Theme.of(context).colorScheme.secondary.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/icon.png',
                  width: 150,
                  height: 150,
                ),
                const SizedBox(height: 24),
                Text(
                  'Vault Locked',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _authMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 64),
                if (_canAuthenticate)
                  _isAuthenticating
                      ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white))
                      : ElevatedButton.icon(
                          onPressed: _authenticate,
                          icon: Icon(_getBiometricIcon(), size: 28),
                          label: const Text('Unlock Vault'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.9),
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            elevation: 8,
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getBiometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) return Icons.face_unlock_outlined;
    if (_availableBiometrics.contains(BiometricType.fingerprint)) return Icons.fingerprint;
    return Icons.lock_person_outlined;
  }
}
