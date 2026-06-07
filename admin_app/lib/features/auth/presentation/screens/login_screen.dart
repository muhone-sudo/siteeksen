import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _localAuth = LocalAuthentication();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _biometricLoginAvailable = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final hasSession = await apiClient.hasStoredSession();
      final enabled = await apiClient.isBiometricEnabled();
      if (mounted) {
        setState(() => _biometricLoginAvailable = canCheck && hasSession && enabled);
      }
    } catch (_) {
      // Biyometrik donanım/izin yoksa buton gizli kalır
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await apiClient.login(_phoneController.text, _passwordController.text);
      if (!mounted) return;
      await _maybeOfferBiometricEnable();
      if (!mounted) return;
      context.go('/');
    } catch (e) {
      setState(() {
        _errorMessage = 'Giriş başarısız. Bilgilerinizi kontrol edin.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _maybeOfferBiometricEnable() async {
    final alreadyEnabled = await apiClient.isBiometricEnabled();
    if (alreadyEnabled) return;
    final canCheck = await _localAuth.canCheckBiometrics;
    if (!canCheck || !mounted) return;

    final shouldEnable = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Biyometrik Giriş'),
        content: const Text(
          'Bir sonraki girişte parmak izi veya yüz tanıma ile hızlıca giriş yapmak ister misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hayır'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Etkinleştir'),
          ),
        ],
      ),
    );

    if (shouldEnable == true) {
      await apiClient.setBiometricEnabled(true);
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Giriş yapmak için kimliğinizi doğrulayın',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (!authenticated) return;

      final restored = await apiClient.loginWithStoredSession();
      if (!mounted) return;
      if (restored) {
        context.go('/');
      } else {
        setState(() => _errorMessage = 'Oturum yenilenemedi, lütfen şifrenizle giriş yapın');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Biyometrik doğrulama başarısız');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.apartment,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  const Text(
                    'SiteEksen',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Text(
                    'Yönetici Paneli',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.errorColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppTheme.errorColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Phone field
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Telefon Numarası',
                      hintText: '+90 555 123 4567',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Telefon numarası gerekli';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Şifre gerekli';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Login button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Giriş Yap'),
                  ),
                  const SizedBox(height: 16),

                  // Biometric login
                  if (_biometricLoginAvailable) ...[
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleBiometricLogin,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Biyometrik Giriş'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Forgot password
                  TextButton(
                    onPressed: () {
                      // TODO: Şifremi unuttum
                    },
                    child: const Text('Şifremi Unuttum'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
