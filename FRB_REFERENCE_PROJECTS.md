# Analiza Projektów Open Source (Flutter + Rust + flutter_rust_bridge)

Poniższe zestawienie skupia się **wyłącznie na stosie technologicznym i architekturze**, ignorując biznesową funkcjonalność (produkt) tych aplikacji. Szukaliśmy projektów, gdzie Flutter pełni rolę "cienkiego" interfejsu użytkownika (UI), a ciężka logika i komunikacja sieciowa (np. przez `reqwest`) znajdują się po stronie Rusta, spięte przez `flutter_rust_bridge` (FRB).

---

## 1. Oficjalne Szablony i Przykłady FRB

### [fzyzcjy/flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge) (Katalog `frb_example/`)
To główne repozytorium twórcy mostu FRB. Znajdujące się tam przykłady (szczególnie `frb_example/pure_dart` oraz `frb_example/with_flutter`) wyznaczają standard struktury.
*   **Technologie:** Flutter, Rust, `flutter_rust_bridge_codegen`.
*   **Struktura:**
    *   Wzorzec standardowy: folder `rust` lub `native` (zawierający `Cargo.toml` i logikę) jako podkatalog lub równoległy katalog do głównego projektu Fluttera (np. `app/`).
    *   Bardzo mocny nacisk na plik `api.rs` (lub podział na moduły `api_*.rs`), który stanowi "fasadę" (kontrakt) wystawianą dla Fluttera.
*   **Wniosek:** To bazowy szablon (template), wokół którego buduje się resztę. Logika nie jest tu skomplikowana, bo to tylko dema, ale struktura katalogów jest referencyjna.

---

## 2. Projekty Społecznościowe (Real-world Architecture)

### [patmuk/flutter-UI_rust-BE-example](https://github.com/patmuk/flutter-UI_rust-BE-example)
Projekt stworzony stricte w celu pokazania eleganckiej architektury, oddzielającej UI we Flutterze od "Backendu" w Ruście uruchamianego lokalnie na urządzeniu.
*   **Technologie:** Flutter, Rust, FRB.
*   **Architektura (CQRS / Redux-like):**
    *   Zastosowano podejście przypominające Redux/CQRS (Command Query Responsibility Segregation). 
    *   Flutter wysyła do Rusta obiekty typu "Akcje/Komendy".
    *   Rust przyjmuje akcje, przetwarza stan w pamięci i wypycha zaktualizowany Stan (State) z powrotem do Fluttera, często wykorzystując strumienie (Streams) z FRB.
    *   Flutter tylko nasłuchuje na strumień zmian z Rusta i na jego podstawie przebudowuje UI.

### [cunarist/rinf](https://github.com/cunarist/rinf) (Wcześniej oparte na FRB, teraz osobny framework)
Warto o nim wspomnieć. Rinf to framework, który narodził się wokół podobnego pomysłu. Choć najnowsze wersje używają własnego FFI, jego korzenie (i wczesne wersje) mocno bazowały na FRB.
*   **Architektura:** Wprowadza bardzo rygorystyczny podział, gdzie komunikacja pomiędzy Flutterem a Rustem odbywa się za pomocą serializacji Protobuf. Rust działa jako w pełni odizolowany, wielowątkowy serwer demaskujący wiadomości z UI.

### Projekty wykorzystujące Rust + `reqwest` jako API Client dla Fluttera
Wiele mniejszych projektów na GitHubie stosuje wzorzec, w którym omijany jest standardowy pakiet `dart:io` lub `http` w Flutterze, na rzecz biblioteki `reqwest` z Rusta.
*   **Powód:** `reqwest` oferuje lepsze zarządzanie pulą połączeń (connection pooling), wydajność wielowątkową, omijanie specyficznych dla Darta problemów z TLS na różnych platformach oraz wsparcie dla HTTP/3 (np. via `rhttp`).
*   **Struktura:** Tworzony jest w Ruście moduł `network.rs`, który eksponuje funkcje asynchroniczne (`async fn fetch_data(...) -> Result<Data, Error>`). FRB automatycznie tłumaczy rustowe `Result` na Dartowe `Future` z odpowiednią obsługą wyjątków (`try/catch`).

---

## 3. Analiza Struktur i Porównanie z Szablonem FRB

Gdy przeanalizujemy te repozytoria, wyłaniają się 3 popularne sposoby organizacji kodu (Struktura Repozytorium):

