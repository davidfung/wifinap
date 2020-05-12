import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wifi_iot/wifi_iot.dart';

import '../constants.dart';
import '../main.dart';
import '../utils/sysutils.dart';

const btnStart = 'Start';
const btnCancel = 'Cancel';

enum AppState { napping, awake }

const Icon wifiOnIcon = Icon(
  Icons.wifi,
  size: 200,
  color: appColor,
);

const Icon wifiOffIcon = Icon(
  Icons.signal_wifi_off,
  size: 185,
  color: Colors.amber,
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

class _WiFiStatusState extends State<WiFiStatus> with WidgetsBindingObserver {
  AppState appState = AppState.awake;
  final alarmID = Random().nextInt(pow(2, 31));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    port.listen((_) async => await _checkpoint());

    void _initialCheckpoint() async {
      await _checkpoint();
    }

    _initialCheckpoint();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.resumed:
        syPrint2("applifecycle=$state, calling checkpint...");
        _checkpoint();
        break;
      default:
        break;
    }
  }

  /// Call this routine regularly to see what should we do next.
  /// Usually repeatedly called by an alarm, but also being called at start up
  /// and button click.
  Future<void> _checkpoint() async {
    syPrint("_checkpoint()");
    int epochTime = prefs.getInt(keyTargetTime);
    DateTime targetTime = DateTime.fromMillisecondsSinceEpoch(epochTime);
    DateTime currentTime = DateTime.now();
    Duration tolerance = Duration(seconds: alarmDuration ~/ 2);
    bool timeIsUp =
        targetTime.difference(currentTime.add(tolerance)).isNegative;

    // cancel any pending alarm
    await AndroidAlarmManager.cancel(alarmID);

    // If time's up, re-enable Wifi,
    // else keep wifi off and schedule a new alarm.
    if (timeIsUp) {
      syPrint("Time's Up !! Enabling WiFi");
      await WiFiForIoTPlugin.setEnabled(true);
      if (appState != AppState.awake) {
        syPrint2("State Change to AWAKE");
        setState(() {
          appState = AppState.awake;
        });
      }
    } else {
      syPrint2("Counting down to $targetTime: $currentTime...");
      await WiFiForIoTPlugin.setEnabled(false);
      if (appState != AppState.napping) {
        syPrint2("State Change to napping");
        setState(() {
          appState = AppState.napping;
        });
      }
      await AndroidAlarmManager.oneShot(
        const Duration(seconds: alarmDuration),
        alarmID,
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
    if (appState == AppState.awake) {
      return _awakeWidget();
    } else {
      return _nappingWidget();
    }
  }

  Widget _nappingWidget() {
    int epochTime = prefs.getInt(keyTargetTime);
    DateTime targetTime = DateTime.fromMillisecondsSinceEpoch(epochTime);
    String targetTimeStr = DateFormat('jms').format(targetTime);
    return Column(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Container(
            child: wifiOffIcon,
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            child: Column(
              children: <Widget>[
                Text(
                  msgSleep,
                  style: TextStyle(fontSize: 40),
                ),
                Text(
                  targetTimeStr,
                  style: TextStyle(fontSize: 35),
                ),
                SizedBox(height: 30),
                RaisedButton(
                  padding: EdgeInsets.all(15),
                  child: Text(
                    btnCancel,
                    style: TextStyle(fontSize: 30),
                  ),
                  onPressed: () async {
                    syPrint("Cancelled");
                    await prefs.setInt(keyTargetTime, 0);
                    await _checkpoint();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _awakeWidget() {
    return Column(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: Container(
            child: wifiOnIcon,
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            child: Column(
              children: <Widget>[
                Text(
                  msgAwake,
                  style: TextStyle(fontSize: 40),
                ),
                Text(
                    "for $defaultNapMinutes ${"minute".plural(defaultNapMinutes)}",
                    style: TextStyle(fontSize: 35)),
                SizedBox(height: 30),
                RaisedButton(
                  padding: EdgeInsets.all(15),
                  child: Text(btnStart, style: TextStyle(fontSize: 30)),
                  onPressed: () async {
                    final DateTime targetTime = DateTime.now()
                        .add(Duration(minutes: defaultNapMinutes));
                    syPrint2("Button pressed! Disable WiFi until $targetTime");
                    int epochTime = targetTime.millisecondsSinceEpoch;
                    await prefs.setInt(keyTargetTime, epochTime);
                    await _checkpoint();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
