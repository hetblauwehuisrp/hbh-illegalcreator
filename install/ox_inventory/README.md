# ox_inventory installatie

Deze map bevat de items en afbeeldingen voor hbh-illegalcreator.

1. Kopieer `items.lua` naar `ox_inventory/data/items.lua` of kopieer alleen het HBH ILLEGALCREATOR DRUGS gedeelte naar je bestaande items.lua.
2. Kopieer alle PNG-bestanden uit `web/images/` naar `ox_inventory/web/images/`.
3. Restart `ox_inventory` en daarna `hbh-illegalcreator`.

De verpakte drugs-items hebben `consume = 1` en triggeren automatisch:

```lua
hbh-illegalcreator:client:useDrug
```

Toegevoegde drugssoorten:
- Coke
- Wiet
- Meth
- XTC
- LSD
- Heroïne
- Ketamine
- Crack
- Opium
- GHB
- Speed
- Paddo's
