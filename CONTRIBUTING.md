# Bidra till TVDash

## Arbetsflöde

1. Utgå från `main`, skapa en branch: `feature/<kort-namn>`, `fix/<kort-namn>` eller `chore/<kort-namn>`.
2. Gör små, fokuserade commits.
3. Kör tester och lint lokalt (se nedan).
4. Öppna en pull request mot `main` och gå igenom checklistan.

`main` ska alltid gå att bygga och köra.

## Commit-meddelanden

Vi följer [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(dashboard): add weather tile
fix(focus): restore focus after closing detail view
docs: describe release process
refactor, test, chore, build, ci …
```

Första raden max ~72 tecken, imperativ form, engelska.

## Innan du pushar

```sh
DEST='platform=tvOS Simulator,name=Apple TV 4K (4th generation)'
xcrun swift-format format -i -r TVDash TVDashTests
xcrun swift-format lint -r TVDash TVDashTests
xcodebuild test -project TVDash.xcodeproj -scheme TVDash -destination "$DEST"
```

## PR-checklista

- [ ] Bygger utan varningar
- [ ] Tester tillagda/uppdaterade och gröna
- [ ] Testat med Siri Remote i simulatorn (fokus, Menu-knapp, Play/Pause där relevant)
- [ ] Fungerar i både ljust och mörkt läge
- [ ] Texter går via String Catalog (lokaliserbara)
- [ ] VoiceOver-etiketter på ikoner/bilder utan text
- [ ] `CHANGELOG.md` uppdaterad om ändringen märks för användaren
- [ ] ADR skriven om ett större arkitekturbeslut fattats
