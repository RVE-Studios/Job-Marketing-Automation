# Geteste query-patronen (DBSQL)

## Recruiterfunnel per persoon, WS/echt gesplitst
```sql
SELECT r.kandidaat_gevonden_door_naam AS recruiter,
       COALESCE(w.warme_stoel, false) AS warme_stoel,
       COUNT(*) AS inschrijvingen,
       SUM(CASE WHEN r.is_aangeboden THEN 1 ELSE 0 END) AS aangeboden,
       SUM(CASE WHEN r.intake THEN 1 ELSE 0 END) AS intakes,
       SUM(CASE WHEN r.is_geplaatst THEN 1 ELSE 0 END) AS geplaatst
FROM gold.general.recruitment_algemeen r
LEFT JOIN gold.recruitment.wall_aanvragen w ON w.aanvraag_id = r.aanvraag_id
WHERE r.aangemaakt_op >= '2026-01-01'
  AND r.kandidaat_gevonden_door_naam IN ('Gian Moorman','Queenten Leonora', ...)
GROUP BY 1,2 ORDER BY 1,2;
```

## Hansibor per recruiter (lopende inzetten)
```sql
SELECT p.hunter_naam,
       COUNT(*) AS actieve_plaatsingen,
       ROUND(SUM(p.marge * p.uren_per_week * 3.942), 0) AS hansibor
FROM gold.general.plaatsingen_algemeen p
WHERE p.status = 'Actief'   -- geverifieerd 30-09-2026; zie schema.md voor alle waarden
GROUP BY 1 ORDER BY hansibor DESC;
```
Let op: kies het attributieveld bewust (hunter_naam voor contracten; voor recruitercredit koppel via plaatsing_id naar recruitment_algemeen.kandidaat_gevonden_door_naam).

## Marge per klant met ICTU-markering
```sql
SELECT eindklant_naam,
       COUNT(*) AS contracten,
       ROUND(AVG(marge),2) AS gem_marge_uur,
       CASE WHEN eindklant_naam ILIKE '%ICTU%' THEN 'cap € 7,50/uur sinds jun 2026' END AS opmerking
FROM gold.general.plaatsingen_algemeen
WHERE startdatum >= '2026-01-01'
GROUP BY 1 ORDER BY contracten DESC;
```

## Bronanalyse (inschrijvingen vs plaatsingen)
```sql
SELECT bron, COUNT(*) AS inschrijvingen,
       SUM(CASE WHEN is_geplaatst THEN 1 ELSE 0 END) AS geplaatst,
       ROUND(100.0*SUM(CASE WHEN is_geplaatst THEN 1 ELSE 0 END)/COUNT(*),1) AS conv_pct
FROM gold.general.recruitment_algemeen
WHERE aangemaakt_op >= '2026-01-01'
GROUP BY 1 ORDER BY inschrijvingen DESC;
```

## Naamzoeken (trema-proof)
```sql
WHERE kandidaat_gevonden_door_naam ILIKE '%de Vries%'
```

## Checklist vóór rapportage
- Scope bevestigd (personen, periode, team vs vestiging)
- WS/echt gesplitst
- ICTU-cap benoemd als ICTU in scope zit
- Hansibor i.p.v. YTD voor sturing
- Niet-toegerekende contracten geteld en vermeld
- Verlof/beschikbaarheid gecheckt bij dips
