import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'event.dart';

class EventListScreen extends StatefulWidget {
  @override
  _EventListScreenState createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> _hasJoinedEvent(String eventId) async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    DocumentSnapshot attendeeDoc = await _firestore
        .collection('events')
        .doc(eventId)
        .collection('attendees')
        .doc(user.uid)
        .get();
    return attendeeDoc.exists;
  }

  Future<void> _joinEvent(String eventId) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please log in to join an event')),
        );
        return;
      }

      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('attendees')
          .doc(user.uid)
          .set({
        'email': user.email,
        'joinedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully joined the event')),
      );
    } catch (e) {
      print('Error joining event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join event: $e')),
      );
    }
  }

  Future<void> _leaveEvent(String eventId) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please log in to leave an event')),
        );
        return;
      }

      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('attendees')
          .doc(user.uid)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully left the event')),
      );
    } catch (e) {
      print('Error leaving event: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to leave event: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Events'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('events').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data!.docs.map((doc) {
            return Event.fromDocument(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('Description: ${event.description}'),
                      Text('Location: ${event.location}'),
                      Text('Date: ${event.date}'),
                      Text('Time: ${event.time}'),
                      Text('Created by: ${event.creatorEmail}'),
                      SizedBox(height: 8),
                      FutureBuilder<bool>(
                        future: _hasJoinedEvent(event.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          }
                          bool hasJoined = snapshot.data ?? false;
                          return ElevatedButton(
                            onPressed: hasJoined
                                ? () => _leaveEvent(event.id)
                                : () => _joinEvent(event.id),
                            child: Text(hasJoined ? 'Leave Event' : 'Join Event'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}