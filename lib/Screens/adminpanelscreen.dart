import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminPanelScreen extends StatefulWidget {
  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  Future<void> updateRequestStatus(String requestId, String status, String petId) async {
    final firestore = FirebaseFirestore.instance;

    await firestore.collection('adoption_requests').doc(requestId).update({'status': status});

    if (status == 'approved') {
      await firestore.collection('pets').doc(petId).update({'status': 'Adopted'});
    }
  }

  Future<void> deletePet(String petId) async {
    await FirebaseFirestore.instance.collection('pets').doc(petId).delete();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Pet post deleted.")));
  }

  void showRequestDetails(Map<String, dynamic> data, String requestId) async {
    final petDoc = await FirebaseFirestore.instance.collection('pets').doc(data['petId']).get();
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(data['userId']).get();

    final petName = petDoc.exists ? petDoc['name'] ?? 'Unknown' : 'Unknown';
    final userName = userDoc.exists ? userDoc['username'] ?? 'Unknown' : 'Unknown';

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          children: [
            Text("Adoption Request Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text("Pet Name: $petName"),
            Text("User Name: $userName"),
            Text("Phone: ${userDoc['phone'] ?? 'Unknown'}"),
            SizedBox(height: 10),
            Text("Message: ${data['message'] ?? 'No message'}"),
            Text("Status: ${data['status'] ?? 'pending'}"),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.check),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () async {
                    Navigator.pop(context);
                    await updateRequestStatus(requestId, 'approved', data['petId']);
                  },
                  label: Text("Approve"),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.close),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    Navigator.pop(context);
                    await updateRequestStatus(requestId, 'rejected', data['petId']);
                  },
                  label: Text("Reject"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget buildRequestList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('adoption_requests')
          .orderBy('requestedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        final requests = snapshot.data!.docs;
        if (requests.isEmpty) return Center(child: Text("No adoption requests."));

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final data = requests[index].data() as Map<String, dynamic>;
            final requestId = requests[index].id;

            return FutureBuilder(
              future: Future.wait([
                FirebaseFirestore.instance.collection('pets').doc(data['petId']).get(),
                FirebaseFirestore.instance.collection('users').doc(data['userId']).get(),
              ]),
              builder: (context, AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
                if (!snapshot.hasData) return ListTile(title: Text("Loading..."));

                final pet = snapshot.data![0];
                final user = snapshot.data![1];

                return Card(
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    title: Text("Pet: ${pet['name'] ?? 'Unknown'}"),
                    subtitle: Text("User: ${user['username'] ?? 'Unknown'}\nStatus: ${data['status']}"),
                    trailing: Icon(Icons.info_outline),
                    onTap: () => showRequestDetails(data, requestId),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget buildPetList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('pets').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        final pets = snapshot.data!.docs;
        if (pets.isEmpty) return Center(child: Text("No pets posted."));

        return ListView.builder(
          itemCount: pets.length,
          itemBuilder: (context, index) {
            final data = pets[index].data() as Map<String, dynamic>;
            final petId = pets[index].id;

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(data['imageUrl'] ?? ''),
                ),
                title: Text(data['name'] ?? 'Unnamed Pet'),
                subtitle: Text("Type: ${data['type'] ?? ''} • Status: ${data['status'] ?? ''}"),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final confirm = await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text("Delete Pet"),
                        content: Text("Are you sure you want to delete this pet?"),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("Cancel")),
                          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text("Delete")),
                        ],
                      ),
                    );
                    if (confirm == true) await deletePet(petId);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Panel"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: logout,
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.assignment), text: "Requests"),
            Tab(icon: Icon(Icons.pets), text: "Pet Posts"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildRequestList(),
          buildPetList(),
        ],
      ),
    );
  }
}
