# Plan realizacji projektu (prosto, ale „na czysto”)

**Temat:** Aplikacja dla dzieci składająca się z „Nadzorcy” (kiosk/parental lock) i „Wtyczek” (gry edukacyjne).

---

## 1) Wybór stosu i założenia (upraszczamy maksymalnie)

* **Frontend mobilny:** (CLI + VS Code; bez Android Studio).
frontend mobilny ma byc mozliwie prosty, nie (do przemyslenia aplikacja webowa, czy nawet strona internetowa ktora bedziemy wlaczac na telefonie, moze byc tez flutter - wybierz najlepsze dla tego celu)

* **Warstwa natywna (tylko to, co konieczne):** cienki plugin Android (Kotlin), wywoływany z frontend do:

  * Lock Task Mode / App Pinning (kiosk),
  * Device Owner (na *jednym* urządzeniu testowym – pełny kiosk),
  * blokady klawiszy systemowych w trybie kiosk.
* **Wtyczki – gry:** proste **gry HTML5/JS** uruchamiane w **WebView** (pakowane jako assets).

  * Komunikacja gry ↔ nadzorca przez prosty **JS bridge**.
* **Backend/telemetria/konfiguracja rodzica:** **n8n** (self-hosted lub w chmurze), do:

  * zbierania logów (czas gry, wyniki),
  * zdalnego nadawania konfiguracji (np. lista gier, czas dzienny),
  * ewentualnego **zdalnego odblokowania** („awaryjna” dezaktywacja kiosku).
* **Bez Android Studio:** (Android SDK – tylko narzędzia wiersza poleceń).

> **Uwaga dot. kiosku:** „pełny” Lock Task Mode bez potwierdzeń wymaga **Device Owner** i zwykle **resetu urządzenia** (na sprzęcie testowym). Alternatywnie: „App Pinning”

---

## 2) Wymagania

### Funkcjonalne

1. **Kiosk (Nadzorca)**

   * Start w trybie pełnoekranowym, blokada nawigacji systemowej.
   * Biały-/czarny-lista aplikacji (docelowo tylko nasza).
   * **Wyjście** wyłącznie po **sekretnej czynności** (gest + PIN).
   * Limit czasu gry dziennie (np. 20/30/45 min) – potem blokada.
2. **Wtyczki (Gry)**

   * 2 gry HTML5 dla różnych grup wiekowych.
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

* **frontend app „Nadzorca”**

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
