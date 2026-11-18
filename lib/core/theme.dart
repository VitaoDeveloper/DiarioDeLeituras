import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
  );
}

ThemeData buildDarkAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
  );
}
