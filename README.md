# Arogya-Saathi (आरोग्य-साथी)
> **Speak Naturally. Get Structured. Care Smarter.**  
> *AI-Assisted Multilingual Clinical Intake, Explainable Emergency Triage, and ABDM/AYUSH Integrated Healthcare Platform.*

---

## ⚡ Quick Start: How to Run Each Folder (Step-by-Step)

The project consists of three independent folders. Run each folder in its own terminal window:

| Folder | What It Is | Port / URL | Quick Command |
| :--- | :--- | :--- | :--- |
| 📁 **`backend/`** | FastAPI Python Server | `http://127.0.0.1:8000` | `.\.venv\Scripts\python.exe -m uvicorn main:app --port 8000 --reload` |
| 📁 **`patient_app/`** | Flutter Patient Web App | `http://localhost:5173` | `flutter run -d chrome --web-port 5173` |
| 📁 **`physician_app/`** | Flutter Doctor Portal | `http://localhost:5174` | `flutter run -d chrome --web-port 5174` |

---

### 1️⃣ How to Run `backend/` (Terminal 1)
The backend runs the API, clinical NLP engines, database, and triage rule engine.

```powershell
# Step 1: Open Terminal and navigate into backend
cd c:\Users\saipa\Desktop\SIH\SIH_PROJECT\backend

# Step 2: Create Python virtual environment (if not already created)
# Using uv (fastest):
uv venv .venv --python 3.13
uv pip install -r requirements.txt --python .venv

# (Or using standard python):
# python -m venv .venv
# .\.venv\Scripts\activate
# pip install -r requirements.txt

# Step 3: Start the backend server
.\.venv\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```
✅ **Verify it's working**: Open your browser to [http://127.0.0.1:8000/api/docs](http://127.0.0.1:8000/api/docs) to see the interactive Swagger API documentation.

---

### 2️⃣ How to Run `patient_app/` (Terminal 2)
This is the multilingual voice-enabled intake web app used by patients in waiting rooms.

```powershell
# Step 1: Open a NEW Terminal and navigate into patient_app
cd c:\Users\saipa\Desktop\SIH\SIH_PROJECT\patient_app

# Step 2: Install Flutter dependencies
flutter pub get

# Step 3: Run the app in Google Chrome on port 5173
flutter run -d chrome --web-port 5173
```
✅ **Verify it's working**: Google Chrome will automatically open [http://localhost:5173](http://localhost:5173) showing the patient intake screen.

---

### 3️⃣ How to Run `physician_app/` (Terminal 3)
This is the doctor's clinical workspace with the prioritized emergency triage queue.

```powershell
# Step 1: Open a NEW Terminal and navigate into physician_app
cd c:\Users\saipa\Desktop\SIH\SIH_PROJECT\physician_app

# Step 2: Install Flutter dependencies
flutter pub get

# Step 3: Run the portal in Google Chrome on port 5174
flutter run -d chrome --web-port 5174
```
✅ **Verify it's working**: Google Chrome will open [http://localhost:5174](http://localhost:5174).  
🔑 **Login with pre-seeded demo doctor credentials**:
- **Email**: `dr.sharma@arogyasaathi.demo`
- **Password**: `demo@123`

---

