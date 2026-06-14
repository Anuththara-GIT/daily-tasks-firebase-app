# Daily Tasks App

A Flutter task planner powered by Firebase Authentication and Cloud Firestore.

This project lets users create an account, log in, plan tasks by date, and keep their own task list synced with Firebase.

## Features

- Email and password sign up
- Email and password login
- Logout support
- User-specific task storage
- Add tasks with:
  - title
  - description
  - category (`Personal` or `Work`)
  - scheduled date
- View tasks for the selected date
- `Today` shortcut button
- Calendar picker for future dates
- Green highlights on calendar dates that already have tasks
- Mark tasks as completed or active
- Delete tasks
- Open a task to view full details
- Firebase-backed persistence after refresh or restart

## Tech Stack

- Flutter
- Dart
- Firebase Core
- Firebase Authentication
- Cloud Firestore

## Supported Platforms

- Android
- Web
- Windows

## Firebase Requirements

Before running the app, make sure Firebase is configured correctly.

### 1. Create a Firebase project

Create a project in the Firebase Console.

### 2. Enable Authentication

In Firebase Console:

1. Open `Authentication`
2. Go to `Sign-in method`
3. Enable `Email/Password`

### 3. Enable Firestore

Create a Cloud Firestore database for the project.

### 4. Android setup

1. Register an Android app in Firebase
2. Use package name:

```text
com.example.daily_tasks_app
```

3. Download `google-services.json`
4. Place it in:

```text
android/app/google-services.json
```

### 5. Web setup

The project already includes web Firebase configuration in:

```text
lib/firebase_options.dart
```

If you use a different Firebase project, update that file with your own web config.

## How Data Is Stored

Each signed-in user has a separate Firestore task collection:

```text
users/{uid}/daily_tasks
```

Each task document stores values such as:

- `title`
- `description`
- `category`
- `isCompleted`
- `taskDate`
- `taskDateKey`
- `createdAt`
- `updatedAt`

## Getting Started

### Prerequisites

Make sure these are installed:

- Flutter SDK
- Android Studio
- Android SDK
- A browser such as Chrome or Edge for web testing

## Run the Project

### 1. Get packages

```bash
flutter pub get
```

### 2. Run on web

```bash
flutter run -d chrome
```

or

```bash
flutter run -d edge
```

### 3. Run on Android

Connect a device or start an emulator, then run:

```bash
flutter run
```

## Run in Android Studio

1. Open Android Studio
2. Select `Open`
3. Open the root project folder, not only the `android` folder
4. Wait for Gradle sync to finish
5. Open a terminal in Android Studio and run:

```bash
flutter pub get
```

6. Start an emulator from `Device Manager` or connect a physical Android phone
7. Press the green `Run` button

## Common Issues

### Email/Password sign-in not enabled

If the app shows an authentication error, enable `Email/Password` in Firebase Authentication.

### Firestore not ready

If saving tasks fails, make sure:

- Firestore Database is created
- Firebase project configuration is correct
- Internet connection is available

### Android local setup

Do not share machine-specific files like:

```text
android/local.properties
```

That file is generated locally for each developer environment.

## Project Structure

```text
lib/
  app.dart
  firebase_options.dart
  models/
  screens/
  services/
android/
web/
windows/
test/
```

## Author Notes

This project is structured as a simple Firebase-based task planner assignment with authentication, calendar-based planning, and per-user task separation.
