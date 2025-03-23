import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'event.dart';

class JoinedEventsScreen extends StatefulWidget {
  @override
  _JoinedEventsScreenState createState() => _JoinedEventsScreenState();
}

class _JoinedEventsScreenState extends State<JoinedEventsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Event>> _fetchJoinedEvents() async {
    User? user = _auth.currentUser;
    if (user == null) {
      return [];
    }

    List<Event> joinedEvents = [];

    // Fetch the user's joined events
    QuerySnapshot joinedEventsSnapshot = await _firestore
        .collection('user_events')
        .doc(user.uid)
        .collection('joined_events')
        .get();

    // Fetch the event details for each joined event
    for (var doc in joinedEventsSnapshot.docs) {
      String eventId = doc['eventId'];
      DocumentSnapshot eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (eventDoc.exists) {
        Event event = Event.fromDocument(eventDoc.data() as Map<String, dynamic>, eventDoc.id);
        joinedEvents.add(event);
      }
    }

    return joinedEvents;
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

      // Remove user from the event's attendees subcollection
      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('attendees')
          .doc(user.uid)
          .delete();

      // Remove event from the user's joined events
      await _firestore
          .collection('user_events')
          .doc(user.uid)
          .collection('joined_events')
          .doc(eventId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully left the event')),
      );
      setState(() {}); // Refresh the UI
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
        title: Text('My Joined Events'),
        backgroundColor: const Color.fromARGB(255, 70, 173, 89), // Match your app's theme
      ),
      body: FutureBuilder<List<Event>>(
        future: _fetchJoinedEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final joinedEvents = snapshot.data ?? [];

          if (joinedEvents.isEmpty) {
            return Center(child: Text('You haven\'t joined any events yet.'));
          }

          return ListView.builder(
            itemCount: joinedEvents.length,
            itemBuilder: (context, index) {
              final event = joinedEvents[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text('Description: ${event.description}'),
                      Text('Location: ${event.location}'),
                      Text('Date: ${event.date}'),
                      Text('Time: ${event.time}'),
                      Text('Created by: ${event.creatorEmail}'),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _leaveEvent(event.id),
                        child: Text('Leave Event'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
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