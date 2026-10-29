// Base URL for the Django backend
// Change this to your server's IP/domain when deploying
const String kBaseUrl = 'http://10.0.2.2:8000'; // Android emulator → localhost
// const String kBaseUrl = 'http://localhost:8000'; // iOS simulator

// WebSocket base URL
const String kWsBaseUrl = 'ws://10.0.2.2:8000';
// const String kWsBaseUrl = 'ws://localhost:8000'; // iOS simulator

// API endpoints
const String kApiTrips = '$kBaseUrl/api/trips/';
String kApiJoinTrip(String code) => '$kBaseUrl/api/trips/$code/join/';
String kApiMembers(String code) => '$kBaseUrl/api/trips/$code/members/';
String kApiLeaveTrip(String code) => '$kBaseUrl/api/trips/$code/leave/';
String kApiTripDetail(String code) => '$kBaseUrl/api/trips/$code/';

// WebSocket endpoint
String kWsTripUrl(String code, String memberId) =>
    '$kWsBaseUrl/ws/trip/$code/$memberId/';

// Location update interval in seconds
const int kLocationUpdateIntervalSeconds = 30;

// AdMob IDs (TEST IDs — replace with real ones from AdMob console)
// Android test IDs
const String kAndroidBannerAdId = 'ca-app-pub-3940256099942544/6300978111';
const String kAndroidInterstitialAdId = 'ca-app-pub-3940256099942544/1033173712';

// iOS test IDs
const String kIosBannerAdId = 'ca-app-pub-3940256099942544/2934735716';
const String kIosInterstitialAdId = 'ca-app-pub-3940256099942544/4411468910';

// Avatars
const List<Map<String, String>> kAvatars = [
  {'id': 'bike', 'emoji': '🏍️', 'label': 'Bike'},
  {'id': 'car', 'emoji': '🚗', 'label': 'Car'},
  {'id': 'bicycle', 'emoji': '🚲', 'label': 'Bicycle'},
  {'id': 'hiker', 'emoji': '🥾', 'label': 'Hiker'},
  {'id': 'van', 'emoji': '🚐', 'label': 'Van'},
  {'id': 'truck', 'emoji': '🛻', 'label': 'Truck'},
];

// Color presets for rider color picker
const List<String> kColorPresets = [
  '#FF6B35', // Orange (default)
  '#00D68F', // Green
  '#4FC3F7', // Blue
  '#FFD600', // Yellow
  '#FF4D6A', // Red
  '#B39DDB', // Purple
  '#F06292', // Pink
  '#80DEEA', // Cyan
];
