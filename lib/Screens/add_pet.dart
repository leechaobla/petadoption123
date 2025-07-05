import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddPetScreen extends StatefulWidget {
  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final breedCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();

  String type = 'Dog';
  String gender = 'Male';

  File? imageFile;
  final picker = ImagePicker();
  bool loading = false;

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => imageFile = File(picked.path));
    }
  }

  Future<void> uploadPet() async {
    if (!_formKey.currentState!.validate() || imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all fields and pick an image")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final username = userDoc.data()?['username'] ?? 'Unknown';

      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance.ref().child('pet_images/$fileName.jpg');
      await ref.putFile(imageFile!);
      final imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('pets').add({
        'name': nameCtrl.text.trim(),
        'breed': breedCtrl.text.trim(),
        'location': locationCtrl.text.trim(),
        'age': ageCtrl.text.trim(),
        'gender': gender,
        'description': descriptionCtrl.text.trim(),
        'type': type,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.now(),
        'postedBy': username,
        'status': 'Available',
        'userId': user.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pet listed successfully!")),
      );

      await Future.delayed(Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload pet: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add New Pet")),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: "Pet Name"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return "Name is required";
                  if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) return "Only letters allowed";
                  if (value.trim().length < 2) return "Too short";
                  return null;
                },
              ),
              TextFormField(
                controller: breedCtrl,
                decoration: InputDecoration(labelText: "Breed"),
                validator: (value) => value == null || value.trim().isEmpty ? "Breed is required" : null,
              ),
              TextFormField(
                controller: locationCtrl,
                decoration: InputDecoration(labelText: "Location"),
                validator: (value) => value == null || value.trim().isEmpty ? "Location is required" : null,
              ),
              TextFormField(
                controller: ageCtrl,
                decoration: InputDecoration(labelText: "Age (in years)"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return "Age is required";
                  if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) return "Age must be a number";
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: gender,
                decoration: InputDecoration(labelText: "Gender"),
                items: ['Male', 'Female']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) => setState(() => gender = val!),
                validator: (value) => value == null ? "Please select gender" : null,
              ),
              DropdownButtonFormField<String>(
                value: type,
                decoration: InputDecoration(labelText: "Type"),
                items: ['Dog', 'Cat', 'Rabbit', 'Other']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (val) => setState(() => type = val!),
                validator: (value) => value == null ? "Please select type" : null,
              ),
              TextFormField(
                controller: descriptionCtrl,
                decoration: InputDecoration(labelText: "Description"),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return "Description is required";
                  if (value.trim().length < 10) return "Too short – add more details";
                  return null;
                },
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: imageFile != null
                      ? Image.file(imageFile!, fit: BoxFit.cover)
                      : Text("Tap to pick image"),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: uploadPet,
                child: Text("Submit Pet"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
