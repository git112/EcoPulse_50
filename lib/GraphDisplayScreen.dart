import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// New screen to display graphs

// Graph display screen
class GraphDisplayScreen extends StatefulWidget {
  final String graphType;

  GraphDisplayScreen({required this.graphType});

  @override
  _GraphDisplayScreenState createState() => _GraphDisplayScreenState();
}

class _GraphDisplayScreenState extends State<GraphDisplayScreen> {
  List<File> _graphFiles = [];

  @override
  void initState() {
    super.initState();
    _loadGraphFiles();
  }

  Future<void> _loadGraphFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      print("Looking for graphs in directory: ${directory.path}");
      final files = Directory(directory.path).listSync();
      setState(() {
        _graphFiles = files
            .where((file) => file is File && file.path.endsWith('.png'))
            .where((file) => file.path.contains(widget.graphType))
            .map((file) {
              print("Found graph file: ${file.path}");
              return File(file.path);
            })
            .toList();
        _graphFiles.sort((a, b) => b.path.compareTo(a.path));
        print("Total ${widget.graphType} graphs found: ${_graphFiles.length}");
      });
    } catch (e) {
      print("Error loading graph files: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.graphType == 'daily' ? 'Daily' : 'Weekly'} Graphs'),
        backgroundColor: Colors.blue[900],
      ),
      body: _graphFiles.isEmpty
          ? Center(child: Text('No ${widget.graphType} graphs available. Try generating graphs for past data.'))
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _graphFiles.length,
              itemBuilder: (context, index) {
                final file = _graphFiles[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          file.path.split('/').last,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Image.file(
                        file,
                        height: 300,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          print("Error loading image ${file.path}: $error");
                          return Text('Error loading graph: $error');
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}