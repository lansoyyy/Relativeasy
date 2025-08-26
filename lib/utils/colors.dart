import 'package:flutter/material.dart';

// Amuma Health App Color Palette - Blue & Orange Theme
const primary = Color(0xFF00537A); // Deep Blue - Main brand color
const primaryLight = Color(0xFFA8E8F9); // Light Blue - Accents and backgrounds
const primaryDark = Color(0xFF013C58); // Darker Blue - Emphasis and headers

const accent =
    Color(0xFFFFBA42); // Bright Orange - Call-to-action and highlights
const accentLight = Color(0xFFFFF35B); // Light Yellow - Secondary highlights
const accentDark = Color(0xFFF5A201); // Dark Orange - Active states

const background = Color(0xFFFAFAFA); // Very light background
const surface = Color(0xFFFFFFFF); // Surface color (white)
const surfaceBlue = Color(0xFFF0F8FF); // Light blue surface for health cards

const textPrimary = Color(0xFF013C58); // Dark blue for main text
const textSecondary = Color(0xFF00537A); // Medium blue for secondary text
const textLight = Color(
    0xFF666666); // Grey for light text - redefined for backward compatibility
const textOnPrimary = Color(0xFFFFFFFF); // White text on blue backgrounds
const textOnAccent = Color(0xFF013C58); // Dark blue text on orange backgrounds

// Health-specific colors
const healthGreen = Color(0xFF4CAF50); // For positive health indicators
const healthRed = Color(0xFFE57373); // For alerts and warnings (softer red)
const healthYellow = Color(0xFFFFB74D); // For caution states

// Legacy colors (keeping for backward compatibility)
const secondary = Color(0xFF00537A); // Medium Blue
const darkPrimary = Color(0xFF013C58); // Dark Blue
const black = Color(0xFF000000); // Black
const white = Color(0xFFFFFFFF); // White
const grey = Color(0xFFE0E0E0); // Light Grey

// New color aliases for easier migration
const buttonText = textOnPrimary; // White text for buttons
const textGrey = textLight; // Grey text
const textDark = textPrimary; // Dark text

TimeOfDay parseTime(String timeString) {
  List<String> parts = timeString.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}
