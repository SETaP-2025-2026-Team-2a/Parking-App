# Parking App

A mobile application for finding and managing parking spaces, built with Flutter frontend and Python Flask backend.

## Project Structure

```
Parking-App/
├── frontend/          # Flutter mobile application
│   ├── lib/
│   │   ├── main.dart           # Main app entry point
│   │   └── data/               # Data layer (BLoC, API, models)
│   ├── android/                # Android platform files
│   ├── ios/                    # iOS platform files
│   ├── web/                    # Web platform files
│   └── pubspec.yaml            # Flutter dependencies
│
└── backend/           # Flask REST API server
    ├── app.py                  # API endpoints
    └── requirements.txt        # Python dependencies
```

## Features

- **Home Tab**: Displays a list of available parking spots with:
  - Parking location name
  - Number of available spaces
  - Distance from current location
- **Search Tab**: Search functionality (coming soon)
- **Profile Tab**: User profile management (coming soon)
- **Settings Tab**: App settings (coming soon)

## Technologies Used

### Frontend
- **Flutter** - Cross-platform mobile framework
- **flutter_bloc** - State management
- **http** - API communication
- **equatable** - Value equality

### Backend
- **Flask** - Python web framework
- **Flask-RESTful** - REST API extension
- **Flask-CORS** - Cross-origin resource sharing

## Getting Started

### Prerequisites
- Flutter SDK (^3.9.2)
- Python 3.x
- pip (Python package manager)

### Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Run the Flask server:
   ```bash
   python app.py
   ```

   The server will start at `http://127.0.0.1:8080/`

### Frontend Setup

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```

2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```

3. Run the Flutter app:
   ```bash
   flutter run
   ```

   Select your target device (Android emulator, iOS simulator, or web browser)

## API Endpoints

### GET `/`
Returns a list of available parking locations.



## Architecture

The app follows a clean architecture pattern with BLoC (Business Logic Component) for state management:

- **Cubit**: Manages app state and business logic
- **Repository**: Abstracts data sources
- **Data Provider**: Handles API communication
- **Models**: Data structures and serialization

## Development

### Running Tests
```bash
cd frontend
flutter test
```

### Building for Production

**Android:**
```bash
flutter build apk
```

**iOS:**
```bash
flutter build ios
```

**Web:**
```bash
flutter build web
```

## Contributing

This is a university project for Level 5 Software Engineering.

## License

This project is for educational purposes.

