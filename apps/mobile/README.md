# Unishare Mobile

Cross-platform Flutter app (iOS, Android, Web) for academic content sharing — Firebase-native.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- [Firebase CLI](https://firebase.google.com/docs/cli): `npm install -g firebase-tools`
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli): `dart pub global activate flutterfire_cli`

## Getting Started

### 1. Install dependencies

```bash
cd apps/mobile
flutter pub get
```

### 2. Connect to Firebase

Firebase config files are gitignored and must be generated locally. You need to be added to the Firebase project first — ask the project owner to invite you via the [Firebase Console](https://console.firebase.google.com).

Once you have access:

```bash
firebase login
flutterfire configure
```

Select the `unishare-flutter` project when prompted. This generates:
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

### 3. Generate code

Riverpod and Freezed files are also gitignored and must be generated locally:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Run the app

```bash
flutter run              # connected device or emulator
flutter run -d chrome    # web
```

## Common Commands

```bash
flutter analyze                              # static analysis
dart format .                               # format code
flutter test                                # unit + widget tests
dart run build_runner watch                 # watch mode for code gen
```
