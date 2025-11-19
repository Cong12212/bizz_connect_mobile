# BizConnect Mobile

A modern Flutter mobile application for business contact relationship management (CRM). BizConnect helps professionals manage business contacts, set reminders, organize with tags, and share digital business cards on the go.

---

## 📱 Overview

BizConnect Mobile is the companion app for the BizConnect web platform, providing full-featured contact management capabilities optimized for mobile devices. Built with Flutter for cross-platform compatibility (iOS & Android).

---

## ✨ Features

### 📇 Contact Management
- **Full CRUD Operations**: Create, view, edit, and delete contacts
- **Rich Contact Profiles**: 
  - Personal info (name, job title, company)
  - Contact details (email, phone, mobile)
  - Address with multi-level location (Country → State → City)
  - Social media links (LinkedIn, website)
  - Custom notes
- **Smart Search**: Real-time search across all contact fields
- **Tag Organization**: Categorize contacts with custom tags
- **Import/Export**: 
  - Bulk import from Excel/CSV
  - Export contacts in multiple formats
- **Offline Support**: View contacts even without internet connection

### 🔔 Reminders & Follow-ups
- **Smart Reminders**: Set reminders for one or multiple contacts
- **Flexible Scheduling**: 
  - Custom date and time picker
  - Timezone-aware scheduling
  - Recurring reminders (coming soon)
- **Status Management**: Track reminder status (pending, done, skipped, cancelled)
- **Push Notifications**: Never miss a follow-up
- **Calendar Integration**: Sync with device calendar
- **Overdue Alerts**: Visual indicators for overdue tasks

### 🏷️ Tag System
- **Custom Tags**: Create unlimited tags for contact categorization
- **Visual Organization**: Color-coded tags for easy recognition
- **Bulk Operations**: Add/remove tags from multiple contacts
- **Smart Filtering**: 
  - Filter by single or multiple tags
  - AND/OR logic support
  - Exclude specific tags

### 💼 Digital Business Cards
- **Create & Share**: 
  - Design professional digital business cards
  - Include company logo and branding
  - Add all contact details and social links
- **QR Code Sharing**: Generate QR codes for instant sharing
- **Public/Private Mode**: Control card visibility
- **View Analytics**: Track how many times your card is viewed
- **Quick Connect**: Scan others' cards to add contacts instantly
- **Offline Cards**: Save cards for offline viewing

### 🔔 Notification Center
- **Unified Inbox**: All notifications in one place
- **Smart Categorization**: 
  - Reminders
  - Contact updates
  - System notifications
- **Filter Options**: View by unread, upcoming, or past
- **Quick Actions**: Mark as read, done, or archived with swipe gestures

### 📊 Dashboard
- **At-a-Glance Overview**:
  - Total contacts count
  - Pending reminders
  - Unread notifications
  - Active tags
- **Recent Activity**: Timeline of recent actions
- **Quick Actions**: Fast access to common tasks
- **Statistics**: Contact growth and engagement metrics

---

## 🛠️ Tech Stack

### Core Framework
- **Flutter 3.x** - Cross-platform UI framework
- **Dart 3.x** - Programming language

### State Management
- **Provider** / **Riverpod** - State management solution
- **BLoC Pattern** - Business logic separation

### Networking & Storage
- **Dio** - HTTP client for API requests
- **Hive** / **SQLite** - Local database for offline support
- **Shared Preferences** - Key-value storage
- **Secure Storage** - Encrypted credential storage

### Key Packages
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.1
  riverpod: ^2.4.9
  
  # Networking
  dio: ^5.4.0
  retrofit: ^4.0.3
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  sqflite: ^2.3.0
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0
  
  # UI Components
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  flutter_svg: ^2.0.9
  
  # QR Code
  qr_flutter: ^4.1.0
  qr_code_scanner: ^1.0.1
  
  # File Handling
  file_picker: ^6.1.1
  excel: ^4.0.2
  path_provider: ^2.1.1
  
  # Notifications
  flutter_local_notifications: ^16.3.0
  firebase_messaging: ^14.7.6
  
  # Calendar
  table_calendar: ^3.0.9
  syncfusion_flutter_calendar: ^24.1.41
  
  # Utils
  intl: ^0.18.1
  url_launcher: ^6.2.2
  share_plus: ^7.2.1
  permission_handler: ^11.1.0
