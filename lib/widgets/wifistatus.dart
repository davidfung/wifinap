import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:flutter/material.dart';
import 'package:wifi_iot/wifi_iot.dart';

import '../constants.dart';
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
  int napCount;
  int counter;
  bool alarmActive = false;
  final alarmID = Random().nextInt(pow(2, 31));

  @override
  void initState() {
    super.initState();
    // Make this state listens to the background isolate.
    port.listen((_) async => await _decrementCounter());
    napCount = prefs.getInt(keyNapCount);
    counter = prefs.getInt(keyCounter);
  }

  Future<void> _decrementCounter() async {
    // Do nothing if alarm not active
    if (!alarmActive) {
      return;
    }

    // Decrement the counter.
    counter = prefs.getInt(keyCounter) - 1;
    await prefs.setInt(keyCounter, counter);

    // If time's up, re-enable Wifi, else re-schedule alarm.
    if (counter <= 0) {
      print("==== Time's Up !! Enableing WiFi");
      await WiFiForIoTPlugin.setEnabled(true);
      alarmActive = false;
    } else {
      print("==== Counting... $counter");
      await AndroidAlarmManager.oneShot(
        const Duration(seconds: alarmDuration),
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
    if (alarmActive) {
      return _alarmActiveWidget();
    } else {
      return _alarmInactiveWidget();
    }
  }

  Widget _alarmActiveWidget() {
    String minutes = "minute";
    if (counter > 1) {
      minutes += 's';
    }
    return Column(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: FittedBox(
            alignment: Alignment.bottomCenter,
            child: Text("$counter"),
          ),
        ),
        Expanded(
          flex: 1,
          child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              child: RaisedButton(
                child: Text("Cancel"),
                onPressed: () async {
                  print("==== Cancelled");
                  await WiFiForIoTPlugin.setEnabled(true);
                  await AndroidAlarmManager.cancel(alarmID);
                  alarmActive = false;
                  setState(() {});
                },
              )),
        ),
      ],
    );
  }

  Widget _alarmInactiveWidget() {
    return Column(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: FittedBox(
            alignment: Alignment.bottomCenter,
            child: Text("Disable WiFi for $napCount seconds"),
          ),
        ),
        Expanded(
          flex: 1,
          child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              child: RaisedButton(
                child: Text("Start"),
                onPressed: () async {
                  final DateTime now = DateTime.now();
                  print("================ [$now] Button pressed! Disable WiFi");
                  counter = napCount;
                  await prefs.setInt(keyCounter, counter);
                  await AndroidAlarmManager.oneShot(
                    const Duration(seconds: alarmDuration),
                    alarmID,
                    callback,
                    exact: true,
                    wakeup: true,
                    allowWhileIdle: true,
                    rescheduleOnReboot: true,
                  );
                  await WiFiForIoTPlugin.setEnabled(false);
                  alarmActive = true;
                  setState(() {});
                },
              )),
        ),
      ],
    );
  }
}
