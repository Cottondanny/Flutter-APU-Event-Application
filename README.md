# studenthub

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Local secrets setup

This repo keeps local secrets out of Git.

Before running the app on a new machine:

1. Copy `lib/firebase_options.example.dart` to `lib/firebase_options_local.dart`.
2. Put your real Firebase values into `lib/firebase_options_local.dart`.
3. Add your Firebase Android config file at `android/app/google-services.json`.
4. Add your Google Maps key to `android/local.properties`:

```properties
maps.api.key=YOUR_ANDROID_GOOGLE_MAPS_KEY
```