```

---

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── app/                      # App-level configuration
│   ├── routes/              # Route definitions
│   ├── themes/              # Theme configuration
│   └── constants/           # App constants
├── core/                     # Core functionality
│   ├── api/                 # API client setup
│   ├── models/              # Data models
│   ├── services/            # Business services
│   └── utils/               # Helper utilities
├── features/                 # Feature modules
│   ├── auth/                # Authentication
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   ├── contacts/            # Contact management
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   ├── reminders/           # Reminders
│   ├── tags/                # Tag management
│   ├── notifications/       # Notification center
│   ├── business_card/       # Business cards
│   ├── dashboard/           # Dashboard
│   └── settings/            # App settings
├── shared/                   # Shared widgets & utils
│   ├── widgets/             # Reusable widgets
│   └── extensions/          # Dart extensions
└── l10n/                    # Localization files
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x or higher
- Dart SDK 3.x or higher
- Android Studio / Xcode (for mobile development)
- Backend API server running

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd bizconnect-mobile
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure API endpoint**

Create `lib/core/config/api_config.dart`:
```dart
class ApiConfig {
  static const String baseUrl = 'http://your-api-url.com/api';
  static const String wsUrl = 'ws://your-api-url.com';
}
```

Or use environment-specific configs:
```bash
# Development
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api

# Production
flutter run --dart-define=API_BASE_URL=https://api.bizconnect.com/api
```

4. **Run the app**

**iOS:**
```bash
flutter run -d ios
```

**Android:**
```bash
flutter run -d android
```

**Both (with device selection):**
```bash
flutter run
```

---

## 🔧 Configuration

### Environment Variables

Create `.env` file in project root:
```env
API_BASE_URL=http://your-api-url.com/api
API_TIMEOUT=30000
ENABLE_LOGGING=true
```

### Firebase Setup (for push notifications)

1. **Add Firebase to your project:**
   - iOS: Add `GoogleService-Info.plist` to `ios/Runner/`
   - Android: Add `google-services.json` to `android/app/`

2. **Configure Firebase in `main.dart`:**
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

### App Permissions

**iOS (`ios/Runner/Info.plist`):**
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan QR codes</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to save business cards</string>
<key>NSContactsUsageDescription</key>
<string>We need contacts access to import contacts</string>
```

**Android (`android/app/src/main/AndroidManifest.xml`):**
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

---

## 🎨 UI/UX Features

- **Material Design 3**: Modern, clean interface
- **Dark Mode Support**: Automatic theme switching
- **Responsive Layouts**: Optimized for all screen sizes
- **Smooth Animations**: Delightful micro-interactions
- **Gesture Support**: Swipe actions, pull-to-refresh
- **Accessibility**: Screen reader support, high contrast
- **Localization**: Multi-language support (EN, VI)

---

## 🔒 Authentication & Security

### Authentication Flow
1. **Login/Register** → Email & password authentication
2. **Email Verification** → Verify account via email link/code
3. **JWT Storage** → Secure token storage with encryption
4. **Auto Refresh** → Automatic token refresh on API calls
5. **Biometric Auth** → Face ID / Touch ID support (optional)

### Security Features
- Encrypted local storage for sensitive data
- Certificate pinning for API calls
- Biometric authentication option
- Auto-logout after inactivity
- Secure session management

---

## 📦 Build & Release

### Android Release Build

1. **Generate keystore:**
```bash
keytool -genkey -v -keystore ~/bizconnect-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias bizconnect
```