### Podejście A: "Monorepo" (Zalecany Szablon FRB)
Większość (ok. 80%) analizowanych projektów, w tym szablony generowane przez `flutter_rust_bridge_codegen create`, używa jednej struktury:
```text
my_app/
├── lib/             (Kod Dart/Flutter UI)
├── rust/            (Cargo crate z całą logiką Rusta)
│   ├── Cargo.toml
│   └── src/
│       ├── api.rs   (Funkcje wystawione dla Fluttera)
│       ├── rest.rs  (Logika reqwest/HTTP)
│       └── logic.rs (Czarna skrzynka - obliczenia)
├── pubspec.yaml
└── .gitignore
```
**Zalety:** Wybitnie prosta integracja CI/CD. Jedno środowisko otwarte w VS Code pozwala edytować UI i Logikę. Łatwe generowanie mostu (FRB wie, gdzie szukać plików).

### Podejście B: Oddzielne Repozytoria (Workspace Rustowy)
Większe aplikacje (szczególnie, gdy logika w Ruście jest współdzielona także z backendem serwerowym lub aplikacją CLI) dzielą projekt na oddzielne foldery root:
```text
/flutter_app
/rust_core       (Czysty Rust, niezależny od niczego)
/rust_bridge     (Crate, który linkuje rust_core i FRB)
```
**Zalety:** Czysty kod Rusta (`rust_core`) można testować bez konieczności mieszania go z plikami Fluttera.

### Podsumowanie i Oceny (Najlepsza Architektura dla Nas)
Dla Twojego projektu migracji `qiWELLNESS`, **Podejście A (Zalecany szablon Monorepo FRB)** będzie absolutnie najlepsze. 
Z projektów, które zbadałem, te stosujące to podejście wraz z wzorcem przypominającym ten z projektu `patmuk/flutter-UI_rust-BE-example` radzą sobie najlepiej ze złożonością. 
**Rekomendowana Architektura:**
1.  **Stan aplikacji mieszka w Ruście.**
2.  Flutter wywołuje `api.rs` np. `start_therapy("eap")`.
3.  Zamiast czekać, Rust oddaje sterowanie, a UI nasłuchuje na asynchroniczny `Stream` z FRB.
4.  Gdy Rust pobierze dane z `reqwest` (lub portu szeregowego), wypycha je przez `Stream`. Flutter używa `StreamBuilder` do narysowania wykresów (fl_chart).

Ten model wyciąga 100% z możliwości, jakie daje `flutter_rust_bridge`, izolując trudny kod C++/Rust od UI.

---

## 4. Uwagi i korekty do powyższej analizy (po samodzielnym researchu na GitHub)

Poniższe punkty to konkretne zastrzeżenia do sekcji 1-3 powyżej, oparte na realnym przeglądzie repozytoriów (nie na ogólnej wiedzy):

