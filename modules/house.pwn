#include <YSI_Coding\y_timers>
enum kuca_data {
    kId,
    kTip,
    kVlasnik[24],
    kOpis[50],
    Float:kUlazX,
    Float:kUlazY,
    Float:kUlazZ,
    Float:kIzlazX,
    Float:kIzlazY,
    Float:kIzlazZ,
    kCena,
    kLevel,
    kEnterijer,
    kVW,
    kKupljena,
    kZakljucana,
    kNovac,
    kPickup,
    Text3D:kLabel,
    kRacunVreme
}
new Kuca[MAX_KUCA][kuca_data];

enum kuca_interijer_data {
    kiIme[50],
    kiIntID,
    Float:kiX,
    Float:kiY,
    Float:kiZ
}

new MaleKuce[][kuca_interijer_data] = {
    {"Jeftina Garsonjera", 1, 223.043, 1287.056, 1082.140},
    {"Drvena Koliba", 2, 225.756, 1021.423, 1084.017}
};

new SrednjeKuce[][kuca_interijer_data] = {
    {"Porodicni Dom", 5, 235.508, 1187.168, 1080.250},
    {"Momacka Gajba", 10, 2262.83, -1137.71, 1050.63}
};

new VelikeKuce[][kuca_interijer_data] = {
    {"Vila Richman", 15, 327.919, 1477.514, 1084.437},
    {"Moderni Dvorac", 7, 225.63, 1022.47, 1084.01}
};

// Koristi TASK a ne STOCK za automatsko ponavljanje
task KucaRacunVreme[3600000]() 
{
    new h_query[128]; // Promenjeno ime u h_query da izbegneš shadowing warning
    for(new i = 0; i < MAX_KUCA; i++)
    {
        if(Kuca[i][kId] != 0 && Kuca[i][kKupljena] == 1)
        {
            Kuca[i][kRacunVreme]--;

            if(Kuca[i][kRacunVreme] <= 0)
            {
                NaplatiRacunKuce(i);
                Kuca[i][kRacunVreme] = 24;
            }
            
            mysql_format(g_SQL, h_query, sizeof(h_query), "UPDATE Kuce SET racunVreme = %d WHERE id = %d", Kuca[i][kRacunVreme], Kuca[i][kId]);
            mysql_tquery(g_SQL, h_query);
        }
    }
    return 1;
}

stock NaplatiRacunKuce(houseid)
{
    new cenaRacuna = Kuca[houseid][kCena] / 100; // 1% cene kuce je racun
    new vlasnik[24];
    format(vlasnik, 24, Kuca[houseid][kVlasnik]);

    foreach(new i : Player)
    {
        new pIme[24];
        GetPlayerName(i, pIme, 24);
        if(!strcmp(pIme, vlasnik))
        {
            // PlayerInfo[i][pBanka] -= cenaRacuna;
            new str[128];
            format(str, sizeof(str), "{FF0000}[ House System | Info ]: {FFFFFF}Platili ste racun za kucu u iznosu od {00FF00}%d$.", cenaRacuna);
            SendClientMessage(i, -1, str);
            return 1;
        }
    }

    // Ako je offline
    new query[128];
    mysql_format(g_SQL, query, sizeof(query), "UPDATE Korisnici SET Banka = Banka - %d WHERE Ime = '%e'", cenaRacuna, vlasnik);
    mysql_tquery(g_SQL, query);
    return 1;
}

forward LoadHouses();
public LoadHouses()
{
    new rows = cache_num_rows();
    if(rows == 0) return printf("[ House System | Info ]: Nema kuca u bazi podataka.");

    for(new i = 0; i < rows; i++)
    {
        // Ucitavamo podatke iz baze u nas enum
        cache_get_value_name_int(i, "id", Kuca[i][kId]);
        cache_get_value_name(i, "vlasnik", Kuca[i][kVlasnik]);
        cache_get_value_name(i, "opis", Kuca[i][kOpis]);
        cache_get_value_name_float(i, "ulazX", Kuca[i][kUlazX]);
        cache_get_value_name_float(i, "ulazY", Kuca[i][kUlazY]);
        cache_get_value_name_float(i, "ulazZ", Kuca[i][kUlazZ]);
        cache_get_value_name_float(i, "izlazX", Kuca[i][kIzlazX]);
        cache_get_value_name_float(i, "izlazY", Kuca[i][kIzlazY]);
        cache_get_value_name_float(i, "izlazZ", Kuca[i][kIzlazZ]);
        cache_get_value_name_int(i, "cena", Kuca[i][kCena]);
        cache_get_value_name_int(i, "level", Kuca[i][kLevel]);
        cache_get_value_name_int(i, "enterijer", Kuca[i][kEnterijer]);
        cache_get_value_name_int(i, "virtualWorld", Kuca[i][kVW]);
        cache_get_value_name_int(i, "kupljena", Kuca[i][kKupljena]);
        cache_get_value_name_int(i, "zakljucana", Kuca[i][kZakljucana]);

        OsveziKucu(i);
    }
    printf("[ House System | Info ]: Uspesno ucitano %d kuca iz baze.", rows);
    return 1;
}

