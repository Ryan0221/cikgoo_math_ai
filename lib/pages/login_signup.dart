import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cikgoo_math_ai/pages/verification_code.dart';

class LoginSignup extends StatefulWidget {
  const LoginSignup({super.key});

  @override
  State<LoginSignup> createState() => _LoginSignupState();
}

class _LoginSignupState extends State<LoginSignup> {
  bool isLogin = false;

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Validation States
  bool _hasLength = false;
  bool _hasUpperCase = false;
  bool _hasLowerCase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;
  bool _isMatch = false;
  bool _isValidEmail = false;

  bool _isLoading = false;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    setState(() {
      _isValidEmail = RegExp(
        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      ).hasMatch(value);
    });
  }

  void _validatePassword(String value) {
    setState(() {
      _hasLength = value.length >= 12 && value.length <= 64;
      _hasUpperCase = value.contains(RegExp(r'[A-Z]'));
      _hasLowerCase = value.contains(RegExp(r'[a-z]'));
      _hasNumber = value.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>-_]'));
      _isMatch =
          _passwordController.text == _confirmPasswordController.text &&
          _passwordController.text.isNotEmpty;
    });
  }

  void _validateConfirmPassword(String value) {
    setState(() {
      _isMatch = _passwordController.text == value && value.isNotEmpty;
    });
  }

  // NEW: Helper function to create the Firestore User Document
  Future<void> _checkAndCreateUserDoc(User user) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final docSnap = await docRef.get();

    // Only create the document if it doesn't exist yet (so we don't overwrite names on login)
    if (!docSnap.exists) {
      String finalName;

      // 1. Check if Firebase pulled a real name from Google
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        finalName = user.displayName!; // Use the real Google name
      }
      // 2. If no name exists (Email/Password signup), generate the random one
      else {
        String randomNums = List.generate(
          9,
          (_) => Random().nextInt(10),
        ).join();
        finalName = 'user$randomNums';
      }

      // Save it to Firestore
      await docRef.set({
        'uid': user.uid,
        'email': user.email,
        'name': finalName,
        'createdAt': FieldValue.serverTimestamp(),
        "current_form": 4,
        "math_spm_f4_completed": 0,
        "math_spm_f5_completed": 0,
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    // Start the loading spinner
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // If the user taps the button but then closes the popup
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign into Firebase
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      // NEW: Check if this is their first time logging in. If so, create database profile!
      if (userCredential.user != null) {
        await _checkAndCreateUserDoc(userCredential.user!);
      }

      /*if (mounted) {
        Navigator.pushReplacementNamed(context, '/first_page');
      }*/
    } catch (e) {
      // CRITICAL: This catches any crashes or Exception 10s so the app doesn't freeze!
      print("Google Sign-In Error: $e");
    } finally {
      // FINALLY always runs at the very end, whether the try succeeds OR fails.
      // We check 'mounted' just in case the AuthGate already navigated them away.
      if (mounted) {
        setState(() {
          _isLoading = false; // Turn off the spinner safely
        });
      }
    }
  }

  // --- Forgot Password Dialog ---
  // --- UPDATED: Secure Forgot Password Dialog ---
  void _showForgotPasswordDialog(BuildContext context) {
    final TextEditingController resetEmailController = TextEditingController();

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A2A49),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            title: const Text("Reset Password", style: TextStyle(color: Colors.white)),
            content: TextField(
              controller: resetEmailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Enter your email address",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.blueAccent),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  String email = resetEmailController.text.trim();
                  if (email.isEmpty) return;

                  try {
                    // NEW SECURE METHOD: Just send the email.
                    // If they used Google, this will safely allow them to link a password!
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

                    if (context.mounted) {
                      Navigator.pop(context); // Close dialog

                      // Notice the generic message: This prevents hackers from knowing if the email exists!
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("A reset link has been send to your inbox."),
                            backgroundColor: Colors.green
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                },
                child: const Text("Send Reset Link", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image/Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF223257),
                  Color(0xFF1A2A49),
                  Color(0xFF0E1A2E),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Login/Signup Form
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isLogin ? 'Login' : 'Sign Up',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 30),

                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                children: [
                                  _buildTabItem(
                                    "Login",
                                    isLogin,
                                    () => setState(() => isLogin = true),
                                  ),
                                  _buildTabItem(
                                    "Sign Up",
                                    !isLogin,
                                    () => setState(() => isLogin = false),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 25),

                            // Input Fields
                            _buildTextField(
                              "Email Address",
                              Icons.email_outlined,
                              controller: _emailController,
                              onChanged: _validateEmail,
                            ),

                            if (_emailController.text.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  bottom: 4,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isValidEmail
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: _isValidEmail
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isValidEmail
                                          ? "Valid Email"
                                          : "Invalid Email", // Text changes here
                                      style: TextStyle(
                                        color: _isValidEmail
                                            ? Colors.greenAccent
                                            : Colors
                                                  .redAccent, // Color changes here
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 15),

                            _buildTextField(
                              "Password",
                              Icons.lock_outline,
                              obscure: true,
                              controller: _passwordController,
                              onChanged: _validatePassword,
                            ),

                            if (isLogin) ...[
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 10, right: 5),
                                  child: GestureDetector(
                                    onTap: () => _showForgotPasswordDialog(context),
                                    child: const Text(
                                      "Forgot password?",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              alignment: Alignment.topCenter,
                              child: !isLogin
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (_passwordController
                                            .text
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          _buildRequirementLine(
                                            "12~64 characters",
                                            _hasLength,
                                          ),
                                          _buildRequirementLine(
                                            "Uppercase",
                                            _hasUpperCase,
                                          ),
                                          _buildRequirementLine(
                                            "Lowercase",
                                            _hasLowerCase,
                                          ),
                                          _buildRequirementLine(
                                            "Number",
                                            _hasNumber,
                                          ),
                                          _buildRequirementLine(
                                            "Special Character",
                                            _hasSpecialChar,
                                          ),
                                        ],

                                        const SizedBox(height: 15),
                                        _buildTextField(
                                          "Confirm Password",
                                          Icons.lock_reset,
                                          obscure: true,
                                          controller:
                                              _confirmPasswordController,
                                          onChanged: _validateConfirmPassword,
                                        ),

                                        if (_confirmPasswordController
                                            .text
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          _buildRequirementLine(
                                            "Password match",
                                            _isMatch,
                                          ),
                                        ],
                                      ],
                                    )
                                  : const SizedBox.shrink(),
                            ),

                            const SizedBox(height: 30),

                            // Action Button
                            GestureDetector(
                              onTap: () async {
                                if (_isLoading) return;

                                if (isLogin) {
                                  setState(() => _isLoading = true);
                                  try {
                                    await FirebaseAuth.instance
                                        .signInWithEmailAndPassword(
                                          email: _emailController.text.trim(),
                                          password: _passwordController.text,
                                        );

                                    // Do NOT put any Navigator.push here!
                                    // AuthGate will automatically detect the login and change the screen.
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            "Login failed. Check email and password.",
                                          ),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  } finally {
                                    // We only turn off the loading spinner if the widget is still on screen
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                } else {
                                  // Check validation
                                  if (!_hasLength ||
                                      !_hasUpperCase ||
                                      !_hasLowerCase ||
                                      !_hasNumber ||
                                      !_hasSpecialChar ||
                                      !_isMatch ||
                                      !_isValidEmail) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _isValidEmail
                                              ? "Please meet all password requirements"
                                              : "Please enter a valid email",
                                        ),
                                        backgroundColor: Colors.redAccent
                                            .withValues(alpha: 0.8),
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() {
                                    _isLoading = true;
                                  });

                                  //Generate a 6-digit random code
                                  String verificationCode =
                                      (Random().nextInt(900000) + 100000)
                                          .toString();

                                  bool emailSent = await sendVerificationEmail(
                                    _emailController.text.trim(),
                                    verificationCode,
                                  );

                                  if (!emailSent) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            "Failed to send email. Please check your connection.",
                                          ),
                                          backgroundColor: Colors.redAccent
                                              .withValues(alpha: 0.8),
                                        ),
                                      );
                                    }
                                    return; // Stop execution
                                  }

                                  setState(() {
                                    _isLoading = false;
                                  });

                                  // Wait for verification result from the next screen
                                  if (context.mounted) {
                                    bool? isVerified = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VerificationCode(
                                          email: _emailController.text,
                                          expectedCode: verificationCode,
                                        ),
                                      ),
                                    );

                                    if (isVerified == true) {
                                      setState(() => _isLoading = true);
                                      try {
                                        // NEW: 1. Create the Firebase Auth Account
                                        UserCredential userCred =
                                            await FirebaseAuth.instance
                                                .createUserWithEmailAndPassword(
                                                  email: _emailController.text
                                                      .trim(),
                                                  password:
                                                      _passwordController.text,
                                                );

                                        // NEW: 2. Create the Firestore database record
                                        if (userCred.user != null) {
                                          await _checkAndCreateUserDoc(
                                            userCred.user!,
                                          );
                                        }
                                        await FirebaseAuth.instance.signOut();

                                        setState(() {
                                          isLogin = true;
                                          _passwordController.clear();
                                          _confirmPasswordController.clear();
                                        });

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                "Account created! Please login",
                                              ),
                                              backgroundColor: Colors.green
                                                  .withValues(alpha: 0.8),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Error creating account: $e",
                                              ),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() => _isLoading = false);
                                        }
                                      }
                                    }
                                  }
                                }
                              },
                              child: Container(
                                height: 55,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: Colors.white24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          isLogin ? 'Login' : 'Sign Up',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    'Sign in with:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 15),

                  GestureDetector(
                    onTap: _signInWithGoogle,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape
                                .circle, // Makes it a perfect round icon
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Image.asset(
                            'assets/google.png',
                            height: 30,
                            width: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementLine(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.cancel,
            color: isMet ? Colors.greenAccent : Colors.redAccent,
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.greenAccent : Colors.redAccent,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white60,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    IconData icon, {
    bool obscure = false,
    TextEditingController? controller,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 20,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white38),
        ),
      ),
    );
  }
}

Future<bool> sendVerificationEmail(String recipientEmail, String code) async {
  // REPLACE THESE WITH YOUR ACTUAL EMAILJS KEYS
  const String serviceId = 'service_kztffbw';
  const String templateId = 'template_o1rkfb8';
  const String publicKey = 'YQRUGEBpuaq20usOk';

  final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

  try {
    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': publicKey,
        'template_params': {
          'to_email': recipientEmail,
          'verification_code': code,
        },
      }),
    );

    return response.statusCode == 200;
  } catch (e) {
    print("Error sending email: $e");
    return false;
  }
}
