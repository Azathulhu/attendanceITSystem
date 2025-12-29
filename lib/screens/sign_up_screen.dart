import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import '../primary_button.dart';
import '../soft_text_field.dart';

class SignUpScreen extends StatefulWidget {
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthService authService = AuthService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  String role = "student"; 
  bool isLoading = false;

  void _signUp() async {
    setState(() => isLoading = true);
    final error = await authService.signUp(
      emailController.text.trim(),
      passwordController.text.trim(),
      nameController.text.trim(),
      role,
    );
    setState(() => isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sign Up")),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Create Account",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 20),
      
            SoftTextField(controller: nameController, label: "Full Name"),
            SoftTextField(controller: emailController, label: "Email"),
            SoftTextField(
              controller: passwordController,
              label: "Password",
              obscure: true,
            ),
      
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: role,
                  items: ['student', 'teacher']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => role = v!),
                ),
              ),
            ),
      
            SizedBox(height: 20),
      
            PrimaryButton(
              text: "Sign Up",
              loading: isLoading,
              onTap: _signUp,
            ),
          ],
        ),
      ),
    );
  }
}
