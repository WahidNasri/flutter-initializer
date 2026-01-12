
# 🚀 Flutter App Template

A scalable, production-ready Flutter project template packed with essential tools, dependencies, and a script to boost feature development using a clean architecture approach.

---

## 📦 Dependencies

This template includes the following major packages:

```yaml
flutter_riverpod: ^2.6.1           # State management
dartz: ^0.10.1                     # Functional programming
dio: ^5.9.1                        # HTTP client
pretty_dio_logger: ^1.4.0          # Dio logging
json_annotation: ^4.9.0            # JSON serialization
flutter_secure_storage: ^10.0.0    # Secure key-value storage
easy_localization: ^3.0.8          # Localization
auto_route: ^10.0.1                # Declarative routing
local_auth: ^3.0.0                 # Face ID / Fingerprint
location: ^8.0.1                   # Device location
url_launcher: ^6.3.2               # Open URLs, apps, etc.
flutter_jailbreak_detection:
  git:
    url: https://github.com/pdurasie-ecovery/flutter_jailbreak_detection.git
    ref: add-namespace             # Jailbreak/root detection
```

---

## 📁 Project Structure

```
lib/
├── base/               # Core setup: routing, localization, themes
├── features/           # Modular features
│   └── <feature_name>/
│       ├── bloc/
│       │   ├── data/
│       │   ├── repositories/
│       │   ├── models/
│       │   ├── providers/
│       └── ui/
│           ├── screens/
│           └── widgets/
├── main.dart           # App entry point
```

---

## ⚙️ Feature Generator Script

This project comes with a Bash script to automate feature creation with optional screen and BLoC wiring.

### 🔧 Script Location

```
./feature.sh
```

### 🧪 Usage

```bash
./feature.sh create <feature_name> [--with-screen true|false] [--fill-bloc true|false]
```

### 🧾 Examples

```bash
# Generate a full feature with bloc (Business logic) and UI screen
./feature.sh create profile --with-screen true --fill-bloc true

# Generate only the folder structure for a feature
./feature.sh create settings
```

### 🛠 Output

Creates the following structure under `lib/features/<feature_name>`:

- `bloc/data` – Abstract + implementation classes
- `bloc/repositories` – Abstract + implementation classes
- `bloc/providers` – Riverpod StateNotifierProvider
- `ui/screens` – Optional screen
- Registers screen route in `app_router.dart` (if screen is included)
- Runs `build_runner` to regenerate routing

---

## 🚀 Getting Started

### 1. Install Packages

```bash
flutter pub get
```

### 2. Generate Localization (Optional)

```bash
flutter pub run easy_localization:generate -S assets/translations -f keys -o locale_keys.g.dart
```

### 3. Generate Routing

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 🤝 Contributing

You’re welcome to fork and improve this template. Pull requests are appreciated!

---

## 📄 License

MIT License — Free to use, modify, and distribute.

---
