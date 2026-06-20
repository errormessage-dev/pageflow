# Installing Flutter for Pageflow

Since Flutter is not currently installed on your system, here's how to install it:

## Option 1: Download Flutter SDK (Recommended)

1. **Download Flutter SDK**:
   - Go to https://flutter.dev/docs/get-started/install/windows
   - Download the Flutter SDK zip file
   - Extract it to a location like `C:\flutter`

2. **Add Flutter to PATH**:
   - Open System Properties → Advanced → Environment Variables
   - Add `C:\flutter\bin` to your PATH variable
   - Restart your terminal/PowerShell

3. **Verify Installation**:
   ```bash
   flutter doctor
   ```

## Option 2: Using Chocolatey (if you have it)

```bash
choco install flutter
```

## Option 3: Using winget (Windows 10/11)

```bash
winget install Flutter.Flutter
```

## After Installing Flutter

1. **Get Dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run the App**:
   ```bash
   # For Windows desktop
   flutter run -d windows
   
   # For web browser
   flutter run -d edge
   
   # For Chrome browser
   flutter run -d chrome
   ```

3. **Check Available Devices**:
   ```bash
   flutter devices
   ```

## Troubleshooting

If you get permission errors:
- Run PowerShell as Administrator
- Or use the Windows setup script: `scripts\setup.bat`

## Next Steps

Once Flutter is installed, you can:
- Run the app on Windows desktop
- Test in web browsers
- Build for Android/iOS when you have those platforms set up

The app will work great on Windows and web for testing the PDF functionality! 