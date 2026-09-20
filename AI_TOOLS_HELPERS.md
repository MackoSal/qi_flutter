# AI Tools Helper

## English

### Purpose

This guide describes the AI roles and skills stored in `.gemini/`, how to invoke them reliably, and when to use them in `qi_flutter`.

`AGENTS.md` remains the source of truth for architecture and project constraints. Read it before using any role or skill.

### Reliable Invocation

The portable form works in GitHub Copilot, Claude Code, and Gemini because it explicitly names the file:

```text
Read .gemini/rules/architect.md and act as the Architect.
Design the Flutter-to-Rust boundary for device communication. Do not edit files yet.
```

```text
Read .gemini/skills/plan/SKILL.md and follow its workflow where compatible with your available tools.
Plan the Ryodoraku measurement feature.
```

Use a **rule** to set the role, scope, quality bar, and output style. Use a **skill** to apply a task workflow. They can be combined:

```text
Use .gemini/skills/plan/SKILL.md. First apply the Analyst role from
.gemini/rules/analyst.md, then create an implementation plan.
```

### Tool Support

- **Gemini:** Depending on the Gemini runner, entries under `.gemini/skills/` and `.gemini/rules/` may be discovered automatically. Explicitly naming the file is still recommended for important work. Do not assume that every runner registers `/skill-name` as a slash command.
- **GitHub Copilot:** It reads `.github/copilot-instructions.md` and `AGENTS.md`, but it does not automatically register `.gemini` files as Copilot skills or agents. Use the portable form above, or later adapt selected workflows to `.github/skills/` and `.github/agents/`.
- **Claude Code:** It reads `CLAUDE.md`, but it does not automatically register `.gemini` files as Claude skills or agents. Use the portable form above, or later adapt selected workflows to `.claude/skills/` and `.claude/agents/`.
- Some workflows reference **OMX**, `ask_codex`, `ask_gemini`, `ask_claude`, browser automation, Penpot, Widgetbook, or local CLIs. Treat those steps as optional unless the required tool is actually installed and available.

### Rules

#### `analyst` - Analyst
**Purpose:** Turn a request into testable requirements, identify missing decisions, assumptions, boundaries, and edge cases before planning.

**Use when:** A request is vague, safety-critical, or likely to hide workflow details.

**Example:** `Read .gemini/rules/analyst.md. Analyze requirements for recording a Ryodoraku measurement session before implementation.`

#### `architect` - Architect
**Purpose:** Define module boundaries, interfaces, trade-offs, and failure modes.

**Use when:** Adding a Rust subsystem, altering FFI contracts, or changing the Flutter/Rust architecture.

**Example:** `Read .gemini/rules/architect.md. Design the serial-device session boundary between qi_core and Flutter.`

#### `build-fixer` - Build Fixer
**Purpose:** Diagnose and fix compile, link, dependency, and native-toolchain failures with the smallest safe change.

**Use when:** `cargo build`, `flutter run`, Android Gradle, CMake, or FFI linking fails.

**Example:** `Read .gemini/rules/build-fixer.md. Fix the Linux Flutter build failure caused by the Rust bridge.`

#### `code-reviewer` - Code Reviewer
**Purpose:** Review a diff for correctness, regressions, maintainability, style, and missing tests.

**Use when:** Before committing, merging, or accepting a non-trivial change.

**Example:** `Read .gemini/rules/code-reviewer.md. Review the staged Rust parser changes; do not edit files.`

#### `code-simplifier` - Code Simplifier
**Purpose:** Remove accidental complexity and duplication without changing behavior.

**Use when:** A completed feature is overly indirect, repetitive, or difficult to read.

**Example:** `Read .gemini/rules/code-simplifier.md. Simplify the device connection view state without changing behavior.`

#### `critic` - Critic
**Purpose:** Challenge plans and designs for weak assumptions, omissions, and brittle choices.

**Use when:** A plan or architecture decision needs an independent adversarial review.

**Example:** `Read .gemini/rules/critic.md. Critique the proposed USB/BLE migration plan before implementation.`

#### `debugger` - Debugger
**Purpose:** Reproduce, isolate, and correct a runtime defect from evidence such as logs, traces, and failing conditions.

**Use when:** The app hangs, crashes, returns incorrect readings, or a native callback behaves unexpectedly.

**Example:** `Read .gemini/rules/debugger.md. Diagnose why the Flutter app stops receiving serial-port readings after reconnecting.`

#### `dependency-expert` - Dependency Expert
**Purpose:** Assess package compatibility, upgrade risks, platform impact, and dependency drift.

**Use when:** Changing Flutter, Rust, Android, iOS, FRB, or native library versions.

**Example:** `Read .gemini/rules/dependency-expert.md. Evaluate upgrading flutter_rust_bridge and identify compatibility work.`

#### `designer` - Designer
**Purpose:** Define usable, consistent UI flows, components, states, and visual hierarchy.

**Use when:** Recreating a Lazarus screen, building a new diagnostic workflow, or defining visual states.

**Example:** `Read .gemini/rules/designer.md. Design the Flutter layout that replaces the legacy main diagnostic window.`

#### `executor` - Executor
**Purpose:** Implement an approved, bounded task and validate the result.

**Use when:** Requirements and the implementation plan are already clear.

**Example:** `Read .gemini/rules/executor.md. Implement the approved device-connection status panel and run relevant checks.`

