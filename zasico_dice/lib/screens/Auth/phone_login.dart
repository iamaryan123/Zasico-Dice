// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import '../../Utils/custom_loading_indicator.dart';
// import '../Utils/utils.dart';
// import '../component/home/FirstScreen.dart';
// import 'set_info.dart';

// class PhoneLoginPage extends StatefulWidget {
//   const PhoneLoginPage({super.key});

//   @override
//   _PhoneLoginPageState createState() => _PhoneLoginPageState();
// }

// class _PhoneLoginPageState extends State<PhoneLoginPage> {
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _otpController = TextEditingController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   String? _verificationId;
//   bool _isLoading = false;

//   Future<void> _verifyPhone() async {
//     setState(() => _isLoading = true);
//     String phoneNumber = _phoneController.text.trim();
//     if (!phoneNumber.startsWith('+')) {
//       phoneNumber = '+92$phoneNumber'; // Adjust country code as needed
//     }
//     await _auth.verifyPhoneNumber(
//       phoneNumber: phoneNumber,
//       verificationCompleted: (PhoneAuthCredential credential) async {
//         await _signInWithCredential(credential);
//       },
//       verificationFailed: (FirebaseAuthException e) {
//         setState(() => _isLoading = false);
//         showToast('Verification failed: ${e.message}', Colors.red);
//       },
//       codeSent: (String verificationId, int? resendToken) {
//         setState(() {
//           _verificationId = verificationId;
//           _isLoading = false;
//         });
//       },
//       codeAutoRetrievalTimeout: (String verificationId) {
//         _verificationId = verificationId;
//       },
//     );
//   }

//   Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
//     setState(() => _isLoading = true);
//     try {
//       UserCredential userCredential = await _auth.signInWithCredential(credential);
//       User? user = userCredential.user;
//       if (user != null) {
//         DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
//         if (userDoc.exists) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => GameMenuScreen()),
//           );
//         } else {
//           await _firestore.collection('users').doc(user.uid).set({
//             'phone': user.phoneNumber,
//             'uid': user.uid,
//             'username': '',
//             'firstName': '',
//             'lastName': '',
//             'email': '',
//             'profilePicture': 'assets/images/ludo_token.png',
//           });
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(builder: (context) => SetInfoPage()),
//           );
//         }
//       }
//     } catch (e) {
//       showToast('Sign-in failed: $e', Colors.red);
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _signInWithOTP() async {
//     String smsCode = _otpController.text.trim();
//     if (_verificationId == null) {
//       showToast('Verification ID not found', Colors.red);
//       return;
//     }
//     PhoneAuthCredential credential = PhoneAuthProvider.credential(
//       verificationId: _verificationId!,
//       smsCode: smsCode,
//     );
//     await _signInWithCredential(credential);
//   }

//   @override
//   void dispose() {
//     _phoneController.dispose();
//     _otpController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Login with Phone'),
//         backgroundColor: Colors.red,
//       ),
//       backgroundColor: theme.scaffoldBackgroundColor,
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             TextField(
//               controller: _phoneController,
//               keyboardType: TextInputType.phone,
//               decoration: InputDecoration(
//                 hintText: 'Phone Number (e.g., 3001234567)',
//                 prefixIcon: const Icon(Icons.phone, color: Colors.red),
//                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12.0),
//                   borderSide: const BorderSide(color: Colors.red, width: 1.5),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12.0),
//                   borderSide: const BorderSide(color: Colors.red, width: 2.0),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//               ),
//               onPressed: _verifyPhone,
//               child: const Text('Send OTP', style: TextStyle(color: Colors.white)),
//             ),
//             if (_verificationId != null) ...[
//               const SizedBox(height: 16),
//               TextField(
//                 controller: _otpController,
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(
//                   hintText: 'Enter OTP',
//                   prefixIcon: const Icon(Icons.lock, color: Colors.red),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12.0),
//                     borderSide: const BorderSide(color: Colors.red, width: 1.5),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12.0),
//                     borderSide: const BorderSide(color: Colors.red, width: 2.0),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue,
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//                 ),
//                 onPressed: _signInWithOTP,
//                 child: const Text('Verify OTP', style: TextStyle(color: Colors.white)),
//               ),
//             ],
//             if (_isLoading) const CustomLoadingIndicator(),
//           ],
//         ),
//       ),
//     );
//   }
// }