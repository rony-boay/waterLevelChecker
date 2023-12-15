import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';

const String firebaseDatabaseURL =
    'https://water-level-checker-default-rtdb.firebaseio.com/';

class DistanceData {
  final DateTime time;
  final double distance;

  DistanceData(this.time, this.distance);
}

class DistanceApp extends StatefulWidget {
  @override
  _DistanceAppState createState() => _DistanceAppState();
}

class _DistanceAppState extends State<DistanceApp> {
  List<DistanceData> data = [];
  DateTime? connectedTime;

  // Define the audioPlayer variable
  AudioPlayer audioPlayer = AudioPlayer();
  @override
  void initState() {
    super.initState();
    connectToWiFi();
    Timer.periodic(Duration(seconds: 1), (_) => fetchData());
  }

  void connectToWiFi() {
    // Connect to Wi-Fi here and set the connectedTime variable
    setState(() {
      connectedTime = DateTime.now();
    });
    print('Connected to Wi-Fi at $connectedTime');
  }

  void fetchData() async {
    final response =
        await http.get(Uri.parse('$firebaseDatabaseURL/distance.json'));
    if (response.statusCode == 200) {
      final jsonResponse = response.body;
      if (jsonResponse != null) {
        if (jsonResponse.startsWith('{') && jsonResponse.endsWith('}')) {
          // Valid JSON object response
          final Map<String, dynamic> json = jsonDecode(jsonResponse);
          final List<DistanceData> fetchedData = json.entries
              .map((entry) => DistanceData(
                  DateTime.parse(entry.key), entry.value as double))
              .toList();
          setState(() {
            if (data.isEmpty ||
                data.last.distance != fetchedData.last.distance) {
              // Only update the distance and connected time if the value has changed
              data = fetchedData;
              connectedTime = DateTime.now();
            }
          });
        } else {
          // Single value response
          final double? distance = double.tryParse(jsonResponse);
          if (distance != null) {
            setState(() {
              if (data.isEmpty || data.last.distance != distance) {
                // Only update the distance and connected time if the value has changed
                data = [DistanceData(DateTime.now(), distance as double)];
                connectedTime = DateTime.now();
              }
            });
          } else {
            print('Invalid JSON response: $jsonResponse');
          }
        }
      } else {
        print('Empty response');
      }
    } else {
      print('HTTP request failed with status: ${response.statusCode}');
    }
    setState(() {
      if (data.isNotEmpty && data.last.distance <= 10) {
        // Only show the warning popup and play the tune if the distance is less than or equal to 10
        showWarningPopup();
      }
    });
  }

  void showWarningPopup() async {
    // Play the warning tune before showing the alert dialog.
    await audioPlayer
        .play('assets/standard-emergency-warning-signal-sews.mp3' as Source);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Warning'),
          content: Text('The distance is less than or equal to 10.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Water_Level_Checker'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  'Date:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  connectedTime != null
                      ? DateFormat('yyyy-MM-dd').format(connectedTime!)
                      : 'Not connected',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Distance:',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            '${data.isNotEmpty ? data.last.distance.toStringAsFixed(1) : '0.0'} in',
            style: TextStyle(fontSize: 78),
          ),
          SizedBox(height: 20),
          Text(
            'Time:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            connectedTime != null
                ? DateFormat('h:mm:ss').format(connectedTime!)
                : 'Not connected',
            style: TextStyle(fontSize: 22),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    title: 'Water_Level_Checker',
    theme: ThemeData(primarySwatch: Colors.blue),
    home: Center(child: DistanceApp()),
  ));
}
