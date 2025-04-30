import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class MobileSignupPage extends StatefulWidget {
  static Route route() {
    return MaterialPageRoute(builder: (context) => const MobileSignupPage());
  }

  const MobileSignupPage({super.key});

  @override
  State<MobileSignupPage> createState() => _MobileSignupPageState();
}

class _MobileSignupPageState extends State<MobileSignupPage> {
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _phoneNumber = "";
  bool _isLoading = false;
  PhoneNumber _initialPhoneNumber = PhoneNumber(isoCode: 'LK');

  // Color theme
  final Color _primaryColor = const Color(0xFF075E54);
  final Color _buttonColor = const Color(0xFF25D366);

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // For development testing only - remove in production
      await FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: true,
      );

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        },
        verificationFailed: (e) {
          _showErrorSnackBar(_getErrorMessage(e));
        },
        codeSent: (verificationId, resendToken) {
          if (mounted) {
            Navigator.pushNamed(
              context,
              '/otp_verification',
              arguments: {
                'verificationId': verificationId,
                'resendToken': resendToken,
                'phoneNumber': _phoneNumber,
              },
            );
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {},
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        _showErrorSnackBar(
          "SMS verification is not enabled for this region. "
          "Please contact support.",
        );
      } else {
        _showErrorSnackBar("Error: ${_getErrorMessage(e)}");
      }
    } catch (e) {
      _showErrorSnackBar("An error occurred: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return "Invalid phone number format";
      case 'too-many-requests':
        return "Too many attempts. Try again later";
      case 'quota-exceeded':
        return "Quota exceeded. Contact support";
      case 'operation-not-allowed':
        return "SMS verification not enabled";
      default:
        return e.message ?? "Verification failed";
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/images/login.webp', // Replace with your background image path
            fit: BoxFit.cover,
          ),

          // Dark overlay for readability
          Container(color: Colors.black.withOpacity(0.4)),

          // Signup Form
          Center(
            child: Card(
              elevation: 8,
              color: Colors.white.withOpacity(0.9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'SIGN UP',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      InternationalPhoneNumberInput(
                        onInputChanged: (number) {
                          setState(() {
                            _phoneNumber = number.phoneNumber ?? "";
                          });
                        },
                        selectorConfig: const SelectorConfig(
                          selectorType: PhoneInputSelectorType.DIALOG,
                          showFlags: true,
                          useEmoji: true,
                        ),
                        initialValue: _initialPhoneNumber,
                        textFieldController: _phoneController,
                        formatInput: true,
                        keyboardType: TextInputType.phone,
                        inputDecoration: InputDecoration(
                          labelText: "Phone Number",
                          hintText: "712345678",
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _primaryColor),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter a phone number";
                          }
                          if (_phoneNumber.isEmpty) {
                            return "Please select a valid country code";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _sendOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _buttonColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Center(
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('SEND VERIFICATION CODE'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        child: const Text("Already have an account? LOGIN"),
                      ),
                    ],
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
