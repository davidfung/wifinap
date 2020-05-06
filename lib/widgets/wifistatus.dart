import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:flutter/material.dart';
import 'package:wifi_iot/wifi_iot.dart';

import '../constants.dart';
import '../main.dart';

const iconSize = 200.0;
//const btnFontSize = 60.0;
const btnStart = 'Start';
const btnCancel = 'Cancel';

const Icon wifiOnIcon = Icon(
  Icons.wifi,
  size: iconSize,
  color: Colors.green,
);

const Icon wifiOffIcon = Icon(
  Icons.signal_wifi_off,
  size: iconSize,
  color: Colors.red,
);

// Whenever the alarm fires, send a null message to the UI Isolate.
Future<void> alarmCallback() async {
  SendPort uiSendPort;
  uiSendPort ??= IsolateNameServer.lookupPortByName(isolateName);
  uiSendPort?.send(null);
}

class WiFiStatus extends StatefulWidget {
  @override
  _WiFiStatusState createState() => _WiFiStatusState();
}

class _WiFiStatusState extends State<WiFiStatus> {
  bool isSleeping = false;
  final alarmID = Random().nextInt(pow(2, 31));

  @override
  void initState() {
    super.initState();
    // Listen to the background isolate.
    port.listen((_) async => await _checkpoint());

    void _initCheckpoint() async {
      await _checkpoint();
    }

    _initCheckpoint();
  }

  /// Call this routine regularly to see what should we do next.
  /// Usually repeatedly called by an alarm, but also being called at start up.
  Future<void> _checkpoint() async {
    int epochTime = prefs.getInt(keyTargetTime);
    DateTime targetTime = DateTime.fromMillisecondsSinceEpoch(epochTime);
    DateTime currentTime = DateTime.now();
    bool timeIsUp = targetTime.difference(currentTime).isNegative;

    // If time's up, re-enable Wifi,
    // else keep wifi off and schedule a new alarm.
    if (timeIsUp) {
      print("==== Time's Up !! Enabling WiFi");
      await WiFiForIoTPlugin.setEnabled(true);
      if (isSleeping) {
        // case of app was killed and restarted while a timer is running
        isSleeping = false;
        setState(() {});
      }
    } else {
      print("==== Counting down to $targetTime: $currentTime...");
      await WiFiForIoTPlugin.setEnabled(false);
      if (!isSleeping) {
        // case of app was killed and restarted while a timer is running
        isSleeping = true;
        setState(() {});
      }
      await AndroidAlarmManager.oneShot(
        const Duration(seconds: alarmDuration),
        Random().nextInt(pow(2, 31)),
        alarmCallback,
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
    DateTime targetTime = DateTime.fromMillisecondsSinceEpoch(epochTime);
    return Column(
      children: <Widget>[
        Expanded(
            flex: 2,
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
          flex: 3,
          child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              child: RaisedButton(
                child: Text(btnCancel),
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
          flex: 2,
          child: FittedBox(
            alignment: Alignment.bottomCenter,
            child: Text(msgAwake),
          ),
        ),
        Expanded(
          flex: 1,
          child: FittedBox(
            alignment: Alignment.topCenter,
            child: Text("for $defaultNapMinutes minutes"),
          ),
        ),
        Expanded(
          flex: 4,
          child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.topCenter,
              child: RaisedButton(
                child: Text(btnStart),
                onPressed: () async {
                  final DateTime now =
                      DateTime.now().add(Duration(minutes: defaultNapMinutes));
                  int epochTime = now.millisecondsSinceEpoch;

                  print("================ [$now] Button pressed! Disable WiFi");
                  await prefs.setInt(keyTargetTime, epochTime);
                  await AndroidAlarmManager.oneShot(
                    const Duration(seconds: alarmDuration),
                    alarmID,
                    alarmCallback,
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
