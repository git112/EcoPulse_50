import 'package:flutter/material.dart';
import 'package:flutter_application_2/Main%20screen/individual_screen.dart';
import 'package:flutter_application_2/Organizational.dart';
import 'package:flutter_application_2/user_info_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  _UserDashboardScreenState createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen (DashboardScreen)
          },
        ),
        title: const SizedBox.shrink(), // Remove the title text
        backgroundColor: const Color.fromARGB(255, 70, 173, 89), // Match the color from your code
        actions: [
          // Add the person icon in a circular container at the top-right corner, make it clickable
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                // Navigate to UserInfoScreen when the person icon is clicked
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserInfoScreen()),
                );
              },
              child: const CircleAvatar(
                backgroundColor: Colors.white,
                radius: 18, // Adjust the size of the circle
                child: Icon(
                  Icons.person,
                  color: Color.fromARGB(255, 12, 119, 31), // Match the app's theme color
                  size: 24, // Adjust the size of the icon
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white, // Underline color for the selected tab
          indicatorWeight: 3.0, // Thickness of the underline
          tabs: const [
            Tab(text: 'Individual'),
            Tab(text: 'Organization'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Individual tab content
           ClimateActionsScreen(),
          // Organization tab content (placeholder)
          OrganizationalEmissionsCalculator(),
        ],
      ),
    );
  }
}