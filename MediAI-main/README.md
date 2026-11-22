# MediAI - Edge-AI Dermatological Triage and Biosensor Telemetry System

MediAI is a specialized, zero-cloud medical edge platform developed for low-resource and rural clinics across Pakistan where internet connectivity is intermittent or completely absent. It integrates localized on-device deep learning triage, multi-modal medical IoT telemetry, an embedded DRAP pharmacology database, and safe clinical guardrails.

---

## 1. System Architecture & Zero-Cloud Edge Pipeline

- **100% On-Device Framework**: Operates entirely offline without requiring cloud APIs, external microservices, or internet connectivity.
- **DermaPulse Neural Engine**: Executes quantized INT8/FP16 models via the local TensorFlow Lite (TFLite) C++ runtime with persistent 4-thread CPU interpreter execution.
- **Ultra-Low Latency (<90ms)**: Edge inference executes in under 90 milliseconds on mobile ARM chipsets, enabling immediate clinical feedback in primary healthcare centers.
- **Deterministic Edge Synthesis**: Clinical summaries, bilingual explanations, observations, and recommendations are synthesized locally on-device.

---

## 2. Input Quality Gate & Skin Tone Fairness

MediAI replaces naive heuristic HSV filtering with an on-device multi-stage quality assurance gate:
1. **Laplacian Variance Motion-Blur Rejection**:
   - Convolves downsampled grayscale frames with a discrete $3 \times 3$ Laplacian kernel.
   - Measures edge sharpness variance; images falling below threshold ($\sigma^2 < 14.0$) are rejected before model inference with bilingual retake guidance.
2. **Ambient Luminance Thresholding**:
   - Analyzes mean photometric luminance to eliminate extreme deep shadows ($\mu_Y < 32.0$ or $>65\%$ shadow area) and harsh specular glare ($\mu_Y > 238.0$ or $>40\%$ saturated highlights).
3. **Fitzpatrick Skin Tone Fairness (Types III to V)**:
   - Specifically calibrated for the ethnic demographic baseline of South Asian populations (Fitzpatrick skin types III, IV, and V).
   - Utilizes dual YCbCr and normalized RGB chromaticity models to prevent false out-of-domain rejections of darker or tanned skin tones and active erythematous/inflammatory lesions.
4. **Demographic Baseline Dataset**:
   - Primary diagnostic classifiers are powered by the proprietary DermaPulse clinical dataset (24 clinical dermatological classes), with demographic baseline characteristics explicitly documented.

---

## 3. Offline Localized Pharmacology Module

- **Embedded DRAP Database**: Standalone local database of Drug Regulatory Authority of Pakistan (DRAP) approved over-the-counter (OTC) dermatological topicals and soothing formulations.
- **Zero Cloud API Dependency**: Fully replaces unstable external cloud APIs (e.g., OpenFDA) with deterministic local brand and generic mappings (e.g., *Polyfax*, *Canesten*, *Dermaspor*, *Fucidin*, *Calamox*, *Permethrin/Scabite*, *Hydrocortisone*).
- **Instant Bilingual Self-Care Guidance**: Provides instantaneous English and Urdu application instructions, DRAP registration numbers, safety contraindications, and precautions offline.

---

## 4. Multi-Modal Biosensor Telemetry & Safe Clinical Guardrails

- **ESP32-S3 Microcontroller Telemetry via BLE**:
  - **MAX30102 PPG**: High-precision Photoplethysmography streaming Heart Rate (HR), Blood Oxygen Saturation ($\text{SpO}_2$), Perfusion Index, and cuffless Estimated Blood Pressure via Pulse Wave Analysis (PWA).
  - **MLX90614 Contactless IR**: Dual-channel ambient and object/skin surface temperature sensing.
- **Safe Clinical Guardrails**:
  - **No Systemic Diagnoses**: The system strictly avoids diagnosing systemic conditions (such as sepsis, bacteremia, shock, or anaphylaxis).
  - **Cross-Referenced Distress Flagging**: Cross-references visual lesion severity (e.g. cellulitis, bullous disease, extensive ulcers) with acute vital anomalies (Fever $>38.5^\circ\text{C}$, Tachycardia $>110\text{ bpm}$, Hypoxia $<92\%$, or BP shock) to strictly:
    > *"Flag possible systemic distress for urgent clinical referral."*
  - Renders bilingual high-visibility emergency referral banners with nearest tertiary hospital routing.
