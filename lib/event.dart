class Event {
  final String id; // Firestore document ID
  final String title;
  final String description;
  final String location;
  final String date;
  final String time;
  final String creatorEmail;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.time,
    required this.creatorEmail,
  });

  // Convert Event object to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'date': date,
      'time': time,
      'creatorEmail': creatorEmail,
    };
  }

  // Create an Event object from a Firestore document
  factory Event.fromDocument(Map<String, dynamic> doc, String id) {
    return Event(
      id: id,
      title: doc['title'] ?? '',
      description: doc['description'] ?? '',
      location: doc['location'] ?? '',
      date: doc['date'] ?? '',
      time: doc['time'] ?? '',
      creatorEmail: doc['creatorEmail'] ?? '',
    );
  }
}