#### `explore` - Explorer
**Purpose:** Inspect the repository and report existing patterns, ownership, and likely edit locations without changing code.

**Use when:** Starting unfamiliar work or locating legacy functionality before migration.

**Example:** `Read .gemini/rules/explore.md. Find how the Lazarus application sends the calib command and summarize the protocol.`

#### `git-master` - Git Master
**Purpose:** Prepare clean commits, safe branch operations, and reviewable Git history.

**Use when:** Splitting staged changes, preparing a PR, resolving a non-trivial Git state, or making releases.

**Example:** `Read .gemini/rules/git-master.md. Split the staged architecture changes into logical commits without losing work.`

#### `planner` - Planner
**Purpose:** Break complex work into ordered implementation steps, dependencies, acceptance criteria, and validation gates.

**Use when:** A task spans multiple files, layers, or milestones.

**Example:** `Read .gemini/rules/planner.md. Plan the first vertical slice for live serial-device readings in Flutter.`

#### `researcher` - Researcher
**Purpose:** Gather evidence and compare technical alternatives before selecting an approach.

**Use when:** Library, platform, protocol, or design choices are uncertain.

**Example:** `Read .gemini/rules/researcher.md. Compare serialport, native USB, and BLE options for the next hardware layer.`

#### `security-reviewer` - Security Reviewer
**Purpose:** Review secrets, data flows, unsafe boundaries, dependencies, and input handling for security weaknesses.

**Use when:** Adding networking, credentials, persistence, imports, update flows, or external-device input.

**Example:** `Read .gemini/rules/security-reviewer.md. Review the planned REST client and local patient-history storage.`

#### `team-executor` - Team Executor
**Purpose:** Coordinate parallel work, ownership boundaries, hand-offs, and integration checkpoints.

**Use when:** A change genuinely needs multiple agents or contributors working in parallel.

**Example:** `Read .gemini/rules/team-executor.md. Divide the device-session feature between Rust protocol work and Flutter UI work.`

#### `test-engineer` - Test Engineer
**Purpose:** Define test coverage, edge cases, test data, and validation strategy.

**Use when:** Adding parsers, calculations, safety behavior, state machines, or user-facing diagnostic flows.

**Example:** `Read .gemini/rules/test-engineer.md. Design tests for the serial response parser and its malformed-input behavior.`

#### `verifier` - Verifier
**Purpose:** Check the completed implementation against acceptance criteria and regressions.

**Use when:** Before declaring a task done, merging a feature, or releasing a build.

**Example:** `Read .gemini/rules/verifier.md. Verify the device reconnect flow against the approved requirements.`

#### `vision` - Vision
**Purpose:** Evaluate whether a feature and UX direction still support the intended product outcome.

**Use when:** Scope is expanding or a technical solution may compromise the clinical control-panel experience.

**Example:** `Read .gemini/rules/vision.md. Assess whether the proposed dashboard supports fast, low-error practitioner workflows.`

#### `writer` - Writer
**Purpose:** Produce clear documentation, technical explanations, decision records, and release notes.

**Use when:** Updating README files, documenting a protocol, or recording an architectural decision.

**Example:** `Read .gemini/rules/writer.md. Document the Rust serial-session lifecycle for contributors.`

### Skills

#### `ai-slop-cleaner` - AI Slop Cleaner
**Purpose:** Remove generic, repetitive, unnecessary, or misleading AI-generated code comments and prose.

**Use when:** A generated patch or document is bloated or contains stale template content.

**Example:** `Read .gemini/skills/ai-slop-cleaner/SKILL.md. Clean generated comments from app/flutter/lib without changing behavior.`

#### `ask-claude` - Ask Claude
**Purpose:** Request an independent answer from a locally installed Claude CLI and preserve it as an artifact.

**Use when:** A difficult decision benefits from a second model's opinion.

**Example:** `Read .gemini/skills/ask-claude/SKILL.md. Ask Claude to critique the proposed Rust device-state model.`

**Availability:** Requires the local `claude` CLI or compatible OMX integration.

#### `ask-gemini` - Ask Gemini
**Purpose:** Request an independent answer from a Gemini integration and preserve or use the result.

**Use when:** You need a second opinion while working in another AI tool.

**Example:** `Read .gemini/skills/ask-gemini/SKILL.md. Ask Gemini for alternative error-recovery strategies for a serial disconnect.`

**Availability:** Requires a Gemini integration or configured external command.

#### `autopilot` - Autopilot
**Purpose:** Drive a clear task through investigation, implementation, and validation with limited user interruption.

**Use when:** The requested result is clear and the task is safe to execute end-to-end.

**Example:** `Read .gemini/skills/autopilot/SKILL.md. Implement the approved mock Ryodoraku chart vertical slice and validate it.`

#### `cancel` - Cancel
**Purpose:** Stop an active workflow or long-running operation in a controlled way.

**Use when:** The task is no longer wanted, the direction changed, or a background process must be stopped.

**Example:** `Read .gemini/skills/cancel/SKILL.md. Cancel the current broad migration workflow and preserve its findings.`

#### `code-review` - Code Review
**Purpose:** Run a structured review of a diff, with findings prioritized by impact.

**Use when:** Before merge, after a large patch, or before accepting AI-generated changes.

