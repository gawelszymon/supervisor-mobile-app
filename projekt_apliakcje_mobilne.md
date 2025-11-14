# Plan realizacji projektu (prosto, ale „na czysto”)

**Temat:** Aplikacja dla dzieci składająca się z „Nadzorcy” (kiosk/parental lock) i „Wtyczek” (gry edukacyjne).
**Zespół:** Duch Bartosz, Gaweł Szymon, Krzyszczuk Jakub
**Opiekun:** dr inż. Krzysztof Rusek

---

## 1) Wybór stosu i założenia (upraszczamy maksymalnie)

* **Frontend mobilny:** **Flutter** (CLI + VS Code; bez Android Studio).

  * Powód: jedna baza kodu, bardzo dobre wsparcie dla WebView i kanałów platformowych (do funkcji Androida).
* **Warstwa natywna (tylko to, co konieczne):** cienki plugin Android (Kotlin), wywoływany z Fluttera do:

  * Lock Task Mode / App Pinning (kiosk),
  * Device Owner (na *jednym* urządzeniu testowym – pełny kiosk),
  * blokady klawiszy systemowych w trybie kiosk.
* **Wtyczki – gry:** proste **gry HTML5/JS** uruchamiane w **WebView** Fluttera (pakowane jako assets).

  * Komunikacja gry ↔ nadzorca przez prosty **JS bridge**.
* **Backend/telemetria/konfiguracja rodzica:** **n8n** (self-hosted lub w chmurze), do:

  * zbierania logów (czas gry, wyniki),
  * zdalnego nadawania konfiguracji (np. lista gier, czas dzienny),
  * ewentualnego **zdalnego odblokowania** („awaryjna” dezaktywacja kiosku).
* **Bez Android Studio:** używamy `flutter doctor`, `flutter build apk`, `flutter install`, `adb`. (Android SDK – tylko narzędzia wiersza poleceń).

> **Uwaga dot. kiosku:** „pełny” Lock Task Mode bez potwierdzeń wymaga **Device Owner** i zwykle **resetu urządzenia** (na sprzęcie testowym). Alternatywnie: „App Pinning” (z potwierdzeniem użytkownika) – prostsze demo, ale mniej „pancerne”. W projekcie pokażemy **oba warianty**.

---

## 2) Wymagania

### Funkcjonalne

1. **Kiosk (Nadzorca)**

   * Start w trybie pełnoekranowym, blokada nawigacji systemowej.
   * Biały-/czarny-lista aplikacji (docelowo tylko nasza).
   * **Wyjście** wyłącznie po **sekretnej czynności** (gest + PIN).
   * Limit czasu gry dziennie (np. 20/30/45 min) – potem blokada.
2. **Wtyczki (Gry)**

   * Min. 2 gry HTML5 dla różnych grup wiekowych.
   * API raportowania: start/stop gry, wynik, czas, poziom.
3. **Panel rodzica (light)**

   * Ekran w aplikacji z ustawieniami (PIN, wybór gier, limit).
   * Opcjonalnie: zdalna flaga „unlock” przez webhook z **n8n**.
4. **Logowanie**

   * Lokalne (SQLite/Hive) + wysyłka do **n8n** (batched).

### Niefunkcjonalne

* Prosty UI, duże przyciski, bez zbędnych ekranów.
* Działa offline (gry w assetach), sieć tylko do logów/konfigu.
* Testy na **co najmniej 1 fizycznym urządzeniu** z Android 10+.

---

## 3) Architektura (wysoki poziom)

* **Flutter app „Nadzorca”**

  * Ekran wyboru gry → WebView (gra).
  * Moduł „KioskController” (kanał platformowy do Androida):

    * `startLockTask()`, `stopLockTask()`, `setLockTaskPackages()`.
    * Rejestracja jako **Device Owner** (tryb demo – jedno urządzenie).
  * „ParentGuard”: detekcja **sekretnego gestu** (np. długi przytrzymany róg ekranu + przesunięcie), potem **PIN**.
  * „TimeGuard”: licznik limitu czasu, blokuje wejście do gier po przekroczeniu.
  * „PluginBridge”: JS <-> Dart (zdarzenia z gry i komendy do gry).
* **Gry HTML5/JS** (w `/assets/games/...`)

  * Wywołują `window.postMessage('GAME_EVENT', {...})` (lub analogiczny hook) – odbierane w Flutterze.
