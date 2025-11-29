# SMM Panel Android App

A fully featured SMM (Social Media Marketing) Panel Android application built with Flutter. This app connects to SMM Panel backend servers and provides a complete mobile experience for managing social media marketing services.

## Features

- **User Authentication**: Login/Register with API or offline mode
- **Dashboard**: View order statistics, balance, and quick actions
- **Services Browser**: Browse SMM services by category (Instagram, TikTok, YouTube, Twitter, etc.)
- **Order Management**: Create and track orders
- **User Profile**: View profile, balance, and app settings
- **API Integration**: Connect to any SMM Panel backend server
- **Offline Mode**: Works without server connection using local storage

## Screenshots

The app includes:
- Login/Register screens with tabs
- Dashboard with statistics cards
- Services browser with category sidebar
- Order creation modal
- Order history list
- Profile management

## API Compatibility

This app is designed to work with SMM Panel backends that implement standard API endpoints:
- `POST /api/login` - User authentication
- `POST /api/register` - User registration
- `GET /api/me` - Get user profile
- `GET /api/categories` - Get service categories
- `GET /api/products` - Get products/services
- `POST /api/orders` - Get user orders
- `POST /api/orders/create` - Create new order

Compatible with: [SMM-backend-server-CRM-site-management](https://github.com/SMMPanelRU/SMM-backend-server-CRM-site-management)

## Default Credentials (Offline Mode)

- **Email**: `admin@admin.com`
- **Password**: `admin123`

## How to Build

### Prerequisites
- Flutter SDK (stable channel)
- Android SDK

### Build Locally

```bash
cd smm_flutter_app

# Create platform files if missing
flutter create .

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# The APK will be at: build/app/outputs/flutter-apk/app-release.apk
```

### Using CI/CD

Push to the `main` branch or trigger the workflow manually. The GitHub Actions workflow will:
1. Set up Flutter environment
2. Build the release APK
3. Upload the APK as an artifact named `smm-release-apk`

## Configuration

1. Open the app
2. Go to Settings (gear icon on login screen or in Profile tab)
3. Enter your SMM Panel API URL (e.g., `https://your-panel.com`)
4. Test the connection
5. Save settings

## Project Structure

```
smm_flutter_app/
├── lib/
│   ├── main.dart           # Main app with all screens
│   ├── models/
│   │   ├── user.dart       # User model
│   │   ├── category.dart   # Category model
│   │   ├── product.dart    # Product/Service model
│   │   └── order.dart      # Order model
│   └── services/
│       └── api_service.dart # API client
└── pubspec.yaml
```

## Demo Services (Offline Mode)

The app includes demo services for testing without a backend:
- **Instagram**: Followers, Likes, Views
- **TikTok**: Followers, Likes, Views
- **YouTube**: Subscribers, Views, Likes
- **Twitter/X**: Followers, Likes, Retweets

## License

MIT License