**Example:** `Read .gemini/skills/code-review/SKILL.md. Review the current staged changes; do not edit files.`

#### `configure-notifications` - Configure Notifications
**Purpose:** Configure workflow notifications and status reporting.

**Use when:** An available environment supports task, CI, or collaboration notifications and you want to configure them.

**Example:** `Read .gemini/skills/configure-notifications/SKILL.md. Configure build-failure notifications for the project if supported.`

**Availability:** Requires compatible notification tooling in the active environment.

#### `deep-interview` - Deep Interview
**Purpose:** Elicit hidden requirements and decisions through structured, sequential questions.

**Use when:** Product behavior, safety constraints, or user workflow is underspecified.

**Example:** `Read .gemini/skills/deep-interview/SKILL.md. Interview me to define the patient-session save workflow.`

#### `design-system` - Design System
**Purpose:** Define or apply reusable Flutter theme tokens, components, and visual rules.

**Use when:** Establishing the initial visual system or making screens visually consistent.

**Example:** `Read .gemini/skills/design-system/SKILL.md. Define Flutter theme tokens and core controls for the diagnostic application.`

#### `doctor` - Doctor
**Purpose:** Diagnose project and environment health, then suggest or apply focused setup repairs.

**Use when:** Flutter, Rust, FRB, Android SDK/NDK, or desktop prerequisites are missing or misconfigured.

**Example:** `Read .gemini/skills/doctor/SKILL.md. Diagnose why the Android build cannot locate the Rust toolchain.`

**Availability:** Needs relevant local CLIs such as `flutter`, `cargo`, `rustc`, and platform tooling.

#### `help` - Help
**Purpose:** Explain available workflows and recommend the next action for a task.

**Use when:** You are unsure which role or skill applies.

**Example:** `Read .gemini/skills/help/SKILL.md. Recommend the right workflow for migrating one legacy Pascal dialog to Flutter.`

#### `hud` - HUD
**Purpose:** Present compact workflow status, active tasks, and progress information.

**Use when:** A supported runner provides a task/status interface and work has several active stages.

**Example:** `Read .gemini/skills/hud/SKILL.md. Show the current implementation and validation status for this migration task.`

**Availability:** Depends on runner-specific status tooling.

#### `note` - Note
**Purpose:** Persist a decision or important context as a project note.

**Use when:** You need to record a protocol fact, architectural decision, or unresolved risk for future work.

**Example:** `Read .gemini/skills/note/SKILL.md. Record that Web and WebSocket architectures are explicitly out of scope.`

**Availability:** The storage destination depends on the active runner; verify it before relying on persistent memory.

#### `omx-setup` - OMX Setup
**Purpose:** Configure or diagnose the OMX/OMX workflow used by these AI assets.

**Use when:** You intentionally use OMX and need its setup, not for ordinary Flutter/Rust development.

**Example:** `Read .gemini/skills/omx-setup/SKILL.md. Check whether this workspace has the prerequisites for OMX workflows.`

**Availability:** Requires OMX-specific tooling.

#### `penpot-design-system` - Penpot Design System
**Purpose:** Translate a Penpot design system into implementable UI tokens and components.

**Use when:** The source design is maintained in Penpot.

**Example:** `Read .gemini/skills/penpot-design-system/SKILL.md. Map the Penpot controls to Flutter theme extensions and widgets.`

**Availability:** Requires Penpot assets or integration.

#### `plan` - Plan
**Purpose:** Produce a grounded implementation plan with requirements, steps, risks, and validation.

**Use when:** The work is broad, ambiguous, multi-layered, or expensive to reverse.

**Example:** `Read .gemini/skills/plan/SKILL.md. Plan the migration of the legacy serial communication protocol into qi_core.`

#### `ralph` - Ralph
**Purpose:** Execute an approved plan through a structured, persistent delivery workflow.

**Use when:** A plan already exists and you want an execution-oriented workflow with checkpoints.

**Example:** `Read .gemini/skills/ralph/SKILL.md. Execute the approved plan for mock diagnostic readings.`

**Availability:** Some stages may require OMX-specific agents or commands.

#### `ralplan` - Ralph Plan
**Purpose:** Build or refine a plan using the Ralph planning workflow.

**Use when:** A substantial task needs a deliberate plan before using `ralph` for execution.

**Example:** `Read .gemini/skills/ralplan/SKILL.md. Create a Ralph-ready plan for the device connection lifecycle.`

**Availability:** Some stages may require OMX-specific agents or commands.

#### `security-review` - Security Review
**Purpose:** Perform a structured security review of code, dependencies, data, and external boundaries.

**Use when:** Before handling patient data, network traffic, credentials, updates, or untrusted device input.

**Example:** `Read .gemini/skills/security-review/SKILL.md. Review the data storage design before patient profiles are implemented.`

#### `skill` - Skill Authoring
**Purpose:** Create or improve a reusable project skill.

**Use when:** A repeated workflow needs a documented, triggerable procedure.

**Example:** `Read .gemini/skills/skill/SKILL.md. Create a skill for validating the serial protocol parser.`

#### `team` - Team
**Purpose:** Coordinate several agents or contributors around a shared plan, roles, and verification path.

**Use when:** Work can be safely parallelized across independent areas.

**Example:** `Read .gemini/skills/team/SKILL.md. Coordinate parallel Rust protocol analysis and Flutter screen reconstruction.`

