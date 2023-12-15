import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';

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
  bool showingWarning =
      false; // Variable to keep track if the warning popup is showing

  final player = AudioPlayer();

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

    // Check if the distance is less than or equal to 5
    if (data.isNotEmpty && data.last.distance <= 6 && !showingWarning) {
      // Only show the warning popup and play the tune if the distance is less than or equal to 5
      showWarningPopup();
    } else if (data.isNotEmpty && data.last.distance > 6 && showingWarning) {
      // If distance is greater than 5 and warning popup is showing, close the popup
      closeWarningPopup();
    }
  }

  void showWarningPopup() async {
    setState(() {
      showingWarning = true;
    });

    // Play the warning tune before showing the alert dialog.
    try {
      await player.setAsset('assets/Horn.mp3');
      await player.play();
    } catch (e) {
      print('Error while playing audio: $e');
      // Handle the error as needed
    }

    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent users from dismissing the popup by tapping outside
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async =>
              false, // Disable the back button while the popup is showing
          child: AlertDialog(
            title: Text('Warning'),
            content: Text('Motor bnd kr do.'),
            actions: [
              TextButton(
                onPressed: () async {
                  // Stop the warning tune, close the dialog, and dispose of the player.
                  await player.stop();
                  player.dispose();
                  Navigator.of(context).pop();
                  setState(() {
                    showingWarning = false;
                  });
                },
                child: Text('OK'),
              ),
              TextButton(
                onPressed: () async {
                  // Stop the warning tune and close the dialog, but keep the player for potential future warnings.
                  await player.stop();
                  Navigator.of(context).pop();
                  setState(() {
                    showingWarning = false;
                  });
                },
                child: Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  void closeWarningPopup() {
    setState(() {
      showingWarning = false;
    });
    player.stop();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
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
