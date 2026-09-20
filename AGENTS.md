# qi_flutter - System Knowledge Base & Migration Guide

Ten dokument służy jako główne źródło wiedzy (Single Source of Truth) dla obecnych i przyszłych agentów AI (Antigravity) oraz programistów pracujących nad projektem. Zawiera analizę starego kodu i wytyczne dla nowej architektury.

## 1. Cel Projektu
Migracja aplikacji desktopowej **qiWELLNESS** z technologii Lazarus/Free Pascal na nowoczesny stos **Flutter (UI) + Rust (Logika)**.
Aplikacja jest panelem sterowania dla urządzenia do biorezonansu/elektroakupunktury (komunikacja przez port szeregowy, w przyszłości planowane przejście na natywne USB lub BLE).

## 2. Analiza Starego Systemu (Legacy - Pascal)
Stary kod znajduje się w folderze `qiWELLNESS/` (w repozytorium wykluczony ze śledzenia w `.gitignore`).
Główne domeny aplikacji:
- **Komunikacja Sprzętowa**: Port szeregowy/USB (`TLazSerial` w `unitmain.pas`). Krótkie komendy tekstowe (np. `eap`, `ion`, `freq 100 100`, `calib`).
- **Integracja Web (REST)**: Moduł `biorest.pas` i funkcja `AtlasSearchBAP` z `unitmain.pas` pobierają dane z serwisu `http://biotronics.eu`.
- **Baza danych**: **Brak lokalnej bazy SQL**.
- **Główne tryby terapii/diagnostyki (Modalities)**: Ryodoraku, EAV, VEG, EAP, ION.

## 3. Architektura Docelowa (Multi-crate Workspace)
Zastosujemy zaawansowany wzorzec modułowy oparty na Rust Workspace (inspirowany strukturą projektu `crispy-tivi`), **ALE** z ważnym zastrzeżeniem: **Nie obsługujemy platformy Web i nie stosujemy architektury serwera WebSocket**. 
Aplikacja jest w 100% natywna, a cała "ciężka" logika (matematyka, stan maszyny, bezpośrednia komunikacja z portami) znajduje się w Ruście, odcięta od UI i połączona wyłącznie przez FFI w pamięci.

*   **Warstwa Prezentacji (Flutter/Dart - Native App)**:
    *   Skompilowana **wyłącznie** jako aplikacja Desktop (PC Linux/Windows/macOS) i Mobile (Android/iOS).
    *   Tylko UI i zarządzanie stanem widoku. Odtworzenie kontrolek z `unitmain.lfm`.
*   **Warstwa Logiki (Rust Workspace)**:
    *   `crates/qi_core`: Czysta logika biznesowa i sprzętowa (`serialport`, docelowo też natywne API USB/BLE). Nie wie o istnieniu Fluttera. Stan maszyny i obliczenia.
    *   `crates/qi_ffi`: Crate pełniący rolę bezpośredniego mostu FFI w pamięci. Zawiera kod **flutter_rust_bridge (FRB)** wystawiający funkcje z `qi_core` dla Fluttera.

## 4. Plan Realizacji (Kamienie Milowe)

### Milestone 1: Replikacja UI (PC & Mobile) i Szkielet Architektury
**Główny cel: Działający interfejs graficzny na platformach Natywnych (PC: Linux/Win/Mac, Mobile: Android/iOS), połączony z Rustem (Mocki). Zero Web.**
1. Inicjalizacja projektu Flutter (z wykluczeniem targetu Web).
2. Setup struktury Rust Workspace (`qi_core`, `qi_ffi`) + `flutter_rust_bridge_codegen`.
3. Zbudowanie układu graficznego odpowiadającego staremu oknu głównemu.
4. Utworzenie kontraktów w Rust (`pub fn` wywoływane przez Flutter). Zwracanie zmockowanych danych (np. losowe punkty do wykresu Ryodoraku), co pozwoli w pełni przetestować UI.

### Milestone 2: Pełna Logika i Integracja Sprzętowa (Control Panel)
**Główny cel: Przeniesienie komunikacji z urządzeniem i API do Rusta.**
1. Implementacja crate'a `serialport` w `qi_core` (przygotowanie gruntu pod przyszłe protokoły jak surowe USB czy BLE).
2. Translacja logiki binarnej/tekstowej (`SerialRxData` z Pascala) na parser w Rust.
3. Aplikacja natywna (Flutter Desktop/Mobile) w pełni kontroluje maszynę na żywo.

### Milestone 3: Baza Danych i Archiwizacja
**Główny cel: Zapisywanie historii diagnoz i profili pacjentów.**
1. Dodanie lokalnej bazy (np. `rusqlite` w `qi_core`) na PC/Tel lub przygotowanie do synchronizacji z chmurą.

## 5. Konfiguracja Środowiska Pracy
- Wymagane zainstalowane narzędzia: `rustc`, `cargo`, `flutter`, `dart`.
- Zależności dla Linux PC (Desktop Flutter): `libgtk-3-dev`, `cmake`, `ninja-build`, `pkg-config`, biblioteki developerskie C++.
- Zalecana praca w **DevContainer** dla ujednolicenia środowiska i uniknięcia konfliktów pakietów systemowych na lokalnej maszynie programisty.
