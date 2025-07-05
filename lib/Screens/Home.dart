import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled/Screens/add_pet.dart';
import 'package:untitled/Screens/pet_detail.dart';
import 'package:untitled/Screens/profile.dart';
import 'package:untitled/Screens/saved_pets_screen.dart';
import 'package:untitled/Screens/viewsentrequests.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<String> categories = ['All', 'Dog', 'Cat', 'Rabbit'];
  String selectedCategory = 'All';
  String? username;

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Future<void> fetchUsername() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          username = userDoc['username'];
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUsername();
  }

  Widget _buildHomeTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (username != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Welcome back, $username!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        // Category Chips
        SizedBox(
          height: 45,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = categories[index];
              final selected = selectedCategory == category;
              return ChoiceChip(
                label: Text(category),
                selected: selected,
                onSelected: (_) => setState(() => selectedCategory = category),
                selectedColor: Colors.teal,
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // Pet Cards
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: selectedCategory == 'All'
                ? FirebaseFirestore.instance
                .collection('pets')
                .where('status', isEqualTo: 'Available')
                .snapshots()
                : FirebaseFirestore.instance
                .collection('pets')
                .where('status', isEqualTo: 'Available')
                .where('type', isEqualTo: selectedCategory)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No pets found."));
              }

              final pets = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: pets.length,
                itemBuilder: (context, index) {
                  final doc = pets[index];
                  final pet = {
                    ...doc.data() as Map<String, dynamic>,
                    'id': doc.id,
                  };

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          pet['imageUrl'] ?? '',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                          const Icon(Icons.pets),
                        ),
                      ),
                      title: Text(pet['name'] ?? 'Unnamed'),
                      subtitle: Text(
                          "${pet['breed'] ?? ''} • ${pet['location'] ?? ''}"),
                      trailing:
                      const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PetDetailScreen(petData: pet),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesTab() => SavedPetsScreen();

  Widget _buildSentRequestsTab() => SentRequestsScreen();

  Widget _buildProfileTab() => ProfileScreen();

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildHomeTab(),
      _buildFavoritesTab(),
      _buildSentRequestsTab(),
      _buildProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('PetAdopt'),
        backgroundColor: Colors.teal,
      ),
      body: tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.teal,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Saved"),
          BottomNavigationBarItem(icon: Icon(Icons.send), label: "Requests"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddPetScreen()),
          );
        },
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add),
        label: const Text("List a Pet for Adoption"),
      )
          : null,
    );
  }
}
