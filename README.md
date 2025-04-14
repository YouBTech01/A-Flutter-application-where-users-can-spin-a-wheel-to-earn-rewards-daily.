# Spin to Earn

A Flutter application where users can spin a wheel to earn rewards daily.

## Features

- User authentication with Firebase
- Daily rewards system with spin wheel
- Mobile ads integration
- Referral system
- Withdrawal request system

## Requirements

- Flutter SDK 3.29.1
- Dart 3.7.0
- Android SDK 35 (minimum SDK 21)

## Setup Instructions

### 1. Flutter Setup

Make sure you have Flutter installed. This project uses Flutter 3.29.1 and Dart 3.7.0.

```bash
flutter --version
```

### 2. Firebase Configuration

This project requires Firebase. You'll need to set up your own Firebase project:

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android application to your Firebase project
   - Use package name: `com.example.spin_to_earn` (or update it in the project)
   - Follow Firebase instructions to download `google-services.json`
3. Place your `google-services.json` file in the `android/app/` directory
   - An example file `google-services.json.example` is provided for reference

### 3. AdMob Configuration (Optional)

The app is configured to use Google's test ad unit IDs by default. For production:

1. Create an AdMob account at [AdMob](https://admob.google.com/)
2. Create ad units for banner, interstitial, and rewarded ads
3. Replace the test ad unit IDs in `lib/services/ad_service.dart` with your real ones

### 4. Install Dependencies

```bash
flutter pub get
```

### 5. Run the App

```bash
flutter run
```

## Project Structure

- `lib/main.dart` - App entry point
- `lib/screens/` - App screens (auth, home, etc.)
- `lib/providers/` - State management
- `lib/services/` - Firebase and other services
- `lib/models/` - Data models
- `lib/widgets/` - Reusable UI components

## Notes

- For GitHub, sensitive API keys and Firebase configurations have been removed
- The app will not fully function without your own Firebase and AdMob setup
- This is a demonstration project and not intended for production use without proper configuration

## License

This project is open source under the MIT License.
