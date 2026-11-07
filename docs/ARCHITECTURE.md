# Arkitektur

## Översikt

TVDash är en ren SwiftUI-app för tvOS. Arkitekturen är medvetet enkel: **vy + observerbar modell per feature**,
med delad kod i `Core/`. Vi inför fler lager (t.ex. repositories, moduler) först när ett konkret behov uppstår.

```
┌──────────────┐   läser state / anropar metoder   ┌──────────────────┐
│  SwiftUI View │ ────────────────────────────────▶ │ @Observable Model │
└──────────────┘ ◀──────── observation ──────────── └────────┬─────────┘
                                                             │ async
                                                    ┌────────▼─────────┐
                                                    │ Services (Core/)  │  nätverk, lagring
                                                    └──────────────────┘
```

## Mappar

| Mapp | Innehåll | Regler |
|---|---|---|
| `App/` | `@main`, root-scen, beroendeuppsättning | Ingen affärslogik |
| `Features/<Namn>/` | `<Namn>View.swift`, `<Namn>Model.swift`, ev. undervyer | En feature känner inte till en annan features interna typer |
| `Core/Models/` | Värdetyper (`struct`, `enum`) | `Sendable`, inget UI, ingen I/O |
| `Core/Services/` | Nätverk, persistens, systemintegrationer | Exponeras via `protocol` så de kan mockas i tester |
| `Resources/` | Assets, `Localizable.xcstrings` | |

## Dataflöde

- **Modeller** (`@Observable final class`) äger state för en skärm och exponerar metoder för användarhändelser.
  State som inte ska ändras utifrån är `private(set)`.
- **Vyer** är tunna: layout, fokus, navigation. De tar emot modellen via `@Bindable` eller environment.
- **Tjänster** injiceras i modellernas `init` (constructor injection). Använd protokoll som gräns, så tester kan
  skicka in fejk-implementationer.
- Delade tjänster som många skärmar behöver kan läggas i SwiftUI `Environment` via `@Entry`.

## Concurrency

- Projektet kör **Swift 6 språkläge** med **`@MainActor` som standardisolering** och *approachable concurrency*.
  All kod är alltså main-actor om inget annat sägs – det passar UI-kod.
- Tungt arbete (parsning, bildbehandling) markeras `@concurrent` / `nonisolated` och körs utanför main.
- Typer som skickas mellan isoleringsdomäner måste vara `Sendable`.
- Använd `.task { }` i vyer för asynkront arbete kopplat till vyns livstid – det avbryts automatiskt.

## Navigation

`NavigationStack` i roten. När appen får fler toppnivåsektioner: `TabView` (tvOS visar den som flikrad
överst/sidebar). Navigationstillstånd hålls i modellen om det behöver återställas eller deep-linkas.

## Persistens och nätverk (när det behövs)

- Små inställningar: `@AppStorage`. Observera att tvOS kan rensa lokal cache-lagring – spara inget viktigt
  enbart lokalt. Använd iCloud (`NSUbiquitousKeyValueStore` / CloudKit) för data som ska överleva.
- Strukturerad data: SwiftData.
- Nätverk: `URLSession` med `async/await`, `Codable`-modeller, en tjänst per extern API.

## Beslut

Arkitekturbeslut dokumenteras som ADR i [`docs/adr/`](adr/README.md).