**Availability:** May rely on runner-specific multi-agent or OMX support.

#### `trace` - Trace
**Purpose:** Follow execution through logs, callbacks, and layers to locate a root cause.

**Use when:** A failure crosses Flutter, FFI, Rust, and hardware boundaries.

**Example:** `Read .gemini/skills/trace/SKILL.md. Trace a measurement request from the Flutter button to the serial response.`

**Availability:** Benefits from local logs, tracing, `adb logcat`, or equivalent diagnostics.

#### `ultrawork` - UltraWork
**Purpose:** Run a disciplined high-throughput implementation workflow with continuous verification.

**Use when:** A well-bounded but substantial task needs fast, end-to-end delivery.

**Example:** `Read .gemini/skills/ultrawork/SKILL.md. Deliver the approved mock chart feature with tests and validation.`

**Availability:** May rely on runner-specific orchestration support.

#### `visual-verdict` - Visual Verdict
**Purpose:** Compare a rendered UI against a design or reference and provide a concrete visual QA verdict.

**Use when:** Recreating a legacy dialog, checking responsive layout, or reviewing UI polish.

**Example:** `Read .gemini/skills/visual-verdict/SKILL.md. Review the rendered diagnostic screen against the legacy layout reference.`

**Availability:** Requires screenshots, a running app, or design references.

#### `web-clone` - Web Clone
**Purpose:** Recreate a referenced web UI or interaction pattern in a local implementation.

**Use when:** A web page is an explicit design reference for a Flutter screen.

**Example:** `Read .gemini/skills/web-clone/SKILL.md. Recreate the selected dashboard interaction in native Flutter; do not add Web support.`

**Availability:** May require browser inspection or web-access tooling.

#### `widgetbook-design-system` - Widgetbook Design System
**Purpose:** Build, catalog, and validate a component system through Widgetbook.

**Use when:** The Flutter component library has reached the point where isolated component review is useful.

**Example:** `Read .gemini/skills/widgetbook-design-system/SKILL.md. Set up Widgetbook stories for the shared diagnostic controls.`

**Availability:** Requires Widgetbook dependencies and configuration.

#### `worker` - Worker
**Purpose:** Complete one bounded implementation task with clear scope and verification.

**Use when:** A task is small enough not to need broad planning or multi-agent coordination.

**Example:** `Read .gemini/skills/worker/SKILL.md. Add a typed Rust model for a device status response and test it.`

---

## Polski

### Cel

Ten przewodnik opisuje role i skille AI zapisane w `.gemini/`, sposób ich pewnego wywoływania oraz sytuacje, w których warto ich używać w `qi_flutter`.

`AGENTS.md` pozostaje źródłem prawdy dla architektury i ograniczeń projektu. Przeczytaj go przed użyciem dowolnej roli lub skilla.

### Pewne Wywoływanie

Poniższa forma działa przenośnie w GitHub Copilot, Claude Code i Gemini, ponieważ jawnie wskazuje plik:

```text
Read .gemini/rules/architect.md and act as the Architect.
Design the Flutter-to-Rust boundary for device communication. Do not edit files yet.
```

```text
Read .gemini/skills/plan/SKILL.md and follow its workflow where compatible with your available tools.
Plan the Ryodoraku measurement feature.
```

Użyj **rule**, aby ustawić rolę, zakres odpowiedzialności, standard jakości i styl odpowiedzi. Użyj **skilla**, aby zastosować workflow dla rodzaju zadania. Można je łączyć:

```text
Use .gemini/skills/plan/SKILL.md. First apply the Analyst role from
.gemini/rules/analyst.md, then create an implementation plan.
```

### Obsługa Przez Narzędzia

- **Gemini:** Zależnie od użytego runnera wpisy w `.gemini/skills/` i `.gemini/rules/` mogą być wykrywane automatycznie. Dla istotnej pracy nadal zalecane jest jawne wskazanie pliku. Nie zakładaj, że każdy runner rejestruje `/nazwa-skilla` jako slash command.
- **GitHub Copilot:** Odczytuje `.github/copilot-instructions.md` oraz `AGENTS.md`, ale nie rejestruje automatycznie plików `.gemini` jako skilli lub agentów Copilota. Użyj powyższej formy przenośnej albo później dostosuj wybrane workflow do `.github/skills/` i `.github/agents/`.
- **Claude Code:** Odczytuje `CLAUDE.md`, ale nie rejestruje automatycznie plików `.gemini` jako skilli lub agentów Claude. Użyj powyższej formy przenośnej albo później dostosuj wybrane workflow do `.claude/skills/` i `.claude/agents/`.
- Część workflow odwołuje się do **OMX**, `ask_codex`, `ask_gemini`, `ask_claude`, automatyzacji przeglądarki, Penpot, Widgetbook albo lokalnych CLI. Traktuj te kroki jako opcjonalne, dopóki wymagane narzędzie nie jest faktycznie zainstalowane i dostępne.

### Role

#### `analyst` - Analityk
**Cel:** Zamienia wymaganie w testowalne kryteria, wskazuje brakujące decyzje, założenia, granice i przypadki brzegowe przed planowaniem.

**Kiedy użyć:** Gdy wymaganie jest nieprecyzyjne, krytyczne dla bezpieczeństwa lub może ukrywać szczegóły workflow.

