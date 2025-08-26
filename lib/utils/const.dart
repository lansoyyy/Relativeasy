// Physics Constants
const double speedOfLight = 299792458.0; // m/s
const double speedOfLightKmH = 1079252848.8; // km/h
const double speedOfLightMph = 670616629.0; // mph

// App Assets
String logo = 'assets/images/logo.png';
String einsteinIcon = 'assets/images/einstein.png';
String rocketIcon = 'assets/images/rocket.png';
String clockIcon = 'assets/images/clock.png';
String rulerIcon = 'assets/images/ruler.png';
String galaxyIcon = 'assets/images/galaxy.png';

// Badge Icons
List<String> badgeIcons = [
  'assets/images/badges/einstein_apprentice.png',
  'assets/images/badges/speed_sprinter.png',
  'assets/images/badges/time_twister.png',
  'assets/images/badges/shrink_master.png',
  'assets/images/badges/daily_streaker.png',
  'assets/images/badges/relativity_challenger.png',
  'assets/images/badges/formula_wizard.png',
  'assets/images/badges/concept_crusher.png',
  'assets/images/badges/level_legend.png',
  'assets/images/badges/grand_master.png',
];

// Difficulty Levels
enum DifficultyLevel {
  beginner,
  intermediate,
  expert,
}

// XP Values
const Map<DifficultyLevel, int> xpValues = {
  DifficultyLevel.beginner: 5,
  DifficultyLevel.intermediate: 10,
  DifficultyLevel.expert: 15,
};

// Problems to level up
const Map<DifficultyLevel, int> problemsToLevelUp = {
  DifficultyLevel.beginner: 4,
  DifficultyLevel.intermediate: 3,
  DifficultyLevel.expert: 2,
};

// Tutorial Steps
List<String> tutorialSteps = [
  'Welcome to Relativeasy! Let\'s explore Einstein\'s theory of special relativity.',
  'First, let\'s understand the speed of light - the cosmic speed limit.',
  'When objects travel at very high speeds, time and space behave differently.',
  'Time dilation: Moving clocks run slower relative to stationary observers.',
  'Length contraction: Objects appear shorter in the direction of motion.',
  'Let\'s calculate some examples together!',
];

// Animation Durations (in milliseconds)
const int shortAnimationDuration = 300;
const int mediumAnimationDuration = 600;
const int longAnimationDuration = 1000;

// App Limits
const double maxVelocityRatio = 0.99; // 99% of speed of light
const double minVelocityRatio = 0.01; // 1% of speed of light
const int maxDailyStreak = 365;
const int maxLeaderboardEntries = 100;
