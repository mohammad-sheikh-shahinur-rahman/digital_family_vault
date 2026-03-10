# Digital Family Vault 📱

**Tagline:** “পরিবারের সব গুরুত্বপূর্ণ কাগজ এক নিরাপদ জায়গায়”

Digital Family Vault is a professional, offline-first, encrypted, and biometric-secured family document vault built with Flutter. It provides a secure, private sanctuary for your family's most sensitive documents.

## 🚀 Project Status: Production Ready ✅
The app is fully functional with a focus on high-grade security and user-friendly experience.

## 🔐 Core Features

### 🔒 1. Security (Bank-Grade)
- **Biometric Protection**: Fingerprint / Face ID integration using `local_auth`.
- **Hardware-Backed Encryption**: **AES-256** encryption with keys stored in the device's secure enclave (Keystore/Keychain).
- **Session Auto-Lock**: Automatically locks the vault when the app is minimized or the screen turns off.
- **Privacy-First**: Zero data leaves your device. No cloud login required.

### 📂 2. Document Management
- **Family Profiles**: Dedicated spaces for Father, Mother, Children, and more.
- **Smart Search**: Instant global search across all documents and categories.
- **Emergency Mode**: A high-visibility, read-only mode for critical documents (NID, Blood Group) accessible via a single tap.
- **Expiry Reminders**: Intelligent local notifications sent 30 days before document expiration.

### 📷 3. Smart Scan & Storage
- **Integrated Scanner**: Capture documents directly within the app.
- **Secure Vault**: All captured images are encrypted and stored in a hidden, protected directory.
- **Interactive Viewer**: High-resolution viewer with pinch-to-zoom and pan support.

### ☁️ 4. Backup & Recovery
- **Encrypted Export**: Pack your entire vault (database + encrypted files) into a secure ZIP.
- **Full Restore**: Seamlessly migrate or recover data from a backup file.

## 🧠 Tech Stack
- **Frontend:** Flutter (Material 3)
- **State Management:** Riverpod
- **Database:** Isar (High-performance NoSQL)
- **Security:** `local_auth`, `encrypt`, `flutter_secure_storage`
- **Notifications:** `flutter_local_notifications`
- **Compression:** `archive`

## 📁 Professional Folder Structure
```text
lib/
 ├─ core/
 │   ├─ constants/       # App-wide strings & theme constants
 │   ├─ encryption/      # AES-256 logic
 │   ├─ security/        # Biometric & session lock services
 │   ├─ storage/         # Isar database providers
 │   └─ notifications/   # Local notification system
 ├─ features/
 │   ├─ auth/            # Lock screen & authentication UI
 │   ├─ backup/          # ZIP export/import logic
 │   ├─ documents/       # Document listing, viewing, & storage
 │   ├─ emergency/       # Quick-access safety mode
 │   ├─ family/          # Profile management
 │   ├─ home/            # Dashboard & Search
 │   └─ scanner/         # Camera & capture UI
 ├─ widgets/             # Reusable UI components
 ├─ theme/               # Material 3 styling
 └─ main.dart            # Initialization & lifecycle management
```

---
*Built with Privacy and Security as a Priority.*
