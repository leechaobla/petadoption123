import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PetDetailScreen extends StatefulWidget {
  final Map<String, dynamic> petData;

  const PetDetailScreen({super.key, required this.petData});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  bool isFavorite = false;
  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    checkIfFavorited();
  }

  Future<void> checkIfFavorited() async {
    if (user == null || widget.petData['id'] == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('favorites')
        .doc(widget.petData['id']);

    final doc = await favRef.get();
    if (doc.exists) {
      setState(() => isFavorite = true);
    }
  }

  Future<void> toggleFavorite() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to favorite pets.")),
      );
      return;
    }

    final petId = widget.petData['id'];
    if (petId == null) return;

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('favorites')
        .doc(petId);

    if (isFavorite) {
      await favRef.delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Removed from favorites")),
      );
    } else {
      await favRef.set(widget.petData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Added to favorites")),
      );
    }

    setState(() => isFavorite = !isFavorite);
  }

  void showAdoptionForm(BuildContext context) async {
    final messageCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Prevent requesting your own pet
    if (widget.petData['userId'] == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You cannot adopt your own pet.")),
      );
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (userDoc.exists) {
      nameCtrl.text = userDoc['username'] ?? '';
      phoneCtrl.text = userDoc['phone'] ?? '';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Adoption Request",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                decoration:
                InputDecoration(labelText: "Your Name", border: OutlineInputBorder()),
              ),
              SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                decoration: InputDecoration(
                    labelText: "Phone Number", border: OutlineInputBorder()),
              ),
              SizedBox(height: 10),
              TextField(
                controller: messageCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Why do you want to adopt this pet?",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final phone = phoneCtrl.text.trim();
                  final message = messageCtrl.text.trim();
                  final petId = widget.petData['id'];
                  final petOwnerId = widget.petData['userId'];
                  final petName = widget.petData['name'] ?? 'Unknown';

                  if (name.isEmpty || phone.isEmpty || message.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please fill in all fields.")),
                    );
                    return;
                  }

                  try {
                    await FirebaseFirestore.instance
                        .collection('adoption_requests')
                        .add({
                      'petId': petId,
                      'petName': petName,
                      'userId': currentUser.uid,
                      'userName': name,
                      'userPhone': phone,
                      'message': message,
                      'status': 'pending',
                      'requestedAt': Timestamp.now(),
                      'petOwnerId': petOwnerId,
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Adoption request submitted.")),
                    );
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: ${e.toString()}")),
                    );
                  }
                },
                child: Text("Submit Request"),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final pet = widget.petData;
    final createdAt = pet['createdAt'] != null
        ? (pet['createdAt'] as Timestamp).toDate()
        : null;
    final formattedDate = createdAt != null
        ? DateFormat.yMMMMd().format(createdAt)
        : 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: Text(pet['name'] ?? 'Pet Details'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  pet['imageUrl'] ?? '',
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.pets, size: 100),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              pet['name'] ?? 'Unnamed',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${pet['type'] ?? ''} • ${pet['breed'] ?? ''} • ${pet['gender'] ?? ''} • ${pet['age'] ?? ''} years',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text('Location: ${pet['location'] ?? 'Unknown'}'),
            Text(
              'Status: ${pet['status'] ?? 'Unknown'}',
              style: TextStyle(
                color: (pet['status'] ?? '')
                    .toString()
                    .toLowerCase() ==
                    'available'
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            Text('Posted by: ${pet['postedBy'] ?? 'Unknown'}'),
            Text('Posted on: $formattedDate'),
            const SizedBox(height: 20),
            const Text(
              'About this pet:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(pet['description'] ?? 'No description available.'),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : null,
                  ),
                  label: Text(isFavorite ? 'Unfavorite' : 'Favorite'),
                  onPressed: toggleFavorite,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.pets),
                  label: const Text('Request to Adopt'),
                  onPressed: () => showAdoptionForm(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
