import 'package:flutter/material.dart';

// Relativeasy App Color Palette - Space & Science Theme
const primary = Color(0xFF1A1A2E); // Deep Space Blue - Main brand color
const primaryLight = Color(0xFF16213E); // Dark Blue - Accents and backgrounds
const primaryDark = Color(0xFF0F0F23); // Darker Blue - Emphasis and headers

const accent =
    Color(0xFF00D4FF); // Electric Blue - Call-to-action and highlights
const accentLight = Color(0xFF7FEFFF); // Light Blue - Secondary highlights
const accentDark = Color(0xFF0099CC); // Dark Blue - Active states

const secondary = Color(0xFFFF6B35); // Cosmic Orange - Secondary accent
const secondaryLight = Color(0xFFFF8C69); // Light Orange
const secondaryDark = Color(0xFFE55A2B); // Dark Orange

const background = Color(0xFF0A0A0A); // Deep black background
const surface = Color(0xFF1E1E1E); // Dark surface color
const surfaceLight = Color(0xFF2A2A2A); // Lighter surface for cards

const textPrimary = Color(0xFFFFFFFF); // White for main text
const textSecondary = Color(0xFFB0B0B0); // Light grey for secondary text
const textLight = Color(0xFF808080); // Grey for light text
const textOnPrimary = Color(0xFFFFFFFF); // White text on dark backgrounds
const textOnAccent = Color(0xFF000000); // Black text on bright backgrounds

// Physics/Science specific colors
const successGreen =
    Color(0xFF00FF7F); // For correct answers and positive results
const errorRed = Color(0xFFFF4444); // For errors and warnings
const warningYellow = Color(0xFFFFD700); // For caution states
const infoBlue = Color(0xFF00BFFF); // For information and hints

// Special relativistic colors
const lightSpeedGold = Color(0xFFFFD700); // Represents speed of light
const timeDilationPurple = Color(0xFF9932CC); // For time dilation effects
const lengthContractionCyan =
    Color(0xFF00FFFF); // For length contraction effects

// Legacy colors (keeping for backward compatibility)
const darkPrimary = Color(0xFF0F0F23); // Dark Blue
const black = Color(0xFF000000); // Black
const white = Color(0xFFFFFFFF); // White
const grey = Color(0xFF404040); // Dark Grey

// New color aliases for easier usage
const buttonText = textOnPrimary; // White text for buttons
const textGrey = textLight; // Grey text
const textDark = textPrimary; // White text (inverted for dark theme)

// Badge colors for achievement system
const badgeGold = Color(0xFFFFD700);
const badgeSilver = Color(0xFFC0C0C0);
const badgeBronze = Color(0xFFCD7F32);
const badgeSpecial = Color(0xFFFF69B4);

TimeOfDay parseTime(String timeString) {
  List<String> parts = timeString.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}