2. **Configure `android/key.properties`:**
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=bizconnect
storeFile=/path/to/bizconnect-key.jks
```

3. **Build APK:**
```bash
flutter build apk --release
```

4. **Build App Bundle (for Play Store):**
```bash
flutter build appbundle --release
```

### iOS Release Build

1. **Configure signing in Xcode**
2. **Build:**
```bash
flutter build ios --release
```

3. **Archive & upload to App Store Connect**

---

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test
```

### Widget Tests
```bash
flutter test test/widgets
```

### Code Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## 📊 Performance Optimization

- **Image Caching**: Cached network images for faster loading
- **Lazy Loading**: Load data on demand
- **Database Indexing**: Optimized database queries
- **Code Splitting**: Modular feature loading
- **Asset Optimization**: Compressed images and assets
- **Memory Management**: Proper dispose of resources

---

## 🐛 Troubleshooting

### Common Issues

**Build Failed**
```bash
flutter clean
flutter pub get
flutter run
```

**API Connection Issues**
- Check API base URL configuration
- Verify network permissions
- Check backend server status
- Test with Postman/curl first

**iOS Build Issues**
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter run
```

**Android Build Issues**
- Check `minSdkVersion` (minimum 21)
- Verify Gradle version compatibility
- Clean build: `flutter clean`
- Check Java version (Java 11 recommended)

**Common Errors:**
```bash
# Gradle sync failed
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get

# Pod install failed
cd ios
pod repo update
pod install
cd ..
```

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Submit Pull Request

### Coding Standards
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use meaningful variable/function names
- Add comments for complex logic
- Write tests for new features
- Update documentation
- Run `flutter analyze` before committing
- Format code with `flutter format .`

### Pull Request Guidelines
- Describe changes in detail
- Reference related issues
- Include screenshots for UI changes
- Ensure all tests pass
- Update CHANGELOG.md

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

```
MIT License

Copyright (c) 2024 BizConnect Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 👥 Team

- **Mobile Development Team** - Flutter development
- **Backend Team** - API development
- **Design Team** - UI/UX design
- **QA Team** - Testing and quality assurance

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Dart team for the powerful language
- Open source community for packages and support
- Design inspiration from modern CRM applications
- All contributors who helped improve this project

---

## 📞 Support

