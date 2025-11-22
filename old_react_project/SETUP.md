# 🚀 Silni Setup Guide

## Prerequisites

- Node.js 18+ installed
- iOS Simulator (XCode) for iOS development
- Android Studio for Android development

## Quick Start

### 1. Install Dependencies

```bash
npm install
```

### 2. Choose Your Development Mode

#### Option A: iOS Development Build (Recommended)

This app uses custom native modules that require a development build:
- `@shopify/react-native-skia` - For liquid animations
- `react-native-reanimated` - For smooth animations
- `expo-blur` - For glassmorphism effects
- `react-native-worklets-core` - For worklets

**Build and Run:**

```bash
# First time (takes 5-10 minutes)
npx expo run:ios

# Subsequent runs (much faster)
npm start
# Press 'i' for iOS
```

#### Option B: Android Development Build

```bash
# First time
npx expo run:android

# Subsequent runs
npm start
# Press 'a' for Android
```

### 3. Development Workflow

After the first build:

```bash
# Start the development server
npm start

# Then:
# - Press 'i' for iOS simulator
# - Press 'a' for Android emulator
# - Scan QR code with Expo Go app (limited features)
```

## 🎨 UI Features Implemented

### WOW Animations (Better than Headspace!)

1. **Liquid/Blob Morphing Background**
   - Headspace-style organic animations
   - GPU-accelerated with Skia
   - Multiple morphing blobs

2. **Glassmorphism**
   - Frosted glass cards
   - Blur effects
   - Depth and layering

3. **3D Card Flips**
   - Tap the streak card to flip
   - Perspective transforms
   - Spring physics

4. **Particle Confetti**
   - Celebrates every 7-day streak
   - 400 particles
   - Haptic feedback

5. **Parallax Scrolling**
   - Multi-layer depth
   - Different speeds per section
   - Opacity fades

6. **Spring Physics**
   - Bouncy button interactions
   - Scale animations
   - Haptic feedback

## 🐛 Troubleshooting

### Worklets Version Mismatch

If you see: `Mismatch between JavaScript part and native part of Worklets`

**Solution:**
```bash
# Stop the server (Ctrl+C)
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
npx expo start --clear
```

Or simply:
```bash
npx expo run:ios --clean
```

### Firebase Analytics Warnings

These are suppressed in the code (Analytics not supported in React Native).
If you still see them:
```bash
npx expo start --clear
```

### Cache Issues

If changes don't appear:
```bash
npx expo start --clear
```

### Native Module Not Found

Make sure you're using a development build, not Expo Go:
```bash
npx expo run:ios  # or run:android
```

## 📁 Project Structure

```
Silni/
├── src/
│   ├── components/
│   │   ├── animated/     # WOW UI animations
│   │   └── ui/           # Glass cards, gradients
│   ├── screens/
│   │   ├── auth/         # Login, Signup, Onboarding
│   │   └── main/         # Home, Relatives, Stats, More
│   ├── navigation/       # App navigation
│   ├── store/           # Zustand state management
│   ├── services/        # Firebase, Auth, Storage
│   ├── constants/       # Colors, Typography, Spacing
│   └── config/          # Firebase config
├── docs/                # PRD and documentation
└── App.tsx             # Entry point
```

## 🔥 Firebase Setup

Firebase is already configured in `src/config/firebase.ts`.

**Features:**
- Authentication with AsyncStorage persistence
- Firestore database
- Firebase Storage
- Analytics disabled (not supported in React Native)

## 📱 Running on Physical Device

### iOS:

```bash
npx expo run:ios --device
```

### Android:

```bash
npx expo run:android --device
```

## 🚢 Building for Production

### Using EAS Build (Recommended)

```bash
# Install EAS CLI
npm install -g eas-cli

# Login
eas login

# Configure
eas build:configure

# Build for iOS
eas build --platform ios

# Build for Android
eas build --platform android
```

## 📚 Resources

- [Expo Documentation](https://docs.expo.dev)
- [React Native](https://reactnative.dev)
- [Firebase](https://firebase.google.com/docs)
- [Silni PRD](./docs/silni_full_prd.md)

## 🆘 Need Help?

1. Check [Expo Troubleshooting](https://docs.expo.dev/troubleshooting/overview/)
2. Check Firebase logs in console
3. Clear cache: `npx expo start --clear`
4. Clean build: `npx expo run:ios --clean`

## 🎯 Next Steps

1. Build the app: `npx expo run:ios`
2. Test all animations and interactions
3. Continue with authentication flows
4. Implement relatives management
5. Add interaction tracking
6. Build statistics dashboard

---

**Made with 💚 for صلة الرحم**
