# CLAUDE.md

Instruktioner för AI-assistenter (Claude Code m.fl.) som arbetar i detta repo.

## Projektet

TVDash är en tvOS-app (Apple TV) i SwiftUI. Endast tvOS – inga iOS/macOS-targets.
Läs [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) innan större ändringar.

## Kommandon

```sh
DEST='platform=tvOS Simulator,name=Apple TV 4K (4th generation)'
xcodebuild build -project TVDash.xcodeproj -scheme TVDash -destination "$DEST"
xcodebuild test  -project TVDash.xcodeproj -scheme TVDash -destination "$DEST"
xcrun swift-format lint -r TVDash TVDashTests
```

Kör test + lint innan du säger att en ändring är klar.

## Regler

- **Projektfilen:** `TVDash.xcodeproj/project.xcproj` använder Xcode 27:s textformat och folder-synkade grupper.
  Lägg nya Swift-filer direkt i rätt mapp under `TVDash/` eller `TVDashTests/` – redigera inte projektfilen för
  att lägga till filer. Ändra bara build settings där om det verkligen behövs.
- **Swift 6 strict concurrency** är på, och standardisoleringen är `@MainActor`. Markera bakgrundsarbete
  explicit med `nonisolated` / `@concurrent` och gör modeller `Sendable`.
- **State:** `@Observable`-klasser för skärmlogik, `@State` för ägd state, `@Bindable` för att skicka vidare.
  Använd inte `ObservableObject`/`@Published` i ny kod.
- **Tester:** Swift Testing (`import Testing`, `@Test`, `#expect`), inte XCTest, för nya enhetstester.
- **tvOS-UI:** allt interaktivt måste vara fokuserbart och fungera med Siri Remote. Se
  [docs/TVOS_DESIGN.md](docs/TVOS_DESIGN.md). Inga touch-gester, inga hovers, inga små klickytor.
- **Inga nya beroenden** (SPM-paket) utan att fråga först.
- **Hemligheter** (API-nycklar o.d.) får aldrig hamna i källkod eller git.
- Kod, identifierare och kodkommentarer på engelska. Dokumentation i `docs/` på svenska.
- Uppdatera `CHANGELOG.md` under `[Unreleased]` för användarsynliga ändringar.
- Större arkitekturval → skriv en ADR i `docs/adr/`.
