import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'Screens/splashscreen.dart';
import 'Screens/Auth/login.dart';
import 'Screens/home.dart';
import 'Screens/adminpanelscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetAdopt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: SplashScreenWrapper(),
    );
  }
}

class SplashScreenWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show splash while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        }

        // Not logged in
        if (!snapshot.hasData) {
          return LoginScreen();
        }

        // Logged in, now check role in Firestore
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState != ConnectionState.done) {
              return SplashScreen(); // Still loading user data
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return LoginScreen(); // If user doc not found
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final role = userData['role']?.toString().toLowerCase();

            if (role == 'admin') {
              return AdminPanelScreen();
            } else {
              return HomeScreen();
            }
          },
        );
      },
    );
  }
}
