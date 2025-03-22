// Add to your imports
import 'package:flutter_dotenv/flutter_dotenv.dart' as dotenv;

// Add these properties to your _TravelEmissions_CalculatorState class
late GeminiInsightsService _geminiService;
late EmissionFactorService _emissionFactorService;
String _insightsText = 'Tap "Generate Insights" to get personalized advice.';
bool _isLoadingInsights = false;
DateTime? _lastEmissionFactorUpdate;

// Add this to initState()
@override
void initState() {
  super.initState();
  _loadApiKeys();
  _loadCalculations();
  _loadTarget();
  _loadPoints();
  _loadLastEmissionFactorUpdate();
  _scheduleFirebaseUpload();
  _scheduleWeeklyGraphGeneration();
  _updateRewardStatus();
}

// Add these methods to your class
Future<void> _loadApiKeys() async {
  await dotenv.load();
  String geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  String emissionsApiKey = dotenv.env['EMISSIONS_API_KEY'] ?? '';
  
  _geminiService = GeminiInsightsService(geminiApiKey);
  _emissionFactorService = EmissionFactorService(emissionsApiKey);
  
  // Schedule weekly emission factor updates
  _emissionFactorService.scheduleWeeklyEmissionFactorUpdates((updatedFactors) {
    setState(() {
      emissionsPerKm = updatedFactors;
      _lastEmissionFactorUpdate = DateTime.now();
      _saveLastEmissionFactorUpdate();
    });
    
    // Show a notification to the user that emission factors were updated
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Emission factors have been updated with the latest data!'),
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            _showEmissionFactorsDialog();
          },
        ),
      ),
    );
  });
}

Future<void> _generateInsights() async {
  if (_calculations.isEmpty) {
    setState(() {
      _insightsText = 'No travel data available yet. Make some calculations first!';
    });
    return;
  }
  
  setState(() {
    _isLoadingInsights = true;
    _insightsText = 'Generating insights...';
  });
  
  try {
    double target = double.tryParse(_target) ?? 100.0;
    String insights = await _geminiService.generateInsights(
      _calculations, 
      _totalEmissions,
      target
    );
    
    setState(() {
      _insightsText = insights;
      _isLoadingInsights = false;
    });
  } catch (e) {
    setState(() {
      _insightsText = 'Error generating insights. Please try again later.';
      _isLoadingInsights = false;
    });
    print('Error in generating insights: $e');
  }
}

void _showEmissionFactorsDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Current Emission Factors'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: emissionsPerKm.keys.length,
            itemBuilder: (context, index) {
              String vehicle = emissionsPerKm.keys.elementAt(index);
              Map<String, double> fuelMap = emissionsPerKm[vehicle]!;
              
              return ExpansionTile(
                title: Text(vehicle),
                children: fuelMap.entries.map((entry) {
                  return ListTile(
                    title: Text(entry.key.split(' (')[0]),
                    subtitle: Text('${entry.value} kg CO2e per km'),
                  );
                }).toList(),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() {
                _isLoadingInsights = true;
              });
              
              // Force an update of emission factors
              Map<String, Map<String, double>>? updated = 
                  await _emissionFactorService.updateEmissionFactors();
              
              setState(() {
                if (updated != null) {
                  emissionsPerKm = updated;
                  _lastEmissionFactorUpdate = DateTime.now();
                  _saveLastEmissionFactorUpdate();
                }
                _isLoadingInsights = false;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(updated != null 
                    ? 'Emission factors updated successfully!' 
                    : 'Could not update emission factors. Will try again later.'),
                ),
              );
            },
            child: Text('Refresh Now'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Close'),
          ),
        ],
      );
    },
  );
}

Future<void> _loadLastEmissionFactorUpdate() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? lastUpdateStr = prefs.getString('last_emission_factor_update');
  if (lastUpdateStr != null) {
    setState(() {
      _lastEmissionFactorUpdate = DateTime.parse(lastUpdateStr);
    });
  }
}

Future<void> _saveLastEmissionFactorUpdate() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if (_lastEmissionFactorUpdate != null) {
    await prefs.setString('last_emission_factor_update', _lastEmissionFactorUpdate!.toIso8601String());
  }
}

// Add this UI section to your build method, before the calculation history section
Widget _buildInsightsSection() {
  return Card(
    elevation: 4,
    margin: EdgeInsets.symmetric(vertical: 16),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Travel Insights',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_lastEmissionFactorUpdate != null)
                Tooltip(
                  message: 'Emission factors last updated on ${DateFormat('yyyy-MM-dd').format(_lastEmissionFactorUpdate!)}',
                  child: InkWell(
                    onTap: _showEmissionFactorsDialog,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          'Factors',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: _isLoadingInsights
                ? Center(child: CircularProgressIndicator())
                : Text(_insightsText),
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(Icons.lightbulb_outline),
              label: Text('Generate Insights'),
              onPressed: _generateInsights,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[700],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}