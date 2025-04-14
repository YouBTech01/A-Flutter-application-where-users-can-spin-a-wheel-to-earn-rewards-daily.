import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  bool _isInitialized = false;

  factory AdService() => _instance;

  AdService._internal();

  // For testing ads in development - using Google's test ad unit IDs
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Google test ad unit
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // Google test ad unit
    } else {
      // For web/desktop in debug mode
      return kDebugMode ? 'ca-app-pub-3940256099942544/6300978111' : '';
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Google test ad unit
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Google test ad unit
    } else {
      // For web/desktop in debug mode
      return kDebugMode ? 'ca-app-pub-3940256099942544/1033173712' : '';
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917'; // Google test ad unit
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // Google test ad unit
    } else {
      // For web/desktop in debug mode
      return kDebugMode ? 'ca-app-pub-3940256099942544/5224354917' : '';
    }
  }

  // Initialize mobile ads SDK with test device configuration
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure test devices (replace with your test device IDs if needed)
      List<String> testDeviceIds = [
        'EMULATOR', // Generic emulator/simulator ID
      ];

      // Set up request configuration for test ads
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: testDeviceIds,
          // Setting tagForChildDirectedTreatment and tagForUnderAgeOfConsent to ensure test ads work
          tagForChildDirectedTreatment:
              TagForChildDirectedTreatment.unspecified,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
          maxAdContentRating: MaxAdContentRating.g,
        ),
      );

      // Initialize MobileAds
      await MobileAds.instance.initialize();

      // Mark as initialized
      _isInitialized = true;
      debugPrint(
        'AdMob initialized successfully with test device configuration',
      );
    } catch (e) {
      debugPrint('Failed to initialize AdMob: $e');
      // Attempt simplified initialization as fallback
      try {
        await MobileAds.instance.initialize();
        _isInitialized = true;
        debugPrint('AdMob initialized with simplified configuration');
      } catch (e2) {
        debugPrint('Fallback initialization also failed: $e2');
      }
    }
  }

  // Check if we're on a supported platform for ads
  bool get isAdSupported => Platform.isAndroid || Platform.isIOS || kDebugMode;

  // Load a banner ad
  BannerAd? createBannerAd() {
    if (!_isInitialized) {
      // Try to initialize if not already done
      initialize().then(
        (_) => debugPrint('Initialized AdMob during banner ad creation'),
      );
      return null;
    }

    if (bannerAdUnitId.isEmpty) {
      debugPrint('Banner ad unit ID is empty, not showing ads');
      return null;
    }

    try {
      return BannerAd(
        adUnitId: bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) => debugPrint('Banner ad loaded successfully'),
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            debugPrint('Banner ad failed to load: $error');
            // Log details about the error
            debugPrint(
              'Error code: ${error.code}, message: ${error.message}, domain: ${error.domain}',
            );
          },
          // Adding more listener callbacks for better debugging
          onAdOpened: (ad) => debugPrint('Banner ad opened'),
          onAdClosed: (ad) => debugPrint('Banner ad closed'),
          onAdImpression: (ad) => debugPrint('Banner ad impression recorded'),
        ),
      );
    } catch (e) {
      debugPrint('Error creating banner ad: $e');
      return null;
    }
  }

  // Load an interstitial ad
  Future<InterstitialAd?> loadInterstitialAd() async {
    if (!_isInitialized) {
      // Try to initialize if not already done
      await initialize();
    }

    if (interstitialAdUnitId.isEmpty) {
      debugPrint('Interstitial ad unit ID is empty, not showing ads');
      return null;
    }

    Completer<InterstitialAd?> completer = Completer<InterstitialAd?>();

    try {
      // Use a longer timeout for ad loading
      Timer timeoutTimer = Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          debugPrint('Interstitial ad load timed out');
          completer.complete(null);
        }
      });

      InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Interstitial ad loaded successfully');
            timeoutTimer.cancel();
            completer.complete(ad);
          },
          onAdFailedToLoad: (error) {
            timeoutTimer.cancel();
            debugPrint('Interstitial ad failed to load: $error');
            debugPrint(
              'Error code: ${error.code}, message: ${error.message}, domain: ${error.domain}',
            );
            completer.complete(null);
          },
        ),
      );

      return await completer.future;
    } catch (e) {
      debugPrint('Error loading interstitial ad: $e');
      return null;
    }
  }

  // Show an interstitial ad
  Future<void> showInterstitialAd() async {
    if (!_isInitialized) {
      // Try to initialize if not already done
      await initialize();
    }

    try {
      debugPrint('Attempting to load and show interstitial ad');
      InterstitialAd? interstitialAd = await loadInterstitialAd();

      if (interstitialAd != null) {
        interstitialAd.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            debugPrint('Interstitial ad dismissed');
            ad.dispose();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            debugPrint('Failed to show interstitial ad: $error');
            ad.dispose();
          },
          onAdShowedFullScreenContent: (ad) {
            debugPrint('Interstitial ad showed successfully');
          },
          onAdImpression: (ad) {
            debugPrint('Interstitial ad impression recorded');
          },
        );

        await interstitialAd.show();
        debugPrint('Interstitial ad show method called');
      } else {
        debugPrint('Interstitial ad was null, cannot show');
      }
    } catch (e) {
      debugPrint('Error showing interstitial ad: $e');
    }
  }

  // Load a rewarded ad
  Future<RewardedAd?> loadRewardedAd() async {
    if (!_isInitialized) {
      // Try to initialize if not already done
      await initialize();
    }

    if (rewardedAdUnitId.isEmpty) {
      debugPrint('Rewarded ad unit ID is empty, not showing ads');
      return null;
    }

    Completer<RewardedAd?> completer = Completer<RewardedAd?>();

    try {
      // Use a longer timeout for ad loading
      Timer timeoutTimer = Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          debugPrint('Rewarded ad load timed out');
          completer.complete(null);
        }
      });

      RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Rewarded ad loaded successfully');
            timeoutTimer.cancel();
            completer.complete(ad);
          },
          onAdFailedToLoad: (error) {
            timeoutTimer.cancel();
            debugPrint('Rewarded ad failed to load: $error');
            debugPrint(
              'Error code: ${error.code}, message: ${error.message}, domain: ${error.domain}',
            );
            completer.complete(null);
          },
        ),
      );

      return await completer.future;
    } catch (e) {
      debugPrint('Error loading rewarded ad: $e');
      return null;
    }
  }

  // Show a rewarded ad and return success status
  Future<bool> showRewardedAd() async {
    if (!_isInitialized) {
      // Try to initialize if not already done
      await initialize();
    }

    // If in debug mode and running on an unsupported platform, reward the user
    if (!isAdSupported) {
      debugPrint(
        'Platform not supported for ads, auto-rewarding in debug mode',
      );
      return true;
    }

    try {
      debugPrint('Attempting to load and show rewarded ad');
      final Completer<bool> rewardCompleter = Completer<bool>();
      RewardedAd? rewardedAd = await loadRewardedAd();

      if (rewardedAd != null) {
        rewardedAd.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            debugPrint('Rewarded ad dismissed');
            ad.dispose();
            if (!rewardCompleter.isCompleted) {
              rewardCompleter.complete(false);
            }
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            debugPrint('Failed to show rewarded ad: $error');
            ad.dispose();
            if (!rewardCompleter.isCompleted) {
              // In case of failure, still reward the user in debug mode
              rewardCompleter.complete(kDebugMode);
            }
          },
          onAdShowedFullScreenContent: (ad) {
            debugPrint('Rewarded ad showed successfully');
          },
          onAdImpression: (ad) {
            debugPrint('Rewarded ad impression recorded');
          },
        );

        rewardedAd.setImmersiveMode(true);

        // Add a timeout for the reward
        Timer(const Duration(seconds: 30), () {
          if (!rewardCompleter.isCompleted) {
            debugPrint('Rewarded ad timed out waiting for reward');
            rewardCompleter.complete(kDebugMode);
          }
        });

        await rewardedAd.show(
          onUserEarnedReward: (_, reward) {
            debugPrint('User earned reward: ${reward.amount}');
            if (!rewardCompleter.isCompleted) {
              rewardCompleter.complete(true);
            }
          },
        );
        debugPrint('Rewarded ad show method called');

        return await rewardCompleter.future;
      } else {
        debugPrint('Rewarded ad was null, cannot show');
        // If loading fails, reward the user in debug mode
        return kDebugMode;
      }
    } catch (e) {
      debugPrint('Error showing rewarded ad: $e');
      // If there's an exception, reward the user in debug mode
      return kDebugMode;
    }
  }
}
