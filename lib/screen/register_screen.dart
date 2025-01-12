import 'package:do_an/screen/home_screen.dart';
import 'package:do_an/screen/login_screen.dart';
import 'package:do_an/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedGender;
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _authService = AuthService(); // Thêm dòng này


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF7C4DFF),
        // Mũi tên back tự động xuất hiện khi có leading
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Đăng Ký',
          style: TextStyle(color: Colors.white),
          ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _displayNameController,
                  decoration: _buildInputDecoration('Họ và tên', Icons.person),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Vui lòng nhập họ tên' : null,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _buildInputDecoration('Email', Icons.email),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Vui lòng nhập email';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!))
                      return 'Email không hợp lệ';
                    return null;
                  },
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
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Vui lòng nhập mật khẩu' : null,
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _buildInputDecoration('Số điện thoại', Icons.phone),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Vui lòng nhập số điện thoại';
                    if (!RegExp(r'^[0-9]{10}$').hasMatch(value!))
                      return 'Số điện thoại không hợp lệ';
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _addressController,
                  decoration: _buildInputDecoration('Địa chỉ', Icons.location_on),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Vui lòng nhập địa chỉ' : null,
                ),
                SizedBox(height: 20),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: _buildInputDecoration('Ngày sinh', Icons.calendar_today),
                    child: Text(
                      _selectedDate == null
                          ? 'Chọn ngày sinh'
                          : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: _buildInputDecoration('Giới tính', Icons.person_outline),
                  items: ['Nam', 'Nữ', 'Khác']
                      .map((gender) => DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Vui lòng chọn giới tính' : null,
                ),

                SizedBox(height: 30),
                ElevatedButton(
                  // Trong hàm onPressed của nút đăng ký:
                  onPressed: _isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          if (_selectedDate == null) {
                            // Sử dụng BuildContext an toàn
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng chọn ngày sinh'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            return;
                          }
                          
                          setState(() => _isLoading = true);
                          
                          try {
                            final user = await _authService.registerWithEmailAndPassword(
                              email: _emailController.text,
                              password: _passwordController.text,
                              displayName: _displayNameController.text,
                              phone: _phoneController.text,
                              address: _addressController.text,
                              birthDate: _selectedDate!,
                              gender: _selectedGender!,
                            );
                            
                            // Kiểm tra mounted trước khi sử dụng context
                            if (!mounted) return;
                            
                            if (user != null) {
                              // Chuyển hướng đến màn hình chính
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginScreen(),
                                ),
                              );
                            }
                          } catch (e) {
                            // Kiểm tra mounted trước khi hiển thị lỗi
                            if (!mounted) return;
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Đăng ký thất bại: ${e.toString()}'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF7C4DFF),
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    //child widget 
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
                          'Đăng Ký',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Color(0xFF7C4DFF)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Color(0xFF7C4DFF), width: 2),
      ),
      labelStyle: TextStyle(color: Color(0xFF7C4DFF)),
    );
  }
}