@echo off
REM Script to fix flutter analyze errors by cleaning and regenerating code

echo Navigating to mobile app directory...
cd /d "D:\Desktop\KMUTT\SYSS\CSC234\unishare-flutter\apps\mobile"

echo.
echo 1. Cleaning flutter build...
call flutter clean

echo.
echo 2. Getting dependencies...
call flutter pub get

echo.
echo 3. Running build_runner to regenerate code...
call dart run build_runner build --delete-conflicting-outputs

echo.
echo 4. Running flutter analyze to check for errors...
call flutter analyze

echo.
echo Done! Now you can commit.
pause
