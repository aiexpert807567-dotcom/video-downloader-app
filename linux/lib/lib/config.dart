class AppConfig {
  /// EDIT THIS ONE LINE after you deploy the backend to Render.
  /// Paste the URL Render gives you (looks like
  /// https://video-downloader-backend-xxxx.onrender.com) with NO trailing slash.
  static const String backendBaseUrl =
      "https://video-downloader-backend-bc5k.onrender.com";

  /// Flip to true later to turn ads on. No other code changes needed
  /// anywhere else in the app.
  static const bool showAds = false;

  /// Google's official TEST ad unit IDs. Safe to ship like this since
  /// showAds is false. Replace with your real AdMob unit IDs before
  /// you ever flip showAds to true.
  static const String bannerAdUnitId = "ca-app-pub-3940256099942544/6300978111";
  static const String interstitialAdUnitId =
      "ca-app-pub-3940256099942544/1033173712";
}
