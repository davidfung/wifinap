import 'package:flutter/material.dart';

// Strings
const String appTitle = 'WiFi Nap';
const String aboutUrl = 'https://amg99.com';

// Styles
const TextStyle captionStyle =
    TextStyle(fontWeight: FontWeight.bold, fontSize: 18);
const TextStyle bodyStyle = TextStyle(fontSize: 16);
const TextStyle linkStyle = TextStyle(fontSize: 18, color: Colors.blue);

// Shared Preferences keys
const String keyCounter = 'counter'; // a working counter shared by isolates
const String keyNapCount = 'napCount'; // nap time = nap count x alarm duration

// Settings
const int defaultNapCount = 5;

// Isolate
const String isolateName = 'isolate';

// Alarm
// Although the alarm is set by minutes, we schedule it by seconds
// for debugging purpose.
const alarmDuration = 60; // in seconds
