# 0002. Indexdata från Yahoo Finance

- **Status:** Accepterad
- **Datum:** 2026-11-07

## Sammanhang

Startvyn visar OMXS30:s utveckling sedan årsskiftet. Vi behöver dagliga stängningskurser från årets början,
senaste värde och föregående års sista stängning (baslinje för utveckling i år), helst utan API-nyckel.

## Beslut

Vi använder Yahoo Finance chart-endpoint:

```
https://query1.finance.yahoo.com/v8/finance/chart/%5EOMX?range=ytd&interval=1d
```

- Symbol: `^OMX` (= OMXS30).
- Baslinje: `meta.chartPreviousClose` (föregående års sista stängning).
- Senaste värde: `meta.regularMarketPrice`, tid: `meta.regularMarketTime`.
- Data hämtas när vyn visas och sedan var 5:e minut. Misslyckas en uppdatering ligger gammal data kvar.
- Allt ligger bakom protokollet `IndexHistoryProviding`, implementerat av `YahooFinanceService`.

## Alternativ som övervägdes

- *Nasdaq Nordic API:* officiell källa men odokumenterat och ändras ofta.
- *Betal-API:er (t.ex. EOD Historical Data, Twelve Data):* stabila men kräver nyckel och kostar pengar.

## Konsekvenser

- Endpointen är **inofficiell**: den kan ändras eller blockeras utan förvarning. Klienter utan User-Agent får
  HTTP 429. URLSessions standardvärde fungerar.
- Kurserna kan vara fördröjda (~15 min) och är inte avsedda för handel.
- Vid publicering i App Store bör villkoren ses över. Byte av källa påverkar bara `YahooFinanceService`.
