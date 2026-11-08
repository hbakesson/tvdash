# Changelog

Alla märkbara ändringar dokumenteras här.

Formatet följer [Keep a Changelog](https://keepachangelog.com/sv/1.1.0/) och projektet använder
[Semantic Versioning](https://semver.org/lang/sv/).

## [Unreleased]

### Added

- Startvyn visar OMXS30:s utveckling sedan årsskiftet: senaste värde, förändring i punkter och procent,
  samt ett diagram med dagliga stängningskurser. Data uppdateras var 5:e minut.
- Svensk lokalisering.
- En skärm per region (Globalt, Nordamerika, Europa, Norden, Asien och tillväxt) med 1, 3, 5 och 10 års
  prisutveckling, årlig takt över 10 år och snitt per region för 11 index.
- Flikrad för att bläddra mellan OMXS30 och regionerna; senast visade flik sparas.
- Välj tidsperiod för indexdiagrammet: 1 mån, 3 mån, 6 mån, i år, 1 år, 5 år, 10 år eller max. Senast valda
  period sparas och gäller alla index.
- Varje index på regionskärmarna går att välja och öppnar ett eget diagram med tidsperioder.
- Regionskärmarna visar även utveckling för 1 mån, 3 mån, 6 mån och i år, till vänster om års-kolumnerna.
- App-ikon i fyra lager (parallax) med ordet "index" över en stigande graf, samt Top Shelf-bilder.
  Genereras av `scripts/generate-icons.swift`.

### Changed

- Appen heter nu "Index" på Apple TV:ns hemskärm (tidigare "TVDash").

### Removed

- Exempel-dashboarden med låtsasdata.

## [0.1.0] - 2026-11-07

### Added

- Projektgrund: tvOS-app i SwiftUI med Swift 6 och Swift Testing.
- Dashboard-skärm med fokuserbara kort och exempeldata.
- Dokumentation: arkitektur, kodriktlinjer, tvOS-design, testning, release och ADR.
