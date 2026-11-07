# Testning

## Ramverk

- **Enhetstester:** [Swift Testing](https://developer.apple.com/documentation/testing) (`import Testing`) i
  `TVDashTests/`. XCTest används bara om något kräver det (t.ex. prestandamätning).
- **UI-tester:** läggs till som separat target (`TVDashUITests`, XCUITest) när det finns flöden värda att skydda.
  Navigera med `XCUIRemote.shared.press(.down)` osv. – det finns inga tap-gester på tvOS.

## Köra

```sh
xcodebuild test -project TVDash.xcodeproj -scheme TVDash \
  -destination 'platform=tvOS Simulator,name=Apple TV 4K (4th generation)'
```

I Xcode: `⌘U` för alla, eller diamanten bredvid ett test.

## Vad testar vi

| Nivå | Vad | Exempel |
|---|---|---|
| Modeller | Logik i `@Observable`-modeller och värdetyper | val, filtrering, felhantering |
| Tjänster | Avkodning och felvägar, mot fejkad transport | `Codable` mot fixtures i JSON |
| Vyer | Testas via `#Preview` och manuellt i simulatorn | — |

Vyer enhetstestas inte – håll dem tunna så logiken hamnar i testbara modeller.

## Konventioner

- En `@Suite` per typ som testas: `IndexOverviewModelTests.swift`.
- Testnamn beskriver beteende: `failedRefreshKeepsPreviousData()`.
- Arrange / Act / Assert, separerade med tomrad.
- `try #require(...)` i stället för force unwrap.
- Parameteriserade tester (`@Test(arguments:)`) för samma logik med många indata.
- Inga riktiga nätverksanrop i tester – injicera fejk-tjänster via protokoll.
- Tester ska vara deterministiska: injicera klocka/datum/slump om logiken beror på dem.
