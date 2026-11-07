# Kodriktlinjer

Utgångspunkt: [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).
Formatering sköts av `swift-format` (konfig i `.swift-format`) – diskutera inte stil som verktyget avgör.

## Språk

- Kod, identifierare, kodkommentarer och commit-meddelanden: **engelska**.
- Dokumentation i `docs/`: svenska.
- Användarsynlig text: skrivs på engelska i koden och översätts i String Catalog.

## Namngivning och filer

- En huvudtyp per fil; filnamnet = typnamnet (`DashboardModel.swift`).
- Vyer slutar på `View`, skärmmodeller på `Model`, tjänster på `Service`, protokoll beskriver förmåga
  (`WeatherProviding`).
- Booleans läses som påståenden: `isLoading`, `hasError`.

## Swift

- Föredra `struct` och `enum`; `final class` endast för identitet/referenssemantik (t.ex. `@Observable`-modeller).
- `let` före `var`. Minsta möjliga åtkomstnivå (`private` som standard).
- Inga force unwraps (`!`) eller `try!` i produktionskod. I tester: `try #require(...)`.
- Hantera fel med `throws` och typade fel där det ger värde; visa begripliga felmeddelanden i UI.
- Inga `print` i committad kod – använd `Logger` (OSLog) med subsystem `com.hbakesson.tvdash`.

```swift
import OSLog
private let logger = Logger(subsystem: "com.hbakesson.tvdash", category: "Dashboard")
```

## SwiftUI

- Bryt ut undervyer när en `body` blir längre än ~40 rader eller upprepas.
- `@State` för state vyn äger; `@Bindable` för att binda till en `@Observable`-modell; `@Environment` för delade
  beroenden. Inte `ObservableObject`, `@Published`, `@StateObject` i ny kod.
- Varje vy med intressanta tillstånd har en `#Preview` (gärna flera: tomt, laddar, fel).
- Använd systemets typsnittsstilar (`.title`, `.headline`) så Dynamic Type och tvOS-skalning fungerar.
- Färger och bilder via asset catalog (genererade symboler: `Color.accent`, `Image(.logo)`).

## Concurrency

Se [ARCHITECTURE.md](ARCHITECTURE.md#concurrency). Kort: main actor som standard, `Sendable`-modeller,
strukturerad concurrency (`async let`, `TaskGroup`, `.task`) framför fristående `Task { }`.

## Dokumentationskommentarer

`///` på typer och icke-uppenbara funktioner. Förklara *varför*, inte *vad* koden redan säger.
