# Schema-referentie gold (Databricks)

Peildatum kolomlijst: 30 september 2026. Verifieer bij twijfel met `DESCRIBE TABLE`.

## gold.general.recruitment_algemeen (inschrijvingen, bron Kats)
Eén rij per inschrijving (kandidaat × aanvraag).
- Sleutels: aanvraag_id, aanvraag_naam, inschrijving_id, inschrijving_naam, kandidaat_id, kandidaat_naam, klant_id, klant_naam, plaatsing_id
- Statusvlaggen: is_aangeboden, intake, is_geplaatst (BOOLEAN); inschrijving_status, intake_type
- Datums (STRING): aangemaakt_op, aangeboden_op, intake_datum, plaatsing_datum, aanvraag_startdatum, plaatsing_startdatum, plaatsing_verwachte_einddatum, plaatsing_einddatum, plaatsing_beeindigd_op
- Mensen: kandidaat_gevonden_door_id/_naam (attributie recruiter), hunter_naam, recruiter_naam (aanvraageigenaar), accountmanager_naam
- Team: team (L-IP, G-IP, ...)
- Bron: bron (Web, Supplier, LinkedIn, ...); leverancier_id/_naam, leverancier_contactpersoon_id/_naam
- Aanvraag: aanvraag_status, aanvraag_fase, kpi_aanvraag (BOOLEAN)
- Plaatsing: plaatsing_status, plaatsing_fase
- Financieel: inkoop_tarief, verkoop_tarief, marge (DECIMAL, per uur), marge_per_maand

## gold.general.plaatsingen_algemeen (contracten, bron Zeerm/Business Central)
Eén rij per plaatsing/contract.
- Sleutels: plaatsing_id, bc_project_id, aanvraag_id, aanvraag_naam
- Type/status: plaatsing_type, status, fase, contract_type, is_sow, is_verlenging, inkooprelatie_type, tijdregistratie_via
- Datums (STRING): startdatum, einddatum, beeindigd_op; actuele_duur_maanden, geplande_duur_maanden (INT); TIMESTAMP: aanmaakdatum, laatst_gewijzigd, contractering_afgerond_op, welkomstmail_verzonden_op
- Partijen: opdrachtgever_naam, eindklant_naam, broker_naam, inkooprelatie_naam, administratie_naam, professional_naam, functie_professional (elk met _sf_id en _bc_nummer)
- Mensen: accountmanager_naam, recruiter_naam, hunter_naam, contractmanager_naam (elk met _id)
- Tarieven: inkoop_tarief, verkoop_tarief, marge, marge_incl_kickback, marge_interne_verrekening, marge_per_maand, hero_premium_fee, target_contribution
- Flags: inkoop_marge_fee, alleen_verkoopmarge, hero_is_margin_only_partij, reiskosten, reiskosten_bedrag
- Volumes: uren_per_week, minimum_uren, maximum_uren, uren_specificatie, uren_tekst
- Gefactureerd: totale_omzet, totale_kosten, totale_marge, totale_uren, omzet_ytd, kosten_ytd, marge_ytd, uren_ytd, aantal_facturen_verkoop/inkoop, laatste_verkoop/inkoop_factuur_datum
- Locatie: vestiging, werklocatie

Waarden (geverifieerd 30-09-2026):
- status: Actief (2.934), Beëindigd (1.873, met trema), Nog niet gestart (282)
- plaatsing_type: MSP (3.188), Interim (1.421), Hotseat (455), SOW (20), W&S (4)
- fase: Gereed, In afwachting van dossier, Ter ondertekening inkoop, Dossier indienen, Klaar voor contractering, Ter ondertekening verkoop, Dossier controleren, Dossier indienen - Nog niet ingelogd, Nieuw
- Hotseat in plaatsing_type is de contractkant van een warme stoel; aan de aanvraagkant gebruik je wall_aanvragen.warme_stoel

## gold.recruitment.wall_aanvragen (aanvragen)
Eén rij per aanvraag.
- aanvraag_id, aanvraag_naam, team, assistent_team, vestiging, record_type_naam, aanvraag_status, aanvraag_fase, kpi_aanvraag, actief_zoeken
- aanmaakdatum (TIMESTAMP), startdatum (DATE), externe_deadline
- n_lopende_intakes, has_lopende_aanbieding, n_inschrijvingen_totaal
- klant_id/_naam, accountmanager_naam, recruiter_naam, hunter_naam
- functie, functiegroep, opdracht_type, **warme_stoel (BOOLEAN)**

## gold.general.gespreksverslagen
gespreksverslag_id, datum_gesprek, type_gesprek, contact_type, bron, gesprek_met, kandidaat_naam, contact_1..3_naam, notitie, probleem_definitie, doel, wity_samenvatting, vacature_id, inschrijving_id, opportunity_id, tarief, interne_salarisindicatie, beschikbaar_vanaf, is_fieldmanagement, taak_voor_sales_support, eigenaar_naam, aangemaakt_door_naam, aangemaakt_op, laatste_activiteit_op

## gold.general.team_maandoverzicht
Maandelijkse teamstatistieken: beste_recruiter, grootste_deal_*, aantal_nieuwe_kandidaten/klanten/collegas, drukste/stilste_dag, contracten en facturen per persoon, totaal_aantal_plaatsingen, meeste_vergaderingen_*.

## Overige tabellen (naam alleen; describe bij gebruik)
- general: contactpersonen, wall_plaatsingen
- sales: accounts_clv, monthly_cost_per_placement, quarterly_cost_per_placement, placement_flow_monthly, team_targets_per_maand, portbase_management_report, portbase_operational_report
- finance: alle_openstaande_posten, openstaande_bedragen_per_klant, monthly_invoicing, plaatsingen_gefactureerd_per_maand, leverancier_uitgaven_per_maand, software_en_licentie_kosten
- contracts: dagelijkse_contracts_kpi, dagelijke_contracts_resultaten
- recruitment: jobs_metrics, daily_open_placement_count, agreement_conga_sign_transactions
- it: daily_logins, aircall_daily_calls, active_time_registrators, hero_portal_timeregistration, portal_support_cases, portal_users_by_role, hero_premium_sales

## Joins
- recruitment_algemeen <-> plaatsingen_algemeen: plaatsing_id
- recruitment_algemeen <-> wall_aanvragen: aanvraag_id
- plaatsingen_algemeen <-> wall_aanvragen: aanvraag_id
