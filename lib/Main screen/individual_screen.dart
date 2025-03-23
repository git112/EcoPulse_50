import 'package:flutter/material.dart';
import 'package:flutter_application_2/travel.dart';
import 'package:flutter_application_2/energy.dart';

// Main screen with categories
class ClimateActionsScreen extends StatelessWidget {
  // List of categories with their details and image paths
  final List<Map<String, String>> categories = [
    {
      "title": "Travel",
      "description": "Track your transportation emissions",
      "image":
          "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80",
      "isLocal": "false",
    },
    {
      "title": "Energy",
      "description": "Monitor your energy consumption",
      "image":
          "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80",
      "isLocal": "false",
    },
    
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/background.jpg"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ACTIONS",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Choose a category to take your next climate action!",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return CategoryCard(
                      title: categories[index]["title"]!,
                      description: categories[index]["description"]!,
                      imageUrl: categories[index]["image"]!,
                      isLocal: categories[index]["isLocal"] == "true",
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryCard extends StatefulWidget {
  final String title;
  final String description;
  final String imageUrl;
  final bool isLocal;

  const CategoryCard({
    Key? key,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.isLocal,
  }) : super(key: key);

  @override
  _CategoryCardState createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: InkWell(
          onTap: () {
            if (widget.title == "Travel") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TravelEmissions_Calculator(),
                ),
              );
            } else if (widget.title == "Energy") {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EnergyUsageCalculator(),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: widget.isLocal
                        ? Image.asset(widget.imageUrl, fit: BoxFit.cover)
                        : Image.network(widget.imageUrl, fit: BoxFit.cover),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.description,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