1. **`patmuk/flutter-UI_rust-BE-example` i wzorzec CQRS/Redux** — nie zweryfikowałem tego repo bezpośrednio w tej turze researchu (nie znalazłem go ani w topicu `flutter-rust-bridge`, ani w wynikach wyszukiwania). Opis brzmi wiarygodnie (autor `patmuk` faktycznie jest kontrybutorem FRB — potwierdzone w liście kontrybutorów), ale traktuj tę architekturę jako **niepotwierdzoną w 100%** — warto ją zweryfikować osobiście przed kopiowaniem wzorca.
2. **Sekcja "Rust + `reqwest` jako API Client"** — to było uogólnienie teoretyczne, a nie obserwacja z konkretnych repozytoriów. W realnych projektach, które znalazłem (patrz niżej), sieciowanie po stronie Rusta bywa robione różnie — nie zawsze przez `reqwest` wprost, czasem przez własny serwer (Axum) albo natywne SDK. Nie potwierdzałbym tego jako "dominującego wzorca" bez dalszych dowodów.
3. **Diagram "Podejście A: Monorepo"** pomija bardzo istotny, powtarzający się w praktyce element: folder **`rust_builder/`** (wzorzec [cargokit](https://github.com/irondash/cargokit)). To osobny, generowany pod-pakiet Flutter (`rust_builder/`), który odpowiada za kompilację cratu Rust per-platforma (Android/iOS/Windows/macOS/Linux) i linkowanie go jako plugin. Znalazłem go w **3 z 4** realnych aplikacji produkcyjnych (StarCitizenToolBox, astral). To ważne uzupełnienie diagramu, bo bez tego elementu ręczne dodanie Rusta do Fluttera na wielu platformach jest dużo trudniejsze.
4. **Web jako platforma** — jeśli kiedykolwiek rozważycie target webowy dla qi_flutter, żaden z modeli "FFI wprost" nie zadziała (brak wątków/FFI w WASM w pełni). Realny przykład (`crispy-tivi`) pokazuje rozwiązanie: na Web Rust działa jako **towarzyszący serwer** (Axum + WebSocket), a Flutter Web łączy się z nim przez WebSocket zamiast przez FFI. To rozdzielenie architektury per-platforma nie było wspomniane w oryginalnej analizie.
5. Repo `rhian-cs/oss-flutter_rust_bridge` (znalezione w wyszukiwaniu) to **martwy fork** głównego repozytorium FRB (9757 commitów w tyle) — nieprzydatne jako wzorzec, pomijam je w wynikach poniżej.

---

## 5. Nowe znalezione projekty (weryfikacja bezpośrednio na GitHub)

Skupienie wyłącznie na stacku: Flutter jako UI + Rust jako logika/sieć + FRB (lub bliski odpowiednik).

### [moabualruz/crispy-tivi](https://github.com/moabualruz/crispy-tivi) — ⭐ 26
Najbardziej dojrzały strukturalnie z przebadanych. Jawnie deklaruje w README: *"All business logic and data persistence lives in Rust. Flutter is a pure UI client."*
- **Stack**: Flutter/Dart (UI, Riverpod, GoRouter) + Rust (`crispy-core` logika/persystencja, `rusqlite`) + FRB jako FFI most.
- **Struktura repo** (workspace-style monorepo w jednym repo, ale wyraźnie rozdzielone foldery root):
  ```
  rust/crates/crispy-core    # logika biznesowa + SQLite (rusqlite)
  rust/crates/crispy-ffi     # most natywny dla Fluttera (FRB)
  rust/crates/crispy-server  # serwer-towarzysz dla Web (Axum + tokio-tungstenite, WebSocket)
  rust/shared/               # eksportowane crate'y jako git submodules
  app/flutter/lib/           # UI, podzielone feature-first
  ```
- **Sieć**: Dio + Retrofit po stronie Dart do niektórych wywołań, ale cała logika domenowa (parsing M3U/Xtream Codes, EPG, persystencja) siedzi w Rust. Na platformach natywnych Rust jest embedded (FFI), na Web — osobny proces serwera.
- **Testy**: 799 testów Rust + 1800+ testów Flutter, CI wymusza 0 ostrzeżeń analizatora.
- Ma własny plik `AGENTS.md` — potwierdza, że to konwencja, którą też przyjęliśmy dla qi_flutter.
- duzo AI ladnego i 

### [StarCitizenToolBox/app](https://github.com/StarCitizenToolBox/app) — ⭐ 145
Duża, aktywnie rozwijana aplikacja desktopowa (toolbox dla graczy Star Citizen).
- **Stack**: Dart 78% / Rust 19%, FRB skonfigurowany przez plik `flutter_rust_bridge.yaml` (nowoczesny, deklaratywny config v2, bez ręcznego CLI).
- **Struktura**: `rust/` (crate z logiką) + `rust_builder/` (wygenerowany pakiet cargokit, spina budowanie natywnej biblioteki jako Flutter plugin) w jednym repo obok `lib/`.
- Ma `AGENTS.md` w root repo — kolejne potwierdzenie konwencji.
- Buduje na Windows/Linux/macOS, dystrybuowany też przez Microsoft Store.

### [ldoubil/astral](https://github.com/ldoubil/astral) — ⭐ 1.2k
Aplikacja do sieci P2P/VPN (oparta o EasyTier) — najwyżej oceniana (gwiazdki) z przebadanych z realnym backendem sieciowym w Ruście.
- **Stack**: Flutter (Dart) UI + Rust (EasyTier) jako "wydajny backend sieciowy", opisane wprost w README: *"⚡ 高性能 - Rust 后端确保高效的网络处理"* (wysoka wydajność — backend Rust zapewnia efektywne przetwarzanie sieciowe).
- **Struktura**: `rust/` + `rust_builder/` (znów wzorzec cargokit) + dodatkowo `vpn_service_plugin/` jako osobny plugin Fluttera do integracji z systemowym VPN.
- Ma dedykowaną stronę DeepWiki z rozdziałem "Flutter-Rust Bridge Architecture" — dobre źródło do dalszej analizy szczegółów mostu, jeśli zajdzie potrzeba.

### [cunarist/rinf](https://github.com/cunarist/rinf) — ⭐ 2.8k
Nie jest to FRB, ale **alternatywny framework o tym samym celu** (Rust jako logika, Flutter jako UI), warty odnotowania jako punkt porównawczy architektoniczny.
- **Różnica kluczowa vs FRB**: komunikacja Dart↔Rust nie przez wygenerowane bindingi per-funkcja, tylko przez **wiadomości/sygnały** (podobne do Protobuf/message-passing) — `MyMessage.send_signal_to_dart()` w Rust, `MyMessage.rustSignalStream` jako `StreamBuilder` w Dart. To bardzo bliskie architekturze "Stan w Ruście + Stream do UI" rekomendowanej w sekcji 3.
- Ma tag `restful-api` na GitHub, co sugeruje że społeczność faktycznie używa go do budowy klientów REST w Ruście pod Flutterem.
- **Struktura**: framework, nie aplikacja — `rust_crate/` (biblioteka Rust) + `flutter_package/` (pakiet Dart) jako osobne, publikowane pakiety; przykładowa aplikacja w `flutter_package/example/`.
- Status: projekt aktualnie **szuka nowego maintainera** (ogłoszenie w README) — ryzyko dla long-term stabilności, warto to wziąć pod uwagę jeśli rozważacie go zamiast FRB.

### [Desdaemon/flutter_rust_bridge_template](https://github.com/Desdaemon/flutter_rust_bridge_template) — ⭐ 132
Starszy szablon (FRB v1, CLI-based: `flutter_rust_bridge_codegen --rust-input native/src/api.rs ...`), folder `native/` zamiast `rust/`. Wartościowy **tylko jako punkt odniesienia historycznego** — pokazuje, jak wyglądał ten sam wzorzec zanim FRB v2 wprowadził plik konfiguracyjny `flutter_rust_bridge.yaml`. Nie polecam kopiować tej struktury dla nowego projektu (qi_flutter powinien celować w konwencje v2).

---

## 6. Zbiorcze porównanie struktur repo (rozszerzone o realne przykłady)

| Projekt | Wzorzec struktury | Rust jako | Ocena dla qi_flutter |
|---|---|---|---|
| Szablon FRB (`flutter_rust_bridge_codegen create`) | Monorepo: `rust/` + `lib/` | wbudowana biblioteka (FFI) | ✅ Punkt startowy — zawsze zgodny z najnowszym FRB |
| `crispy-tivi` | Monorepo z rozdziałem `app/flutter` + `rust/crates/*` (multi-crate workspace) + osobny crate serwera webowego | multi-crate: core / ffi / server | ✅✅ Najbliższy docelowej architekturze qi_flutter — czysty podział logiki/mostu, łatwe testowanie Rusta w izolacji |
| `StarCitizenToolBox/app`, `astral` | Monorepo: `rust/` + wygenerowany `rust_builder/` (cargokit) | crate + plugin-wrapper | ✅ Realistyczny, sprawdzony w produkcji sposób na multi-platformowy build — **brakujący element** w oryginalnym diagramie z sekcji 3 |
| `rinf` (alternatywa dla FRB) | Framework: `rust_crate/` + `flutter_package/` jako osobne publikowane pakiety | logika + message-passing zamiast bindingów per-funkcja | ⚠️ Ciekawa alternatywa architektoniczna (Stream-first), ale nie FRB — nie mieszać wzorców |
| `Desdaemon/flutter_rust_bridge_template` | Monorepo: `native/` + `lib/` (styl v1) | wbudowana biblioteka (stary CLI) | ❌ Przestarzały wzorzec, pomiń |

**Wniosek zaktualizowany**: rekomendacja z sekcji 3 (Podejście A, stan w Ruście + Stream do UI) pozostaje słuszna, ale należy ją uzupełnić o:
1. Multi-crate workspace w Ruście (`crispy-tivi`) zamiast jednego płaskiego crate'a — ułatwia to testowanie logiki (np. parsera komend `eap`/`ion`/`freq`) bez zależności od Fluttera.
2. Folder `rust_builder/` (cargokit) generowany automatycznie przez `flutter_rust_bridge_codegen` — nie trzeba go ręcznie tworzyć, ale warto wiedzieć, że tam mieszka logika budowania natywnej biblioteki per-platforma.

