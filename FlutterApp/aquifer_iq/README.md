# Aquifer IQ — Flutter App

Smart Water Quality Monitor with BLE + Gemini AI

## Project Structure

```
lib/
├── main.dart                    # Entry point + Provider setup
├── screens/
│   └── dashboard_screen.dart   # Main UI screen
├── services/
│   ├── ble_service.dart        # BLE connection + data parsing
│   └── ai_service.dart         # Gemini AI visual analysis
└── widgets/
    └── gauge_widget.dart       # Circular gauge component
```

## Setup Steps

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Gemini API Key
- Go to https://aistudio.google.com
- Create an API key
- Replace `YOUR_GEMINI_API_KEY` in `lib/services/ai_service.dart`

### 3. ESP32 BLE UUIDs
In `lib/services/ble_service.dart`, update:
- `SERVICE_UUID` → match your ESP32 BLE service UUID
- `CHARACTERISTIC_UUID` → match your ESP32 characteristic UUID
- Device name `"AquiferIQ"` → match your ESP32's advertised name

### 4. ESP32 Data Format
The ESP32 must send JSON over BLE notifications:
```json
{"tds": 120.5, "purity": 98.2, "temp": 22.1}
```

### 5. Run
```bash
flutter run
```

## Android Min SDK
Make sure `android/app/build.gradle` has:
```gradle
minSdkVersion 21
```

## Notes
- BLE scanning requires Location permission on Android (system requirement)
- Tap the connection pill in the header to start scanning
- Tap it again while connected to disconnect
