# SLChess Client Flutter

A modern chess application built with Flutter that offers both online and offline chess gameplay, puzzles, and social features.

## Features

- 🎮 Online and offline chess gameplay
- 🧩 Chess puzzles and training
- 👥 User profiles and leaderboards
- 🔐 Secure authentication with AWS Amplify
- 💳 Integrated payment system (ZaloPay)
- 📱 Cross-platform support (Android, iOS, Web, Windows, Linux, macOS)
- 🎯 Real-time matchmaking
- 📊 Match history and statistics
- 🔄 Active matches tracking

## Getting Started

### Prerequisites

- Flutter SDK (^3.5.4)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- AWS Account (for authentication and backend services)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/slchess-client-flutter.git
cd slchess-client-flutter
```

2. Install dependencies:
```bash
flutter pub get
```

3. Create a `.env` file in the root directory with your configuration:

4. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── core/
│   ├── models/         # Data models
│   ├── screens/        # UI screens
│   ├── services/       # Business logic and API services
│   └── widgets/        # Reusable UI components
├── assets/            # Images, fonts, and other static assets
└── main.dart          # Application entry point
```

## Dependencies

- **Authentication**: `amplify_flutter`, `amplify_auth_cognito`
- **State Management**: `hive`, `hive_flutter`
- **Networking**: `http`, `web_socket_channel`
- **UI Components**: `scrollable_positioned_list`
- **Storage**: `flutter_secure_storage`, `shared_preferences`
- **Chess Logic**: `chess`
- **API Integration**: `graphql`
- **Payment**: `flutter_zalopay_sdk`

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Chess piece assets and resources
- AWS Amplify for backend services
- Flutter team for the amazing framework
