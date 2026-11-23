import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Thin wrapper around Google Mobile Ads.
///
/// Uses Google's official TEST ad unit IDs. Replace [_androidBanner] /
/// [_iosBanner] with your real AdMob banner unit IDs (and the app IDs in
/// AndroidManifest.xml / Info.plist) before releasing.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  static const _androidBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _iosBanner = 'ca-app-pub-3940256099942544/2934735716';

  bool _initialized = false;
  Future<void>? _initFuture;

  /// Ads are only supported on Android / iOS (not web, desktop or tests).
  bool get supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  String? get bannerUnitId {
    if (!supported) return null;
    return Platform.isAndroid ? _androidBanner : _iosBanner;
  }

  /// Idempotent; every caller shares the same in-flight initialisation.
  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    if (!supported) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (e) {
      debugPrint('AdMob init failed: $e');
    }
  }

  bool get ready => _initialized;
}
