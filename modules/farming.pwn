#define MAX_PLANTS 500
#define FAZA_RASTA_VREME (1 * 60000)
#define MAX_FAZA 3 // Biljka ima 3 faze dok ne bude spremna

enum BiljkaData {
    biljkaID,
    biljkaVlasnikSQLID,
    biljkaFaza,
    bool:biljkaAktivna,
    biljkaObjekat, // ID objekta na mapi
    Float:biljkaX,
    Float:biljkaY,
    Float:biljkaZ,
    biljkaTajmer,
    Text3D:biljkaLabel,
    biljkaVoda,
    bool:imaSeme,
};
new Biljke[MAX_PLANTS][BiljkaData];


forward OnBiljkaInsert(slot);
public OnBiljkaInsert(slot)
{
    Biljke[slot][biljkaID] = cache_insert_id();
    
    if(Biljke[slot][biljkaAktivna]) 
    {
        OsveziBiljkaLabel(slot);
        printf("[FARMING]: Label kreiran za saksiju u slotu %d (Baza ID: %d)", slot, Biljke[slot][biljkaID]);
    }
    return 1;
}

// Funkcije:
forward UcitajSveBiljke();
public UcitajSveBiljke()
{
    new rows = cache_num_rows();
    if(rows == 0) return print("[FARMING]: Nema zasadenih biljaka u bazi.");

    for(new i = 0; i < rows && i < MAX_PLANTS; i++)
    {
        Biljke[i][biljkaAktivna] = true;
        
        // Uzimanje vrednosti iz SQL cache-a
        cache_get_value_name_int(i, "id", Biljke[i][biljkaID]);
        cache_get_value_name_int(i, "vlasnik_id", Biljke[i][biljkaVlasnikSQLID]);
        cache_get_value_name_float(i, "x", Biljke[i][biljkaX]);
        cache_get_value_name_float(i, "y", Biljke[i][biljkaY]);
        cache_get_value_name_float(i, "z", Biljke[i][biljkaZ]);
        cache_get_value_name_int(i, "faza", Biljke[i][biljkaFaza]);
        cache_get_value_name_int(i, "voda", Biljke[i][biljkaVoda]);
        cache_get_value_name_int(i, "imaSeme", Biljke[i][imaSeme]);

        // Kreiranje objekta
        Biljke[i][biljkaObjekat] = CreateDynamicObject(2203, Biljke[i][biljkaX], Biljke[i][biljkaY], Biljke[i][biljkaZ], 0, 0, 0);
        
        // Resetovanje labela i tajmera pre setovanja
        Biljke[i][biljkaLabel] = Text3D:INVALID_3DTEXT_ID;
        Biljke[i][biljkaTajmer] = -1;

        // Ako biljka nije dostigla finalnu fazu, nastavi tajmer
        if(Biljke[i][biljkaFaza] < MAX_FAZA) 
        {
            Biljke[i][biljkaTajmer] = SetTimerEx("BiljkaUpdate", FAZA_RASTA_VREME, false, "i", i);
        }
        
        // Pozivamo stock koji smo ranije napravili da postavi 3D Text
        OsveziBiljkaLabel(i);
    }
    
    printf("[SQL]: Uspesno ucitano %d biljaka iz baze.", rows);
    return 1;
}

