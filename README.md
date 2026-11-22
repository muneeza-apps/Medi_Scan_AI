# 🩺 MediScanAI — Edge-AI & IoT Clinical Decision Support System

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Edge AI](https://img.shields.io/badge/Edge_AI-TFLite_%7C_Offline-FF6F00?style=for-the-badge&logo=tensorflow&logoColor=white)](https://www.tensorflow.org/lite)
[![IoT Hardware](https://img.shields.io/badge/IoT-ESP32_%7C_BLE-E7352C?style=for-the-badge&logo=espressif&logoColor=white)](https://www.espressif.com/)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

**MediScanAI** is a multi-platform, offline-capable clinical triage and patient monitoring system developed as an undergraduate Final Year Project. It bridges **on-device Computer Vision**, **Natural Language Symptom Analysis**, and **Bluetooth Low Energy (BLE) IoT telemetry** to deliver rapid diagnostic insights without relying on continuous cloud connectivity—preserving patient privacy and ensuring reliability in low-bandwidth clinical environments.

---

## 🌟 Key Features

* **Offline Symptom Triage:** Structured symptom intake and AI-assisted preliminary risk stratification running locally on mobile hardware.
* **Edge Vision Diagnostics:** On-device medical image screening (e.g., dermatological/ocular/wound captures) using quantized neural networks for sub-second inference.
* **Real-Time IoT Vitals Telemetry:** Seamless BLE integration with a custom ESP32 sensor node to stream heart rate, SpO₂, and body temperature directly into the mobile dashboard.
* **Zero-Cloud Privacy Architecture:** Patient telemetry and diagnostic inference remain on-device by default, eliminating third-party data exposure.
* **Web Clinical Portal:** Companion web interface for reviewing exported patient reports and longitudinal vitals history.

---

## 🏗️ System Architecture

```text
+-----------------------+       BLE (GATT)       +-----------------------+
|   IoT Sensor Node     | ---------------------> |   Flutter Mobile App  |
|  (ESP32 + Biometrics) |                        |  (MediScanAI Client)  |
+-----------------------+                        +-----------+-----------+
                                                             |
                                    +------------------------+------------------------+
                                    |                                                 |
                                    v                                                 v
                       +-------------------------+                       +-------------------------+
                       |   Edge AI Inference     |                       |   Local Encrypted DB    |
                       | (TFLite Vision & NLP)   |                       | (SQLite / Hive Storage) |
                       +-------------------------+                       +------------+------------+
                                                                                      |
                                                                                      | Optional Sync
                                                                                      v
                                                                         +-------------------------+
                                                                         |   Clinical Web Portal   |
                                                                         +-------------------------+