## 📌 Table of Contents
1. [⚡ Quick Start: How to Run Each Folder](#-quick-start-how-to-run-each-folder-step-by-step)
2. [Overview & Problem Statement](#-overview--problem-statement)
3. [Key Innovations & Features](#-key-innovations--features)
4. [System Architecture & Monorepo Structure](#-system-architecture--monorepo-structure)
5. [Tech Stack & Technologies Used](#-tech-stack--technologies-used)
6. [Prerequisites & System Requirements](#-prerequisites--system-requirements)
7. [Installation & Setup (Step-by-Step)](#-installation--setup-step-by-step)
8. [Where to Add API Keys (.env)](#step-3-configure-environment-variables--api-keys)
9. [Running the Application](#-running-the-application)
10. [Usage Guide: Step-by-Step Procedure](#-usage-guide-step-by-step-procedure)
    - [A. Patient Intake Workflow (Step-by-Step)](#a-patient-intake-workflow-step-by-step)
    - [B. Physician Clinical Portal Workflow (Step-by-Step)](#b-physician-clinical-portal-workflow-step-by-step)
11. [Pre-Seeded Demo Accounts & Clinical Scenarios](#-pre-seeded-demo-accounts--clinical-scenarios)
12. [REST API Endpoints Reference](#-rest-api-endpoints-reference)
13. [Clinical Safety & Compliance Guarantees](#-clinical-safety--compliance-guarantees)
14. [Automated Testing & Verification](#-automated-testing--verification)
15. [Troubleshooting & FAQs](#-troubleshooting--faqs)

---

## 🌟 Overview & Problem Statement

In Indian government hospitals and high-volume Outpatient Departments (OPDs), doctors often attend to **100+ patients per day**, spending an average of **less than 3 minutes per consultation**. This causes:
- **Severe physician burnout** and manual data entry overhead.
- **Lost clinical context** due to scattered paper slips and unorganized historical records.
- **Language and health literacy barriers**, with patients unable to articulate complex symptoms in formal medical terms.
- **Missed critical red flags**, where life-threatening emergencies (e.g., Acute Coronary Syndrome, Stroke) sit undetected in standard waiting room queues.
- **Fragmented care between Modern Allopathy and AYUSH systems**, with no standardized interoperability.

### The Solution: Arogya-Saathi
**Arogya-Saathi** bridges this gap as an intelligent clinical copilot:
1. **Patients speak naturally in their native language** (Hindi, Hinglish, English, etc.) during waiting time.
2. The AI **transcribes, structures, and extracts symptoms** (chief complaint, duration, severity, radiation, associated signs).
3. A **deterministic, 100% explainable Red-Flag Rule Engine** detects critical medical patterns and instantly bumps emergency cases to the top of the physician's queue.
4. **Prescription & report OCR** extracts past medical history into an interactive **Longitudinal Patient Timeline**.
5. Patients can complete an **AYUSH Prakriti Assessment** (Vata-Pitta-Kapha) to capture diet and lifestyle baseline context.
6. The physician reviews pre-structured clinical summaries, performs **Dual Terminology Coding (NAMASTE + ICD-11-TM2)**, confirms diagnosis, and generates **FHIR R4 / ABDM-compliant records**.

> ⚠️ **Strict Clinical Safety Guarantee:** AI assists; it never diagnoses. All AI-extracted findings carry an explicit `needs_review` label requiring human physician confirmation.

---

## 🚀 Key Innovations & Features

| Feature | Description |
| :--- | :--- |
| 🗣️ **Multilingual Voice Intake** | Conversational voice interface supporting Hindi, English, and Hinglish. Uses speech recognition + NLP to formulate targeted clinical follow-up questions. |
| 🚨 **Explainable Red-Flag Triage** | Hard-coded, deterministic clinical rule engine (no LLM hallucinations for emergency triage). Detects cardiac emergencies, strokes, severe sepsis, respiratory distress, and acute abdomen. |
| 📄 **Prescription & Document OCR** | Ingests handwritten and printed prescriptions, discharge summaries, and lab reports using OCR to extract medications and diagnoses. |
| ⏳ **Longitudinal Patient Timeline** | Interactive visual history plotting encounters, past diagnoses, uploaded documents, and medications chronologically. |
| 🌿 **AYUSH & Prakriti Engine** | Standardized 10-question Prakriti questionnaire calculating Vata, Pitta, and Kapha scores with Ahara (dietary) and Vihara (lifestyle) recommendations. |
| 🏷️ **Dual Terminology Coding** | Integrated mapping engine linking allopathic diagnoses to **NAMASTE** (National AYUSH Morbidity Codes) and **ICD-11 TM2** (Traditional Medicine Chapter 2). |
| 🔒 **ABDM & FHIR R4 Ready** | Captures digital informed consent, logs immutable audit trails, and exports standards-compliant FHIR R4 JSON bundles. |
| 👨‍⚕️ **Physician Verification Workspace** | Fast 1-click accept/edit/reject interface for AI findings, drastically reducing consultation intake time from minutes to seconds. |

---

## 🏗️ System Architecture & Monorepo Structure

```
SIH_PROJECT/
├── backend/                        # FastAPI Backend Application
│   ├── app/
│   │   ├── api/                    # REST API Endpoints
│   │   │   ├── auth.py             # Physician/Admin login & JWT auth
│   │   │   ├── patients.py         # Patient CRUD & demographics
│   │   │   ├── encounters.py       # Clinical encounters & interview state
│   │   │   └── clinical.py         # Findings, Red flags, Timeline, AYUSH, FHIR
│   │   ├── core/
│   │   │   ├── config.py           # Application settings (Pydantic Settings)
│   │   │   ├── database.py         # SQLAlchemy engine & session factory
│   │   │   ├── security.py         # Password hashing & JWT tokens
│   │   │   └── seed.py             # Demo data generator (5 fictional patients)
│   │   ├── models/                 # SQLAlchemy ORM Models
│   │   │   ├── patient.py          # Patient model
│   │   │   ├── encounter.py        # Encounter & triage priority
│   │   │   ├── interview.py        # Voice transcripts & segments
│   │   │   ├── clinical_finding.py # AI-extracted & confirmed findings
│   │   │   ├── red_flag.py         # Emergency alert records
│   │   │   ├── document.py         # Uploaded documents & OCR
│   │   │   ├── timeline.py         # Longitudinal timeline events
│   │   │   ├── ayush.py            # Prakriti assessment & dosha scores
│   │   │   ├── diagnosis.py        # Confirmed diagnoses & code mappings
│   │   │   └── fhir_resource.py    # Consent & audit log models
│   │   └── services/               # Business Logic & Clinical Engines
│   │       ├── ai/                 # ASR, OCR, and Clinical NLP Services
│   │       ├── ayush/              # Prakriti questionnaire & scoring engine
│   │       ├── fhir/               # ABDM FHIR R4 bundle builder
│   │       ├── rules/              # Deterministic Red-Flag Rule Engine
│   │       └── terminology/        # NAMASTE & ICD-11-TM2 mapping engine
│   ├── arogya_saathi.db            # SQLite database file
│   ├── main.py                     # FastAPI entrypoint
│   ├── requirements.txt            # Python dependencies
│   ├── test_live_flow.py           # End-to-end automated integration test
│   └── .env                        # Backend environment configuration
│
├── patient_app/                    # Flutter Patient Mobile/Web App
│   ├── lib/
│   │   ├── core/                   # Design system, themes, and ABDM constants
│   │   ├── models/                 # Dart data transfer objects
│   │   ├── screens/                # 12 Patient Intake Screens (Welcome to Success)
│   │   ├── services/               # API service layer (HTTP client)
│   │   └── main.dart               # Flutter application entry point
│   └── pubspec.yaml                # Flutter dependencies
│
├── physician_app/                  # Flutter Physician Portal (Web/Desktop)
│   ├── lib/
│   │   ├── models/                 # Dart models for clinical workspace
│   │   ├── screens/                # Dashboard, Triage Queue, Clinical Workspace
│   │   ├── services/               # API client for triage & clinical confirmation
│   │   └── main.dart               # Flutter application entry point
│   └── pubspec.yaml                # Flutter dependencies
│
├── stitch_assets/                  # UI design mockups, emblems, and visual specifications
└── README.md                       # Complete Project Guide & Documentation
```

---

## 💻 Tech Stack & Technologies Used

Arogya-Saathi is built using a modern, scalable, and resilient technology stack designed for high availability in OPD environments and cross-platform flexibility:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        FRONTEND PRESENTATION                           │
│  Flutter 3.x (Dart 3.x) • Provider State Management • GoRouter 14.x    │
│  Patient Web/Mobile App (Port 5173)  │ Physician Clinical Portal (5174)│
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ REST API (JSON / HTTP)
┌───────────────────────────────────▼────────────────────────────────────┐
│                        BACKEND API & ENGINES                           │
│  FastAPI (Python 3.13) • Uvicorn ASGI • SQLAlchemy 2.0 • Pydantic v2   │
│  SQLite / PostgreSQL • JWT OAuth2 Security (BCrypt / Passlib / JOSE)   │
├────────────────────────────────────────────────────────────────────────┤
│                      CLINICAL INTELLIGENCE & AI                        │
│  SpeechRecognition + PyDub • PyTesseract OCR + Pillow Image Processing │
│  Cloud LLM (OpenAI / Gemini) + Deterministic Bilingual NLP Fallback   │
│  100% Deterministic Explainable Clinical Red-Flag Emergency Engine     │
│  AYUSH Prakriti Scorer • Dual Coding (NAMASTE + WHO ICD-11-TM2)        │
│  ABDM Consent Management • HL7 FHIR R4 Bundle Generator                │
└────────────────────────────────────────────────────────────────────────┘
```

### 1. Programming Languages & Runtimes
- **Python 3.13 / 3.12**: Core backend programming language chosen for async performance, rich NLP/AI ecosystem, and clinical data manipulation.
- **Dart 3.x**: Strongly-typed client-optimized language powering the reactive Flutter frontends.
- **HTML5, CSS3 & JavaScript (CanvasKit / Skwasm)**: Web assembly and canvas rendering targets for browser deployment.
- **SQL**: Relational database queries executed via SQLAlchemy ORM.

### 2. Backend Web Framework & Server
- **FastAPI (v0.115.0)**: Modern, high-velocity async ASGI web framework providing automated OpenAPI/Swagger documentation, dependency injection, and high throughput.
- **Uvicorn (v0.30.6)**: Lightning-fast ASGI server implementation based on `uvloop` and `httptools`.
- **SQLAlchemy (v2.0.35)**: Enterprise-grade Python SQL toolkit and Object Relational Mapper for database abstraction.
- **Pydantic (v2.8.2) & Pydantic-Settings (v2.4.0)**: High-speed data parsing, strict typing, and environment-driven configuration management.
- **SQLite**: Local zero-configuration relational database engine for lightweight, portable, and reliable persistence.
- **HTTPX (v0.27.2)**: Fully featured HTTP client with async support used for external LLM API calls and service communication.
- **Aiofiles (v24.1.0)**: Non-blocking asynchronous file I/O for prescription document storage and retrieval.
- **Python-Multipart (v0.0.9)**: Streaming multipart/form-data parser for medical document uploads.
- **Python-Dotenv (v1.0.1)**: Seamless management and injection of `.env` configuration files.

### 3. Artificial Intelligence, Speech & Vision
- **SpeechRecognition (v3.10.4)**: Multilingual speech recognition interface capturing and transcribing patient symptoms in Hindi, English, and Hinglish.
- **PyDub (v0.25.1)**: Audio preprocessing, format normalization, and audio chunking.
- **PyTesseract (v0.3.10) & Google Tesseract OCR**: Optical Character Recognition engine extracting text from physical prescription photos, doctor slips, and diagnostic reports.
- **Pillow / PIL (v10.4.0)**: Image manipulation library providing binarization, resizing, and noise filtering for prescription image scans prior to OCR.
- **Clinical NLP Service (Dual-Mode)**:
  - *Cloud LLM Mode*: Integration with OpenAI (`gpt-4o-mini`) or Google Gemini for nuanced conversational symptom extraction and dynamic question generation.
  - *Offline Rule-Based Fallback*: Deterministic regex and semantic keyword extractor handling Hindi, English, and Hinglish medical terminology without internet connectivity.
- **Deterministic Red-Flag Rule Engine**: 100% explainable, rule-based clinical safety engine evaluating symptom combinations (cardiac, neurological, respiratory distress, acute abdomen, severe sepsis) without generative hallucination risks.
- **AYUSH Prakriti Calculation Engine**: Algorithmic scoring model computing Tridosha percentages (Vata, Pitta, Kapha) from a 10-point standardized physiological and lifestyle questionnaire.

### 4. Security, Cryptography & Authentication
- **OAuth2 with Password Flow**: Robust standard protocol for physician authentication.
- **Python-JOSE (v3.3.0)**: Complete JavaScript Object Signing and Encryption implementation for JSON Web Token (JWT) encoding and verification.
- **Passlib (v1.7.4)**: Password hashing library providing comprehensive context handling.
- **BCrypt (v4.0.1)**: Adaptive, salted cryptographic password hashing for credential protection.
- **FastAPI CORS Middleware**: Configurable Cross-Origin Resource Sharing restricting API access to verified client origins.

### 5. Healthcare Standards, Interoperability & Terminology
- **HL7 FHIR R4 (Fast Healthcare Interoperability Resources)**: Generates valid FHIR JSON bundles (`Patient`, `Encounter`, `Condition`, `Observation`, `Consent`, `AuditEvent`) ready for Health Information Exchange (HIE-CM).
- **ABDM (Ayushman Bharat Digital Mission)**: Compliant with national digital health standards, including ABHA (Ayushman Bharat Health Account) linking and digital informed consent tracking.
- **NAMASTE Portal Terminology**: National AYUSH Morbidity and Standardized Terminologies Electronic Portal mapping for Ayurveda, Yoga & Naturopathy, Unani, Siddha, and Homeopathy.
- **WHO ICD-11-TM2**: Dual-coding integration with World Health Organization International Classification of Diseases 11th Revision (Traditional Medicine Chapter 2).

### 6. Frontend Libraries & Flutter Packages
- **Flutter SDK 3.x**: Cross-platform declarative UI toolkit compiling natively to Web (Chrome), Windows, Android, and iOS.
- **Provider (v6.1.2 / v6.1.1)**: Scoped reactive state management ensuring synchronous state synchronization across triage queues and clinical workspaces.
- **GoRouter (v14.0.0 / v13.2.0)**: Declarative, type-safe routing architecture supporting deep links, route guards, and path parameters.
- **Dart HTTP (v1.2.0)**: Composable HTTP client library connecting Flutter clients to the backend REST API.
- **Shared Preferences (v2.3.0 / v2.2.2)**: Cross-platform key-value persistence for caching tokens, user preferences, and language selections.
- **Record (v5.1.0)**: Cross-platform high-fidelity audio recorder supporting live microphone streaming on both web and native desktop.
- **Permission Handler (v11.3.0)**: Unified runtime permission management for microphone and camera access.
- **Image Picker (v1.1.0)**: Native image selector allowing patients to snap photos of prescriptions or select images from gallery.
- **Intl (v0.20.2 / v0.19.0)**: Internationalization and localization utility handling date/time formatting, number systems, and multilingual text.
- **Flutter SVG (v2.0.10)**: Vector graphic renderer for razor-sharp medical emblems, status icons, and branding.
- **Lottie (v3.0.0)**: Vector animation library rendering smooth animations for voice listening states, loading spinners, and success tokens.
- **Cupertino Icons (v1.0.8)**: Crisp icon library for clean mobile and web navigation elements.

### 7. Developer Tooling & Package Management
- **uv (v0.11.21)**: Extremely fast Python package installer and resolver written in Rust, reducing setup times from minutes to seconds.
- **Flutter DevTools**: In-browser profiling, widget inspection, and memory analysis suite.
- **Git**: Distributed source control and repository tracking.

---

## 📋 Prerequisites & System Requirements

Before running the project, make sure you have the following installed:
1. **Python**: Version 3.11, 3.12, or 3.13 (or `uv` package manager).
2. **Flutter SDK**: Version 3.2.0 or higher. Run `flutter doctor` to ensure web tools are available.
3. **Google Chrome**: For running the web apps with audio/mic support.
4. *(Optional)* **Tesseract OCR**: If performing live local OCR on scanned images (pre-seeded records work out of the box).
5. *(Optional)* **OpenAI / Gemini API Key**: If you wish to use live cloud LLMs instead of the built-in offline rule-based NLP extractor.

---

## ⚙️ Installation & Setup (Step-by-Step)

### Step 1: Open Terminal in Project Root
```powershell
cd c:\Users\saipa\Desktop\SIH\SIH_PROJECT
```

### Step 2: Set Up Python Backend Virtual Environment

Using `uv` (Fastest, automated):
```powershell
uv venv backend\.venv --python 3.13
uv pip install -r backend\requirements.txt --python backend\.venv
```
*Or using standard Python:*
```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
cd ..
```

### Step 3: Configure Environment Variables & API Keys
The configuration file is located at:
📁 **[`backend/.env`](file:///c:/Users/saipa/Desktop/SIH/SIH_PROJECT/backend/.env)**

Open `backend/.env` and scroll to lines 36–42. Configure your preferred AI provider:

#### Option A: Using Google Gemini (Recommended for Hackathons)
```ini
LLM_PROVIDER=gemini
LLM_API_KEY=AIzaSyYourActualGeminiApiKeyHere
LLM_MODEL=gemini-1.5-flash
LLM_BASE_URL=
```
*(Get a free key from [Google AI Studio](https://aistudio.google.com/app/apikey))*

#### Option B: Using OpenAI (GPT-4o / GPT-4o-mini)
```ini
LLM_PROVIDER=openai
LLM_API_KEY=sk-proj-YourActualOpenAIApiKeyHere
LLM_MODEL=gpt-4o-mini
LLM_BASE_URL=
```

#### Option C: Using Groq (Ultra-fast Llama 3)
```ini
LLM_PROVIDER=openai
LLM_API_KEY=gsk_YourActualGroqApiKeyHere
LLM_MODEL=llama-3.3-70b-versatile
LLM_BASE_URL=https://api.groq.com/openai/v1
```

#### Option D: Offline / Free Mode (No API Key Required)
Leave `LLM_API_KEY` blank:
```ini
LLM_PROVIDER=openai
LLM_API_KEY=
LLM_MODEL=gpt-4o-mini
```
> 💡 If `LLM_API_KEY` is empty, the system automatically uses the internal **deterministic rule-based clinical NLP engine** with zero external calls.

### Step 4: Resolve Flutter Dependencies

Resolve dependencies for the **Patient App**:
```powershell
cd patient_app
flutter pub get
cd ..
```

Resolve dependencies for the **Physician Portal**:
```powershell
cd physician_app
flutter pub get
cd ..
```

---

## 🏃 Running the Application

You can run all three services concurrently in separate terminal windows:

### 1. Start the Backend API Server
```powershell
cd c:\Users\saipa\Desktop\SIH\SIH_PROJECT\backend
.\.venv\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```
- **Backend URL**: [http://127.0.0.1:8000](http://127.0.0.1:8000)
- **Swagger / OpenAPI Documentation**: [http://127.0.0.1:8000/api/docs](http://127.0.0.1:8000/api/docs)
- **Health Check**: [http://127.0.0.1:8000/health](http://127.0.0.1:8000/health)

### 2. Start the Patient App (Port 5173)
```powershell
cd c:\Users\saipa\Desktop\SIH\SIH_PROJECT\patient_app
flutter run -d chrome --web-port 5173
```
- **Patient App URL**: [http://localhost:5173](http://localhost:5173)

### 3. Start the Physician Portal (Port 5174)
```powershell
cd c:\Users\saipa\Desktop\SIH\SIH_PROJECT\physician_app
flutter run -d chrome --web-port 5174
```
- **Physician Portal URL**: [http://localhost:5174](http://localhost:5174)

---

## 📖 Usage Guide: Step-by-Step Procedure

---

### A. Patient Intake Workflow (Step-by-Step)

Follow this step-by-step walkthrough in the **Patient App** ([http://localhost:5173](http://localhost:5173)):

#### Step 1: Welcome & Landing
- Open [http://localhost:5173](http://localhost:5173).
- You will see the Arogya-Saathi welcome banner explaining the intake process.
- Click **"Get Started / शुरू करें"**.

#### Step 2: Language Selection (`/language`)
- Select your preferred language: **Hindi (हिंदी)**, **English**, **Bengali (বাংলা)**, **Tamil (தமிழ்)**, or **Telugu (తెలుగు)**.
- The app adapts its questions, audio prompts, and translations to this selection.

#### Step 3: Digital Informed Consent (`/consent`)
- In accordance with ABDM guidelines, the patient is presented with clear consent checkboxes:
  - Voice recording during interview.
  - Clinical AI text structuring.
  - Document digitization and OCR.
  - Secure ABDM health record linking.
- Check the consent box and tap **"Agree & Proceed"**.

#### Step 4: Patient Details & ABHA ID (`/details`)
- Enter basic demographic details:
  - **Full Name** (e.g., *Rajesh Sharma*)
  - **Age** (e.g., *42*)
  - **Gender** (Male / Female / Other)
  - **Mobile Number** (10 digits)
  - *(Optional)* **ABHA ID** (e.g., `91-1234-5678-9012` for Ayushman Bharat linking)
- Tap **"Next: Intake Interview"**.

#### Step 5: Pre-Interview Guidance (`/before-begin`)
- The screen provides helpful guidance:
  - *"Speak normally as you would speak to a doctor."*
  - *"You can speak in Hindi, English, or mix both (Hinglish)."*
  - *"Mention when the problem started and if the pain spreads anywhere."*
- Tap **"Start Interview"**.

#### Step 6: Voice/Text Symptom Interview (`/interview`)
- The conversational intake assistant asks the opening question:  
  *“आज आप यहाँ क्यों आए हैं? कृपया बताएं क्या तकलीफ है।” (What brings you to the clinic today?)*
- **Voice Mode**: Tap the Microphone button and speak (e.g., *"Mujhe do din se bahut tez bukhar hai aur gale mein dard hai"*).
- **Text Mode**: You can also type symptoms directly into the input field.
- The assistant analyzes your answer and dynamically generates follow-up questions regarding duration, severity, and associated symptoms.
- Tap **"Complete Interview"** when finished.

#### Step 7: Structured Transcript Review (`/transcript`)
- Review what the AI extracted from your speech:
  - **Chief Complaint**: Fever
  - **Duration**: 2 days
  - **Severity**: Severe
  - **Associated Symptoms**: Sore throat
- You can correct any misunderstandings before submission. Tap **"Looks Good, Continue"**.

#### Step 8: Document & Prescription Upload (`/documents`)
- Have an old prescription or blood test report?
- Click **"Take Photo"** or **"Upload Document"**.
- The system runs OCR to read medication names and lab values to link them to your encounter.
- Tap **"Next: Medical History"** (or skip if you have no documents).

#### Step 9: Medical History & Chronic Conditions (`/medical-history`)
- Select any existing medical conditions (Diabetes, Hypertension, Asthma, etc.), current medications, and known drug allergies.
- Tap **"Next: AYUSH Assessment"**.

#### Step 10: Optional AYUSH Prakriti Baseline (`/ayush`)
- Patients can optionally complete an authentic 10-question Ayurvedic Prakriti assessment (body frame, skin type, appetite, weather preference, sleep patterns).
- The system calculates preliminary **Vata**, **Pitta**, and **Kapha** proportions to guide lifestyle discussions.
- Tap **"View Final Summary"**.

#### Step 11: Final Review & Submission (`/summary`)
- Inspect the complete intake packet: Patient details, Chief Complaint, Transcript, Uploaded Records, and AYUSH scores.
- Tap **"Submit to Physician Queue"**.

#### Step 12: Confirmation & Queue Token (`/success`)
- You receive an **OPD Queue Token Number** (e.g., **`TOKEN #A-108`**).
- The system alerts you:  
  *“Your clinical summary has been securely routed to the physician. Please proceed to Waiting Area B.”*

---

### B. Physician Clinical Portal Workflow (Step-by-Step)

Follow this step-by-step walkthrough in the **Physician Portal** ([http://localhost:5174](http://localhost:5174)):

#### Step 1: Doctor Login (`/login`)
- Open [http://localhost:5174](http://localhost:5174).
- Log in using pre-seeded physician credentials:
  - **Email**: `dr.sharma@arogyasaathi.demo`
  - **Password**: `demo@123`
- Click **"Sign In"**.

#### Step 2: Live Triage Dashboard & Prioritized Queue (`/dashboard`)
- The doctor arrives at the **OPD Live Triage Dashboard**.
- Notice how patients are sorted:
  - 🚨 **URGENT**: Patients with triggered emergency red flags appear at the **very top** in red with a flashing badge (e.g., *Ramesh Kumar — Severe Chest Pain with arm radiation*).
  - 🟡 **MODERATE**: Patients with acute conditions (e.g., *Priya Sharma — High Fever 3 days*).
  - 🟢 **ROUTINE**: Follow-ups and routine consultations (e.g., *Suresh Patel — Diabetes follow-up*).
- Click on any patient row to open their **Clinical Workspace**.

#### Step 3: Clinical Workspace Overview (`/workspace/:id`)
The workspace displays all relevant patient context side-by-side:
- **Patient Banner**: Name, Age, Gender, ABHA ID, Mobile, Language, Encounter Priority.
- **Red-Flag Alert Bar**: If an emergency pattern was triggered, the exact rule (e.g., `cardiac_emergency`) and trigger terms (`chest_pain`, `sweating`, `radiation_arm`) are displayed with clinical guidance (*"Rule out Acute Coronary Syndrome immediately"*).

#### Step 4: AI-Extracted Findings & Verification
- Under **History of Present Illness (HPI)** and **Clinical Findings**, review the AI-extracted fields:
  - `Chief Complaint`: Chest pain
  - `Duration`: 2 hours
  - `Severity`: Severe
  - `Radiation`: Left arm
- Notice the **"AI Extracted — Needs Review"** tag.
- The physician can click **Accept**, **Edit**, or **Dismiss** on any finding. Once confirmed, the tag updates to **"Physician Confirmed"**.

#### Step 5: Review Audio Transcript & Raw Voice
- Click the **"Voice Transcript"** tab to read the verbatim conversation between the patient and the AI assistant in the original language (Hindi/English).

#### Step 6: Longitudinal Patient Timeline & Documents
- Click the **"Patient Timeline"** tab.
- View the patient's chronological history:
  - *June 2020*: First diagnosed with Hypertension.
  - *March 2025*: Uploaded prescription (Dr. Rajan Mehta: Atorvastatin, Aspirin).
  - *Today*: Emergency Visit for Chest Pain.
- Click any document thumbnail to view the original scan and side-by-side OCR text.

#### Step 7: AYUSH & Prakriti Insights
- For patients who completed the AYUSH module, view their **Prakriti Distribution Bar** (e.g., *Pitta 45%, Vata 35%, Kapha 20%*).
- Read the Ahara (dietary) and Vihara (lifestyle/exercise) recommendations to provide holistic care advice.

#### Step 8: Diagnosis Confirmation & Dual Terminology Mapping
- In the **Diagnosis** card, enter or select the primary diagnosis (e.g., *Type 2 Diabetes Mellitus* or *Acute Coronary Syndrome*).
- Click **"Auto-Map Terminology"**:
  - Automatically queries the Dual Mapping Engine.
  - Displays the corresponding **NAMASTE Code** (e.g., `NAMASTE-EN-001: Madhumeha`).
  - Displays the corresponding **ICD-11-TM2 Code** (e.g., `5A11: Type 2 diabetes mellitus`).
- Confirm the diagnosis with one click.

#### Step 9: Prescription & Notes
- Enter Rx items:
  - Drug Name, Dosage, Frequency, Duration (e.g., *Tab. Metformin 500mg - 1 tablet twice daily after meals - 30 days*).
- Add Physician Clinical Notes.

#### Step 10: Finalize Encounter & Export FHIR Bundle
- Click **"Finalize Encounter"**.
- The encounter status moves to `COMPLETED`.
- The system generates an ABDM-compliant **FHIR R4 Bundle** containing:
  - `FHIR Patient`
  - `FHIR Encounter`
  - `FHIR Condition` (with dual NAMASTE/ICD-11 codes)
  - `FHIR Observation` (symptoms, vitals)
  - `FHIR Consent` & `AuditEvent` records.
- The record is now permanently archived and ready for ABDM health information exchange (HIE-CM).

---

## 👥 Pre-Seeded Demo Accounts & Clinical Scenarios

The system automatically initializes and seeds 5 realistic clinical scenarios for testing and demonstration:

### Demo User Accounts
| Role | Email | Password | Name |
| :--- | :--- | :--- | :--- |
| **Physician** | `dr.sharma@arogyasaathi.demo` | `demo@123` | Dr. Priya Sharma (General Medicine) |
| **Admin** | `admin@arogyasaathi.demo` | `admin@123` | System Administrator |

### Pre-Seeded Patient Scenarios
| Patient | Age/Gender | Presentation | Priority & Triage | Features Demonstrated |
| :--- | :--- | :--- | :--- | :--- |
| **Ramesh Kumar** | 45M | Severe chest pain (2 hrs) radiating to left arm with diaphoresis | 🚨 **URGENT** (Top of Queue) | Cardiac Red Flag rule trigger, Hindi voice transcript, uploaded prescription OCR, urgent alert banner. |
| **Priya Sharma** | 32F | High fever for 3 days with sore throat and dry cough | 🟡 **MODERATE** | Acute infectious presentation, AI finding verification, English interview. |
| **Suresh Patel** | 62M | Routine Type 2 Diabetes & Hypertension follow-up | 🟢 **ROUTINE** (Completed) | Longitudinal timeline spanning 10 years, confirmed diagnosis, **Dual NAMASTE (`NAMASTE-EN-001`) + ICD-11-TM2 (`5A11`) coding**. |
| **Meera Devi** | 38F | Chronic fatigue and digestive complaints | 🟢 **ROUTINE** | **Full AYUSH Prakriti profile (Pitta-Vata)** with Ahara and Vihara lifestyle guidance. |
| **Arjun Singh** | 28M | Right knee pain and swelling following sports injury | 🟢 **ROUTINE** | Musculoskeletal trauma OPD intake, duration & mobility assessment. |

---

## 📡 REST API Endpoints Reference

The FastAPI backend exposes a clean, modular REST API under `/api/v1`:

### Authentication (`/api/v1/auth`)
- `POST /auth/login`: Authenticate with email/password; returns JWT access token.
- `GET /auth/me`: Get profile of the currently logged-in physician.

### Patients (`/api/v1/patients`)
- `GET /patients`: List patients (supports `search` query).
- `POST /patients`: Register a new patient with ABHA ID and demographics.
- `GET /patients/{id}`: Get full patient profile including medical history and consent.

### Encounters (`/api/v1/encounters`)
- `GET /encounters`: List active encounters (filter by `status`, `priority`, `physician_id`).
- `POST /encounters`: Create a new clinical encounter.
- `GET /encounters/{id}`: Get complete encounter packet (findings, interview, red flags, documents).
- `PATCH /encounters/{id}/status`: Transition encounter status (`waiting`, `in_intake`, `physician_review`, `completed`).

### Clinical Interviews (`/api/v1/interviews`)
- `POST /interviews/start`: Start an interactive multilingual intake session.
- `POST /interviews/{id}/respond`: Submit patient speech/text; runs NLP extraction & generates next clinical question.
- `POST /interviews/{id}/complete`: Finalize interview and generate HPI summary.

### Clinical Workspace & Findings (`/api/v1/clinical`)
- `GET /clinical/encounters/{id}/findings`: List findings requiring review.
- `POST /clinical/findings/{id}/verify`: Physician confirms, edits, or rejects an AI finding.
- `GET /clinical/encounters/{id}/red-flags`: Check active red-flag emergency alerts.
- `GET /clinical/patients/{id}/timeline`: Retrieve chronological longitudinal timeline.
- `POST /clinical/documents/upload`: Upload image/PDF prescription for OCR processing.
- `GET /clinical/encounters/{id}/ayush`: Get AYUSH Prakriti dosha breakdown and lifestyle recommendations.
- `POST /clinical/diagnoses`: Record confirmed diagnosis with automatic NAMASTE + ICD-11-TM2 dual mapping.
- `GET /clinical/encounters/{id}/fhir`: Export encounter as an ABDM-compliant FHIR R4 JSON Bundle.

---

## 🛡️ Clinical Safety & Compliance Guarantees

1. **Deterministic Red-Flag Rules**: Emergency triage rules are entirely rule-based and deterministic. The system never relies on generative AI or stochastic sampling to decide if a patient is experiencing an emergency.
2. **Explainable Triggers**: Every red flag clearly lists the exact trigger keywords and clinical rationale so the physician knows *why* the patient was flagged.
3. **Transparent AI Labels**: Every entity extracted by the NLP service has `source: "ai_extracted"` and `needs_review: true`. It is visually highlighted in yellow until explicitly signed off by the physician.
4. **ABDM Informed Consent**: All patient voice recordings and data processing are gated by explicit digital consent with timestamped audit logging.
5. **No Invented Terminology**: The NAMASTE and ICD-11-TM2 mapper strictly queries curated clinical mapping dictionaries; it never hallucinates codes.

---

## 🧪 Automated Testing & Verification

The project includes an end-to-end integration test validating the entire live pipeline:
```powershell
cd c:\Users\saipa\Desktop\SIH\SIH_PROJECT\backend
.\.venv\Scripts\python.exe test_live_flow.py
```

### What the test validates:
1. Patient registration with preferred language.
2. Encounter creation and queue assignment.
3. Multilingual interview initialization.
4. Voice submission and NLP symptom extraction.
5. Deterministic Red-Flag rule evaluation (verifying emergency alert triggers).
6. Clinical finding verification.
7. Dual coding lookup (NAMASTE + ICD-11).
8. FHIR R4 Bundle generation.

---

## 🔧 Troubleshooting & FAQs

### Q: What if port 8000, 5173, or 5174 is already in use?
- You can change the ports easily:
  - **Backend**: Pass `--port 8080` to uvicorn, and update `_baseUrl` in `patient_app/lib/services/api_service.dart` and `physician_app/lib/services/api_service.dart`.
  - **Flutter Apps**: Run `flutter run -d chrome --web-port <new_port>`.

### Q: Microphone permission in Chrome
- When running Flutter Web, Chrome will request permission to use your microphone.
- Click **"Allow"** when prompted. If you prefer not to use voice, you can type your answers into the text box on the interview screen.

### Q: Can I run this without an OpenAI or Gemini API Key?
- **Yes!** If `LLM_API_KEY` is blank in `backend/.env`, the backend automatically falls back to its built-in rule-based NLP extraction service. It parses symptoms, durations, severities, and radiation without any external API calls.

### Q: How do I run the apps on Windows Desktop instead of Chrome?
- Both Flutter apps support native Windows Desktop. Run:
  ```powershell
  cd patient_app
  flutter run -d windows
  ```

---

## 📄 License & Hackathon Attribution

Developed for **Smart India Hackathon (SIH)**.  
*All demo patient data and medical records are fictional and generated strictly for evaluation, testing, and demonstration purposes.*
