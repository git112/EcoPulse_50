import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_event_screen.dart';
import 'event_detail_screen.dart';

class EventListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Eco-Friendly Events'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .orderBy('dateTime', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No events found. Create one!'));
          }

          final events = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(8.0),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final eventData = event.data() as Map<String, dynamic>;
              final participants = List<String>.from(eventData['participants'] ?? []);

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text(
                    eventData['title'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Date: ${eventData['dateTime'].toDate().toString().split('.')[0]}\n'
                    'Location: ${eventData['location']}\n'
                    'Participants: ${participants.length}',
                  ),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      if (userId != null && !participants.contains(userId)) {
                        await FirebaseFirestore.instance
                            .collection('events')
                            .doc(event.id)
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
                    child: Text('Join'),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailScreen(eventId: event.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateEventScreen()),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Create Event',
      ),
    );
  }
}