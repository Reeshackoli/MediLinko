class ApiConfig {
  // Base URL for API - Uses environment variable or defaults to localhost
  // Override by running: flutter run --dart-define=API_URL=http://YOUR_IP:3000/api
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // IMPORTANT: Change this IP to your computer's IP address when running on physical device
    // To find your IP: Run 'ipconfig' (Windows) or 'ifconfig' (Mac/Linux)
    // Current IP: 192.168.29.106 (Sushil's PC)
    // For others: Default is 'localhost' for local testing
    const myDeviceIp = String.fromEnvironment('MY_IP', defaultValue: '192.168.29.106');
    
    // Default URLs for different platforms
    // For Web/Emulator: Use localhost
    // For Physical Device: Use computer's actual IP
    return 'http://$myDeviceIp:3000/api';
  }
  
  // API Endpoints
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get getMe => '$baseUrl/auth/me';
  static String get profile => '$baseUrl/profile';
  static String get wizardStep => '$baseUrl/profile/wizard';
  static String get doctors => '$baseUrl/users/doctors';
  static String get pharmacies => '$baseUrl/users/pharmacies';
  static String get health => '$baseUrl/health';
  
  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
}
