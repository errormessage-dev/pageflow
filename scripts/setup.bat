@echo off
echo 🚀 Setting up Pageflow development environment...

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter is not installed. Please install Flutter first:
    echo    https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo ✅ Flutter is installed

REM Get dependencies
echo 📦 Getting Flutter dependencies...
flutter pub get

REM Check for connected devices
echo 📱 Checking for connected devices...
flutter devices

echo 🎉 Setup complete!
echo.
echo To run the app:
echo   flutter run
echo.
echo To build for Android:
echo   flutter build apk --release
echo.
echo To build for iOS:
echo   flutter build ios --release
pause 