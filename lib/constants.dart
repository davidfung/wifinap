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
const String keyCounter = 'counter';
const String keyNapCount = 'napCount'; // nap time = nap count x alarm duration

// Settings
const int defaultNapCount = 300; //15;

// Isolate
const String isolateName = 'isolate';

// Alarm
const alarmDuration = 1; // in seconds
