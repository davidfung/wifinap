import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wifi_iot/wifi_iot.dart';

import '../main.dart';

const napDuration = 300; // seconds
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

class WiFiStatus extends StatefulWidget {
  @override
  _WiFiStatusState createState() => _WiFiStatusState();
}

class _WiFiStatusState extends State<WiFiStatus> {
  bool _wifiEnabled;

  // The background
  static SendPort uiSendPort;

  @override
  void initState() {
    super.initState();

    // Register for events from the background isolate. These messages will
    // always coincide with an alarm firing.
    port.listen((_) async => await _decrementCounter());
  }

  Future<void> _decrementCounter() async {
    print('Decrement counter!');

    // Get the previous cached count and increment it.
    final prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt(countKey) - 1;
    await prefs.setInt(countKey, currentCount);

    if (currentCount == 0) {
      print("==== Time's Up !! Enableing WiFi");
      await WiFiForIoTPlugin.setEnabled(true);
    } else {
      print("==== $currentCount minutes left ...");
      await AndroidAlarmManager.oneShot(
        const Duration(seconds: 5),
        Random().nextInt(pow(2, 31)),
        callback,
        exact: true,
        wakeup: true,
        allowWhileIdle: true,
        rescheduleOnReboot: true,
      );
    }

    // Ensure we've loaded the updated count from the background isolate.
    //await prefs.reload();
    setState(() {});
  }

  // The callback for our alarm
  static Future<void> callback() async {
    final DateTime now = DateTime.now();
    print("================ [$now] Alarm fired!");

    // This will be null if we're running in the background.
    uiSendPort ??= IsolateNameServer.lookupPortByName(isolateName);
    uiSendPort?.send(null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getWiFiState(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            String btnText;
            Icon statusIcon;
            if (_wifiEnabled) {
              statusIcon = statusOnIcon;
            } else {
              statusIcon = statusOffIcon;
            }
            if (_wifiEnabled) {
              btnText = btnCancelCap;
            } else {
              btnText = btnNapCap;
            }
            return Column(
              children: <Widget>[
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomCenter,
                    child: statusIcon,
                  ),
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: RaisedButton(
                      padding:
                          EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                      child: Text(
                        btnText,
                        style: TextStyle(fontSize: btnFontSize),
                      ),
                      onPressed: () async {
                        if (btnText == btnNapCap) {
                          this._wifiEnabled = false;
                          await WiFiForIoTPlugin.setEnabled(false);
                          btnText = btnCancelCap;
                        } else {
                          this._wifiEnabled = true;
                          await WiFiForIoTPlugin.setEnabled(true);
                          btnText = btnNapCap;
                        }
                        setState(() {});
                      },
                    ),
                  ),
                ),
                SizedBox(height: 10.0),
                Text(
                  prefs.getInt(countKey).toString(),
//                  key: ValueKey('BackgroundCountText'),
                ),
                RaisedButton(
                  child: Text("Test"),
                  onPressed: () async {
                    final DateTime now = DateTime.now();
                    print(
                        "================ [$now] Button pressed! Disable WiFi");
                    await prefs.setInt(countKey, 3);
                    await AndroidAlarmManager.oneShot(
                      const Duration(seconds: 5),
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
                )
              ],
            );
          } else {
            return CircularProgressIndicator();
          }
        });
  }

  Future<void> getWiFiState() async {
    _wifiEnabled = await WiFiForIoTPlugin.isEnabled();
  }
}
