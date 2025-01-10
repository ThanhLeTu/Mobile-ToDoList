import 'package:do_an/screen/home_screen.dart';
import 'package:do_an/services/auth_service.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đăng Ký')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(labelText: 'Tên hiển thị'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Vui lòng nhập tên' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Vui lòng nhập email' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Mật khẩu'),
                obscureText: true,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Vui lòng nhập mật khẩu' : null,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    final user = await _authService.registerWithEmailAndPassword(
                      email: _emailController.text,
                      password: _passwordController.text,
                      displayName: _displayNameController.text,
                    );
                    if (user != null) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CalendarScreen(userId: user.uid),
                        ),
                      );
                    }
                  }
                },
                child: Text('Đăng Ký'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
