# Release

## Versionering

- `MARKETING_VERSION` (t.ex. `1.2.0`) följer [SemVer](https://semver.org/lang/sv/): MAJOR.MINOR.PATCH.
- `CURRENT_PROJECT_VERSION` (build-nummer) ökas för **varje** uppladdning till App Store Connect.
- Båda sätts i target-inställningarna (*TVDash → Build Settings → Versioning*), inte i Info.plist.

## Förberedelser (en gång)

1. Medlemskap i Apple Developer Program.
2. Sätt ditt team under *Signing & Capabilities*, behåll *Automatically manage signing*.
3. Kontrollera bundle id `com.hbakesson.tvdash` (ändra om du vill ha ett annat – innan första uppladdningen).
4. Skapa appen i [App Store Connect](https://appstoreconnect.apple.com) med samma bundle id, plattform tvOS.
5. Lägg in riktiga app-ikoner och Top Shelf-bilder (se [TVOS_DESIGN.md](TVOS_DESIGN.md#app-ikon-och-top-shelf)).

## Checklista per release

- [ ] Alla tester gröna, inga varningar i Release-bygge
- [ ] Testat på riktig Apple TV (inte bara simulator)
- [ ] `CHANGELOG.md`: flytta `[Unreleased]` till ny versionsrubrik med datum
- [ ] Höj `MARKETING_VERSION` och `CURRENT_PROJECT_VERSION`
- [ ] Commit `chore(release): vX.Y.Z` och git-tagg `vX.Y.Z`
- [ ] *Product → Archive* (destination: *Any tvOS Device*)
- [ ] *Distribute App → App Store Connect* → TestFlight
- [ ] Testa TestFlight-bygget, skicka sedan för granskning

## Testa på riktig Apple TV

Apple TV och Mac på samma nätverk → på Apple TV: *Inställningar → Fjärrkontroller och enheter → Fjärrapp och
enheter*. I Xcode: *Window → Devices and Simulators* → para ihop. Välj sedan Apple TV:n som destination.