**Przykład:** `Read .gemini/rules/analyst.md. Analyze requirements for recording a Ryodoraku measurement session before implementation.`

#### `architect` - Architekt
**Cel:** Definiuje granice modułów, interfejsy, kompromisy i tryby awarii.

**Kiedy użyć:** Przy dodawaniu podsystemu Rust, zmianie kontraktów FFI albo architektury Flutter/Rust.

**Przykład:** `Read .gemini/rules/architect.md. Design the serial-device session boundary between qi_core and Flutter.`

#### `build-fixer` - Naprawiacz Builda
**Cel:** Diagnozuje i naprawia błędy kompilacji, linkowania, zależności oraz native toolchain najmniejszą bezpieczną zmianą.

**Kiedy użyć:** Gdy nie działa `cargo build`, `flutter run`, Android Gradle, CMake albo linkowanie FFI.

**Przykład:** `Read .gemini/rules/build-fixer.md. Fix the Linux Flutter build failure caused by the Rust bridge.`

#### `code-reviewer` - Recenzent Kodu
**Cel:** Recenzuje diff pod kątem poprawności, regresji, utrzymywalności, stylu i brakujących testów.

**Kiedy użyć:** Przed commitem, mergem albo akceptacją nietrywialnej zmiany.

**Przykład:** `Read .gemini/rules/code-reviewer.md. Review the staged Rust parser changes; do not edit files.`

#### `code-simplifier` - Upraszczacz Kodu
**Cel:** Usuwa przypadkową złożoność i duplikację bez zmiany zachowania.

**Kiedy użyć:** Gdy ukończona funkcja jest zbyt pośrednia, powtarzalna lub trudna do czytania.

**Przykład:** `Read .gemini/rules/code-simplifier.md. Simplify the device connection view state without changing behavior.`

#### `critic` - Krytyk
**Cel:** Podważa plany i projekty pod kątem słabych założeń, pominięć i kruchych wyborów.

**Kiedy użyć:** Gdy plan lub decyzja architektoniczna wymaga niezależnego, krytycznego przeglądu.

**Przykład:** `Read .gemini/rules/critic.md. Critique the proposed USB/BLE migration plan before implementation.`

#### `debugger` - Debugger
**Cel:** Odtwarza, izoluje i poprawia błąd wykonania na podstawie logów, trace'ów i warunków awarii.

**Kiedy użyć:** Gdy aplikacja zawiesza się, crashuje, zwraca błędne odczyty lub callback natywny zachowuje się nieoczekiwanie.

**Przykład:** `Read .gemini/rules/debugger.md. Diagnose why the Flutter app stops receiving serial-port readings after reconnecting.`

#### `dependency-expert` - Ekspert Zależności
**Cel:** Ocena zgodności pakietów, ryzyka aktualizacji, wpływu na platformy i dryfu zależności.

**Kiedy użyć:** Przy zmianie wersji Fluttera, Rusta, Androida, iOS, FRB lub bibliotek natywnych.

**Przykład:** `Read .gemini/rules/dependency-expert.md. Evaluate upgrading flutter_rust_bridge and identify compatibility work.`

#### `designer` - Projektant
**Cel:** Definiuje użyteczne i spójne przepływy UI, komponenty, stany oraz hierarchię wizualną.

**Kiedy użyć:** Przy odtwarzaniu ekranu Lazarusa, budowaniu workflow diagnostycznego albo definiowaniu stanów wizualnych.

**Przykład:** `Read .gemini/rules/designer.md. Design the Flutter layout that replaces the legacy main diagnostic window.`

#### `executor` - Wykonawca
**Cel:** Implementuje zaakceptowane, ograniczone zadanie i waliduje wynik.

**Kiedy użyć:** Gdy wymagania i plan implementacji są już jasne.

**Przykład:** `Read .gemini/rules/executor.md. Implement the approved device-connection status panel and run relevant checks.`

#### `explore` - Eksplorator
**Cel:** Bada repozytorium i raportuje istniejące wzorce, odpowiedzialności oraz prawdopodobne miejsca zmian bez edycji kodu.

**Kiedy użyć:** Przy rozpoczynaniu nieznanej pracy lub szukaniu funkcjonalności legacy przed migracją.

**Przykład:** `Read .gemini/rules/explore.md. Find how the Lazarus application sends the calib command and summarize the protocol.`

#### `git-master` - Ekspert Git
**Cel:** Przygotowuje czyste commity, bezpieczne operacje na branchach i historię łatwą do review.

**Kiedy użyć:** Przy dzieleniu staged changes, przygotowaniu PR, rozwiązywaniu nietrywialnego stanu Git albo release.

**Przykład:** `Read .gemini/rules/git-master.md. Split the staged architecture changes into logical commits without losing work.`

#### `planner` - Planista
**Cel:** Dzieli złożoną pracę na uporządkowane kroki implementacji, zależności, kryteria akceptacji i bramki walidacji.

**Kiedy użyć:** Gdy zadanie obejmuje wiele plików, warstw lub milestone'ów.

**Przykład:** `Read .gemini/rules/planner.md. Plan the first vertical slice for live serial-device readings in Flutter.`

#### `researcher` - Badacz
**Cel:** Zbiera dowody i porównuje alternatywy techniczne przed wyborem podejścia.

**Kiedy użyć:** Gdy nie ma pewności co do biblioteki, platformy, protokołu albo rozwiązania projektowego.

