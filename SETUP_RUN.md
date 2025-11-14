# **1. SETUP (macOS)**

* Zainstaluj **JDK 17**
  `brew install --cask temurin17`

* Zainstaluj **Android SDK (command-line only)**
  `brew install --cask android-commandlinetools`

* Dodaj Android SDK do PATH (dodaj do `~/.zshrc`):

  ```
  export ANDROID_SDK_ROOT=$HOME/Library/Android/sdk
  export PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin
  export PATH=$PATH:$ANDROID_SDK_ROOT/platform-tools
  ```

  Potem wykonaj:
  `source ~/.zshrc`

* Zainstaluj potrzebne pakiety Androida

  ```
  sdkmanager --install "platform-tools" "platforms;android-33" "build-tools;33.0.2"
  yes | sdkmanager --licenses
  ```

* Pobierz **Flutter SDK**
  `git clone https://github.com/flutter/flutter.git ~/flutter`

* Dodaj Flutter do PATH (do `~/.zshrc`):
  `export PATH="$PATH:$HOME/flutter/bin"`

* Aktywuj nowy PATH:
  `source ~/.zshrc`

* Sprawdź konfigurację:
  `flutter doctor`

* Włącz na telefonie Android:
  – Opcje programistyczne
  – Debugowanie USB
  – (Opcjonalnie) Pinowanie ekranu

* Podłącz telefon przez USB i zaakceptuj debugowanie
  `adb devices`
  (powinno pokazać urządzenie)

---

# **2. HOW TO RUN (uruchamianie projektu)**

* Utwórz projekt Flutter

  ```
  flutter create nadzorca_kiosk
  cd nadzorca_kiosk
  ```

* Dodaj zależności w `pubspec.yaml` (webview_flutter, hive itd.)

* Utwórz foldery gier:
  `mkdir -p assets/games/math assets/games/letters`

* Wklej pliki gry `index.html` do odpowiednich folderów

* Wklej kod do plików Fluttera:
  `lib/main.dart`
  `lib/guards.dart`
  `lib/kiosk_controller.dart`
  `lib/n8n_client.dart`

* Wklej kod Kotlina do:
  `android/app/src/main/kotlin/.../MainActivity.kt`

* Pobierz zależności Fluttera:
  `flutter pub get`

* Sprawdź, czy telefon jest widoczny:
  `flutter devices`

* Zbuduj i uruchom aplikację na telefonie:
  `flutter run`

* Otwórz aplikację na telefonie:
  – Przytrzymaj lewy górny róg → wpisz PIN (sekretny gest)
  – „Start kiosk” aby przypiąć aplikację
  – „Stop kiosk” aby wyjść
  – Kliknij kafelek gry → gra odpali się w WebView
