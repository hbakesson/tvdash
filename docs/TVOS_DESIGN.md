# tvOS-design

Apple TV används på 3 meters avstånd med en fjärrkontroll. Det ändrar nästan allt jämfört med iOS.
Referens: [Human Interface Guidelines – tvOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-tvos).

## Fokus är allt

- Det finns ingen pekare eller touch. Användaren flyttar **fokus** mellan element med Siri Remote.
- Allt interaktivt ska vara en `Button`, `NavigationLink` eller ha `.focusable()`.
- Fokuserat element måste synas tydligt. Använd systemets stilar: `.buttonStyle(.card)`, `.buttonStyle(.bordered)`,
  `.buttonStyle(.plain)` + `.hoverEffect(.highlight)`.
- Lägg element i raka rader/kolumner så fokusmotorn kan gissa rätt riktning. Styr vid behov med
  `.focusSection()`, `@FocusState` och `.defaultFocus(_:_:)`.
- Återställ fokus logiskt när användaren går tillbaka från en detaljvy.

## Siri Remote

| Knapp | Förväntat beteende |
|---|---|
| Klickyta / Select | Aktivera fokuserat element |
| Menu / Back | Gå tillbaka ett steg; på rotskärmen → till hemskärmen (blockera inte) |
| Play/Pause | Spela/pausa media; `.onPlayPauseCommand { }` |
| TV/Hem | Hanteras av systemet |

Använd `.onExitCommand` endast för att stänga egna overlays – aldrig för att fånga användaren i appen.

## Layout

- Skärm: 1920×1080 punkter. Respektera **safe area** (ca 60 pt upptill/nertill, 80 pt på sidorna) – lägg inte
  innehåll utanför.
- Stora klickytor och generöst avstånd (≥ 40 pt mellan fokuserbara element) – fokuseffekten förstorar elementet.
- Minsta brödtext ~29 pt; använd systemstilar (`.body`, `.headline`, `.title`) i stället för fasta storlekar.
- Mindre text än på iOS: en skärm ska gå att förstå på ett ögonkast.
- Stöd både ljust och mörkt läge (de flesta kör mörkt).

## App-ikon och Top Shelf

Ikonen är en **layered image** (parallax) med 2–5 lager i `Assets.xcassets/App Icon & Top Shelf Image`.

| Bild | Storlek (1x / 2x) |
|---|---|
| App Icon (hemskärm) | 400×240 / 800×480, lager: Front, Middle, Back |
| App Icon – App Store | 1280×768 |
| Top Shelf Image | 1920×720 / 3840×1440 |
| Top Shelf Image Wide | 2320×720 / 4640×1440 |

Bakgrundslagret ska vara opakt; övriga lager får ha transparens. Förhandsgranska parallax i Xcode.

Ikonen och Top Shelf-bilderna genereras med kod. Ändra `scripts/generate-icons.swift` och kör:

```sh
swift scripts/generate-icons.swift "TVDash/Resources/Assets.xcassets/App Icon & Top Shelf Image.brandassets"
```

## Tillgänglighet

- `accessibilityLabel` på ikoner och bilder utan text; slå ihop kort med `.accessibilityElement(children: .combine)`.
- Testa med VoiceOver (*Settings → Accessibility* i simulatorn) och med *Reduce Motion* påslaget.
- Förmedla aldrig information enbart med färg.

## Media (om appen spelar upp video/ljud)

Använd `AVPlayerViewController` / `VideoPlayer` – systemspelaren ger rätt fjärrkontrollbeteende, undertexter och
Now Playing gratis.
