# Changelog

Alla märkbara ändringar dokumenteras här.

Formatet följer [Keep a Changelog](https://keepachangelog.com/sv/1.1.0/) och projektet använder
[Semantic Versioning](https://semver.org/lang/sv/).

## [Unreleased]

### Added

- Systemdashboard för Apple TV med flikar per kategori: Översikt, Minne, Lagring, Processor, Nätverk och System.
  Data uppdateras varannan sekund.
- Minne: använt och tillgängligt RAM, fördelning per typ, diagram över de senaste två minuterna och appens eget
  minnesavtryck och minnesgräns.
- Lagring: totalt, använt och ledigt diskutrymme samt appens egen storlek uppdelad på app, dokument, cache m.m.
- Processor: belastning totalt (användare/system) och per kärna, historik, samt CPU, trådar och minne för appens
  egen process.
- Nätverk: anslutningstyp (Ethernet/Wi-Fi), router, IPv4/IPv6-adresser, aktuell nedladdnings- och
  uppladdningshastighet och trafik sedan omstart.
- Hastighetstest (nedladdning, uppladdning, svarstid) mot speed.cloudflare.com, startas med en knapp.
- System: modell, tvOS-version och build, Darwin-kärna, drifttid, senaste omstart, temperaturstatus, språk,
  region och tidszon.
- Svensk lokalisering.
- Ny app-ikon i fyra parallax-lager (mätare, staplar per kärna och nätverkspuls) samt nya Top Shelf-bilder.
  Genereras av `scripts/generate-icons.swift`.

### Changed

- Appen heter nu "Driftstats" på hemskärmen (tidigare "Index").

### Removed

- Indexdashboarden (OMXS30, regioner och indexdiagram) och hämtningen från Yahoo Finance.
- Exempel-dashboarden med låtsasdata.

## [0.1.0] - 2026-11-07

### Added

- Projektgrund: tvOS-app i SwiftUI med Swift 6 och Swift Testing.
- Dashboard-skärm med fokuserbara kort och exempeldata.
- Dokumentation: arkitektur, kodriktlinjer, tvOS-design, testning, release och ADR.
