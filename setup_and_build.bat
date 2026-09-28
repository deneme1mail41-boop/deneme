@echo off
setlocal
cd /d %~dp0

echo [1/6] Flutter kontrolu...
where flutter >nul 2>&1
if errorlevel 1 (
  echo HATA: Flutter PATH icinde bulunamadi.
  exit /b 1
)
flutter --version

if not exist android\app\src\main\AndroidManifest.xml (
  echo [2/6] Android platform dosyalari olusturuluyor...
  flutter create --platforms=android --org com.behcet --project-name loto_kolon_uretici .
  if errorlevel 1 exit /b 1
)

echo [3/6] INTERNET izni kontrol ediliyor...
findstr /C:"android.permission.INTERNET" android\app\src\main\AndroidManifest.xml >nul 2>&1
if errorlevel 1 (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$p='android/app/src/main/AndroidManifest.xml'; $s=Get-Content $p -Raw; if($s -notmatch 'android.permission.INTERNET'){ $s=$s -replace '(<manifest[^>]*>)','$1`r`n    <uses-permission android:name=\"android.permission.INTERNET\" />'}; Set-Content -Path $p -Value $s -Encoding UTF8"
)

echo [4/6] Paketler ve analiz...
flutter clean
if errorlevel 1 exit /b 1
flutter pub get
if errorlevel 1 exit /b 1
flutter analyze
if errorlevel 1 exit /b 1

 echo [5/6] Testler...
flutter test
if errorlevel 1 exit /b 1

echo [6/6] Release APK...
flutter build apk --release
if errorlevel 1 exit /b 1

if not exist build\app\outputs\flutter-apk\app-release.apk (
  echo HATA: APK dosyasi olusmadi.
  exit /b 1
)

echo.
echo =============================================
echo BASARILI: APK olusturuldu.
echo build\app\outputs\flutter-apk\app-release.apk
echo =============================================
endlocal
