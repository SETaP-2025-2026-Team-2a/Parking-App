# Parking App

A mobile application for finding and managing parking spaces, built with Flutter frontend and Python Flask backend.

## Project Structure

```
Parking-App/
├── frontend/          # Flutter mobile application
│   ├── lib/
│   │   ├── main.dart           # Main app entry point
│   │   ├── data/               # Data layer (BLoC, API, models)
|   |   ├── pages/              # App views
|   |   └── widgets/            # Widgets used in multiple places within the app.
|   | 
│   ├── android/                # Android platform files
│   ├── ios/                    # iOS platform files
│   ├── web/                    # Web platform files
│   └── pubspec.yaml            # Flutter dependencies
│
└── backend/           # Flask REST API server
    ├── server.py               # API root
    |-- abcxyz_manager.py       # Managers for handling various API routes
    └── requirements.txt        # Python dependencies
```

## Features

- **Home Tab**: Displays a list of available parking spots with:
  - Parking location name
  - Number of available spaces
  - Distance from current location
- **Search Tab**: Search functionality
- **Profile Tab**: User profile management
- **Settings Tab**: App settings

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
- **Supabase** - For hosting the backend database

## Getting Started

Information for getting started with the app, as well as development and testing instructions, can be found in the documentation [here](https://setap-team-2a-2026.readthedocs.io/en/latest/).

## API Endpoints

A full list of API endpoints, their parameters, methods, and return values, can be found in the [documentation](https://setap-team-2a-2026.readthedocs.io/en/latest/api.html).

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

This is a university project for the Level 5 module Software Engineering Theory and Practice.

## License

This project is for educational purposes.