- **Email**: support@bizconnect.com
- **Issues**: [GitHub Issues](https://github.com/bizconnect/mobile/issues)
- **Documentation**: [docs.bizconnect.com](https://docs.bizconnect.com)
- **Community**: [Discord Server](https://discord.gg/bizconnect)

---

## 🗺️ Roadmap

### Version 1.5 (Q1 2025)
- [ ] Biometric authentication
- [ ] Enhanced offline mode
- [ ] Advanced search filters
- [ ] Batch operations
- [ ] Custom contact fields

### Version 2.0 (Q2 2025)
- [ ] Real-time sync with WebSocket
- [ ] Team collaboration features
- [ ] Advanced analytics dashboard
- [ ] Voice notes support
- [ ] Document attachments
- [ ] Meeting scheduler integration
- [ ] Email template library

### Future Features
- [ ] AI-powered contact suggestions
- [ ] Automated follow-up recommendations
- [ ] Multi-account support
- [ ] Advanced reporting and exports
- [ ] Integration with third-party CRM systems
- [ ] Customizable dashboard widgets
- [ ] Activity timeline
- [ ] Contact deduplication

---

## 📱 App Store Links

- **iOS App Store**: [Coming Soon]
- **Google Play Store**: [Coming Soon]

---

## 📸 Screenshots

### Authentication
| Login | Register | Verify Email |
|-------|----------|--------------|
| [Screenshot] | [Screenshot] | [Screenshot] |

### Dashboard & Contacts
| Dashboard | Contact List | Contact Detail |
|-----------|-------------|----------------|
| [Screenshot] | [Screenshot] | [Screenshot] |

### Reminders & Tags
| Reminders | Create Reminder | Tags |
|-----------|----------------|------|
| [Screenshot] | [Screenshot] | [Screenshot] |

### Business Cards
| My Card | Scan QR | Share Card |
|---------|---------|------------|
| [Screenshot] | [Screenshot] | [Screenshot] |

---

## 🔗 Related Projects

- **BizConnect Web**: [github.com/bizconnect/web](https://github.com/bizconnect/web) - React web application
- **BizConnect API**: [github.com/bizconnect/api](https://github.com/bizconnect/api) - Laravel backend API
- **BizConnect Admin**: [github.com/bizconnect/admin](https://github.com/bizconnect/admin) - Admin dashboard

---

## 📊 Project Stats

![GitHub stars](https://img.shields.io/github/stars/bizconnect/mobile)
![GitHub forks](https://img.shields.io/github/forks/bizconnect/mobile)
![GitHub issues](https://img.shields.io/github/issues/bizconnect/mobile)
![GitHub license](https://img.shields.io/github/license/bizconnect/mobile)
![Flutter version](https://img.shields.io/badge/Flutter-3.x-blue)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-green)

---

## 🎯 Key Metrics

- **Lines of Code**: ~15,000+
- **Test Coverage**: 80%+
- **Supported Devices**: iOS 12+, Android 5.0+
- **Languages**: English, Vietnamese
- **Average Bundle Size**: ~25MB
- **Min SDK**: Android 21 (Lollipop)
- **Target SDK**: Android 34

---

## 🌟 Features in Detail

### Contact Import/Export
Supports multiple formats:
- Excel (.xlsx)
- CSV (.csv)
- vCard (.vcf)

Import features:
- Duplicate detection
- Field mapping
- Batch processing
- Error reporting

### Notification System
Types of notifications:
- Reminder alerts
- Contact updates
- System messages
- Sync status

Notification channels:
- In-app notifications
- Push notifications (Firebase)
- Email notifications
- Calendar events

### Search & Filter
Advanced search capabilities:
- Full-text search
- Field-specific search
- Tag filtering
- Date range filtering
- Status filtering
- Combination filters

---

## 💡 Best Practices

### Code Organization
- Follow feature-first structure
- Separate business logic from UI
- Use dependency injection
- Implement repository pattern
- Write reusable widgets

### State Management
- Use Provider for simple state
- Use Riverpod for complex state
- Implement proper error handling
- Handle loading states
- Cache frequently used data

### Performance
- Optimize images and assets
- Use const constructors
- Implement pagination
- Use efficient data structures
- Profile regularly with DevTools

### Testing
- Write unit tests for business logic
- Widget tests for UI components
- Integration tests for critical flows
- Mock external dependencies
- Aim for 80%+ coverage

---

## 🔐 Security Best Practices

- Never commit API keys or secrets
- Use environment variables for configuration
- Implement certificate pinning
- Encrypt sensitive local data
- Validate all user inputs
- Implement rate limiting
- Use secure HTTP (HTTPS) only
- Handle authentication token refresh
- Implement proper session management
- Regular security audits

---

## 📚 Additional Resources

### Documentation
- [Flutter Official Docs](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Material Design Guidelines](https://material.io/design)
- [iOS Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

### Tutorials
- [Flutter Cookbook](https://flutter.dev/docs/cookbook)
- [Dart Tutorials](https://dart.dev/tutorials)
- [State Management Guide](https://flutter.dev/docs/development/data-and-backend/state-mgmt)

### Community
- [Flutter Community](https://flutter.dev/community)
- [Flutter Awesome](https://flutterawesome.com/)
- [Pub.dev](https://pub.dev/) - Dart packages

---

**Version**: 1.0.0  
**Last Updated**: November 2024  
**Minimum Flutter Version**: 3.0.0  
**Supported Platforms**: iOS 12+, Android 5.0+ (API 21+)  
**Build Number**: 1  
**Release Date**: Coming Soon

---

Made with ❤️ using Flutter

**⭐ If you like this project, please give it a star on GitHub! ⭐**
