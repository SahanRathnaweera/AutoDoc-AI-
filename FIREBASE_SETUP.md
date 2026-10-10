# 🔥 Firebase Setup & Configuration Guide

This guide details the step-by-step instructions to connect, configure, and run AutoDoc AI with Firebase Cloud Services.

---

## 1. Prerequisites
Ensure you have the following CLI tools installed:
* [Node.js](https://nodejs.org/) (v18+)
* [Firebase CLI](https://firebase.google.com/docs/cli): `npm install -g firebase-tools`
* [FlutterFire CLI](https://firebase.flutter.dev/docs/cli): `dart pub global activate flutterfire_cli`

---

## 2. Step-by-Step Setup Instructions

### Step 1: Log in to Firebase
```bash
firebase login
```

### Step 2: Create / Select Firebase Project
In the [Firebase Console](https://console.firebase.google.com/):
1. Click **Add project**.
2. Name the project `autodoc-ai` (or select your university project instance).
3. Enable Google Analytics if desired.

### Step 3: Register Platform Applications via FlutterFire CLI
Run FlutterFire configuration from the root of the Flutter project:
```bash
flutterfire configure --project=YOUR_PROJECT_ID
```
* Select target platforms: `Android`, `iOS`, `Web`, `macOS`.
* This will automatically generate `lib/firebase_options.dart` with project-specific IDs and register the Android/iOS bundle identifiers.

### Step 4: Enable Firebase Authentication
In Firebase Console:
1. Navigate to **Build > Authentication > Sign-in method**.
2. Click **Email/Password**.
3. Toggle **Enable** (and optionally Email link / passwordless).
4. Click **Save**.

### Step 5: Provision Cloud Firestore
In Firebase Console:
1. Navigate to **Build > Firestore Database**.
2. Click **Create database**.
3. Select **Production mode** (rules will be applied next).
4. Choose the cloud region closest to your target users (e.g. `asia-south1` or `us-central1`).

### Step 6: Provision Firebase Storage
In Firebase Console:
1. Navigate to **Build > Storage**.
2. Click **Get Started**.
3. Choose standard location matching your Firestore database region.

### Step 7: Deploy Security Rules & Indexes
Deploy the repository's security rules and composite indexes:
```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

### Step 8: Configure Local Development with Firebase Emulator Suite
For local development without touching production data:
```bash
firebase init emulators
# Select Authentication, Firestore, and Storage emulators
firebase emulators:start
```
To direct the Flutter app to the local emulators during development:
```dart
if (kDebugMode) {
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
}
```

### Step 9: Configure Backend Service Account for FastAPI
For the Python/FastAPI backend team:
1. In Firebase Console, go to **Project settings > Service accounts**.
2. Click **Generate new private key**.
3. Save the JSON file as `serviceAccountKey.json` inside your FastAPI backend directory.
4. **Never commit `serviceAccountKey.json` to Git!** Ensure it is in `.gitignore`.

### Step 10: Run the Application
```bash
flutter pub get
flutter run
```

---

## 3. Configuration Files & Secrets Hygiene

| File | Status | Description |
|---|---|---|
| `android/app/google-services.json` | ❌ **Do NOT commit** | Contains Android client API keys. Added to `.gitignore`. |
| `ios/Runner/GoogleService-Info.plist` | ❌ **Do NOT commit** | Contains iOS client API keys. Added to `.gitignore`. |
| `serviceAccountKey.json` | ❌ **Do NOT commit** | Private RSA key for Firebase Admin. Added to `.gitignore`. |
| `lib/core/firebase/firebase_options.dart` | ✅ Safe template committed | Contains generic placeholder credentials; replaced locally by `flutterfire configure`. |
| `firestore.rules` | ✅ **Commit** | Declarative security rules for Cloud Firestore. |
| `storage.rules` | ✅ **Commit** | Declarative security rules for Firebase Storage. |
| `firestore.indexes.json` | ✅ **Commit** | Composite index specifications for queries. |
