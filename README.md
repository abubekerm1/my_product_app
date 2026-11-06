# Activity 13B Firebase Authentication

Abubeker Mohammed  
CSC 4360 Mobile App Development Section B

## Features

- Register and sign in using Firebase email/password authentication.
- Display the signed-in email on the profile.
- Sign out and block access to the protected profile.
- Update passwords and handle recent-login recovery.
- Validate form input and display loading and error feedback.
- Restore the signed-in session after restarting the app.

AuthService contains the authentication operations. AuthGate listens to a stable auth-state stream and chooses the authentication or profile screen.

This project continues the Firebase project used for Activity 12.

## Setup

Install Flutter, Firebase CLI, and FlutterFire CLI. In Firebase Console, select your project and enable Email/Password under Authentication.

From the project root, run:

```bash
flutter pub get
firebase login
flutterfire configure --platforms=android
```

Select your own Firebase project to generate the Android configuration. Keep passwords and service-account credentials out of Git.

The main Android manifest declares the INTERNET permission.

## Run

Connect an Android phone with USB debugging enabled.

```bash
flutter devices
flutter run -d YOUR_DEVICE_ID
```

## Testing

```bash
flutter analyze
flutter test integration_test/auth_test.dart -d YOUR_DEVICE_ID
```

Static analysis reported no issues. The integration test passed on a Samsung SM G998U running Android 15. It checks the signed-out screen and invalid email/password validation, and signs out the current test session.

Manual testing covered registration, profile email, sign-in, sign-out, protected access after logout, session restoration, password updates, rejection of the old password, acceptance of the new password, and offline error feedback.

Recent-login recovery is implemented but was not triggered during the reported tests.

## Release APK

```bash
flutter build apk --release
```

The output is:

```text
build/app/outputs/flutter-apk/app-release.apk
```

The final rebuilt release APK was installed on the Android phone. Sign-in, profile email, and sign-out were verified.

The submission copy is named Abubeker_Mohammed_Activity13B.apk.

## References

- https://firebase.google.com/docs/flutter/setup
- https://firebase.google.com/docs/auth/flutter/start
- https://firebase.google.com/docs/auth/flutter/manage-users
