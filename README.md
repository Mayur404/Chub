# Chub - Student Tracker App

A Flutter application designed to help students manage their daily activities and track important information including bus schedules, mess timings, class timetables, events, holidays, and personal debt tracking.

## Features

- 🚌 **Bus Tracker** - View bus schedules for weekdays and weekends/holidays with real-time next bus information
- 🍽️ **Mess Schedule** - Track mess (dining hall) timings and menus
- 📅 **Timetable** - View your class schedule
- 📆 **Events & Holidays** - Keep track of upcoming events and holidays
- 💰 **Debt Tracker** - Manage and track personal debts and expenses

## Screenshots

The app features a dark theme with a clean, modern UI built with Flutter Material Design.

## Getting Started

### Prerequisites

- Flutter SDK (3.7.0 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- An IDE (VS Code or Android Studio recommended)

### Installation

1. Clone the repository:
```bash
git clone <your-repo-url>
cd Csell
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── api_service.dart          # API service for fetching data
└── pages/
    ├── home.dart            # Home screen with navigation
    ├── bus.dart             # Bus schedule page
    ├── mess.dart            # Mess schedule page
    ├── timetable.dart       # Class timetable page
    ├── events_and_holidays.dart  # Events and holidays page
    └── debt_tracker.dart    # Debt tracking page
```

## Dependencies

- `http: ^1.3.0` - For API calls
- `shared_preferences: ^2.2.2` - For local data storage
- `intl: ^0.19.0` - For date/time formatting
- `flutter_svg: ^2.0.17` - For SVG support
- `flutter_launcher_icons: ^0.14.3` - For app icon generation

## Custom Fonts

The app uses several custom fonts:
- LilitaOne
- Child
- Please
- Sacrifice
- Roboto
- Round (default)

## API Integration

The app fetches data from Google Apps Script endpoints. The API URLs are configured in the respective page files.

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web
```

## Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## Development

This project uses Flutter's standard project structure. The app is configured to run in portrait mode only.

## Notes

- The app uses Google Apps Script for backend API functionality
- Data is cached locally using SharedPreferences for offline access
- Bus schedules update every 30 seconds to show the next available bus

## License

This project is open source and available for use.

## Contributing

Feel free to submit issues and enhancement requests!
