# ⚡ Quick Commands Reference

## 🚀 Running the App

```bash
# Run on Chrome (Web) - Easiest for testing
flutter run -d chrome

# Run on Android emulator
flutter run -d android

# Run on connected Android device
flutter run

# Run in release mode (better performance)
flutter run --release -d chrome
```

## 📦 Package Management

```bash
# Install all dependencies
flutter pub get

# Update dependencies
flutter pub upgrade

# Clean build cache
flutter clean

# Rebuild after clean
flutter pub get
```

## 🛠️ Development Commands

```bash
# Check for issues
flutter doctor

# Analyze code
flutter analyze

# Format code
dart format lib/

# Build for Web
flutter build web

# Build for Android APK
flutter build apk

# Build for Android App Bundle
flutter build appbundle
```

## 🔥 Firebase Commands

```bash
# These are handled in the code automatically
# Just make sure your .env file is configured!
```

## 🎨 VS Code Tips

### Recommended Extensions:
1. **Flutter** (by Dart Code)
2. **Dart** (by Dart Code)
3. **Error Lens** (shows errors inline)
4. **Prettier** (code formatting)
5. **Material Icon Theme** (nice icons)

### Keyboard Shortcuts:
- `Ctrl + Shift + P` - Command palette
- `F5` - Run app
- `Shift + F5` - Stop app
- `r` (in terminal) - Hot reload
- `R` (in terminal) - Hot restart
- `q` - Quit

## 🐛 Debugging

```bash
# Run with debug logging
flutter run -v

# Check device info
flutter devices

# Clear app data (Android)
flutter run --clear-cache
```

## 📱 Emulator Management

```bash
# List available emulators
flutter emulators

# Launch specific emulator
flutter emulators --launch <emulator-id>

# Launch Chrome for web
flutter run -d chrome
```

## 🎯 Most Used Commands (Copy These!)

```bash
# Start fresh (if something breaks)
flutter clean && flutter pub get && flutter run -d chrome

# Quick test on web
flutter run -d chrome

# Build production web app
flutter build web --release

# Build production Android APK
flutter build apk --release
```

## 📊 Performance

```bash
# Run with performance overlay
flutter run --profile

# Measure app size
flutter build apk --analyze-size

# Check for performance issues
flutter run --trace-skia
```

## 🔍 Finding Issues

```bash
# If build fails, try:
flutter clean
flutter pub get
flutter run -d chrome

# If dependencies conflict, try:
flutter pub upgrade --major-versions
```

## 💡 Pro Tips

1. **Always run `flutter pub get` after adding dependencies**
2. **Use hot reload (`r`) instead of restarting the app**
3. **Test on Web first (faster iteration)**
4. **Run `flutter clean` if weird errors occur**
5. **Keep Flutter updated:** `flutter upgrade`

---

**Save this file! You'll use these commands often.** 📌