stock OsveziKucu(id)
{
    if(Kuca[id][kLabel] != Text3D:INVALID_3DTEXT_ID) Delete3DTextLabel(Kuca[id][kLabel]);
    if(Kuca[id][kPickup] != -1) DestroyPickup(Kuca[id][kPickup]);

    new labelStr[256];

    if(Kuca[id][kKupljena] == 0)
    {
        format(labelStr, sizeof(labelStr), "{00FF00}[ KUCA NA PRODAJU ]\n{FFFFFF}Opis: %s\nCena: {00FF00}%d$\n{FFFFFF}Level: %d\nKoristite /kupikucu", 
            Kuca[id][kOpis], Kuca[id][kCena], Kuca[id][kLevel]);
        
        Kuca[id][kPickup] = CreatePickup(1273, 1, Kuca[id][kUlazX], Kuca[id][kUlazY], Kuca[id][kUlazZ], 0);
        Kuca[id][kLabel] = Create3DTextLabel(labelStr, -1, Kuca[id][kUlazX], Kuca[id][kUlazY], Kuca[id][kUlazZ] + 0.5, 20.0, 0, 1);
    }
    else
    {
        new status[20];
        if(Kuca[id][kZakljucana] == 1) status = "{FF0000}Zakljucano";
        else status = "{00FF00}Otkjlucano";

        format(labelStr, sizeof(labelStr), "{0080FF}[ KUCA ]\n{FFFFFF}Vlasnik: {0080FF}%s\n{FFFFFF}Opis: %s\nStatus: %s", 
            Kuca[id][kVlasnik], Kuca[id][kOpis], status);
        
        Kuca[id][kPickup] = CreatePickup(1272, 1, Kuca[id][kUlazX], Kuca[id][kUlazY], Kuca[id][kUlazZ], 0);
        Kuca[id][kLabel] = Create3DTextLabel(labelStr, -1, Kuca[id][kUlazX], Kuca[id][kUlazY], Kuca[id][kUlazZ] + 0.5, 20.0, 0, 1);
    }
    return 1;
}

stock PostaviEnterijerKuce(playerid, tip)
{
    switch(tip)
    {
        case 1:
        {
            SetPlayerInterior(playerid, 2);
            SetPlayerPos(playerid, 225.756, 1021.423, 1084.017);
        }
        case 2:
        {
            SetPlayerInterior(playerid, 5);
            SetPlayerPos(playerid, 235.508, 1187.168, 1080.250); 
        }
        case 3:
        {
            SetPlayerInterior(playerid, 15);
            SetPlayerPos(playerid, 327.919, 1477.514, 1084.437);
        }
    }
    return 1;
}

stock PrikaziGlavniMeniKuce(playerid)
{
    new str[256], statusCena[32], statusLevel[32], statusTip[64];
    
    if(GetPVarInt(playerid, "HK_Cena") == 0) statusCena = "{FF0000}Nije uneto";
    else format(statusCena, 32, "{00FF00}%d$", GetPVarInt(playerid, "HK_Cena"));

    if(GetPVarInt(playerid, "HK_Level") == 0) statusLevel = "{FF0000}Nije uneto";
    else format(statusLevel, 32, "{00FF00}%d", GetPVarInt(playerid, "HK_Level"));

    if(GetPVarInt(playerid, "HK_Enterijer") == -1) statusTip = "{FF0000}Nije izabrano";
    else statusTip = "{00FF00}Izabrano";

    format(str, sizeof(str), "1) Cena: %s\n2) Level kuce: %s\n3) Tip i Enterijer: %s\n{FFFFFF}------------------\n{00FF00}>> NASTAVI SA KREIRANJEM <<", 
        statusCena, statusLevel, statusTip);

    SPD(playerid, HS_KREIRANJE_KUCE, DIALOG_STYLE_LIST, "Kreiranje Kuce (Admin)", str, "Izaberi", "Izadji");
    return 1;
}

