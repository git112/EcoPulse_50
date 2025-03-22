import 'package:flutter/material.dart';

// Main screen with categories
class ClimateActionsScreen extends StatelessWidget {
  // List of categories with their details and image paths
  final List<Map<String, String>> categories = [
    {
      "title": "Travel",
      "description": "Track your transportation emissions",
      "image":
          "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80", // New Unsplash image for Travel (airplane wing with clouds)
      "isLocal": "false", // Network image
    },
    {
      "title": "Energy",
      "description": "Monitor your energy consumption",
      "image":
          "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80", // House with solar panels
      "isLocal": "false",
    },
    {
      "title": "Food",
      "description": "Measure your dietary impact",
      "image":
          "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80", // Bowl of food
      "isLocal": "false",
    },
    {
      "title": "Waste",
      "description": "Calculate your waste footprint",
      "image":
          "https://images.unsplash.com/photo-1604187351574-c75ca79f5807?ixlib=rb-4.0.3&auto=format&fit=crop&w=1350&q=80", // Recycling bins
      "isLocal": "false",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with app name, background image, and profile icon
            Stack(
              children: [
                // Background image
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/background.jpg"), // Local image
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Header content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "ECOPULSE",
                        style: TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white.withOpacity(0.8),
                        child: Icon(Icons.person, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Actions section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
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
            // Categories list
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

// Widget for each category card
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
            // Navigate to FinalPage when the card is tapped
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FinalPage(category: widget.title),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Category image with error handling
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[200], // Placeholder background
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child:
                        widget.isLocal
                            ? Image.asset(
                              widget.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey[400],
                                    size: 30,
                                  ),
                                );
                              },
                            )
                            : Image.network(
                              widget.imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (
                                context,
                                child,
                                loadingProgress,
                              ) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                (loadingProgress
                                                        .expectedTotalBytes ??
                                                    1)
                                            : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey[400],
                                    size: 30,
                                  ),
                                );
                              },
                            ),
                  ),
                ),
                SizedBox(width: 16),
                // Category title and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.description,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Arrow button with hover effect
                MouseRegion(
                  onEnter: (_) => setState(() => _isHovered = true),
                  onExit: (_) => setState(() => _isHovered = false),
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to FinalPage when the button is tapped
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => FinalPage(category: widget.title),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _isHovered
                                ? Colors.grey[300]
                                : Colors.grey[200], // Change color on hover
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey[600],
                          size: 16,
                        ),
                        onPressed: () {
                          // This is handled by GestureDetector above
                        },
                      ),
                    ),
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

// Final page to display after clicking a category
class FinalPage extends StatelessWidget {
  final String category;

  const FinalPage({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category), backgroundColor: Colors.green[700]),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Welcome to the $category Section!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                "Here you can take actions to reduce your $category-related carbon footprint.",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Go back to the previous screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: Text(
                  "Go Back",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
