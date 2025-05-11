import 'package:flutter/material.dart';
import '../../api_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class RegisterScreenTablet extends StatefulWidget {
  const RegisterScreenTablet({super.key});

  @override
  State<RegisterScreenTablet> createState() => _RegisterScreenTabletState();
}

class _RegisterScreenTabletState extends State<RegisterScreenTablet> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isNameValid = false;
  bool isEmailValid = false;
  bool isPasswordValid = false;

  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  final nameRegex = RegExp(r'^[a-zA-Zá-žÁ-Ž\s]{2,}$');

  void handleRegister() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (!isNameValid || !isEmailValid || !isPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zadaj všetky údaje správne!')),
      );
      return;
    }

    final api = ApiService();
    final success = await api.register(name, email, password);

    if (success) {
      FirebaseAnalytics.instance.logEvent(name: 'register_success');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registrácia úspešná')));
      Navigator.pushNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registrácia zlyhala')));
    }
  }

  Widget _buildValidatedField({
    required String label,
    required TextEditingController controller,
    required bool isValid,
    required void Function(String) onChanged,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isValid ? Icons.check_circle : Icons.cancel,
            key: ValueKey<bool>(isValid),
            color: isValid ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Container(
                color: const Color(0xFF4A2C7A),
                child: const Center(child: Icon(Icons.person_add, size: 120)),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildValidatedField(
                          label: 'Meno',
                          controller: nameController,
                          isValid: isNameValid,
                          onChanged: (value) {
                            setState(() {
                              isNameValid = nameRegex.hasMatch(value.trim());
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildValidatedField(
                          label: 'Email',
                          controller: emailController,
                          isValid: isEmailValid,
                          onChanged: (value) {
                            setState(() {
                              isEmailValid = emailRegex.hasMatch(value.trim());
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildValidatedField(
                          label: 'Heslo',
                          controller: passwordController,
                          isValid: isPasswordValid,
                          obscureText: true,
                          onChanged: (value) {
                            setState(() {
                              isPasswordValid = value.trim().length >= 6;
                            });
                          },
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: handleRegister,
                          child: const Text('Registrovať sa'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/login');
                          },
                          child: const Text('Máš účet? Prihlásiť sa'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
