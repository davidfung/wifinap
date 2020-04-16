import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wifi_iot/wifi_iot.dart';

import '../main.dart';

const iconSize = 200.0;
const timerFontSize = 120.0;
const btnFontSize = 60.0;
const btnNapCap = 'Nap';
const btnCancelCap = 'Cancel';

const Icon statusOnIcon = Icon(
  Icons.wifi,
  size: iconSize,
  color: Colors.green,
);

const Icon statusOffIcon = Icon(
  Icons.signal_wifi_off,
  size: iconSize,
  color: Colors.red,
);

//const alarmDuration = 3; // in seconds
const alarmDuration = 60; // in seconds
const alarmCount = 5; // nap time = alarmDuration x alarmCount

// The callback for the alarm.  Whenever the alarm fires, send a null
// message to the UI Isolate.
Future<void> callback() async {
  SendPort uiSendPort;
  uiSendPort ??= IsolateNameServer.lookupPortByName(isolateName);
  uiSendPort?.send(null);
}

class WiFiStatus extends StatefulWidget {
  @override
  _WiFiStatusState createState() => _WiFiStatusState();
}

class _WiFiStatusState extends State<WiFiStatus> {
  int currentCount = 0;

  @override
  void initState() {
    super.initState();
    // Make this state listens to the background isolate.
    port.listen((_) async => await _decrementCounter());
  }

  Future<void> _decrementCounter() async {
    // increment the counter
    final prefs = await SharedPreferences.getInstance();
    currentCount = prefs.getInt(countKey) - 1;
    await prefs.setInt(countKey, currentCount);
    setState(() {});

    // If time's up, re-enable Wifi, else re-schedule alarm.
    if (currentCount <= 0) {
      print("==== Time's Up !! Enableing WiFi");
      await WiFiForIoTPlugin.setEnabled(true);
    } else {
      print("==== Counting... $currentCount");
      await AndroidAlarmManager.oneShot(
        const Duration(seconds: 3),
        Random().nextInt(pow(2, 31)),
        callback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
      );
    }

    // inform flutter the currentCount has changed
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: FittedBox(
              alignment: Alignment.bottomCenter, child: Text("$currentCount")),
        ),
        Expanded(
          flex: 1,
          child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              child: RaisedButton(
                child: Text("Disable WiFi"),
                onPressed: () async {
                  final DateTime now = DateTime.now();
                  print("================ [$now] Button pressed! Disable WiFi");
                  currentCount = alarmCount;
                  await prefs.setInt(countKey, alarmCount);
                  await AndroidAlarmManager.oneShot(
                    const Duration(seconds: alarmDuration),
                    Random().nextInt(pow(2, 31)),
                    callback,
                    exact: true,
                    wakeup: true,
                    allowWhileIdle: true,
                    rescheduleOnReboot: true,
                  );
                  await WiFiForIoTPlugin.setEnabled(false);
                  setState(() {});
                },
              )),
        ),
      ],
    );
  }
}
