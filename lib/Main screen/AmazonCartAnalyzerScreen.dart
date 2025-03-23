import 'dart:convert';
import 'package:flutter/material.dart';



class RecipeSearchScreen extends StatefulWidget {
  @override
  _RecipeSearchScreenState createState() => _RecipeSearchScreenState();
}

class _RecipeSearchScreenState extends State<RecipeSearchScreen> {
  List<Map<String, dynamic>> recipes = [];
  List<Map<String, dynamic>> filteredRecipes = [];
  TextEditingController ingredientController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadRecipes();
  }

  // Load static JSON data instead of reading from a file
  void loadRecipes() {
    String jsonString = '''
    [
      {
        "name": "Vegetable Stir-Fry",
        "ingredients": ["carrot", "broccoli", "onion", "garlic"],
        "carbon_footprint": 0.3
      },
      {
        "name": "Lentil Soup",
        "ingredients": ["lentils", "tomato", "onion", "garlic"],
        "carbon_footprint": 0.2
      },
      {
        "name": "Quinoa Salad",
        "ingredients": ["quinoa", "cucumber", "tomato", "olive oil"],
        "carbon_footprint": 0.25
      }
    ]
    ''';

    List<dynamic> jsonData = json.decode(jsonString);
    setState(() {
      recipes = jsonData.cast<Map<String, dynamic>>();
    });
  }

  // Filter recipes based on user input
  void searchRecipes() {
    List<String> inputIngredients = ingredientController.text.toLowerCase().split(',').map((e) => e.trim()).toList();

    setState(() {
      filteredRecipes = recipes.where((recipe) {
        List<String> recipeIngredients = List<String>.from(recipe['ingredients']);
        return inputIngredients.every((ingredient) => recipeIngredients.contains(ingredient));
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Find Low-Carbon Recipes")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: ingredientController,
              decoration: InputDecoration(
                labelText: "Enter available ingredients (comma separated)",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(onPressed: searchRecipes, child: Text("Search Recipes")),
            Expanded(
              child: ListView.builder(
                itemCount: filteredRecipes.length,
                itemBuilder: (context, index) {
                  var recipe = filteredRecipes[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(recipe['name']),
                      subtitle: Text("CO2 Footprint: ${recipe['carbon_footprint']} kg"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}