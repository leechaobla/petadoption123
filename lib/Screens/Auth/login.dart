import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:untitled/Screens/Auth/register.dart';
import 'package:untitled/Screens/home.dart';
import 'package:untitled/Screens/adminpanelscreen.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final auth = FirebaseAuth.instance;
  bool loading = false;

  bool _navigated = false;

  Future<void> login() async {
    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter both email and password.")),
        );
      }
      return;
    }

    if (mounted) setState(() => loading = true);

    try {
      final userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final userData = userDoc.data();
      print("User Firestore data: $userData");

      final role = userData?['role']?.toString().toLowerCase().trim();
      print("Detected role: $role");

      if (!_navigated && mounted) {
        _navigated = true;

        Future.microtask(() {
          if (!mounted) return;

          if (role == 'admin') {
            print("🟢 Redirecting to Admin Panel");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => AdminPanelScreen()),
            );
          } else {
            print("🔵 Redirecting to Home");
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomeScreen()),
            );
          }
        });
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg = "Login failed.";
        if (e.code == 'user-not-found') {
          msg = "No user found with this email.";
        } else if (e.code == 'wrong-password') {
          msg = "Incorrect password.";
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      print("Login error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: emailCtrl,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passCtrl,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            loading
                ? CircularProgressIndicator()
                : ElevatedButton(onPressed: login, child: Text("Login")),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RegisterScreen()),
                );
              },
              child: Text("Don't have an account? Register"),
            )
          ],
        ),
      ),
    );
  }
}
