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

const Icon wifiOffIcon = Icon(
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
  DateTime targetTime;
  DateTime currentTime;
  bool isSleeping = false;
  final alarmID = Random().nextInt(pow(2, 31));

  @override
  void initState() {
    super.initState();
    // Listen to the background isolate.
    port.listen((_) async => await _checkTimesUp());
  }

  Future<void> _checkTimesUp() async {
    // Do nothing if alarm not active
    if (!isSleeping) {
      return;
    }

    int epochTime = prefs.getInt(keyTargetTime);
    targetTime = DateTime.fromMillisecondsSinceEpoch(epochTime);
    currentTime = DateTime.now();

    // If time's up, re-enable Wifi, else re-schedule alarm.
    bool timeIsUp = targetTime.difference(currentTime).isNegative;
    if (timeIsUp) {
      print("==== Time's Up !! Enableing WiFi");
      isSleeping = false;
      await WiFiForIoTPlugin.setEnabled(true);
      setState(() {});
    } else {
      print("==== Counting down to $targetTime: $currentTime...");
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
  }

  @override
  Widget build(BuildContext context) {
    if (isSleeping) {
      return _sleepWidget();
    } else {
      return _awakeWidget();
    }
  }

  Widget _sleepWidget() {
    int epochTime = prefs.getInt(keyTargetTime);
    targetTime = DateTime.fromMillisecondsSinceEpoch(epochTime);
    return Column(
      children: <Widget>[
        Expanded(
            flex: 1,
            child: FittedBox(
              alignment: Alignment.center,
              child: wifiOffIcon,
            )),
        Expanded(
          flex: 1,
          child: FittedBox(
            alignment: Alignment.bottomCenter,
            child: Text(msgSleep),
          ),
        ),
        Expanded(
          flex: 1,
          child: FittedBox(
            alignment: Alignment.topCenter,
            child: Text("$targetTime"),
          ),
        ),
        Expanded(
          flex: 2,
          child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              child: RaisedButton(
                child: Text("Cancel"),
                onPressed: () async {
                  print("==== Cancelled");
                  await WiFiForIoTPlugin.setEnabled(true);
                  await AndroidAlarmManager.cancel(alarmID);
                  isSleeping = false;
                  setState(() {});
                },
              )),
        ),
      ],
    );
  }

  Widget _awakeWidget() {
    return Column(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: FittedBox(
            alignment: Alignment.bottomCenter,
            child: Text(msgAwake),
          ),
        ),
        Expanded(
          flex: 2,
          child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              child: RaisedButton(
                child: Text("Start"),
                onPressed: () async {
                  final DateTime now =
                      DateTime.now().add(Duration(minutes: defaultNapMinutes));
                  int epochTime = now.millisecondsSinceEpoch;

                  print("================ [$now] Button pressed! Disable WiFi");
                  await prefs.setInt(keyTargetTime, epochTime);
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
                  isSleeping = true;
                  setState(() {});
                },
              )),
        ),
      ],
    );
  }
}