**Przykład:** `Read .gemini/rules/researcher.md. Compare serialport, native USB, and BLE options for the next hardware layer.`

#### `security-reviewer` - Recenzent Bezpieczeństwa
**Cel:** Analizuje sekrety, przepływy danych, niebezpieczne granice, zależności i obsługę wejścia pod kątem luk bezpieczeństwa.

**Kiedy użyć:** Przy dodawaniu sieci, poświadczeń, persystencji, importów, aktualizacji albo danych z urządzenia zewnętrznego.

**Przykład:** `Read .gemini/rules/security-reviewer.md. Review the planned REST client and local patient-history storage.`

#### `team-executor` - Koordynator Zespołu
**Cel:** Koordynuje pracę równoległą, granice odpowiedzialności, przekazania i punkty integracji.

**Kiedy użyć:** Gdy zmiana rzeczywiście wymaga kilku agentów albo współpracowników pracujących równolegle.

**Przykład:** `Read .gemini/rules/team-executor.md. Divide the device-session feature between Rust protocol work and Flutter UI work.`

#### `test-engineer` - Inżynier Testów
**Cel:** Definiuje pokrycie testami, przypadki brzegowe, dane testowe i strategię walidacji.

**Kiedy użyć:** Przy dodawaniu parserów, obliczeń, zachowania krytycznego dla bezpieczeństwa, maszyn stanów albo diagnostycznych przepływów użytkownika.

**Przykład:** `Read .gemini/rules/test-engineer.md. Design tests for the serial response parser and its malformed-input behavior.`

#### `verifier` - Weryfikator
**Cel:** Sprawdza ukończoną implementację względem kryteriów akceptacji i regresji.

**Kiedy użyć:** Przed uznaniem zadania za ukończone, mergem funkcji albo wydaniem builda.

**Przykład:** `Read .gemini/rules/verifier.md. Verify the device reconnect flow against the approved requirements.`

#### `vision` - Wizja Produktowa
**Cel:** Ocenia, czy funkcja i kierunek UX nadal wspierają zamierzony rezultat produktu.

**Kiedy użyć:** Gdy zakres się rozszerza albo rozwiązanie techniczne może pogorszyć doświadczenie panelu klinicznego.

**Przykład:** `Read .gemini/rules/vision.md. Assess whether the proposed dashboard supports fast, low-error practitioner workflows.`

#### `writer` - Autor Dokumentacji
**Cel:** Tworzy zrozumiałą dokumentację, wyjaśnienia techniczne, zapisy decyzji i release notes.

**Kiedy użyć:** Przy aktualizowaniu README, dokumentowaniu protokołu albo rejestrowaniu decyzji architektonicznej.

**Przykład:** `Read .gemini/rules/writer.md. Document the Rust serial-session lifecycle for contributors.`

### Skille

#### `ai-slop-cleaner` - Czyszczenie AI Slop
**Cel:** Usuwa ogólnikowy, powtarzalny, zbędny albo mylący kod i tekst wygenerowany przez AI.

**Kiedy użyć:** Gdy wygenerowany patch lub dokument jest rozwlekły albo zawiera stare treści z template'u.

**Przykład:** `Read .gemini/skills/ai-slop-cleaner/SKILL.md. Clean generated comments from app/flutter/lib without changing behavior.`

#### `ask-claude` - Zapytaj Claude
**Cel:** Prosi lokalnie zainstalowane Claude CLI o niezależną opinię i zapisuje ją jako artefakt.

**Kiedy użyć:** Gdy trudna decyzja skorzysta na opinii drugiego modelu.

**Przykład:** `Read .gemini/skills/ask-claude/SKILL.md. Ask Claude to critique the proposed Rust device-state model.`

**Dostępność:** Wymaga lokalnego `claude` CLI albo zgodnej integracji OMX.

#### `ask-gemini` - Zapytaj Gemini
**Cel:** Prosi integrację Gemini o niezależną odpowiedź i zapisuje lub wykorzystuje wynik.

**Kiedy użyć:** Gdy podczas pracy w innym narzędziu potrzebujesz drugiej opinii.

**Przykład:** `Read .gemini/skills/ask-gemini/SKILL.md. Ask Gemini for alternative error-recovery strategies for a serial disconnect.`

**Dostępność:** Wymaga integracji Gemini albo skonfigurowanej komendy zewnętrznej.

#### `autopilot` - Autopilot
**Cel:** Przeprowadza jasne zadanie przez badanie, implementację i walidację z ograniczoną liczbą przerw dla użytkownika.

**Kiedy użyć:** Gdy oczekiwany rezultat jest jasny, a zadanie można bezpiecznie wykonać end-to-end.

**Przykład:** `Read .gemini/skills/autopilot/SKILL.md. Implement the approved mock Ryodoraku chart vertical slice and validate it.`

#### `cancel` - Anuluj
**Cel:** Kontrolowanie zatrzymuje aktywny workflow albo długo działającą operację.

**Kiedy użyć:** Gdy zadanie nie jest już potrzebne, kierunek się zmienił albo trzeba zatrzymać proces w tle.

**Przykład:** `Read .gemini/skills/cancel/SKILL.md. Cancel the current broad migration workflow and preserve its findings.`

#### `code-review` - Przegląd Kodu
**Cel:** Wykonuje uporządkowany review diffu z wynikami uporządkowanymi według wpływu.