* **n8n**

  * Endpoint `POST /log` (zbiera logi), `GET /config` (ustawienia), opcjonalnie `POST /unlock`.
  * Proste przepływy: zapisz do Airtable/Sheets/DB + reguły (np. limit globalny).

---

## 4) Etapy i sprinty (6–8 tygodni, 5 sprintów)

### Sprint 0 (2–3 dni) – start i uzgodnienia

* Repo Git (GitHub). Konwencje: GitFlow, konwencje commitów.
* Ticketowanie (GitHub Issues + Projects). Szablon PR.
* Ustalenie urządzenia testowego pod **Device Owner**.
* Decyzja o 2 grach (tematy/zakres).
* Setup **n8n** (lokalnie przez Docker).

**DOD:** działa „hello world” Flutter na urządzeniu; n8n dostępny pod adresem lokalnym; spis zadań.

### Sprint 1 (1,5 tyg.) – MVP Nadzorca + 1 gra (offline)

* Flutter app: ekran start, lista gier (puste), wejście do WebView.
* Gra #1 w assets (np. „Łączenie par obrazków”).
* **App Pinning**: `startLockTask()` z potwierdzeniem systemowym.
* Sekretny gest + ekran PIN (jeszcze bez kryptografii).
* Lokalny log (czas sesji gry).

**DOD:** APK instaluje się CLI, można uruchomić 1 grę, działa pinning, wyjście tylko przez gest+PIN.

### Sprint 2 (1,5 tyg.) – Pełny kiosk + 2. gra + logi do n8n

* Wariant **Device Owner** na testowym urządzeniu (skrypt `adb`):

  * `dpm set-device-owner <pkg>/<admin-receiver>`.
  * `setLockTaskPackages()` → auto-kiosk bez potwierdzenia.
* Gra #2 (np. „Matematyka – licz do 10/20”).
* JS bridge: raporty `session_start/stop`, `score`, `level`.
* Wysłanie logów do n8n (kolejki + retry).

**DOD:** Pełny kiosk na testowym urządzeniu (bez promptów), 2 gry raportują zdarzenia, logi pojawiają się w n8n.

### Sprint 3 (1,5 tyg.) – Panel rodzica + limity czasu + bezpieczeństwo

* Ekran „Ustawienia rodzica” (PIN, limit czasu dziennego, wybór gier).
* Szyfrowanie PIN (np. `flutter_secure_storage`).
* „TimeGuard” – dzienny budżet czasu, licznik pauzuje po wyjściu.
* n8n: opcjonalny „zdalny unlock” (webhook + flaga konfiguracji).
* UX: duże kafle gier, tryb „dziecięcy” bez zbędnych elementów.

**DOD:** Limit czasu działa (po wyczerpaniu nie uruchomisz gry), PIN bezpiecznie przechowywany, zdalny unlock działa na testowym zestawie.

### Sprint 4 (1 tydz.) – Testy, dokumentacja, demo

* Testy ręczne (checklista), smoke test dla obu trybów kiosku.
* Instrukcja „jak zainstalować i włączyć kiosk” (PDF/README).
* Nagranie krótkiego wideo z dema (pełny scenariusz).
* Porządki w repo, tag `v1.0`.

**DOD:** Gotowy build APK, dokumentacja + demo gotowe do prezentacji.

---

## 5) Podział zadań (równo na 3 osoby)

Każda osoba ma **4 główne obszary + 1 wspólny** (testy/dokumentacja). Zadania są przypisane per sprint.

### Duch Bartosz – **Kiosk & Android**

* S0: konfiguracja repo, CI (GitHub Actions build APK).
* S1: App Pinning z Fluttera (kanał platformowy), integracja WebView.
* S2: **Device Owner**: admin receiver, skrypty `adb`, auto-kiosk.
* S3: Blokady power/home (w granicach Lock Task Mode), odporność na rotację/recents.
* S4: Instrukcja techniczna „jak włączyć Device Owner”, checklista bezpieczeństwa.

**Artefakty:** plugin platformowy Kotlin, skrypty `adb`, README (kiosk).

### Gaweł Szymon – **Gry & Plugin API**

* S0: wybór gier i zasobów graficznych (open-license).
* S1: Gra #1 (HTML5/JS) + integracja w WebView.
* S2: **JS Bridge** (zdarzenia: start/stop/score/level) + Gra #2.
* S3: API „parent commands” (pauza, restart), profil trudności wiekowych.
* S4: Optymalizacja ładowania assets, mini-instrukcja „jak stworzyć nową wtyczkę-grę”.

**Artefakty:** /assets/games/…, specyfikacja API wtyczek (MD).