stock FinalizujKreiranjeKuce(playerid)
{
    new kat = GetPVarInt(playerid, "HK_Tip_Kat");
    new entIdx = GetPVarInt(playerid, "HK_Enterijer");
    new cena = GetPVarInt(playerid, "HK_Cena");
    new level = GetPVarInt(playerid, "HK_Level");

    new Float:x, Float:y, Float:z, Float:ex, Float:ey, Float:ez, intID, imeEnt[50];
    GetPlayerPos(playerid, x, y, z);

    // Izvlačenje koordinata iz odgovarajućeg niza (onog iz definicije.pwn)
    if(kat == 1) { 
        ex = MaleKuce[entIdx][kiX]; ey = MaleKuce[entIdx][kiY]; ez = MaleKuce[entIdx][kiZ];
        intID = MaleKuce[entIdx][kiIntID]; format(imeEnt, 50, MaleKuce[entIdx][kiIme]);
    }
    else if(kat == 2) { 
        ex = SrednjeKuce[entIdx][kiX]; ey = SrednjeKuce[entIdx][kiY]; ez = SrednjeKuce[entIdx][kiZ];
        intID = SrednjeKuce[entIdx][kiIntID]; format(imeEnt, 50, SrednjeKuce[entIdx][kiIme]);
    }
    else { 
        ex = VelikeKuce[entIdx][kiX]; ey = VelikeKuce[entIdx][kiY]; ez = VelikeKuce[entIdx][kiZ];
        intID = VelikeKuce[entIdx][kiIntID]; format(imeEnt, 50, VelikeKuce[entIdx][kiIme]);
    }

    new query[1024];
    mysql_format(g_SQL, query, sizeof(query), 
        "INSERT INTO Kuce (tip, opis, ulazX, ulazY, ulazZ, izlazX, izlazY, izlazZ, cena, level, enterijer, virtualWorld) \
        VALUES (%d, '%e', %f, %f, %f, %f, %f, %f, %d, %d, %d, %d)", 
        kat, imeEnt, x, y, z, ex, ey, ez, cena, level, intID, (random(9000) + 100));

    mysql_tquery(g_SQL, query, "OnHouseCreated", "i", playerid);

    // Čišćenje memorije
    DeletePVar(playerid, "HK_Cena");
    DeletePVar(playerid, "HK_Level");
    DeletePVar(playerid, "HK_Enterijer");
    DeletePVar(playerid, "HK_Tip_Kat");
    
    return 1;
}

forward OnHouseCreated(playerid);
public OnHouseCreated(playerid)
{
    new id = -1;
    for(new i = 0; i < MAX_KUCA; i++) {
        if(Kuca[i][kId] == 0) { // Ako je ID 0, znači da je slot prazan
            id = i;
            break;
        }
    }

    if(id != -1)
    {
        Kuca[id][kId] = cache_insert_id();
        
        new query[128];
        mysql_format(g_SQL, query, sizeof(query), "SELECT * FROM Kuce WHERE id = %d", Kuca[id][kId]);
        mysql_tquery(g_SQL, query, "LoadSingleHouse", "i", id);
        
        SendClientMessage(playerid, 0x00FF00FF, "[ House System | Info ]: Kuca je uspesno kreirana i ucitana!");

        new string[128];
        format(string, sizeof(string), "ID: %d, Level: %d, Cena: %d, Tip: %d", Kuca[id][kId], Kuca[id][kLevel], Kuca[id][kCena], Kuca[id][kTip]);
        LogAdminAction(playerid, INVALID_PLAYER_ID, "Kuca kreirana (/kreirajkucu)", string);
    }
    else
    {
        SendClientMessage(playerid, -1, "{FF0000}[ House System | Greska ]: {FFFFFF}Nema vise slobodnih slotova u MAX_KUCA!");
    }
    return 1;
}