**Kiedy użyć:** Przed mergem, po dużym patchu albo przed zaakceptowaniem zmian wygenerowanych przez AI.

**Przykład:** `Read .gemini/skills/code-review/SKILL.md. Review the current staged changes; do not edit files.`

#### `configure-notifications` - Konfiguracja Powiadomień
**Cel:** Konfiguruje powiadomienia workflow i raportowanie statusu.

**Kiedy użyć:** Gdy dostępne środowisko wspiera powiadomienia o zadaniach, CI lub współpracy i chcesz je skonfigurować.

**Przykład:** `Read .gemini/skills/configure-notifications/SKILL.md. Configure build-failure notifications for the project if supported.`

**Dostępność:** Wymaga zgodnego narzędzia powiadomień w aktywnym środowisku.

#### `deep-interview` - Pogłębiony Wywiad
**Cel:** Wydobywa ukryte wymagania i decyzje przez uporządkowane, sekwencyjne pytania.

**Kiedy użyć:** Gdy zachowanie produktu, ograniczenia bezpieczeństwa albo workflow użytkownika są niedoprecyzowane.

**Przykład:** `Read .gemini/skills/deep-interview/SKILL.md. Interview me to define the patient-session save workflow.`

#### `design-system` - System Projektowy
**Cel:** Definiuje lub stosuje wielokrotnie używane tokeny motywu Flutter, komponenty i zasady wizualne.

**Kiedy użyć:** Przy tworzeniu początkowego systemu wizualnego albo ujednolicaniu ekranów.

**Przykład:** `Read .gemini/skills/design-system/SKILL.md. Define Flutter theme tokens and core controls for the diagnostic application.`

#### `doctor` - Diagnostyka Środowiska
**Cel:** Diagnozuje zdrowie projektu i środowiska, a następnie sugeruje lub stosuje skupione naprawy konfiguracji.

**Kiedy użyć:** Gdy brakuje albo są źle skonfigurowane Flutter, Rust, FRB, Android SDK/NDK lub zależności desktopowe.

**Przykład:** `Read .gemini/skills/doctor/SKILL.md. Diagnose why the Android build cannot locate the Rust toolchain.`

**Dostępność:** Wymaga odpowiednich lokalnych CLI, np. `flutter`, `cargo`, `rustc` i narzędzi platformy.

#### `help` - Pomoc
**Cel:** Wyjaśnia dostępne workflow i rekomenduje następne działanie dla zadania.

**Kiedy użyć:** Gdy nie wiesz, która rola lub skill pasuje do zadania.

**Przykład:** `Read .gemini/skills/help/SKILL.md. Recommend the right workflow for migrating one legacy Pascal dialog to Flutter.`

#### `hud` - HUD
**Cel:** Pokazuje zwięzły status workflow, aktywne zadania i informacje o postępie.

**Kiedy użyć:** Gdy obsługiwany runner udostępnia status interfejs, a praca ma kilka aktywnych etapów.

**Przykład:** `Read .gemini/skills/hud/SKILL.md. Show the current implementation and validation status for this migration task.`

**Dostępność:** Zależy od narzędzi statusu specyficznych dla runnera.

#### `note` - Notatka
**Cel:** Zapisuje decyzję albo ważny kontekst jako notatkę projektową.

**Kiedy użyć:** Gdy trzeba zapisać fakt o protokole, decyzję architektoniczną albo nierozwiązane ryzyko na przyszłość.

**Przykład:** `Read .gemini/skills/note/SKILL.md. Record that Web and WebSocket architectures are explicitly out of scope.`

**Dostępność:** Miejsce zapisu zależy od aktywnego runnera; potwierdź je przed poleganiem na trwałej pamięci.

#### `omx-setup` - Konfiguracja OMX
**Cel:** Konfiguruje albo diagnozuje workflow OMX używany przez te zasoby AI.

**Kiedy użyć:** Gdy celowo używasz OMX i potrzebujesz jego konfiguracji, nie do zwykłego developmentu Flutter/Rust.

**Przykład:** `Read .gemini/skills/omx-setup/SKILL.md. Check whether this workspace has the prerequisites for OMX workflows.`

**Dostępność:** Wymaga narzędzi specyficznych dla OMX.

#### `penpot-design-system` - System Projektowy Penpot
**Cel:** Tłumaczy system projektowy Penpot na implementowalne tokeny UI i komponenty.

**Kiedy użyć:** Gdy źródłowy projekt interfejsu jest utrzymywany w Penpot.

**Przykład:** `Read .gemini/skills/penpot-design-system/SKILL.md. Map the Penpot controls to Flutter theme extensions and widgets.`

**Dostępność:** Wymaga zasobów Penpot albo integracji.

#### `plan` - Plan
**Cel:** Tworzy ugruntowany plan implementacji z wymaganiami, krokami, ryzykami i walidacją.

**Kiedy użyć:** Gdy praca jest szeroka, niejednoznaczna, wielowarstwowa albo kosztowna do odwrócenia.

**Przykład:** `Read .gemini/skills/plan/SKILL.md. Plan the migration of the legacy serial communication protocol into qi_core.`

#### `ralph` - Ralph
**Cel:** Wykonuje zaakceptowany plan przez uporządkowany, konsekwentny workflow dostarczania.

