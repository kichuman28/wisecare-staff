# 🌟 WiseCare Staff App

<div align="center">

<img src="assets/logo/logo_no_text.png" alt="Wise Care Banner" width="150" align="center"/>

[![Flutter](https://img.shields.io/badge/Flutter-3.6.0-blue.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

*A powerful Flutter application for healthcare staff management and coordination*

</div>

## 🚀 Features

- 📱 **Cross-Platform Support**: Runs seamlessly on iOS, Android, Web, and Desktop
- 🔐 **Secure Authentication**: Firebase-powered user authentication system
- 📍 **Real-time Location Tracking**: Track staff locations with Google Maps integration
- 💬 **Instant Communication**: Real-time messaging using WebSocket
- 🔄 **State Management**: Efficient state handling with Provider
- 📦 **Offline Support**: Local data persistence using Hive
- 🎨 **Modern UI/UX**: Beautiful and responsive design with custom Quicksand font

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.6.0
- **State Management**: Provider
- **Backend Services**: Firebase (Auth, Firestore)
- **Local Storage**: Hive
- **Maps**: Google Maps Flutter
- **Network**: HTTP, WebSocket
- **UI Components**: Cached Network Image, Flutter SVG, Shimmer

## 📋 Prerequisites

Before you begin, ensure you have the following installed:
- [Flutter](https://flutter.dev/docs/get-started/install) (v3.6.0 or higher)
- [Dart](https://dart.dev/get-dart)
- [Git](https://git-scm.com/)
- [Firebase CLI](https://firebase.google.com/docs/cli) (for deployment)

## 🚀 Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/kichuman28/wisecare-staff.git
   cd wisecare-staff
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a new Firebase project
   - Add your Firebase configuration files:
     - `google-services.json` for Android
     - `GoogleService-Info.plist` for iOS
   - Enable Authentication and Firestore in Firebase Console

4. **Run the app**
   ```bash
   flutter run
   ```

## 📱 Screenshots

<div align="center">
<table>
  <tr>
    <td><img src="screenshots/dashboard screen.jpg" width="200" alt="Dashboard Screen"/></td>
    <td><img src="screenshots/tasks screen.jpg" width="200" alt="Tasks Screen"/></td>
  </tr>
  <tr>
    <td><img src="screenshots/patients screen.jpg" width="200" alt="Patients Screen"/></td>
    <td><img src="screenshots/profile screen.jpg" width="200" alt="Profile Screen"/></td>
  </tr>
</table>
</div>

## 🏗️ Project Structure

```
lib/
├── models/         # Data models
├── providers/      # State management
├── screens/        # UI screens
├── services/       # API and business logic
├── utils/          # Helper functions
└── widgets/        # Reusable UI components
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add: some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Adwaith Jayasankar** - *Initial work* - [YourGithub](https://github.com/kichuman28)
- **Abel Boby** - *Initial work* - [YourGithub](https://github.com/abelboby)

## 🙏 Acknowledgments

- Flutter Team for the amazing framework
- Firebase for backend services
- All contributors who helped with the project

## 📞 Support

For support, email support@wisecare.com or join our Slack channel.

---

<div align="center">
Made with ❤️ by the WiseCare Team
</div>
