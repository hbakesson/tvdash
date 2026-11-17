# 0005. Hastighetstest mot Cloudflare

- **Status:** Accepterad
- **Datum:** 2026-11-18

## Sammanhang

Nätverksskärmen ska visa internethastighet. Byte-räknarna på gränssnitten (ADR 0004) visar bara den trafik som
råkar pågå; för att mäta kapaciteten måste appen själv föra över data mot en server. Vi vill inte ha API-nycklar
eller nya SPM-beroenden.

## Beslut

Hastighetstestet körs bara när användaren trycker på *Testa hastighet* och använder Cloudflares publika
endpoints:

- Svarstid: 5 × `GET https://speed.cloudflare.com/__down?bytes=0`, medianen används.
- Nedladdning: `GET …/__down?bytes=25000000` (25 MB).
- Uppladdning: `POST …/__up` med 10 MB nollor.

Hastigheten räknas som bytes × 8 / (tid − svarstid). Sessionen är `ephemeral` utan cache, med 30 s timeout per
anrop. Implementationen är `CloudflareSpeedTestService` bakom protokollet `SpeedTesting`, och HTTP går via
`HTTPTransport` så att testerna inte gör riktiga nätverksanrop.

## Alternativ som övervägdes

- *Ookla Speedtest:* bästa servertäckningen men kräver licens/SDK.
- *M-Lab NDT7:* öppet, men kräver WebSocket-protokoll och serverlokalisering – mer kod för liknande resultat.
- *Egen server:* full kontroll men kostar drift.

## Konsekvenser

- Ett test för över ~35 MB. Det körs aldrig automatiskt.
- Endpointen är inte formellt dokumenterad som publikt API och kan ändras; byte påverkar bara
  `CloudflareSpeedTestService`.
- Inga personuppgifter skickas, men Cloudflare ser enhetens publika IP-adress, som vid all webbtrafik.
- Ett enda TCP-flöde underskattar mycket snabba anslutningar (> 1 Gbit/s); det räcker för en Apple TV.
