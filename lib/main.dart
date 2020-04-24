import 'dart:isolate';
import 'dart:ui';

import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './constants.dart';
import './widgets/wifistatus.dart';

/// Global [SharedPreferences] object.
SharedPreferences prefs;

/// A port of the UI isolate to receive messages
final ReceivePort port = ReceivePort();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register the UI isolate's SendPort to allow for communication from the
  // background isolate.
  IsolateNameServer.registerPortWithName(
    port.sendPort,
    isolateName,
  );

  prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey(keyNapCount)) {
    await prefs.setInt(keyNapCount, defaultNapCount);
  }
  //await prefs.setInt(keyNapCount, defaultNapCount);
  if (!prefs.containsKey(keyCounter)) {
    await prefs.setInt(keyCounter, 0);
  }

  await AndroidAlarmManager.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'WiFi Nap'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Container(
        alignment: Alignment.center,
        child: WiFiStatus(),
      ),
    );
  }
}
