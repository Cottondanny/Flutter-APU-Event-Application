import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  //form key is used as a remote control to validate the form
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();



  //controllers are needed to store memory
  //they act as bridges between the screen and the memory so the program uses the memory to validate and to do other functions

  final _nameController = TextEditingController();
  final _tpController = TextEditingController();
  final _emailController = TextEditingController();
  final _programmeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _tpController.dispose();
    _emailController.dispose();
    _programmeController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future <void> _register() async{
    // Check if all fields pass their validators first
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final error = await _authService.registerStudent(
      name: _nameController.text.trim(),
      tpNumber: _tpController.text.trim(),
      email: _emailController.text.trim(),
      programme: _programmeController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      password: _confirmPasswordController.text,
    );

    setState(() => _isLoading = false);

    if(error!=null){
      // Show error in a snackbar (little popup at the bottom)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }else {
      // Success! For now just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration successful!'),
          backgroundColor: Colors.green,
        ),
      );
    // Go back to login screen and clear the navigation stack
    // Navigator.pushReplacement, so the user can't press back and end up on the register screen again after logging in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  // A reusable helper so i don't repeat the same TextField code many times
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Account'), centerTitle: true,),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(30),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              // Welcome header
              const SizedBox(height: 16),
              Text(
                'Join StudentHub',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fill in your details to get started.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              //Full name
              _buildField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person_outline_rounded,
                validator: (value) {
                  if(value!.trim().isEmpty) return 'Please enter your name';
                  if (!RegExp(r"^[a-zA-Z\s]+$").hasMatch(value.trim())) {
                    return 'Name should only contain letters';
                  }
                  if (value.trim().length < 2) return 'Name is too short';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              //TP Number
              _buildField(
                controller: _tpController,
                label: 'TP Number',
                icon: Icons.badge_outlined,
                validator: (value) {
                  if(value!.trim().isEmpty) return 'Please enter your TP number';
                  if (!RegExp(r"^TP\d{6}$").hasMatch(value.trim().toUpperCase())) {
                    return 'TP number format: TP followed by 6 digits (e.g. TP081818)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              //Programme
              _buildField(
                controller: _programmeController,
                label: 'Programme',
                icon: Icons.school_outlined,
                validator: (value) {
                  if(value!.trim().isEmpty) return 'Please enter your Programme name';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              //phone 
              _buildField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone_android_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value!.trim().isEmpty) return 'Please enter your phone number';
                  if (!RegExp(r"^(\+?60|0)1[0-9]{8,9}$").hasMatch(value.trim())) {
                    return 'Enter a valid Malaysian number (e.g. 0141234567)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              //email 
              _buildField(
                controller: _emailController,
                label: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value!.trim().isEmpty) return 'Please enter your email';
                  if (!RegExp(r"^[\w.-]+@[\w.-]+\.\w{2,}$").hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              //password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.password_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                        ?Icons.visibility_outlined
                        :Icons.visibility_off_outlined
                      ),
                      onPressed: ()=> setState(() {
                        _obscurePassword =! _obscurePassword;}
                      ),
                    )
                ),
                validator: (value){
                  if (value!.isEmpty) return 'Please enter a password';
                  if (value.length < 8) return 'Password must be at least 8 characters';
                  if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Include at least one uppercase letter';
                  if (!RegExp(r'[0-9]').hasMatch(value)) return 'Include at least one number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              //confirm password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.password),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                        ?Icons.visibility_outlined
                        :Icons.visibility_off_outlined
                      ),
                      onPressed: ()=> setState(() {
                        _obscureConfirmPassword =! _obscureConfirmPassword;}
                      ),
                    )
                ),
                validator: (value){
                  if(value!.trim().isEmpty) return 'Please confirm password';
                  if(value!= _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 30),
              
              //Register button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                    ?const CircularProgressIndicator(color: Colors.white)
                    :const Text('Create Account',  
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),)
                )
              ),
              const SizedBox(height: 16),
            ],
          )
        ),
      ),
    );
  }
}