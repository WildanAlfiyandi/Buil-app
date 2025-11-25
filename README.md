# Buil-app

Project contains a minimal Flutter SMM demo in `smm_flutter_app/`.

**Notes**
- Default admin credentials: `admin@admin.com` / `admin123`
- The repository includes a GitHub Actions workflow to build a release APK.

How to build locally (requires Flutter SDK installed):

```bash
cd smm_flutter_app
# create platform files if missing
flutter create .
flutter pub get
flutter build apk --release
# resulting APK: build/app/outputs/flutter-apk/app-release.apk
```

To trigger CI build: open the Actions tab or push to `main`. The produced artifact is `smm-release-apk`.