**Kiedy użyć:** Gdy plan już istnieje i chcesz workflow skoncentrowany na wykonaniu z punktami kontrolnymi.

**Przykład:** `Read .gemini/skills/ralph/SKILL.md. Execute the approved plan for mock diagnostic readings.`

**Dostępność:** Część etapów może wymagać agentów albo komend specyficznych dla OMX.

#### `ralplan` - Plan Ralph
**Cel:** Buduje albo udoskonala plan z użyciem workflow planowania Ralph.

**Kiedy użyć:** Gdy istotne zadanie potrzebuje przemyślanego planu przed użyciem `ralph` do wykonania.

**Przykład:** `Read .gemini/skills/ralplan/SKILL.md. Create a Ralph-ready plan for the device connection lifecycle.`

**Dostępność:** Część etapów może wymagać agentów albo komend specyficznych dla OMX.

#### `security-review` - Przegląd Bezpieczeństwa
**Cel:** Wykonuje uporządkowany przegląd bezpieczeństwa kodu, zależności, danych i zewnętrznych granic.

**Kiedy użyć:** Przed obsługą danych pacjenta, ruchu sieciowego, poświadczeń, aktualizacji albo niezaufanego wejścia z urządzenia.

**Przykład:** `Read .gemini/skills/security-review/SKILL.md. Review the data storage design before patient profiles are implemented.`

#### `skill` - Tworzenie Skilla
**Cel:** Tworzy lub ulepsza wielokrotnie używany skill projektowy.

**Kiedy użyć:** Gdy powtarzalny workflow potrzebuje udokumentowanej, wywoływalnej procedury.

**Przykład:** `Read .gemini/skills/skill/SKILL.md. Create a skill for validating the serial protocol parser.`

#### `team` - Zespół
**Cel:** Koordynuje kilku agentów lub współpracowników wokół wspólnego planu, ról i ścieżki weryfikacji.

**Kiedy użyć:** Gdy pracę można bezpiecznie zrównoleglić między niezależnymi obszarami.

**Przykład:** `Read .gemini/skills/team/SKILL.md. Coordinate parallel Rust protocol analysis and Flutter screen reconstruction.`

**Dostępność:** Może wymagać wsparcia multi-agent albo OMX specyficznego dla runnera.

#### `trace` - Śledzenie
**Cel:** Śledzi wykonanie przez logi, callbacki i warstwy w celu znalezienia rzeczywistej przyczyny problemu.

**Kiedy użyć:** Gdy błąd przechodzi przez granice Flutter, FFI, Rust i sprzęt.

**Przykład:** `Read .gemini/skills/trace/SKILL.md. Trace a measurement request from the Flutter button to the serial response.`

**Dostępność:** Korzysta z lokalnych logów, tracingu, `adb logcat` albo podobnej diagnostyki.

#### `ultrawork` - UltraWork
**Cel:** Uruchamia zdyscyplinowany workflow szybkiej implementacji z ciągłą weryfikacją.

**Kiedy użyć:** Gdy dobrze ograniczone, lecz istotne zadanie wymaga szybkiego dostarczenia end-to-end.

**Przykład:** `Read .gemini/skills/ultrawork/SKILL.md. Deliver the approved mock chart feature with tests and validation.`

**Dostępność:** Może wymagać wsparcia orkiestracji specyficznego dla runnera.

#### `visual-verdict` - Ocena Wizualna
**Cel:** Porównuje wyrenderowane UI z projektem albo referencją i daje konkretny werdykt visual QA.

**Kiedy użyć:** Przy odtwarzaniu dialogu legacy, kontroli layoutu responsywnego albo przeglądzie dopracowania UI.

**Przykład:** `Read .gemini/skills/visual-verdict/SKILL.md. Review the rendered diagnostic screen against the legacy layout reference.`

**Dostępność:** Wymaga screenshotów, działającej aplikacji albo referencji projektowej.

#### `web-clone` - Klonowanie Web
**Cel:** Odtwarza wskazany interfejs webowy lub wzorzec interakcji w lokalnej implementacji.

**Kiedy użyć:** Gdy strona webowa jest jawną referencją designu dla ekranu Flutter.

**Przykład:** `Read .gemini/skills/web-clone/SKILL.md. Recreate the selected dashboard interaction in native Flutter; do not add Web support.`

**Dostępność:** Może wymagać inspekcji przeglądarki albo narzędzi dostępu do Web.

#### `widgetbook-design-system` - System Projektowy Widgetbook
**Cel:** Buduje, kataloguje i waliduje system komponentów przez Widgetbook.

**Kiedy użyć:** Gdy biblioteka komponentów Flutter jest na etapie, w którym przydatny jest izolowany przegląd komponentów.

**Przykład:** `Read .gemini/skills/widgetbook-design-system/SKILL.md. Set up Widgetbook stories for the shared diagnostic controls.`

**Dostępność:** Wymaga zależności i konfiguracji Widgetbook.

#### `worker` - Wykonawca Zadania
**Cel:** Wykonuje jedno ograniczone zadanie implementacyjne z jasnym zakresem i weryfikacją.

**Kiedy użyć:** Gdy zadanie jest na tyle małe, że nie wymaga szerokiego planowania ani koordynacji wielu agentów.

**Przykład:** `Read .gemini/skills/worker/SKILL.md. Add a typed Rust model for a device status response and test it.`
