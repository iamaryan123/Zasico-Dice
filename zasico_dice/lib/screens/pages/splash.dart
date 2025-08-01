import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Auth/login_page.dart';
import '../Auth/set_info.dart';
import '../../utils/custom_loading_indicator.dart';
import 'game_menu.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Add a delay to simulate splash screen duration
    Future.delayed(const Duration(seconds: 3), () {
      _checkAuthentication();
    });
  }

  // Method to check authentication and navigate accordingly
  void _checkAuthentication() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _checkUserProfile(user);
      } else {
        // Navigate to LoginPage if no user is found
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) =>  AuthSelectionScreen()),
        // );
      }
    });
  }

  // Method to check if user profile is set, navigate accordingly
  void _checkUserProfile(User user) {
    FirebaseFirestore.instance.collection('users').doc(user.uid).get().then((userSnapshot) {
      if (userSnapshot.exists) {
        var userData = userSnapshot.data()!;
        if (userData['firstName'] == null && userData['firstName'].isEmpty && !user.isAnonymous) {
          // Redirect to SetInfoPage if firstName is not set
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SetInfoPage()),
          );
        } else {
          // Redirect to DashboardPage if user profile is complete
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) =>  GameMenuScreen()),
          );
        }
      } else {
        // If no user data is found, navigate to SetInfoPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SetInfoPage()),
        );
      }
    }).catchError((e) {
      // Handle error and navigate to Dashboard if there’s an issue
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>  GameMenuScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image from assets
          Image.asset('assets/images/logo.png', width: 300, height: 300),
          const SizedBox(height: 20),
          // Loading indicator
          const CustomLoadingIndicator(
            dotColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen(); // Show splash screen while checking auth state
        } else if (snapshot.hasData) {
          User? user = snapshot.data;
          if (user != null) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CustomLoadingIndicator(
                  ));
                } else if (userSnapshot.hasData) {
                  var userData = userSnapshot.data!;
                  if (userData['firstName'] == null || userData['firstName'].isEmpty) {
                    return const SetInfoPage(); // Go to profile setup if first name is missing
                  } else {
                    return  GameMenuScreen(); // Go to Dashboard if profile is complete
                  }
                } else {
                  return  GameMenuScreen(); // If error, go to Dashboard
                }
              },
            );
          } else {
            return const LoginPage(); // If no user, show login page
          }
        } else {
          return const LoginPage(); // If no user is logged in, show login page
        }
      },
    );
  }
}