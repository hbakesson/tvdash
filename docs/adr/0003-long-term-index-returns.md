# 0003. Långsiktig avkastning per region

- **Status:** Accepterad
- **Datum:** 2026-11-07

## Sammanhang

Appen ska visa 1, 3, 5 och 10 års utveckling samt årlig takt över 10 år för 11 index, grupperade per region,
med ett snitt per region. En region visas per skärm.

## Beslut

- **Data:** Yahoo Finance chart-endpoint (se [ADR 0002](0002-index-data-from-yahoo-finance.md)) med
  `interval=1d` och `period1` = 10 år + 14 dagar bakåt. Daglig data gör att startkursen hamnar på rätt dag.
- **Avkastning:** prisutveckling utan utdelningar: `senaste / stängning N år sedan − 1`. Startkursen är sista
  stängningen **på eller före** samma kalenderdatum N år före senaste notering.
- **Per år, 10 år:** `(1 + avkastning10)^(1/10) − 1`.
- **Snitt:** aritmetiskt medelvärde per kolumn av de index som har data. Visas bara för regioner med fler än
  ett index. Per år-snittet är medel av radernas årstakt, inte årstakten av snittet.
- **Index utan direkt notering** följs via ETF: MSCI ACWI (`ACWI`), MSCI World (`URTH`), MSCI EM (`EEM`),
  Norden (`XACT-NORDEN.ST`). ETF-kursen exkluderar utdelningar, precis som indexen.
- **Navigering:** `TabView`, en flik per region efter OMXS30-fliken. Vald flik sparas i `@AppStorage`.
- **Uppdatering:** var 15:e minut; alla index hämtas parallellt. Ett index som inte går att hämta visas som "–"
  och räknas inte med i snittet.

## Konsekvenser

- Varje uppdatering hämtar ~11 × 2 500 dagliga punkter. JSON-avkodningen sker utanför main actor.
- Siffrorna skiljer sig från källor som räknar totalavkastning (med återinvesterad utdelning). För ETF:er kan
  skillnaden över 10 år vara stor (t.ex. ACWI ca +169 % pris mot +223 % totalt).
- Nya index eller regioner läggs till i `MarketRegion.all` (`TVDash/Core/Models/MarketCatalog.swift`).
