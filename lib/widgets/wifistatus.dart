import 'package:flutter/material.dart';
import 'package:timer_count_down/timer_count_down.dart';
import 'package:wifi_iot/wifi_iot.dart';

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
  bool _firstTime = true;
  bool _timerRunning = false;
  bool _wifiEnabled;
  int _seconds = napDuration;

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
            if (_timerRunning) {
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
                if (_timerRunning)
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: CountDown(
                        seconds: _seconds,
                        onTimer: () async {
                          this._timerRunning = false;
                          this._wifiEnabled = true;
                          await WiFiForIoTPlugin.setEnabled(true);
                          setState(() {});
                        },
                        style: TextStyle(fontSize: timerFontSize),
                      ),
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
                          this._timerRunning = true;
                          this._wifiEnabled = false;
                          await WiFiForIoTPlugin.setEnabled(false);
                          btnText = btnCancelCap;
                        } else {
                          this._timerRunning = false;
                          this._wifiEnabled = true;
                          await WiFiForIoTPlugin.setEnabled(true);
                          btnText = btnNapCap;
                        }
                        setState(() {});
                      },
                    ),
                  ),
                ),
                SizedBox(height: 10.0)
              ],
            );
          } else {
            return CircularProgressIndicator();
          }
        });
  }

  Future<void> getWiFiState() async {
    if (_firstTime) {
      _wifiEnabled = await WiFiForIoTPlugin.isEnabled();
    }
    _firstTime = false;
  }
}
