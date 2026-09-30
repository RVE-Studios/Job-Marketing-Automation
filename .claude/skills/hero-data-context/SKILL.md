---
name: hero-data-context
description: Hero Interim Professionals data-context voor Databricks-analyses (catalog gold). Gebruik ALTIJD bij vragen over recruiters, plaatsingen, inschrijvingen, aanvragen, marge, Hansibor, funnel, klanten of teamprestaties van Hero, en bij elke SQL-query op gold.general, gold.recruitment, gold.sales of gold.finance. Triggers: "prestaties van", "hoeveel plaatsingen", "marge per", "Hansibor", "warme stoel", "funnel", "recruiterrapport", "teamoverzicht", "Databricks", "Kats-data", "Zeerm-data". Bevat de juiste attributievelden, de WS/echt-splitsing, klantspecifieke regels (ICTU-cap), de Hansibor-formule, naamspelling en bekende datakwaliteitsproblemen.
---

# Hero data-context (Databricks, catalog gold)

Lees dit vóór elke query. De regels hieronder zijn hard: ze corrigeren fouten die eerder tot verkeerde conclusies leidden.

## 1. Attributie: wie krijgt de credit?

| Vraag | Veld | Tabel |
|---|---|---|
| Wie vond de kandidaat (recruiterprestatie) | `kandidaat_gevonden_door_naam` | recruitment_algemeen |
| Wie pakte de aanvraag op | `hunter_naam` | recruitment_algemeen / plaatsingen_algemeen |
| Wie is aanvraageigenaar | `recruiter_naam` | recruitment_algemeen / wall_aanvragen |
| Wie is commercieel eigenaar klant | `accountmanager_naam` | alle tabellen |

**Regel:** recruiterprestaties (inschrijvingen, aanbiedingen, intakes, plaatsingen) attribueer je op `kandidaat_gevonden_door_naam`. Nooit op `hunter_naam` of `recruiter_naam`: de aanvraageigenaar is niet altijd degene die de aanvraag oppakt, en de hunter niet altijd degene die de kandidaat vond.

## 2. Warme stoel versus echte aanvraag

Splits altijd. `gold.recruitment.wall_aanvragen.warme_stoel` (BOOLEAN), join op `aanvraag_id`. Een warme stoel (WS) is een verlenging/overname van een zittende professional; conversie en marge zijn daar niet vergelijkbaar met een echte aanvraag. Rapporteer WS en echt apart, met totaal erbij.

## 3. Klantspecifieke regels

- **ICTU**: sinds juni 2026 een marge-cap van € 7,50 per uur. Lage marge bij ICTU-plaatsingen is dus beleid, geen prestatie-issue. Benoem dit expliciet bij elke marge-analyse waar ICTU in zit.
- Klantconcentratie: EZK en ICTU zijn samen circa 60% van de Hoornse contracten in 2026.

## 4. Hansibor

Hansibor = gemiddelde maandmarge van alle **lopende** inzetten, gecorrigeerd voor werkbare dagen en genormaliseerd op 12 maanden looptijd. Praktische berekening per plaatsing:

```
hansibor = marge (per uur) × uren_per_week × 3,942
```

Gebruik Hansibor in plaats van omzet/marge YTD wanneer het om sturing of forecast gaat; YTD-bedragen zijn afhankelijk van startmoment en niet vergelijkbaar tussen personen. Celdelingsnorm: 700k Hansibor per vestiging.

## 5. Terminologie

Nederlands, Hero-jargon. "Closen" (niet "sluiten"). Inschrijving = kandidaat gekoppeld aan aanvraag (Kats). Plaatsing = contract (Zeerm/BC). Aanvraag = vacature van klant. Hunter = recruiter die zoekt op een aanvraag. Team L-IP en G-IP zijn de Hoornse teams; vestiging in de data kan afwijken van team (collega's onder Alkmaar werken soms in L-IP/G-IP). Vraag bij twijfel wie in scope is.

## 6. Namen en datakwaliteit

- Daniël de Vries staat in Kats **met trema**. Zoek namen altijd met `LIKE '%de Vries%'` of ILIKE, nooit exact.
- Queenten Leonora is een man.
- Datumvelden in recruitment_algemeen en plaatsingen_algemeen zijn STRING; cast of vergelijk als ISO-string (`>= '2026-01-01'`).
- Contracten zonder recruiter/hunter komen voor (16 Hoornse contracten in 2026); benoem niet-toegerekende contracten expliciet.
- Kats-plaatsingen (is_geplaatst) en gestarte contracten (plaatsingen_algemeen) lopen per persoon uiteen; contracten uit inschrijvingen van vóór het jaar tellen wel als contract maar niet in de funnel.
- Verlof en beschikbaarheid verklaren dips; vraag ernaar voordat je een terugval als prestatieprobleem duidt.

## 7. Werkwijze

1. Lees `references/schema.md` voor tabellen en kolommen; `references/queries.md` voor geteste query-patronen.
2. Bevestig scope (welke personen, periode, WS/echt) voordat je rekent.
3. Rapporteer altijd: funnel (inschrijvingen → aangeboden → intake → geplaatst) met conversie per stap, WS/echt-splitsing, en Hansibor voor lopende inzetten.
4. Profielteksten beschrijven patronen in data, geen oordeel over inzet of motivatie. Eindig met gespreksvragen, niet met conclusies over mensen.
5. Rapporten in Hero-huisstijl via de hero-huisstijl skill (blauw #073889, oranje #f46015, Exo + Source Sans 3).
