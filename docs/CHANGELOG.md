# Changelog

## 1.2.0

- Update systeem verder versterkt: updateall kan uit via config, automatisch downloaden kan uit via config en bestanden worden nu ook via directe filesystem fallback opgeslagen als `SaveResourceFile` faalt.
- Update systeem blokkeert `.git`, `.github`, absolute paden en `../` paden strenger.
- Alle verpakte drugs-items zijn nu bruikbaar via ox_inventory en triggeren een client-side effect.
- Drugs iconen vernieuwd naar een duidelijkere inventory-stijl met transparante PNG's.
- 5 extra drugssoorten toegevoegd: crack, opium, GHB, speed en paddo's.
- Config, quick items, NUI drug selectie en ox_inventory installatiemap bijgewerkt naar 12 drugssoorten.

## 1.1.9

- `updateall` maakt nu ontbrekende mappen automatisch aan voordat bestanden worden opgeslagen.
- Updatefout opgelost waarbij bestanden in nieuwe folders zoals `fotos/drugs`, `html/assets/drugs` en `install/ox_inventory` niet opgeslagen konden worden.
- Versiecontrole leest nu eerst `version.txt`, zodat oude `Config.Version` waardes geen verkeerde update melding meer geven.
- Extra padbeveiliging toegevoegd aan de updater tegen absolute paden en `../` paden.


## 1.1.8
- Locale syntax fout opgelost waardoor `_L` niet geladen werd.
- `saveActivity` en server callbacks gebruiken nu weer correcte Nederlandse meldingen.
- Drugs verwerken en drugs verpakken samengevoegd naar één categorie: `Drugs verwerken / verpakken`.
- Binnen de drugs pagina kies je nu zelf of de actie Verwerken of Verpakken is.
- Oude activiteiten met categorie `drugs_verpakken` worden automatisch naar de nieuwe categorie gemigreerd met modus Verpakken.
- Git update batch toegevoegd met expliciete branch refs zodat `src refspec main matches more than one` niet meer ontstaat.
- `.gitattributes` toegevoegd om LF/CRLF waarschuwingen te verminderen.

## 1.1.7
- ox_inventory installatiemap toegevoegd met een `items.lua` gebaseerd op de aangeleverde items.lua.
- 7 drugssoorten toegevoegd: coke, wiet, meth, XTC, LSD, heroïne en ketamine.
- Per drugssoort zijn pluk-, verwerk- en verpak-items toegevoegd.
- Afbeeldingenmap toegevoegd voor ox_inventory en NUI drug-selectie.
- Drugs UI uitgebreid met een drug-soort selectie die automatisch de juiste input/output items invult.


## 1.1.5
- Update systeem blokkeert nu het opstarten wanneer GitHub een nieuwere versie heeft.
- `updateall` downloadt de update nu automatisch via GitHub en stuurt geen downloadlink meer in de console.
- `updateall` schrijft de bestanden direct naar de resource en restart de resource automatisch na een succesvolle update.
- Extra server-side anti-hacker checks toegevoegd voor sessie tokens, stapvolgorde, dubbele stappen, payload grootte en afstand.
- FPS-vriendelijkere client loop toegevoegd: textUI wordt niet meer elke tick opnieuw geopend/gesloten en de loop slaapt langer wanneer dat kan.

## 1.1.4
- Actiepunten kunnen nu worden ingeklapt en weer geopend.
- Drugs plukken heeft een eigen categoriepagina gekregen.
- Drugs verwerken en verpakken gebruiken nu hetzelfde verwerk-systeem en dezelfde UI-flow.
- Verwerk/pluk/verpak instellingen kunnen direct op alle actiepunten worden toegepast.
- Nieuwe actiepunten krijgen automatisch betere defaults per categorie.
- Server-side pre-check toegevoegd zodat ontbrekende items/geld direct worden gemeld voordat animatie/progressbar start.
- Meldingen voor ontbrekende items en geld duidelijker gemaakt.

## 1.1.2
- Onnodige uitlegteksten uit de NUI weggehaald.
- Witwassen duidelijk opgesplitst in starten locatie, auto spawn locatie en klop locaties.
- Auto/bus spawn gebruikt nu de ingestelde auto spawn locatie uit de basis pagina.
- Klop locaties staan nu apart onder actiepunten als witwas-routepunten.

## 1.1.1
- Browser JavaScript confirm/prompt vensters vervangen door een eigen NUI modal binnen FiveM.
- Verwijderen van activiteiten en locatie naam invoeren blijven nu volledig in de creator UI.

## 1.1.0
- UI/UX compacter gemaakt zodat het dashboard netjes binnen het scherm blijft.
- Actiepunten hebben nu paginering, zodat veel locaties niet meer één enorm scherm maken.
- Witwas systeem omgebouwd naar route-flow:
  - NPC op startlocatie met ox_target.
  - Busje spawn bij start.
  - Optionele eigen-voertuig upgrade van 200k eenmalig per speler per activiteit.
  - Random route locaties uit de actiepunten.
  - Per locatie E-interactie met klop animatie en wachttijd.
  - Wachttijd per locatie of random min/max vanuit witwas instellingen.
  - Server-side black_money inname bij start en payout bij route afronding.
  - Standaard maximaal 50% terug, met job percentages voor bijvoorbeeld gangs.
- Extra database tabel toegevoegd voor permanente witwas eigen-voertuig upgrades.

## 1.0.0
- Eerste versie van hbh-illegalcreator.

## 1.1.3
- Update checker toegevoegd via GitHub repo `hetblauwehuisrp/hbh-illegalcreator`.
- Console melding toegevoegd: `er is een update OUDEVERZIE -> NIEUWEVERZIE gebruik updateall voor een update`.
- `updateall` console/admin command toegevoegd om handmatig een updatecheck te starten.
- Tabs worden nu per categorie getoond; de witwas tab verschijnt alleen bij categorie `Witwassen`.
- Visuele bouwer toegevoegd voor verwerken/verpakken/crafting/lab/custom systemen.
- Visuele bouwer ondersteunt slepen van blokken voor required items, verwijderen, rewards, wachttijd, minigame, animatie en politie melding.
- Server-side verwerking toegevoegd voor visual-builder required items en rewards.