forward LoadSingleHouse(id);
public LoadSingleHouse(id)
{
    // Punimo niz podacima koje smo upravo dobili iz baze
    cache_get_value_name_int(0, "id", Kuca[id][kId]);
    cache_get_value_name(0, "vlasnik", Kuca[id][kVlasnik]);
    cache_get_value_name(0, "opis", Kuca[id][kOpis]);
    cache_get_value_name_float(0, "ulazX", Kuca[id][kUlazX]);
    cache_get_value_name_float(0, "ulazY", Kuca[id][kUlazY]);
    cache_get_value_name_float(0, "ulazZ", Kuca[id][kUlazZ]);
    cache_get_value_name_float(0, "izlazX", Kuca[id][kIzlazX]);
    cache_get_value_name_float(0, "izlazY", Kuca[id][kIzlazY]);
    cache_get_value_name_float(0, "izlazZ", Kuca[id][kIzlazZ]);
    cache_get_value_name_int(0, "cena", Kuca[id][kCena]);
    cache_get_value_name_int(0, "level", Kuca[id][kLevel]);
    cache_get_value_name_int(0, "enterijer", Kuca[id][kEnterijer]);
    cache_get_value_name_int(0, "virtualWorld", Kuca[id][kVW]);
    cache_get_value_name_int(0, "kupljena", Kuca[id][kKupljena]);
    cache_get_value_name_int(0, "zakljucana", Kuca[id][kZakljucana]);

    OsveziKucu(id); 
    return 1;
}

hook OnDialogResponse@House(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == HS_KREIRANJE_KUCE)
    {
        if(!response) {
            DeletePVar(playerid, "HK_Cena");
            DeletePVar(playerid, "HK_Level");
            DeletePVar(playerid, "HK_Enterijer");
            DeletePVar(playerid, "HK_Tip_Kat");
            return 1;
        }

        switch(listitem)
        {
            case 0: SPD(playerid, HS_K_CENA, DIALOG_STYLE_INPUT, "Kreiranje: Cena", "Unesite cenu kuce:", "Potvrdi", "Nazad");
            case 1: SPD(playerid, HS_K_LEVEL, DIALOG_STYLE_INPUT, "Kreiranje: Level", "Unesite potreban level:", "Potvrdi", "Nazad");
            case 2: SPD(playerid, HS_K_KAT, DIALOG_STYLE_LIST, "Kreiranje: Kategorija", "1. Male Kuce\n2. Srednje Kuce\n3. Velike Kuce", "Dalje", "Nazad");
            case 4: FinalizujKreiranjeKuce(playerid);
        }
        return 1;
    }

    // OVO TI JE FALILO DA BI SE CENA SACUVALA
    if(dialogid == HS_K_CENA)
    {
        if(!response) return PrikaziGlavniMeniKuce(playerid);
        if(isnull(inputtext) || strval(inputtext) <= 0) return SendClientMessage(playerid, -1, "Cena nije validna!"), PrikaziGlavniMeniKuce(playerid);
        
        SetPVarInt(playerid, "HK_Cena", strval(inputtext));
        return PrikaziGlavniMeniKuce(playerid);
    }

    // OVO TI JE FALILO DA BI SE LEVEL SACUVAO
    if(dialogid == HS_K_LEVEL)
    {
        if(!response) return PrikaziGlavniMeniKuce(playerid);
        if(isnull(inputtext) || strval(inputtext) <= 0) return SendClientMessage(playerid, -1, "Level nije validan!"), PrikaziGlavniMeniKuce(playerid);

        SetPVarInt(playerid, "HK_Level", strval(inputtext));
        return PrikaziGlavniMeniKuce(playerid);
    }

    if(dialogid == HS_K_KAT)
    {
        if(!response) return PrikaziGlavniMeniKuce(playerid);
        
        new listStr[1024];
        SetPVarInt(playerid, "HK_Tip_Kat", listitem + 1);

        if(listitem == 0) {
            for(new i = 0; i < sizeof(MaleKuce); i++) format(listStr, sizeof(listStr), "%s%s\n", listStr, MaleKuce[i][kiIme]);
            SPD(playerid, HS_K_ENT_IZBOR, DIALOG_STYLE_LIST, "Izaberi Malu Kucu", listStr, "Izaberi", "Nazad");
        }
        else if(listitem == 1) {
            for(new i = 0; i < sizeof(SrednjeKuce); i++) format(listStr, sizeof(listStr), "%s%s\n", listStr, SrednjeKuce[i][kiIme]);
            SPD(playerid, HS_K_ENT_IZBOR, DIALOG_STYLE_LIST, "Izaberi Srednju Kucu", listStr, "Izaberi", "Nazad");
        }
        else if(listitem == 2) {
            for(new i = 0; i < sizeof(VelikeKuce); i++) format(listStr, sizeof(listStr), "%s%s\n", listStr, VelikeKuce[i][kiIme]);
            SPD(playerid, HS_K_ENT_IZBOR, DIALOG_STYLE_LIST, "Izaberi Veliku Kucu", listStr, "Izaberi", "Nazad");
        }
        return 1;
    }

    if(dialogid == HS_K_ENT_IZBOR)
    {
        if(!response) return SPD(playerid, HS_K_KAT, DIALOG_STYLE_LIST, "Kreiranje: Kategorija", "1. Male Kuce\n2. Srednje Kuce\n3. Velike Kuce", "Dalje", "Nazad");
        
        SetPVarInt(playerid, "HK_Enterijer", listitem);
        PrikaziGlavniMeniKuce(playerid);
        return 1;
    }

    return 0;
}

