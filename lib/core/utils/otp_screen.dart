import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:splitzon/core/constants/app_colors.dart';
import 'package:splitzon/core/utils/background_theme.dart';
import 'package:splitzon/core/widgets/app_branding.dart';
import 'package:splitzon/core/widgets/otp_submit_btn.dart';
import 'package:splitzon/services/firebase_auth.dart';

class OtpScreen extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String verificationId;
  final bool rememberMe;

  const OtpScreen({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.verificationId,
    required this.rememberMe,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  /// OTP controllers
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  /// Focus nodes
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool isLoading = false;

  /// OTP TIMER
  int _secondsRemaining = 60;
  bool _canResend = false;
  Timer? _timer;

  /// Combine OTP digits
  String get otp => _controllers.map((e) => e.text).join();

  @override
  void initState() {
    super.initState();
    startOtpTimer();
  }

  /// Start OTP countdown timer
  void startOtpTimer() {
    _secondsRemaining = 60;
    _canResend = false;

    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        timer.cancel();
        setState(() {
          _canResend = true;
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  /// Submit OTP
  void submitOtp() async {
    if (otp.length < 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter complete OTP")));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuthMethods(FirebaseAuth.instance).verifyOtpAndHandleUser(
        context: context,
        verificationId: widget.verificationId,
        otp: otp,
        name: widget.name,
        email: widget.email,
        phone: widget.phone,
        rememberMe: widget.rememberMe,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Resend OTP
  Future<void> resendOtp() async {
    if (!_canResend) return;

    await FirebaseAuthMethods(FirebaseAuth.instance).sendOtp(
      context: context,
      name: widget.name,
      email: widget.email,
      phone: widget.phone,
      rememberMe: widget.rememberMe,
    );

    startOtpTimer();
  }

  /// OTP focus movement
  void onOtpChange(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundTheme(
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 10,
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),

          child: Column(
            children: [
              const SizedBox(height: 30),

              /// Illustration
              SvgPicture.asset("assets/login.svg", height: 180),

              const SizedBox(height: 30),

              const Text(
                "Verify Account",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 30),

              /// OTP CARD
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.95),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.08),
                      blurRadius: 25,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),

                child: Column(
                  children: [
                    Text(
                      "Hi ${widget.name}!",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "We sent a verification code to",
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 6),

                    Text(
                      widget.phone,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),

                    const SizedBox(height: 24),

                    /// OTP BOXES
                    /// OTP BOXES
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final boxWidth = (constraints.maxWidth - 40) / 6;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            6,
                            (index) => SizedBox(
                              width: boxWidth,
                              child: TextField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,

                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(1),
                                ],

                                onChanged: (value) => onOtpChange(value, index),

                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),

                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.grey.shade50,

                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),

                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),

                                  focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    /// RESEND TIMER
                    _canResend
                        ? TextButton(
                            onPressed: resendOtp,
                            child: const Text(
                              "Resend OTP",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : Text(
                            "Resend OTP in $_secondsRemaining s",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),

                    const SizedBox(height: 30),

                    /// SUBMIT BUTTON
                    OtpSubmitButton(isLoading: isLoading, onPressed: submitOtp),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              const AppBranding(),
            ],
          ),
        ),
      ),
    );
  }
}