hook OnPlayerEditDynObj@Saks(playerid, objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz)
{
    if(GetPVarInt(playerid, "PostavljaSaksiju") != 1) return 0;

    if(response == EDIT_RESPONSE_FINAL)
    {
        new slot = GetPVarInt(playerid, "Saksija_SlotID");

        // KLJUČ: Prvo dodeli koordinate varijablama, pa tek onda zovi label!
        Biljke[slot][biljkaX] = x;
        Biljke[slot][biljkaY] = y;
        Biljke[slot][biljkaZ] = z;
        Biljke[slot][biljkaAktivna] = true;
        Biljke[slot][biljkaObjekat] = objectid;

        // SIGURNOST: Force-uj label da bude INVALID pre kreiranja
        // Ovo radimo da bi OsveziBiljkaLabel sigurno uradio CreateDynamic3DTextLabel
        Biljke[slot][biljkaLabel] = Text3D:INVALID_3DTEXT_ID; 

        // Sada pozovi label
        OsveziBiljkaLabel(slot);

        // SQL deo
        new bQuery[256];
        mysql_format(g_SQL, bQuery, sizeof(bQuery), 
            "INSERT INTO Biljke (vlasnik_id, x, y, z, faza, voda, imaSeme) VALUES (%d, '%f', '%f', '%f', 0, 0, 0)", 
            Igrac[playerid][IgracId], x, y, z);
        mysql_tquery(g_SQL, bQuery, "OnBiljkaInsert", "i", slot);

        SendClientMessage(playerid, -1, "{00FF00}[Farming]: {FFFFFF}Saksija postavljena!");
        OduzmiItem(playerid, "Saksija", 1);
        
        DeletePVar(playerid, "PostavljaSaksiju");
        DeletePVar(playerid, "Saksija_SlotID");
        return 1;
    }
    else if(response == EDIT_RESPONSE_CANCEL)
    {
        DestroyDynamicObject(objectid);
        DeletePVar(playerid, "PostavljaSaksiju");
        DeletePVar(playerid, "Saksija_SlotID");
        return 1;
    }
    return 0;
}

stock OsveziBiljkaLabel(slot)
{
    new labelStr[256]; // Malo veći buffer za svaki slučaj
    if(!Biljke[slot][imaSeme]) 
    {
        format(labelStr, sizeof(labelStr), "{FFFFFF}[ Prazna Saksija ]\n{FFFF00}Komanda: /plant");
    }
    else 
    {
        new bojaVode[10];
        if(Biljke[slot][biljkaVoda] > 60) bojaVode = "{00FF00}";
        else if(Biljke[slot][biljkaVoda] > 20) bojaVode = "{FFFF00}";
        else bojaVode = "{FF0000}";

        if(Biljke[slot][biljkaFaza] >= MAX_FAZA) {
            format(labelStr, sizeof(labelStr), "{00FF00}[ Marihuana ]\n{FFFFFF}Voda: %s%d%%\n{FFFFFF}Status: {00FF00}Spremna\n{FFFFFF}/harvest", bojaVode, Biljke[slot][biljkaVoda]);
        } else {
            format(labelStr, sizeof(labelStr), "{00FF00}[ Marihuana ]\n{FFFFFF}Voda: %s%d%%\n{FFFFFF}Status: {FFFF00}Raste (%d/%d)\n{FFFFFF}/water", bojaVode, Biljke[slot][biljkaVoda], Biljke[slot][biljkaFaza], MAX_FAZA);
        }
    }

    // --- KLJUČNA IZMENA OVDE ---
    // Proveravamo da li je label validan. 
    // Dodajemo i proveru da li je ID 0, jer to cesto znaci da nije inicijalizovan kako treba
    if(Biljke[slot][biljkaLabel] == Text3D:INVALID_3DTEXT_ID || Biljke[slot][biljkaLabel] == Text3D:0) 
    {
        // Kreiramo ga na Z + 0.8 da bude sigurno iznad saksije
        Biljke[slot][biljkaLabel] = CreateDynamic3DTextLabel(labelStr, -1, 
            Biljke[slot][biljkaX], Biljke[slot][biljkaY], Biljke[slot][biljkaZ] + 0.8, 
            15.0, .worldid = -1, .testlos = 0);
        
        printf("[DEBUG]: Kreiran novi label za slot %d", slot);
    }
    else 
    {
        UpdateDynamic3DTextLabelText(Biljke[slot][biljkaLabel], -1, labelStr);
        printf("[DEBUG]: Update-ovan postojeci label za slot %d", slot);
    }
    return 1;
}

