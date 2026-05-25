```markdown
# 💧 AquaMax: AI-Powered Water Quality & Irrigation Monitoring System

![ESP32](https://img.shields.io/badge/ESP32-Hardware-222222?style=for-the-badge&logo=espressif)
![Flutter](https://img.shields.io/badge/Flutter-Mobile_App-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![OpenAI](https://img.shields.io/badge/GPT--4o-Vision_AI-412991?style=for-the-badge&logo=openai&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-success?style=for-the-badge)

**AquaMax** is a comprehensive IoT and AI-based system that monitors water quality and assists in irrigation decisions using real-time sensor data, an **ESP32** microcontroller, a **Flutter** mobile application, and **GPT-4o Vision**. 

The system collects physical water parameters, processes them on-device, sends them to a mobile app via BLE, and merges them with visual data for advanced AI agricultural analysis.

*(Add your real system diagram image here)*
> `![System Architecture](link_to_your_diagram.png)`

---

## 🧩 System Overview

The project is divided into three tightly integrated components:

**ESP32 Firmware ➔ Flutter Mobile App ➔ GPT-4o Vision (AI Pipeline)**

**Flow:**
1. Sensors collect water data.
2. ESP32 processes and sends data via BLE.
3. Flutter app receives, visualizes, and bundles data with environmental images.
4. Unified data is sent to GPT-4o Vision for intelligent agricultural insights.

---

## ⚙️ Hardware Layer (ESP32)

The ESP32 acts as the core edge device, handling:
* Reading sensor data (TDS, Turbidity, Temperature).
* Basic signal processing (Temperature compensation for TDS, basic noise filtering).
* Broadcasting data via Bluetooth Low Energy (BLE).

**Sensors Used:**
* **TDS Sensor:** Measures water dissolved solids.
* **Turbidity Sensor:** Measures water clarity.
* **DS18B20:** Digital temperature sensor.

**Example BLE Output Format (JSON):**
```json
{
  "tds": 450,
  "turbidity": 120,
  "temp": 25.6
}

```

---

## 📱 Mobile App (Flutter)

Built using Flutter, the application serves as the user interface and AI gateway.

*(Add your UI screenshots here)*

> `![App Dashboard](link_to_dashboard_image.png)`

**The App:**

* Connects to ESP32 via BLE (Update rate: ~1–2 seconds).
* Receives live sensor data.
* Displays dashboards and reports.
* Stores historical readings locally.

**Main Screens:**

* **Dashboard:** Live sensor values and status.
* **Reports:** History and analytical trends.
* **Settings:** Device pairing and configurations.

---

## 🧠 AI Vision Analysis (Core Feature)

AquaMax integrates **GPT-4o Vision** as a core system component, not an optional feature, to enhance decision-making beyond raw sensor data. This module allows the system to combine real-time sensor readings, visual input from the environment, and contextual AI reasoning.

### 📸 How It Works

1. The mobile app captures an image of the water source or irrigation environment.
2. The image is processed and base64 encoded.
3. It is combined with live sensor data from the ESP32.
4. The unified payload is sent to the AI model.
5. The model returns a structured analysis of water quality and environmental conditions.

### 🧾 Unified Input Data Structure

```json
{
  "image": "base64_encoded_image",
  "tds": 450,
  "turbidity": 120,
  "temperature": 25.6
}

```

### 📤 AI Output Example

```json
{
  "water_quality": "moderate",
  "risk_level": "medium",
  "irrigation_recommendation": "suitable with caution",
  "notes": "Possible sediment presence detected in visual input."
}

```

### 🎯 Why This Is a Core Feature

Unlike traditional IoT systems that rely only on numerical sensor data, AquaMax uses multimodal analysis:

* **Sensor data** ➔ gives precise measurements.
* **Vision data** ➔ provides environmental context.
* **AI reasoning** ➔ merges both into actionable insights.

### ⚡ System Impact

* Detects issues that sensors alone cannot identify (e.g., algae, discoloration).
* Improves reliability of irrigation recommendations.
* Enables smarter agricultural decision-making.

---

## 📁 Project Structure

```text
AquaMax/
├── ESP32/        # Firmware code (Arduino/C++)
├── FlutterApp/   # Mobile application (Dart/Flutter)
└── Design/       # UI/UX assets, 3D enclosures & mockups

```

---

## 🚀 How to Run

### 1. ESP32 Firmware

1. Open the `ESP32/` directory.
2. Open the project using **Arduino IDE** or **PlatformIO**.
3. Compile and upload to your ESP32 board.

### 2. Flutter App

```bash
cd FlutterApp/aquifer_iq
flutter pub get
flutter run

```

*Note: iOS/Android Emulators do NOT support BLE. A physical device is required to pair and receive sensor data.*

---

## 📊 Features & Tech Stack

* **Real-time water monitoring:** Instant physical parameter reading.
* **BLE Communication:** Robust, low-latency device-to-mobile sync.
* **Mobile Dashboard:** Clean, reactive visualization.
* **Multimodal AI Analysis:** Fusing hardware data with computer vision.
* **Modular Architecture:** Clean separation of concerns across layers.

**Tech Stack:** ESP32 (Arduino C++) | Flutter (Dart) | Bluetooth Low Energy (BLE) | OpenAI GPT-4o Vision API

---

## 📄 License

This project is licensed under the MIT License.

```

```
