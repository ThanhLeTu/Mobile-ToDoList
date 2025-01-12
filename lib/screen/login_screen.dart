import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // Quản lý trạng thái form
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;  // Ẩn/hiện password

  // Thêm hàm hiển thị thông báo
  void _showMessage(String message, bool isError) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(20),
        duration: Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (userCredential.user != null) {
          _showMessage('Đăng nhập thành công!', false);
          
          // Chờ 2 giây để hiển thị thông báo
          await Future.delayed(Duration(seconds: 2));
          
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CalendarScreen(userId: userCredential.user!.uid),
            ),
          );
        }
      } catch (e) {
        String errorMessage = 'Đã có lỗi xảy ra';
        if (e is FirebaseAuthException) {
          print('Mã lỗi Firebase: ${e.code}'); // In thử mã lỗi khi xảy ra
          switch (e.code) {
            case 'user-not-found':
            case 'wrong-password':
              errorMessage = 'Sai email hoặc mật khẩu';
              break;
            case 'invalid-email':
              errorMessage = 'Email không hợp lệ';
              break;
            case 'too-many-requests':
              errorMessage = 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
              break;
            // Thêm case khác nếu cần (ví dụ 'invalid-credential')
            default:
              errorMessage = 'Đã có lỗi xảy ra: ${e.message}';
          }
        }
        else{
           errorMessage = 'Lỗi không xác định: $e';
        }
        _showMessage(errorMessage, true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 60),
                Icon(
                  Icons.calendar_today,
                  size: 80,
                  color: Color(0xFF7C4DFF),
                ),
                SizedBox(height: 40),
                Text(
                  'Đăng Nhập',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7C4DFF),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email, color: Color(0xFF7C4DFF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Color(0xFF7C4DFF), width: 2),
                    ),
                    labelStyle: TextStyle(color: Color(0xFF7C4DFF)),
                  ),
                  validator: (value) => 
                    value?.isEmpty ?? true ? 'Vui lòng nhập email' : null,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: Icon(Icons.lock, color: Color(0xFF7C4DFF)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        color: Color(0xFF7C4DFF),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Color(0xFF7C4DFF), width: 2),
                    ),
                    labelStyle: TextStyle(color: Color(0xFF7C4DFF)),
                  ),
                  validator: (value) =>
                    value?.isEmpty ?? true ? 'Vui lòng nhập mật khẩu' : null,
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7C4DFF),
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Đăng Nhập',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Chưa có tài khoản? ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegisterScreen()),
                        );
                      },
                      child: Text(
                        'Đăng ký',
                        style: TextStyle(
                          color: Color(0xFF7C4DFF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}