forward BiljkaUpdate(slot);
public BiljkaUpdate(slot)
{
    if(!Biljke[slot][biljkaAktivna]) return 0;

    // 1. Trosenje vode (50% po svakom otkucaju tajmera, kada prodje svaka faza. Sto znaci da igrac mora makar jednom da zalije biljku tokom njenog rasta)
    Biljke[slot][biljkaVoda] -= 50;
    if(Biljke[slot][biljkaVoda] < 0) Biljke[slot][biljkaVoda] = 0;

    // 2. Provera vode: Ako nema vode, biljka ne napreduje u fazi
    if(Biljke[slot][biljkaVoda] <= 0)
    {
        // Samo osvezavamo label da igrac vidi da je na 0%
        OsveziBiljkaLabel(slot);
        
        // Ponovo pokrecemo tajmer da bi sistem proverio vodu opet nakon nekog vremena
        Biljke[slot][biljkaTajmer] = SetTimerEx("BiljkaUpdate", FAZA_RASTA_VREME, false, "i", slot);
        
        printf("[DEBUG]: Biljka %d ne moze da raste - nema vode!", slot);
        return 1; 
    }

    // 3. Biljka ima vode, znaci napreduje u sledecu fazu
    Biljke[slot][biljkaFaza]++;

    // 4. Azuriranje faze I vode u bazi (sve u jednom upitu)
    new upQuery[150];
    mysql_format(g_SQL, upQuery, sizeof(upQuery), "UPDATE Biljke SET faza = %d, voda = %d WHERE id = %d", 
        Biljke[slot][biljkaFaza], Biljke[slot][biljkaVoda], Biljke[slot][biljkaID]);
    mysql_tquery(g_SQL, upQuery);

    // 5. Osvezavanje 3D Texta (pozivamo tvoj stock koji smo malopre prosirili)
    OsveziBiljkaLabel(slot);

    // 6. Ako jos raste, postavi tajmer za sledecu fazu
    if(Biljke[slot][biljkaFaza] < MAX_FAZA)
    {
        Biljke[slot][biljkaTajmer] = SetTimerEx("BiljkaUpdate", FAZA_RASTA_VREME, false, "i", slot);
    }
    
    printf("[DEBUG]: Biljka %d je presla u fazu %d (Voda: %d%%)", slot, Biljke[slot][biljkaFaza], Biljke[slot][biljkaVoda]);
    return 1;
}

CMD:plant(playerid, params[])
{
    if(!Igrac[playerid][LoggedIn]) return 1;
    if(!ImaItemUInv(playerid, "Seme Marihuane")) return SendClientMessage(playerid, -1, "Nemate seme!");

    new slot = -1;
    for(new i = 0; i < MAX_PLANTS; i++) {
        if(Biljke[i][biljkaAktivna] && !Biljke[i][imaSeme] && IsPlayerInRangeOfPoint(playerid, 2.0, Biljke[i][biljkaX], Biljke[i][biljkaY], Biljke[i][biljkaZ])) {
            slot = i;
            break;
        }
    }

    if(slot == -1) return SendClientMessage(playerid, -1, "Morate biti pored prazne saksije!");

    // Sadimo seme u saksiju
    Biljke[slot][imaSeme] = true;
    Biljke[slot][biljkaVoda] = 100;
    Biljke[slot][biljkaFaza] = 0;
    OduzmiItem(playerid, "Seme Marihuane", 1);

    // Update u bazi
    new upQuery[128];
    mysql_format(g_SQL, upQuery, sizeof(upQuery), "UPDATE Biljke SET imaSeme = 1, voda = 100, faza = 0 WHERE id = %d", Biljke[slot][biljkaID]);
    mysql_tquery(g_SQL, upQuery);

    OsveziBiljkaLabel(slot);
    Biljke[slot][biljkaTajmer] = SetTimerEx("BiljkaUpdate", FAZA_RASTA_VREME, false, "i", slot);

    SendClientMessage(playerid, -1, "Zasadili ste seme u saksiju.");
    return 1;
}

