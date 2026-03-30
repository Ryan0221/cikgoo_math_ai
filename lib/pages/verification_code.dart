import 'dart:ui';

import 'package:flutter/material.dart';

class VerificationCode extends StatefulWidget {
  final String email;
  final String expectedCode;

  const VerificationCode({
    super.key,
    required this.email,
    required this.expectedCode,
  });

  @override
  State<VerificationCode> createState() => _VerificationCodeState();
}

class _VerificationCodeState extends State<VerificationCode> {
  final TextEditingController _codeController = TextEditingController();
  bool _hasError = false;

  void _verifyCode() {
    if (_codeController.text == widget.expectedCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text("Email verified! Proceed to Login."),
        backgroundColor: Colors.greenAccent.withValues(alpha: 0.8),
        )
      );
      Navigator.pop(context, true);
    } else {
      setState(() {
        _hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text("Invalid verification code."),
        backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
        ),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF223257), Color(0xFF1A2A49), Color(0xFF0E1A2E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.mark_email_read_outlined, size: 60, color: Colors.white),
                        const SizedBox(height: 20),
                        const Text(
                          'Verify Your Email',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'A 6-digit verification code has send to\n${widget.email}. Please check your inbox.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 30),

                        // The OTP Input Field
                        TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6, // Forces 6 characters
                          textAlign: TextAlign.center, // Centers the numbers
                          style: const TextStyle(color: Colors.white, fontSize: 32, letterSpacing: 15), // Spreads the numbers out
                          onChanged: (val) {
                            setState(() => _hasError = false); // Clear error state on typing
                          },
                          decoration: InputDecoration(
                            counterText: "", // Hides the "0/6" character counter
                            hintText: "••••••",
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), letterSpacing: 15),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            contentPadding: const EdgeInsets.symmetric(vertical: 20),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: _hasError ? Colors.redAccent : Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(color: Colors.white38),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Verify Button
                        GestureDetector(
                          onTap: _verifyCode,
                          child: Container(
                            height: 55,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white24),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 5)),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'Verify Code',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
