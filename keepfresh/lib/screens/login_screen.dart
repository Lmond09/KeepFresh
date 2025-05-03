import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class MainMenuPage extends StatefulWidget {
  const MainMenuPage({super.key});

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoginMode = true;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _buttonAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _buttonAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _handleAction() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      _animationController.forward(from: 0.0);

      final prefs = await SharedPreferences.getInstance();
      final username = _usernameController.text;
      final storedPassword = prefs.getString('user_$username');

      await Future.delayed(const Duration(seconds: 1)); // Simulate processing

      if (!mounted) return;

      if (_isLoginMode) {
        // Login logic
        if (storedPassword == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Username not found!', style: GoogleFonts.poppins()),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else if (storedPassword == _passwordController.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login successful!', style: GoogleFonts.poppins()),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(username: username),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Incorrect password!', style: GoogleFonts.poppins()),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } else {
        // Sign up logic
        if (storedPassword != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Username already exists!', style: GoogleFonts.poppins()),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else {
          await prefs.setString('user_$username', _passwordController.text);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign up successful! Please login.', style: GoogleFonts.poppins()),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _isLoginMode = true;
            _usernameController.clear();
            _passwordController.clear();
          });
        }
      }

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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF26A69A), Color(0xFF80CBC4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Keep Fresh',
                  style: GoogleFonts.poppins(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildModeButton('Login', true),
                    const SizedBox(width: 8),
                    _buildModeButton('Sign Up', false),
                  ],
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: GoogleFonts.roboto(color: Colors.white70),
                          prefixIcon: const Icon(Icons.person, color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white70),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                        ),
                        style: GoogleFonts.roboto(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: GoogleFonts.roboto(color: Colors.white70),
                          prefixIcon: const Icon(Icons.lock, color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.white70),
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                        ),
                        style: GoogleFonts.roboto(color: Colors.white),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      ScaleTransition(
                        scale: _buttonAnimation,
                        child: GestureDetector(
                          onTapDown: (_) => _animationController.forward(from: 0.0),
                          onTapUp: (_) => _handleAction(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF7043), Color(0xFFFF8A65)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  offset: Offset(2, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_isLoading)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  Icon(
                                    _isLoginMode ? Icons.login : Icons.person_add,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                const SizedBox(width: 8),
                                Text(
                                  _isLoginMode ? 'Login' : 'Sign Up',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomePage(username: 'guest'),
                        ),
                      );
                    },
                    child: Text(
                      'Proceed without login',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildModeButton(String label, bool isLogin) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isLoginMode = isLogin;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
        decoration: BoxDecoration(
          color: _isLoginMode == isLogin ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isLoginMode == isLogin ? Colors.white : Colors.white70,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _isLoginMode == isLogin ? Colors.white : Colors.white70,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

