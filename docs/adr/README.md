# Architecture Decision Records (ADR)

En ADR dokumenterar ett viktigt arkitekturbeslut: sammanhanget, beslutet och konsekvenserna.
Syftet är att framtida du (eller någon annan) ska förstå *varför* något är som det är.

## Skriva en ny ADR

1. Kopiera [`template.md`](template.md) till `NNNN-kort-titel.md` (nästa lediga nummer).
2. Fyll i, status `Föreslagen` → `Accepterad` när beslutet är taget.
3. ADR:er ändras inte i efterhand. Ett nytt beslut som ersätter ett gammalt får en ny ADR, och den gamla får
   status `Ersatt av NNNN`.

## Index

| Nr | Titel | Status |
|---|---|---|
| [0001](0001-swiftui-tvos-only.md) | SwiftUI, endast tvOS, Swift 6 | Accepterad |
