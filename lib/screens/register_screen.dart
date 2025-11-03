import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/theme.dart';
import '../widgets/common_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _companyController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _adminCodeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedRole = 'user';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _adminCodeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Validasi kode admin jika role admin
    if (_selectedRole == 'admin') {
      if (_adminCodeController.text.trim() != 'waresysadmin') {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Kode admin salah!';
        });
        return;
      }
    }

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Store name, company, and role in Firestore
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': _nameController.text.trim(),
        'company': _companyController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/admin');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppTheme.textPrimary,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingM,
                        vertical: AppTheme.spacingXS,
                      ),
                      decoration: AppTheme.surfaceDecoration,
                      child: Text(
                        'WARESYS',
                        style: AppTheme.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXXL),
                
                // Welcome Text
                Text(
                  'Bergabung dengan',
                  style: AppTheme.heading1.copyWith(
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingL,
                    vertical: AppTheme.spacingS,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentGreen,
                        AppTheme.accentBlue,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  ),
                  child: Text(
                    'WARESYS',
                    style: AppTheme.heading2.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
                Text(
                  'Daftar akun baru untuk memulai perjalanan bisnis Anda',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXXXL),
                
                // Registration Form Card
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXXL),
                  decoration: AppTheme.cardDecoration,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daftar Akun',
                          style: AppTheme.heading2.copyWith(
                            color: AppTheme.accentGreen,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXXL),
                        
                        // Name Field
                        CommonWidgets.buildTextField(
                          label: 'Nama Lengkap',
                          hint: 'Masukkan nama lengkap Anda',
                          controller: _nameController,
                          prefixIcon: Icons.person_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Silakan masukkan nama Anda';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        
                        // Email Field
                        CommonWidgets.buildTextField(
                          label: 'Email',
                          hint: 'Masukkan email Anda',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Silakan masukkan email Anda';
                            }
                            if (!value.contains('@')) {
                              return 'Silakan masukkan email yang valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        
                        // Company Field
                        CommonWidgets.buildTextField(
                          label: 'Nama Perusahaan',
                          hint: 'Masukkan nama perusahaan Anda',
                          controller: _companyController,
                          prefixIcon: Icons.business_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Silakan masukkan nama perusahaan';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        
                        // Password Field
                        CommonWidgets.buildTextField(
                          label: 'Password',
                          hint: 'Masukkan password Anda',
                          controller: _passwordController,
                          obscureText: true,
                          prefixIcon: Icons.lock_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Silakan masukkan password';
                            }
                            if (value.length < 6) {
                              return 'Password minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        
                        // Confirm Password Field
                        CommonWidgets.buildTextField(
                          label: 'Konfirmasi Password',
                          hint: 'Masukkan ulang password Anda',
                          controller: _confirmPasswordController,
                          obscureText: true,
                          prefixIcon: Icons.lock_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Silakan konfirmasi password';
                            }
                            if (value != _passwordController.text) {
                              return 'Password tidak cocok';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        
                        // Role Selection
                        Text(
                          'Pilih Role',
                          style: AppTheme.labelMedium,
                        ),
                        const SizedBox(height: AppTheme.spacingXS),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingL,
                            vertical: AppTheme.spacingXS,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(AppTheme.radiusM),
                            border: Border.all(color: AppTheme.borderDark),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedRole,
                              isExpanded: true,
                              dropdownColor: AppTheme.surfaceDark,
                              style: AppTheme.bodyMedium,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedRole = newValue!;
                                });
                              },
                              items: <String>['user', 'admin']
                                  .map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value == 'user' ? 'User' : 'Admin',
                                    style: AppTheme.bodyMedium,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        
                        // Admin Code Field (conditional)
                        if (_selectedRole == 'admin') ...[
                          const SizedBox(height: AppTheme.spacingL),
                          CommonWidgets.buildTextField(
                            label: 'Kode Admin',
                            hint: 'Masukkan kode admin',
                            controller: _adminCodeController,
                            prefixIcon: Icons.admin_panel_settings_outlined,
                            validator: (value) {
                              if (_selectedRole == 'admin' && (value == null || value.isEmpty)) {
                                return 'Silakan masukkan kode admin';
                              }
                              return null;
                            },
                          ),
                        ],
                        
                        // Error Message
                        if (_errorMessage != null) ...[
                          const SizedBox(height: AppTheme.spacingL),
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingM),
                            decoration: BoxDecoration(
                              color: AppTheme.errorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusS),
                              border: Border.all(
                                color: AppTheme.errorColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: AppTheme.errorColor,
                                  size: 16,
                                ),
                                const SizedBox(width: AppTheme.spacingS),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.errorColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: AppTheme.spacingXXL),
                        
                        // Register Button
                        CommonWidgets.buildPrimaryButton(
                          text: 'Daftar',
                          onPressed: _register,
                          isLoading: _isLoading,
                          width: double.infinity,
                          icon: Icons.person_add,
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        
                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Sudah punya akun? ',
                              style: AppTheme.bodyMedium,
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text(
                                'Masuk',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.accentGreen,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}


