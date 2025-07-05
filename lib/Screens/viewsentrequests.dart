import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SentRequestsScreen extends StatefulWidget {
  @override
  _SentRequestsScreenState createState() => _SentRequestsScreenState();
}

class _SentRequestsScreenState extends State<SentRequestsScreen> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Center(
        child: Text("Please log in to view your adoption requests."),
      );
    }

    final requestStream = FirebaseFirestore.instance
        .collection('adoption_requests')
        .where('userId', isEqualTo: user!.uid)
        .orderBy('requestedAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: requestStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final error = snapshot.error.toString();
          debugPrint("🔥 Firestore Error: $error");

          if (error.contains('FAILED_PRECONDITION') && error.contains('indexes')) {
            final indexLinkStart = error.indexOf('https://');
            final indexLinkEnd = error.indexOf(')', indexLinkStart);
            final indexUrl = indexLinkEnd != -1
                ? error.substring(indexLinkStart, indexLinkEnd)
                : error.substring(indexLinkStart);

            debugPrint('⚠️ Required index: $indexUrl');
          }

          return Center(child: Text("Error occurred: check console logs."));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(child: Text("You haven’t sent any requests yet."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final requestedAt = (data['requestedAt'] as Timestamp?)?.toDate();
            final formattedDate = requestedAt != null
                ? DateFormat.yMMMd().add_jm().format(requestedAt)
                : 'Unknown';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text("Pet: ${data['petName'] ?? 'Unknown'}"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data['message'] != null) Text("Message: ${data['message']}"),
                    Text(
                      "Status: ${data['status'] ?? 'N/A'}",
                      style: TextStyle(
                        color: data['status'] == 'approved'
                            ? Colors.green
                            : data['status'] == 'rejected'
                            ? Colors.red
                            : Colors.orange,
                      ),
                    ),
                    Text("Sent on: $formattedDate", style: TextStyle(fontSize: 12)),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}
