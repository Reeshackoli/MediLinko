class ApiConfig {
  // Base URL for API - Change this when deploying to production
  // 🔧 CURRENT SETUP: Web Browser (Chrome/Edge)
  // Switch to appropriate URL based on your device:
  static const String baseUrl = 'http://localhost:3000/api'; // ✅ Web Browser
  
  // Available options:
  // For Android Emulator: http://10.0.2.2:3000/api
  // For iOS Simulator: http://localhost:3000/api
  // For Physical Device: http://YOUR_COMPUTER_IP:3000/api (find IP with 'ipconfig')
  // For Web: http://localhost:3000/api
  
  // API Endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register';
  static const String getMe = '$baseUrl/auth/me';
  static const String profile = '$baseUrl/profile';
  static const String wizardStep = '$baseUrl/profile/wizard';
  static const String doctors = '$baseUrl/users/doctors';
  static const String pharmacies = '$baseUrl/users/pharmacies';
  static const String health = '$baseUrl/health';
  
  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
