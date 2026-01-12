import 'package:flutter/material.dart';
import 'package:flutter_initializer/base/styles/colors.dart';

const String _fontFamily = 'ibm';


final appTheme = ThemeData(
  fontFamily: _fontFamily,
  primaryColor: primaryColor,
  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryColor,
    primary: primaryColor,
  ),
  scaffoldBackgroundColor: Colors.white,
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: primaryColor, width: 1.2),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: primaryColor, width: 1.2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: primaryColor, width: 2),
    ),
    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: _fontFamily),
      padding: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: primaryColor,
      backgroundColor: Colors.white,
      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: _fontFamily),
      padding: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      side: BorderSide(color: primaryColor, width: 1.5, style: BorderStyle.solid),
      elevation: 0,
    ),
  ),
  switchTheme: SwitchThemeData(
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    thumbColor: WidgetStateProperty.all(primaryColor),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return primaryColor.withValues(alpha: 0.5);
      }
      return Colors.grey[300];
    }),
  ),
  textTheme: TextTheme(
    bodyLarge: TextStyle(fontSize: 16, color: primaryColor),
    bodyMedium: TextStyle(fontSize: 14, color: primaryColor),
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: primaryColor,
    ),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
      fontFamily: _fontFamily
    ),
  ),
);
