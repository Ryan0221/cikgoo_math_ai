import 'package:flutter/material.dart';

// Global notifier for the app theme.
// Options: 'light', 'dark_none', 'dark_starry'
final ValueNotifier<String> appThemeNotifier = ValueNotifier<String>('dark_starry');