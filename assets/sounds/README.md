# Notification Sounds

This directory should contain custom notification sound files for your Flutter app.

## Adding Custom Notification Sounds

To add custom notification sounds:

1. Place your sound files in this directory (assets/sounds/)
2. Supported formats: .mp3, .wav, .ogg
3. Recommended duration: 1-3 seconds
4. Recommended file size: Under 100KB

## Directory Structure

```
assets/sounds/
├── notification.mp3    # Primary notification sound
├── notification.wav    # Alternative format
└── README.md           # This file
```

## Android Setup

1. Create the folder: `android/app/src/main/res/raw/`
2. Copy your sound file there (e.g., `notification.mp3`)
3. Reference it in FcmService: `sound: 'notification'`

## iOS Setup

1. Add sound files to your Xcode project
2. In Xcode, go to Build Phases -> Copy Bundle Resources
3. Add your sound file there
4. Reference it in FcmService: `sound: 'notification.mp3'`

## Current Configuration

The app is currently configured to use the system default notification sound. To use custom sounds:

1. Add your sound file to this directory
2. Copy it to `android/app/src/main/res/raw/` for Android
3. Uncomment the `sound` parameter in `lib/services/fcm_service.dart`
4. Update the sound reference based on your file name

## Testing Custom Sounds

After adding a custom sound, you can test it using:

```dart
await FcmService().testNotification();
```

This will play your custom notification sound instead of the system default.