CMD:harvest(playerid, params[])
{
    if(!Igrac[playerid][LoggedIn]) return 1;

    new slot = -1;
    // Tražimo saksiju u blizini koja je aktivna i u kojoj zapravo ima nečega (imaSeme)
    for(new i = 0; i < MAX_PLANTS; i++) {
        if(Biljke[i][biljkaAktivna] && Biljke[i][imaSeme] && IsPlayerInRangeOfPoint(playerid, 1.5, Biljke[i][biljkaX], Biljke[i][biljkaY], Biljke[i][biljkaZ])) {
            slot = i;
            break;
        }
    }

    if(slot == -1) return SendClientMessage(playerid, -1, "{FF0000}[Farming]: {FFFFFF}Niste blizu saksije sa zrelom biljkom.");
    if(Biljke[slot][biljkaFaza] < MAX_FAZA) return SendClientMessage(playerid, -1, "{FF0000}[Farming]: {FFFFFF}Biljka jos nije spremna za branje!");

    // Generisanje nasumične količine (2-5g)
    new kolicina = random(4) + 2; 

    // Pokušaj pakovanja u inventar (ako vrati 0, funkcija SpakujUInv će već ispisati poruku za pun inv)
    if(SpakujUInv(playerid, "Marihuana", kolicina) == 0) return 1; 

    // --- USPEŠNO BRANJE ---

    ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.1, 0, 1, 1, 0, 0, 1);
    
    new string[128];
    format(string, sizeof(string), "{00FF00}[Farming]: {FFFFFF}Uspesno ste ubrali marihuanu ({FFFF00}%dg{FFFFFF}).", kolicina);
    SendClientMessage(playerid, -1, string);

    // RESETOVANJE PODATAKA (Saksija ostaje, biljka nestaje)
    Biljke[slot][imaSeme] = false;
    Biljke[slot][biljkaFaza] = 0;
    Biljke[slot][biljkaVoda] = 0;
    
    // Zaustavljamo tajmer rasta pošto je ubrana
    KillTimer(Biljke[slot][biljkaTajmer]);
    Biljke[slot][biljkaTajmer] = -1;

    // SQL: Ne brišemo red (DELETE), nego samo resetujemo statuse u bazi
    new upQuery[150];
    mysql_format(g_SQL, upQuery, sizeof(upQuery), "UPDATE Biljke SET imaSeme = 0, faza = 0, voda = 0 WHERE id = %d", Biljke[slot][biljkaID]);
    mysql_tquery(g_SQL, upQuery);

    // Osvežavamo label da piše "[ Prazna Saksija ]"
    OsveziBiljkaLabel(slot);

    return 1;
}

CMD:water(playerid, params[])
{
    if(!Igrac[playerid][LoggedIn]) return 1;

    new slot = -1;
    for(new i = 0; i < MAX_PLANTS; i++) {
        if(Biljke[i][biljkaAktivna] && IsPlayerInRangeOfPoint(playerid, 1.0, Biljke[i][biljkaX], Biljke[i][biljkaY], Biljke[i][biljkaZ])) {
            slot = i;
            break;
        }
    }

    if(slot == -1) return SendClientMessage(playerid, -1, "{FF0000}[Farming]: {FFFFFF}Niste blizu nijedne biljke.");
    if(Biljke[slot][biljkaVoda] >= 100) return SendClientMessage(playerid, -1, "{FF0000}[Farming]: {FFFFFF}Biljka je vec zalivena.");

    // Provera flašice vode u inventaru
    if(!ImaItemUInv(playerid, "Flasica vode")) 
        return SendClientMessage(playerid, -1, "{FF0000}[Farming]: {FFFFFF}Nemate flašicu vode kod sebe!");

    // Logika zalivanja
    Biljke[slot][biljkaVoda] = 100;
    OduzmiItem(playerid, "Flasica vode", 1); // Potroši vodu
    
    // Azuriraj u bazi
    new wQuery[128];
    mysql_format(g_SQL, wQuery, sizeof(wQuery), "UPDATE Biljke SET voda = 100 WHERE id = %d", Biljke[slot][biljkaID]);
    mysql_tquery(g_SQL, wQuery);

    OsveziBiljkaLabel(slot);
    ApplyAnimation(playerid, "GRENADE", "WEAPON_throw", 4.1, 0, 0, 0, 0, 0, 1);
    SendClientMessage(playerid, -1, "{00BCFF}[Farming]: {FFFFFF}Zalili ste biljku.");
    return 1;
}

