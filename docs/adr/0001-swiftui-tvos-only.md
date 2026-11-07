# 0001. SwiftUI, endast tvOS, Swift 6

- **Status:** Accepterad
- **Datum:** 2026-11-07

## Sammanhang

Vi bygger en dashboard-app för Apple TV, som kompileras och körs från Xcode. Vi vill ha en modern grund som är
lätt att underhålla och som inte kräver externa verktyg.

## Beslut

- **UI:** SwiftUI med `@Observable`-modeller. UIKit endast via `UIViewRepresentable` där SwiftUI saknar stöd.
- **Plattform:** endast tvOS (target-familj 3). Deployment target **tvOS 26.0** – ett år bakåt från aktuell
  version, vilket täcker nästan alla aktiva Apple TV-enheter.
- **Språk:** Swift 6 språkläge, `@MainActor` som standardisolering, approachable concurrency.
- **Tester:** Swift Testing.
- **Projekt:** Xcode-projekt med folder-synkade grupper, inga projektgeneratorer (XcodeGen/Tuist) och inga
  tredjepartsberoenden från start. `swift-format` (följer med Xcode) för formatering.

## Alternativ som övervägdes

- *Multiplatform-target (iOS/macOS/tvOS):* mer komplexitet och kompromisser i UI; tvOS-UI skiljer sig för mycket.
- *UIKit:* mer kod för samma resultat; SwiftUI:s fokusstöd på tvOS är tillräckligt moget.
- *Senaste tvOS (27) som minimum:* nya API:er utan availability-kontroller, men utesluter enheter som inte
  uppdaterats.

## Konsekvenser

- Nya API:er från tvOS 27 kräver `if #available(tvOS 27, *)`.
- Strikt concurrency ger fler kompileringsfel initialt men färre datarace.
- Vill vi stödja iPhone/iPad senare läggs ett nytt target till och delad kod flyttas till ett lokalt Swift-paket.
