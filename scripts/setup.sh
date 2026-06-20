#!/bin/bash

echo "🚀 Setting up Pageflow development environment..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first:"
    echo "   https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter is installed"

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Check for connected devices
echo "📱 Checking for connected devices..."
flutter devices

echo "🎉 Setup complete!"
echo ""
echo "To run the app:"
echo "  flutter run"
echo ""
echo "To build for Android:"
echo "  flutter build apk --release"
echo ""
echo "To build for iOS:"
echo "  flutter build ios --release" 