### Krzyszczuk Jakub – **Rodzic, Limity & n8n**

* S0: uruchomienie n8n (Docker), węzły `HTTP In`, `Google Sheets/DB`.
* S1: Ekran PIN (Flutter), lokalne logi (SQLite/Hive).
* S2: Wysyłka logów do n8n (batch + retry), endpointy `/log`, `/config`.
* S3: **TimeGuard** (limity dzienne), ekran ustawień rodzica, webhook „zdalny unlock”.
* S4: Dashboard w n8n/Sheets (raport: czas łącznie, wyniki), instrukcja rodzica.

**Artefakty:** flow n8n (export JSON), ekrany ustawień, dokumentacja rodzica.

### Wspólne (wszyscy)

* Testy e2e wg checklisty (S4).
* Code review (min. 1 review do każdego PR).
* Demo/wideo i prezentacja (podział ról: narrator, operator, Q&A).

---

## 6) „Definicja ukończenia” (DoD) i akceptacja

* **Nadzorca** uruchamia się w **pełnym kiosku** (Device Owner) na 1 urządzeniu testowym i w **App Pinning** na innym (lub tym samym bez DO).
* **Wyjście** możliwe wyłącznie przez **gest + poprawny PIN** lub przez **zdalny unlock** (n8n).
* **2 gry** działają offline i raportują zdarzenia (czas, wynik, poziom).
* **Limit czasu** odcina start gier po przekroczeniu budżetu.
* **Logi** widoczne w n8n/arkuszu (data, gra, czas, wynik).
* **Instrukcja**: instalacja, włączenie Device Owner, przywrócenie ustawień fabrycznych, zmiana PIN.
* **Build APK** dostępny z CI (artefakt).

---

## 7) Bez Android Studio – komendy „kopiuj-wklej”

1. **Flutter + SDK**: `flutter doctor` (upewnij się, że Android SDK cmdline tools są zainstalowane).
2. **Nowy projekt**: `flutter create kids_kiosk`
3. **Dodanie WebView**: `flutter pub add webview_flutter flutter_secure_storage hive`
4. **Build**: `flutter build apk --release`
5. **Instalacja**: `adb install -r build/app/outputs/flutter-apk/app-release.apk`
6. **(Pełny kiosk na urządzeniu testowym – po factory reset):**

   * `adb shell dpm set-device-owner com.example.kids_kiosk/.MyDeviceAdminReceiver`
   * (w kodzie: `setLockTaskPackages()` → `startLockTask()`)

> Jeśli *nie* możemy zrobić resetu: pokazujemy tryb **App Pinning** (użytkownik potwierdza przypięcie pierwszym razem).

---

## 8) Prosty protokół API dla wtyczek (gry ↔ nadzorca)

* **Z gry (JS) do nadzorcy (Flutter):**
  `postMessage({ type: 'GAME_EVENT', event: 'score', value: 7, level: 2 })`
* **Z nadzorcy do gry:**
  `postMessage({ type: 'PARENT_CMD', cmd: 'pause' | 'resume' | 'restart' })`
* **Zdarzenia minimalne:** `session_start`, `session_end`, `score`, `level_change`, `error`
* **Walidacja:** prosty schemat JSON + wersjonowanie (`apiVersion: 1`)

---

## 9) Ryzyka i plan B

* **Device Owner wymaga resetu** – pokażemy oba tryby (App Pinning + DO).
* **Blokady systemowe** różnią się między producentami – test na min. 2 modelach, jasna instrukcja „znane ograniczenia”.
* **Brak sieci** – logi buforowane lokalnie, wysyłka „później”.

---

## 10) Co dokładnie pokażemy na demo (scenariusz)

1. Instalacja APK z CLI.
2. Uruchomienie – tryb kiosk (brak paska nawigacji/wyjścia).
3. Wejście do **Gry #1**, uzyskanie wyniku, powrót.
4. Przekroczenie limitu czasu → blokada startu gier.
5. Próba wyjścia bez gestu/PIN → **nieudana**.
6. Gest + PIN → **wyjście do systemu**.
7. Logi i konfiguracja widoczne w n8n/arkuszu.

---

## 11) Minimalne „checklisty” jakości

* **PR checklist:** opis, screen/video, test ręczny na urządzeniu, lint.
* **Testy ręczne:**

  * błędny PIN ×3 (cooldown),
  * brak sieci (logi w kolejce),
  * rotacja ekranu,
  * przepełnienie limitu czasu,
  * awaryjny unlock z n8n.
