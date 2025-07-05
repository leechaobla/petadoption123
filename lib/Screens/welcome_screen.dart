import 'package:flutter/material.dart';
import 'package:untitled/Screens/Auth/login.dart';
import 'package:untitled/Screens/Auth/register.dart';

class WelcomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets, size: 100, color: Colors.teal),
            SizedBox(height: 24),
            Text(
              'Welcome to PetAdopt 🐾',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Find your next furry friend today!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                minimumSize: Size(double.infinity, 48),
              ),
              child: Text('Login'),
            ),

            SizedBox(height: 12),

            OutlinedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen()));
              },
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
