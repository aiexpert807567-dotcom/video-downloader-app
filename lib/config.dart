class AppConfig {
  static const String backendBaseUrl =
      "https://REPLACE-WITH-YOUR-RENDER-URL.onrender.com";

  // Ads are removed for now. To bring them back later:
  // 1. Add google_mobile_ads back to pubspec.yaml
  // 2. Re-add the ad code in main.dart and home_screen.dart (see project notes)
  static const bool showAds = false;
}
