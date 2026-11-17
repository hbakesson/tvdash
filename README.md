# TVDash

**Driftstats** – en dashboard-app för Apple TV, byggd med SwiftUI, som visar Apple TV:ns egna systemdata – kategoriserat i
flikar:

- **Översikt:** en ruta per kategori med nyckeltal och minidiagram. Välj en ruta för att öppna kategorin.
- **Minne:** använt/tillgängligt RAM, fördelning (låst, aktivt, komprimerat, inaktivt, fritt), historik och appens
  eget minne.
- **Lagring:** ledigt och använt diskutrymme samt hur mycket appen själv tar.
- **Processor:** belastning totalt och per kärna, historik och den egna processen.
- **Nätverk:** anslutningstyp, router, IP-adresser, trafik just nu och sedan omstart, samt hastighetstest.
- **System:** modell, tvOS-version och build, Darwin-kärna, drifttid, senaste omstart, temperatur, språk och region.

Data uppdateras varannan sekund. tvOS låter inte appar lista andra processer eller installerade appar – se
[ADR 0004](docs/adr/0004-system-metrics-on-tvos.md). Hastighetstestet körs mot Cloudflare, se
[ADR 0005](docs/adr/0005-speed-test-via-cloudflare.md).

> **Status:** tidig grund (v0.1.0). Se [CHANGELOG.md](CHANGELOG.md).

## Krav

| Verktyg | Version |
|---|---|
| Xcode | 27.0 eller senare |
| tvOS deployment target | 26.0 |
| Swift | 6 (språkläge) |

Inga externa beroenden eller verktyg behöver installeras – `swift-format` följer med Xcode.

## Kom igång

```sh
open TVDash.xcodeproj
```

Välj schemat **TVDash** och destinationen **Apple TV 4K (4th generation)**, tryck sedan `⌘R`.

Navigera i simulatorn med piltangenterna, `Enter` = välj, `Esc` = Menu/tillbaka.
Visa Siri Remote-fönstret via *I/O → Show Apple TV Remote* (`⇧⌘R`).

## Vanliga kommandon

```sh
# Bygg
xcodebuild build -project TVDash.xcodeproj -scheme TVDash \
  -destination 'platform=tvOS Simulator,name=Apple TV 4K (4th generation)'

# Testa
xcodebuild test -project TVDash.xcodeproj -scheme TVDash \
  -destination 'platform=tvOS Simulator,name=Apple TV 4K (4th generation)'

# Formatera / linta
xcrun swift-format format -i -r TVDash TVDashTests
xcrun swift-format lint -r TVDash TVDashTests
```

## Projektstruktur

```
tvdash/
├── TVDash.xcodeproj/        Xcode-projekt (mappar synkas automatiskt)
├── TVDash/                  App-target
│   ├── App/                 Entry point och app-nivå-konfiguration
│   ├── Features/            En mapp per skärm/funktion (vy + modell)
│   ├── Core/                Delad kod: modeller, tjänster, hjälpare
│   └── Resources/           Assets, string catalogs
├── TVDashTests/             Enhetstester (Swift Testing)
└── docs/                    Arkitektur, riktlinjer, beslut (ADR)
```

Nya filer som läggs i `TVDash/` eller `TVDashTests/` kommer automatiskt med i rätt target – inget behov av att
lägga till dem manuellt i Xcode.

## Dokumentation

- [Arkitektur](docs/ARCHITECTURE.md) – hur appen är uppbyggd
- [Kodriktlinjer](docs/CODING_GUIDELINES.md) – stil, namngivning, concurrency
- [tvOS-design](docs/TVOS_DESIGN.md) – fokus, Siri Remote, 10-foot UI
- [Testning](docs/TESTING.md) – hur och vad vi testar
- [Release](docs/RELEASE.md) – versionering, TestFlight, App Store
- [Arkitekturbeslut (ADR)](docs/adr/README.md)
- [Bidra](CONTRIBUTING.md) – branchar, commits, PR-checklista
