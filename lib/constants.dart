import 'package:flutter/material.dart';

// Strings
const String appTitle = 'WiFi Nap';
const String aboutUrl = 'https://amg99.com';

// Styles
const TextStyle captionStyle =
    TextStyle(fontWeight: FontWeight.bold, fontSize: 18);
const TextStyle bodyStyle = TextStyle(fontSize: 16);
const TextStyle linkStyle = TextStyle(fontSize: 18, color: Colors.blue);

//
// Shared Preferences keys
const String keyTargetTime = 'keyTargetTime'; // Time to re-enable WiFi

// Defaults
const int defaultNapMinutes = 5;

// Isolate
const String isolateName = 'isolate';

// Alarm interval
const alarmDuration = 30; // in seconds

// UI strings
const msgSleep = 'WiFi disabled until';
const msgAwake = 'Disable WiFi';
