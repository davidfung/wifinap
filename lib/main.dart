import 'dart:isolate';
import 'dart:ui';

import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import './constants.dart';
import './widgets/wifistatus.dart';

SharedPreferences prefs;
final ReceivePort port = ReceivePort();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Register the UI isolate's SendPort for the alarm isolate to talk to.
  IsolateNameServer.registerPortWithName(
    port.sendPort,
    isolateName,
  );

  prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey(keyTargetTime)) {
    await prefs.setInt(keyTargetTime, 0);
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
        primaryColor: appColor,
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
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Container(
          alignment: Alignment.center,
          child: WiFiStatus(),
        ),
      ),
    );
  }
}
