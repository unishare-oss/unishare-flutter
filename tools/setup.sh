#!/usr/bin/env sh
set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"

echo "==> Checking prerequisites..."
if ! command -v flutter > /dev/null 2>&1; then
  echo "Error: flutter not found. Install Flutter from https://docs.flutter.dev/get-started/install"
  exit 1
fi

echo "==> Installing git hooks..."
ln -sf ../../tools/hooks/pre-commit "$REPO_ROOT/.git/hooks/pre-commit"
echo "    pre-commit hook linked."

echo "==> Installing Flutter dependencies..."
cd "$REPO_ROOT/apps/mobile"
flutter pub get

echo "==> Running code generation..."
dart run build_runner build

echo ""
echo "Setup complete!"
echo ""
echo "ACTION REQUIRED — obtain these files from a team member and place them at the paths shown:"
echo "  apps/mobile/lib/firebase_options.dart"
echo "  apps/mobile/android/app/google-services.json"
echo "  apps/mobile/ios/Runner/GoogleService-Info.plist"
echo ""
echo "Without these files the app will not build."
