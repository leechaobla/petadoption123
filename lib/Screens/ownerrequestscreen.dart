import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OwnerRequestsScreen extends StatefulWidget {
  @override
  _OwnerRequestsScreenState createState() => _OwnerRequestsScreenState();
}

class _OwnerRequestsScreenState extends State<OwnerRequestsScreen> {
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> updateRequestStatus(String requestId, String status, String petId) async {
    final firestore = FirebaseFirestore.instance;

    try {
      await firestore.collection('adoption_requests').doc(requestId).update({
        'status': status,
      });

      if (status == 'approved') {
        await firestore.collection('pets').doc(petId).update({
          'status': 'adopted',
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Request marked as $status.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update request: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        body: Center(child: Text("You must be logged in to view requests.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Adoption Requests"),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('adoption_requests')
            .where('petOwnerId', isEqualTo: currentUser!.uid)
            .orderBy('requestedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Log the error to Logcat
            print('🔥 Firestore error: ${snapshot.error}');
            return Center(child: Text("An error occurred: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }


          final requests = snapshot.data?.docs ?? [];

          if (requests.isEmpty) {
            return Center(child: Text("No adoption requests found."));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data() as Map<String, dynamic>;

              final petName = data['petName'] ?? 'Unknown';
              final userName = data['userName'] ?? 'Unknown';
              final userPhone = data['userPhone'] ?? 'Unknown';
              final message = data['message'] ?? '';
              final status = data['status'] ?? 'pending';
              final petId = data['petId'];
              final timestamp = data['requestedAt'] as Timestamp?;
              final formattedDate = timestamp != null
                  ? DateFormat.yMd().add_jm().format(timestamp.toDate())
                  : 'Unknown date';

              return Card(
                margin: EdgeInsets.all(12),
                child: ListTile(
                  title: Text("Pet: $petName"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("From: $userName ($userPhone)"),
                      SizedBox(height: 4),
                      Text("Message: $message"),
                      Text(
                        "Status: $status",
                        style: TextStyle(
                          color: status == 'pending'
                              ? Colors.orange
                              : status == 'approved'
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text("Requested: $formattedDate", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: status == 'pending' && petId != null
                      ? PopupMenuButton<String>(
                    onSelected: (value) => updateRequestStatus(doc.id, value, petId),
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'approved', child: Text("Approve")),
                      PopupMenuItem(value: 'rejected', child: Text("Reject")),
                    ],
                    icon: Icon(Icons.more_vert),
                  )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
