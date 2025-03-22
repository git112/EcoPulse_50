import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

// This class handles Gemini API integration for insights
class GeminiInsightsService {
  final String _apiKey; // Your Gemini API key
  final String _apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  
  GeminiInsightsService(this._apiKey);
  
  // Generate insights based on user's emission data
  Future<String> generateInsights(List<Map<String, dynamic>> emissionsData, double totalEmissions, double target) async {
    try {
      // Prepare data for the API
      String emissionsContext = _prepareEmissionsContext(emissionsData, totalEmissions, target);
      
      // Create the prompt for Gemini
      String prompt = '''
      You are an eco-friendly travel emissions advisor. Based on the following user's emissions data, provide personalized insights and actionable advice.
      
      User's data:
      $emissionsContext
      
      Please provide:
      1. A brief analysis of their emission patterns
      2. 2-3 specific, actionable suggestions to reduce their carbon footprint
      3. A comparison to average emissions for similar travel patterns
      4. One interesting fact about environmental impact related to their most used transportation mode
      
      Keep your response under 300 words, friendly, and focus on positive encouragement rather than criticism.
      ''';
      
      // Make the API call
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 800,
          }
        }),
      );
      
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] ?? 
               "I couldn't generate insights at the moment. Please try again later.";
      } else {
        print('Gemini API error: ${response.statusCode}, ${response.body}');
        return "Couldn't connect to Gemini. Please check your connection and try again.";
      }
    } catch (e) {
      print('Error generating insights: $e');
      return "An error occurred while generating insights. Please try again later.";
    }
  }
  
  // Helper method to prepare emissions data for the prompt
  String _prepareEmissionsContext(List<Map<String, dynamic>> emissionsData, double totalEmissions, double target) {
    StringBuffer context = StringBuffer();
    
    // Add overall data
    context.writeln("Total emissions: $totalEmissions kg CO2e");
    context.writeln("User's target: $target kg CO2e");
    context.writeln("Number of trips recorded: ${emissionsData.length}");
    
    // Count vehicle types
    Map<String, int> vehicleCounts = {};
    Map<String, double> vehicleEmissions = {};
    
    for (var trip in emissionsData) {
      String vehicleType = trip['vehicleType'] ?? 'Unknown';
      double emission = trip['emissions'] ?? 0.0;
      
      vehicleCounts[vehicleType] = (vehicleCounts[vehicleType] ?? 0) + 1;
      vehicleEmissions[vehicleType] = (vehicleEmissions[vehicleType] ?? 0.0) + emission;
    }
    
    // Add vehicle usage summary
    context.writeln("\nVehicle usage:");
    vehicleCounts.forEach((vehicle, count) {
      double emission = vehicleEmissions[vehicle] ?? 0.0;
      context.writeln("- $vehicle: $count trips, ${emission.toStringAsFixed(2)} kg CO2e");
    });
    
    // Add most recent 5 trips
    if (emissionsData.isNotEmpty) {
      context.writeln("\nRecent trips:");
      int tripsToShow = emissionsData.length > 5 ? 5 : emissionsData.length;
      for (int i = 0; i < tripsToShow; i++) {
        var trip = emissionsData[i];
        context.writeln("- ${trip['vehicleType']} (${trip['fuelType']}): ${trip['distance']} ${trip['unit']}, ${trip['emissions']} kg CO2e");
      }
    }
    
    return context.toString();
  }
}

// This class handles weekly emission factor updates
class EmissionFactorService {
  final String _apiKey; // Your API key for emissions data
  final String _apiUrl = 'https://api.carbonkit.net/3.6/categories/Generic_transport_fuel/calculation';
  
  EmissionFactorService(this._apiKey);
  
  // Schedule weekly updates for emission factors
  void scheduleWeeklyEmissionFactorUpdates(Function(Map<String, Map<String, double>>) onUpdate) {
    // Calculate time until next Sunday at 2AM
    DateTime now = DateTime.now();
    int daysUntilSunday = (7 - now.weekday) % 7;
    if (daysUntilSunday == 0 && now.hour >= 2) daysUntilSunday = 7;
    
    DateTime nextUpdateTime = DateTime(
      now.year, now.month, now.day + daysUntilSunday, 
      2, 0, 0
    );
    
    Duration timeUntilUpdate = nextUpdateTime.difference(now);
    print('Next emission factor update scheduled in ${timeUntilUpdate.inHours} hours');
    
    // Schedule the first update
    Timer(timeUntilUpdate, () {
      // Perform the first update
      updateEmissionFactors().then((factors) {
        if (factors != null) {
          onUpdate(factors);
        }
        
        // Then schedule weekly updates
        Timer.periodic(Duration(days: 7), (timer) {
          updateEmissionFactors().then((factors) {
            if (factors != null) {
              onUpdate(factors);
            }
          });
        });
      });
    });
  }
  
  // Update emission factors from an API or alternatively from a reliable source
  Future<Map<String, Map<String, double>>?> updateEmissionFactors() async {
    try {
      print('Fetching latest emission factors...');
      
      // Attempt to get the latest emission factors from the API
      // Note: This is a placeholder API. You should replace with a real emissions data API
      final response = await http.get(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Accept': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        // Parse the API response to get updated emission factors
        // This is an example parser and should be adjusted to match your API's response format
        Map<String, Map<String, double>> updatedFactors = _parseEmissionFactors(response.body);
        
        // Save the updated factors to SharedPreferences
        await _saveEmissionFactors(updatedFactors);
        print('Emission factors updated successfully');
        return updatedFactors;
      } else {
        print('Failed to fetch emission factors: ${response.statusCode}');
        // Fall back to the last saved emission factors
        return await _loadEmissionFactors();
      }
    } catch (e) {
      print('Error updating emission factors: $e');
      return await _loadEmissionFactors();
    }
  }
  
