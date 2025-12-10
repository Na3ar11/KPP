import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'home_screen.dart';
import '../utils/validators.dart';
import '../repositories/auth_repository.dart';
import '../widgets/social_login_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authRepository = AuthRepository();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    
    // Перевіряємо чи користувач повернувся після Google redirect
    _checkRedirectResult();
    
    // Додаємо слухач для автоматичної перевалідації при зміні пароля
    _passwordController.addListener(() {
      if (_confirmPasswordController.text.isNotEmpty) {
        _formKey.currentState?.validate();
      }
    });
  }

  Future<void> _checkRedirectResult() async {
    try {
      final result = await _authRepository.checkRedirectResult();
      if (result != null && result.user != null) {
        if (!mounted) return;
        // Користувач успішно зареєструвався через Google redirect
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      print('Error checking redirect: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authRepository.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );
      
      // Логуємо успішну реєстрацію через email
      await FirebaseAnalytics.instance.logEvent(
        name: 'user_register',
        parameters: {
          'register_method': 'email',
          'user_email': _emailController.text.trim(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Реєстрація успішна! Перевірте email для верифікації.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _isLoading = true);

    try {
      await _authRepository.signInWithGoogle();
      
      await FirebaseAnalytics.instance.logEvent(
        name: 'user_register',
        parameters: {
          'register_method': 'google',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      
      if (!mounted) return;
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
      
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: e.toString().contains('Перенаправлення') ? Colors.blue : Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: e.toString().contains('Перенаправлення') 
              ? const Duration(seconds: 5) 
              : const Duration(seconds: 3),
        ),
      );
      
      
      if (!e.toString().contains('Перенаправлення')) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGoogleAvailable = _authRepository.isGoogleSignInAvailable;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Створити акаунт'),
        leading: _isLoading ? null : IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      const Icon(Icons.person_add, size: 60, color: Colors.deepPurple),
                      const SizedBox(height: 20),
                      const Text(
                        'Приєднуйтесь до нас',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Створіть акаунт, щоб почати',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 40),
                      
                      TextFormField(
                        controller: _nameController,
                        validator: Validators.name,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(
                          labelText: 'Повне ім\'я',
                          prefixIcon: Icon(Icons.person_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.email,
                        enabled: !_isLoading,
                        decoration: const InputDecoration(
                          labelText: 'Електронна пошта',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        validator: Validators.password,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Пароль',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword 
                                  ? Icons.visibility_outlined 
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        // ✅ ВИПРАВЛЕНО: Передаємо контролер замість тексту
                        validator: Validators.confirmPassword(_passwordController),
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Підтвердіть пароль',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword 
                                  ? Icons.visibility_outlined 
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                            },
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Створити акаунт', style: TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(height: 20),
                      
                      if (isGoogleAvailable) ...[
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('АБО', style: TextStyle(color: Colors.grey)),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        SocialLoginButton(
                          label: "Реєстрація через Google",
                          onPressed: _isLoading ? null : _handleGoogleSignUp,
                        ),
                      ],
                      const SizedBox(height: 20),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Вже маєте акаунт?"),
                          TextButton(
                            onPressed: _isLoading ? null : () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Увійти'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}