CMD:kreirajkucu(playerid, params[])
{
    if(!AdminProvera(playerid, 5)) return 1;
    if(!ProveriAdminDuznost(playerid)) return 1;

    SetPVarInt(playerid, "HK_Cena", 0);
    SetPVarInt(playerid, "HK_Level", 0);
    SetPVarInt(playerid, "HK_Tip", 0);
    SetPVarInt(playerid, "HK_Enterijer", -1);

    PrikaziGlavniMeniKuce(playerid);
    return 1;
}

CMD:obrisikucu(playerid, params[])
{
    if(!AdminProvera(playerid, 5)) return 1;
    if(!ProveriAdminDuznost(playerid)) return 1;

    new id = -1;
    for(new i = 0; i < MAX_KUCA; i++)
    {
        if(Kuca[i][kId] != 0)
        {
            if(IsPlayerInRangeOfPoint(playerid, 3.0, Kuca[i][kUlazX], Kuca[i][kUlazY], Kuca[i][kUlazZ]))
            {
                id = i;
                break;
            }
        }
    }

    if(id == -1) return SendClientMessage(playerid, -1, "{FF0000}[ House System | Greska ]: {FFFFFF}Morate biti pored ulaza u neku kucu!");

    new query[128];
    mysql_format(g_SQL, query, sizeof(query), "DELETE FROM Kuce WHERE id = %d", Kuca[id][kId]);
    mysql_tquery(g_SQL, query);

    if(Kuca[id][kLabel] != Text3D:INVALID_3DTEXT_ID) Delete3DTextLabel(Kuca[id][kLabel]);
    if(Kuca[id][kPickup] != -1) DestroyPickup(Kuca[id][kPickup]);

    Kuca[id][kId] = 0;
    Kuca[id][kVlasnik][0] = '\0';
    Kuca[id][kOpis][0] = '\0';
    Kuca[id][kLabel] = Text3D:INVALID_3DTEXT_ID;
    Kuca[id][kPickup] = -1;
    Kuca[id][kKupljena] = 0;

    new string[128];
    format(string, sizeof(string), "ID Kuce: %d", Kuca[id][kId]);

    SendClientMessage(playerid, 0x00FF00FF, "[ House System | Admin Log ]: Kuca je uspesno obrisana iz baze i sa servera.");
    LogAdminAction(playerid, INVALID_PLAYER_ID, "Obrisana kuca (/obrisikucu)", string);
    return 1;
}

CMD:gotokuca(playerid, params[])
{
    if(!AdminProvera(playerid, 1)) return 1;
    if(!ProveriAdminDuznost(playerid)) return 1;

    new houseid;
    if(sscanf(params, "i", houseid)) return SendClientMessage(playerid, -1, "{FF0000}[Koriscenje]: {FFFFFF}/gotokuca [ID Kuce]");

    if(houseid < 0 || houseid >= MAX_KUCA || Kuca[houseid][kId] == 0) return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Ta kuca ne postoji (pogresan ID)!");

    SetPlayerPos(playerid, Kuca[houseid][kUlazX], Kuca[houseid][kUlazY], Kuca[houseid][kUlazZ]);
    SetPlayerVirtualWorld(playerid, 0);
    SetPlayerInterior(playerid, 0);

    new msg[128];
    format(msg, sizeof(msg), "{00FF00}[Admin]: {FFFFFF}Teleportovani ste do kuce ID: %d (Vlasnik: %s).", houseid, Kuca[houseid][kVlasnik]);
    SendClientMessage(playerid, -1, msg);
    return 1;
}