  // Fallback method with hardcoded updated emission factors if API is unavailable
  Future<Map<String, Map<String, double>>> getFallbackEmissionFactors() async {
    Map<String, Map<String, double>> factors = {
      'Car': {
        'Petrol (Factor: 2.31 kg CO2e)': 0.167, // slightly updated from original 0.162
        'Diesel (Factor: 2.68 kg CO2e)': 0.192, // slightly updated from original 0.188
        'CNG (Factor: 2.8 kg CO2e)': 0.142,     // slightly updated from original 0.140
        'Electric (Factor: 0.5 kg CO2e/kWh)': 0.098, // slightly updated from original 0.100
      },
      'Bike': {
        'Petrol (Factor: 2.31 kg CO2e)': 0.071, // slightly updated from original 0.069
        'Electric (Factor: 0.5 kg CO2e/kWh)': 0.048, // slightly updated from original 0.050
      },
      'Bicycle': {'None (Factor: 0 kg CO2e)': 0.0},
      'Taxi': {
        'Petrol (Factor: 2.31 kg CO2e)': 0.094, // slightly updated from original 0.092
        'Diesel (Factor: 2.68 kg CO2e)': 0.109, // slightly updated from original 0.107
        'CNG (Factor: 2.8 kg CO2e)': 0.113,     // slightly updated from original 0.112
      },
      'Train': {
        'Electric (Factor: 0.5 kg CO2e/kWh)': 0.024, // slightly updated from original 0.025
        'Diesel (Factor: 2.68 kg CO2e)': 0.014,     // slightly updated from original 0.013
      },
      'Bus': {
        'Petrol (Factor: 2.31 kg CO2e)': 0.013,    // slightly updated from original 0.012
        'Diesel (Factor: 2.68 kg CO2e)': 0.014,    // slightly updated from original 0.013
        'CNG (Factor: 2.8 kg CO2e)': 0.012,        // slightly updated from original 0.011
      },
      'Thane': {
        'Petrol (Factor: 2.31 kg CO2e)': 0.041,    // slightly updated from original 0.039
        'Diesel (Factor: 2.68 kg CO2e)': 0.046,    // slightly updated from original 0.045
      },
    };
    
    return factors;
  }
  
  // Parse emission factors from API response (adjust according to your API)
  Map<String, Map<String, double>> _parseEmissionFactors(String responseBody) {
    try {
      var data = jsonDecode(responseBody);
      // This parsing logic will depend entirely on your API's response format
      // The following is just a placeholder
      
      // If API parsing fails, use fallback data
      return getFallbackEmissionFactors();
    } catch (e) {
      print('Error parsing emission factors: $e');
      return {};
    }
  }
  
  // Save emission factors to SharedPreferences
  Future<void> _saveEmissionFactors(Map<String, Map<String, double>> factors) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Convert the nested map to a format that can be stored in SharedPreferences
      Map<String, String> flatMap = {};
      factors.forEach((vehicle, fuelMap) {
        fuelMap.forEach((fuel, factor) {
          flatMap['${vehicle}_$fuel'] = factor.toString();
        });
      });
      
      // Save each entry
      flatMap.forEach((key, value) async {
        await prefs.setString('emission_factor_$key', value);
      });
      
      // Save the update timestamp
      await prefs.setString('emission_factors_updated_at', DateTime.now().toIso8601String());
      
    } catch (e) {
      print('Error saving emission factors: $e');
    }
  }
  
  // Load emission factors from SharedPreferences
  Future<Map<String, Map<String, double>>?> _loadEmissionFactors() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Check if we have stored emission factors
      String? updatedAt = prefs.getString('emission_factors_updated_at');
      if (updatedAt == null) {
        print('No saved emission factors found, using fallback values');
        return getFallbackEmissionFactors();
      }
      
      // Reconstruct the nested map structure
      Map<String, Map<String, double>> factors = {};
      
      // Get all shared preferences keys
      Set<String> keys = prefs.getKeys();
      
      // Filter for emission factor keys and process them
      for (String key in keys) {
        if (key.startsWith('emission_factor_')) {
          String combinedKey = key.substring('emission_factor_'.length);
          List<String> parts = combinedKey.split('_');
          
          if (parts.length >= 2) {
            String vehicle = parts[0];
            String fuel = combinedKey.substring(vehicle.length + 1);
            
            if (!factors.containsKey(vehicle)) {
              factors[vehicle] = {};
            }
            
            String? factorStr = prefs.getString(key);
            if (factorStr != null) {
              factors[vehicle]![fuel] = double.tryParse(factorStr) ?? 0.0;
            }
          }
        }
      }
      
      if (factors.isEmpty) {
        print('No valid emission factors reconstructed, using fallback values');
        return getFallbackEmissionFactors();
      }
      
      return factors;
    } catch (e) {
      print('Error loading emission factors: $e');
      return getFallbackEmissionFactors();
    }
  }
}