CMD:postavisaksiju(playerid, params[])
{
    if(!Igrac[playerid][LoggedIn]) return 1;
    
    // Provera da li igrac uopste ima saksiju kod sebe
    if(!ImaItemUInv(playerid, "Saksija")) 
        return SendClientMessage(playerid, -1, "{FF0000}[Farming]: {FFFFFF}Nemate saksiju u inventaru!");

    new id = -1;
    for(new i = 0; i < MAX_PLANTS; i++) {
        if(!Biljke[i][biljkaAktivna]) {
            id = i;
            break;
        }
    }

    if(id == -1) return SendClientMessage(playerid, -1, "Dostignut limit saksija.");

    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    // Kreiramo privremeni objekat saksije (2203) koji igrac pomera
    // Postavljamo ga malo ispred igraca
    new tempObj = CreateDynamicObject(2203, x + 0.5, y + 0.5, z - 0.5, 0.0, 0.0, 0.0);
    
    // Ulazimo u Edit Mode
    EditDynamicObject(playerid, tempObj);
    
    // Koristimo PVare da pamtimo koji slot popunjavamo
    SetPVarInt(playerid, "PostavljaSaksiju", 1);
    SetPVarInt(playerid, "Saksija_SlotID", id);

    SendClientMessage(playerid, -1, "{00BCFF}[Farming]: {FFFFFF}Namestite saksiju strelicama i kliknite na 'Disketicu' da zavrsite.");
    return 1;
}

CMD:uzmisaksiju(playerid, params[])
{
    if(!Igrac[playerid][LoggedIn]) return 1;

    new slot = -1;
    // Tražimo najbližu saksiju u radijusu od 2.0 metara
    for(new i = 0; i < MAX_PLANTS; i++) 
    {
        if(Biljke[i][biljkaAktivna] && IsPlayerInRangeOfPoint(playerid, 2.0, Biljke[i][biljkaX], Biljke[i][biljkaY], Biljke[i][biljkaZ])) 
        {
            slot = i;
            break;
        }
    }

    if(slot == -1) 
        return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Niste blizu nijedne saksije.");

    if(Biljke[slot][imaSeme]) 
        return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Ne mozete uzeti saksiju dok u njoj raste biljka!");

    // Pokušavamo da spakujemo predmet u inventar
    if(SpakujUInv(playerid, "Saksija", 1) == 0) 
    {
        return 1;
    }

    // SQL Brisanje iz baze
    new delQuery[128];
    mysql_format(g_SQL, delQuery, sizeof(delQuery), "DELETE FROM Biljke WHERE id = %d", Biljke[slot][biljkaID]);
    mysql_tquery(g_SQL, delQuery);

    // Unistavanje vizuelnih elemenata
    if(Biljke[slot][biljkaObjekat] != INVALID_STREAMER_ID) DestroyDynamicObject(Biljke[slot][biljkaObjekat]);
    if(Biljke[slot][biljkaLabel] != Text3D:INVALID_3DTEXT_ID) DestroyDynamic3DTextLabel(Biljke[slot][biljkaLabel]);

    // Resetovanje memorije slota
    Biljke[slot][biljkaAktivna] = false;
    Biljke[slot][imaSeme] = false;
    Biljke[slot][biljkaID] = 0;
    Biljke[slot][biljkaLabel] = Text3D:INVALID_3DTEXT_ID;
    Biljke[slot][biljkaObjekat] = INVALID_STREAMER_ID;

    // Animacija i poruka
    ApplyAnimation(playerid, "CARRY", "putdwn", 4.1, 0, 0, 0, 0, 0, 1);
    SendClientMessage(playerid, -1, "{00FF00}[Farming]: {FFFFFF}Uspesno ste pokupili praznu saksiju.");

    return 1;
}

CMD:dajvodu(playerid, params[])
{
    if(!Igrac[playerid][LoggedIn]) return 1;

    if(SpakujUInv(playerid, "Flasica vode", 1) == 0) 
    {
        return 1; 
    }
    SendClientMessage(playerid, -1, "{00FF00}[Farming]: {FFFFFF}Dobili ste flašicu vode.");
    return 1;
}

CMD:dajsaksiju(playerid, params[])
{
    if(SpakujUInv(playerid, "Saksija", 1)) 
    {
        SendClientMessage(playerid, -1, "{00FF00}[Test]: {FFFFFF}Dobili ste 1 saksiju za testiranje.");
    }
    else { // SpakujUInv ce sama ispisati ako je inventar pun 
    }
    return 1;
}