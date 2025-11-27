# MoveEasy

MoveEasy is a comprehensive public transportation management solution designed to improve the commuting experience. It consists of a cross-platform mobile application built with Flutter and a robust backend API powered by Python and Flask.

## Project Structure

The repository is organized into two main directories:

- **`moveeasy_app/`**: The Flutter mobile application source code. This app serves both passengers and drivers, offering features like real-time bus tracking, route planning, and driver dashboards.
- **`MoveEasyDatasets/`**: The Python backend service. It handles API requests, manages GTFS (General Transit Feed Specification) data, provides real-time vehicle positions, and interfaces with Firebase for authentication and data storage.

## Technology Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Python (Flask)
- **Database & Auth**: Firebase (Realtime Database, Authentication)
- **Real-time Data**: GTFS-Realtime bindings (Protobuf)

## Prerequisites

Before you begin, ensure you have the following installed:

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Python 3.x](https://www.python.org/downloads/)
- [Git](https://git-scm.com/)

## Setup Instructions

### 1. Backend Setup (`MoveEasyDatasets`)

The backend provides the API and real-time data feeds.

1.  Navigate to the backend directory:
    ```bash
    cd MoveEasyDatasets
    ```

2.  Create and activate a virtual environment (optional but recommended):
    ```bash
    python -m venv .venv
    # Windows
    .venv\Scripts\activate
    # macOS/Linux
    source .venv/bin/activate
    ```

3.  Install dependencies:
    ```bash
    pip install -r requirements.txt
    ```

4.  **Configuration**:
    The application requires Firebase credentials. You can provide them via an environment variable or a file.
    -   **Environment Variable**: Set `FIREBASE_CREDENTIALS` to the JSON content of your service account key.
    -   **File**: Place your Firebase service account JSON file in a secure location and update `app.py` or set `FIREBASE_KEY_PATH` environment variable.
    -   **Database URL**: Set `DATABASE_URL` environment variable if different from the default.

5.  Run the application:
    ```bash
    python app.py
    ```
    The server will start on `http://0.0.0.0:5001`.

### 2. Frontend Setup (`moveeasy_app`)

The mobile application for end-users.

1.  Navigate to the app directory:
    ```bash
    cd moveeasy_app
    ```

2.  Install Flutter dependencies:
    ```bash
    flutter pub get
    ```

3.  **Configuration**:
    -   Ensure your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are placed in the respective directories (`android/app/` and `ios/Runner/`) for Firebase integration.
    -   Verify the Google Maps API key is configured in `AndroidManifest.xml` and `AppDelegate.swift` / `Runner.entitlements`.

4.  Run the app:
    ```bash
    flutter run
    ```

## Features

-   **Real-time Tracking**: View bus locations in real-time on the map.
-   **Route Management**: Browse available routes and stops.
-   **Driver Dashboard**: Drivers can view their trips, earnings, and reviews.
-   **Authentication**: Secure login for users and drivers.
-   **GTFS Integration**: Uses standard GTFS formats for transport data.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
