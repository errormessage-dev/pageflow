# Pageflow 📄➡️📱

A mobile app that converts PDF documents to HTML for easier reading on mobile devices. Built with Flutter and PDF.js, Pageflow provides a seamless reading experience optimized for mobile screens.

## Features ✨

- **PDF to HTML Conversion**: Convert PDF documents to HTML format for better mobile readability
- **Cross-Platform**: Available for both Android and iOS devices
- **No Backend Required**: Works entirely on-device using PDF.js
- **Touch Gestures**: Swipe up/down to navigate between pages
- **Zoom Controls**: Pinch to zoom and dedicated zoom buttons
- **Modern UI**: Beautiful, intuitive interface with Material Design
- **File Picker**: Easy PDF selection from device storage
- **Responsive Design**: Optimized for various screen sizes

## Screenshots 📸

*Screenshots will be added after the app is built and tested*

## Getting Started 🚀

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Android Studio / Xcode (for building)
- Android device/emulator or iOS device/simulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd pageflow
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Building for Production

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle:**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## How It Works 🔧

Pageflow uses a combination of Flutter and PDF.js to provide a seamless PDF reading experience:

1. **File Selection**: Users can pick PDF files from their device using the file picker
2. **PDF Processing**: The selected PDF is copied to the app's temporary directory
3. **HTML Generation**: A custom HTML page is generated with embedded PDF.js
4. **WebView Rendering**: The HTML is displayed in a Flutter WebView
5. **Interactive Features**: Users can navigate, zoom, and interact with the PDF content

### Technical Stack

- **Frontend**: Flutter (Dart)
- **PDF Processing**: PDF.js (JavaScript library)
- **Web Rendering**: WebView Flutter plugin
- **File Handling**: File Picker and Path Provider plugins
- **Permissions**: Permission Handler plugin

## Project Structure 📁

```
pageflow/
├── lib/
│   ├── main.dart                 # App entry point
│   └── screens/
│       ├── home_screen.dart      # Main screen with file picker
│       └── pdf_viewer_screen.dart # PDF viewer with WebView
├── android/                      # Android-specific configuration
├── ios/                         # iOS-specific configuration
├── pubspec.yaml                 # Dependencies and assets
└── README.md                    # This file
```

## Dependencies 📦

- `webview_flutter`: For displaying HTML content
- `file_picker`: For selecting PDF files
- `path_provider`: For accessing device directories
- `permission_handler`: For handling file permissions

## Permissions 🔐

The app requires the following permissions:

**Android:**
- `READ_EXTERNAL_STORAGE`: To read PDF files
- `WRITE_EXTERNAL_STORAGE`: To save temporary files
- `MANAGE_EXTERNAL_STORAGE`: For Android 11+ file access
- `INTERNET`: For loading PDF.js from CDN

**iOS:**
- Document folder access
- Photo library access

## Usage Guide 📖

1. **Launch the App**: Open Pageflow on your device
2. **Select a PDF**: Tap "Open PDF" to choose a PDF file from your device
3. **Read**: The PDF will be converted to HTML and displayed in the viewer
4. **Navigate**: Use the toolbar buttons or swipe gestures to navigate pages
5. **Zoom**: Use the zoom buttons or pinch gestures to adjust the view

## Customization 🎨

### Styling
The app uses Material Design 3 with a blue color scheme. You can customize the theme in `lib/main.dart`.

### PDF.js Configuration
The PDF.js viewer is configured in `lib/screens/pdf_viewer_screen.dart`. You can modify:
- Default zoom level
- Page rendering quality
- Touch gesture sensitivity
- Toolbar appearance

## Troubleshooting 🔧

### Common Issues

1. **PDF not loading**: Ensure the PDF file is not corrupted and the app has proper permissions
2. **Slow performance**: Large PDF files may take time to load. Consider optimizing PDF size
3. **Permission denied**: Grant storage permissions when prompted

### Debug Mode
Run the app in debug mode for detailed logs:
```bash
flutter run --debug
```

## Contributing 🤝

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License 📄

This project is proprietary software. All rights reserved.

## Acknowledgments 🙏

- [PDF.js](https://mozilla.github.io/pdf.js/) - Mozilla's PDF rendering library
- [Flutter](https://flutter.dev/) - Google's UI framework
- [WebView Flutter](https://pub.dev/packages/webview_flutter) - Flutter WebView plugin

## Support 💬

If you encounter any issues or have questions, please:
1. Check the troubleshooting section
2. Search existing issues
3. Create a new issue with detailed information

---

**Made with ❤️ for better mobile reading** 