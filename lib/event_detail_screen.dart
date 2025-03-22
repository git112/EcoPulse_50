import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;

  EventDetailScreen({required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Details'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('events').doc(eventId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Event not found.'));
          }

          final eventData = snapshot.data!.data() as Map<String, dynamic>;
          final participants = List<String>.from(eventData['participants'] ?? []);

          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eventData['title'],
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'Description: ${eventData['description']}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'Date & Time: ${DateFormat('yyyy-MM-dd HH:mm').format(eventData['dateTime'].toDate())}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'Location: ${eventData['location']}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 16),
                Text(
                  'Participants: ${participants.length}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      if (userId != null && !participants.contains(userId)) {
                        await FirebaseFirestore.instance
                            .collection('events')
                            .doc(eventId)
                            .update({
                          'participants': FieldValue.arrayUnion([userId]),
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Joined the event!')),
                        );
                      } else if (participants.contains(userId)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('You have already joined this event.')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    ),
                    child: Text(
                      'Join Event',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}