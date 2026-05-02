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
    kRacunVreme,
    kImaSef,
    kSefNovac,
    kSefDroga,
    kSefOruzje
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
    {"Jeftina Garsonjera", 1, 223.19, 1287.08, 1082.14}, // Mala prikolica
    {"Drvena Koliba", 2, 225.53, 1021.42, 1084.01}      // Whitewood kuca
};

new SrednjeKuce[][kuca_interijer_data] = {
    {"Porodicni Dom", 5, 235.50, 1187.16, 1080.25},     // CJ-eva kuca stil
    {"Momacka Gajba", 10, 2262.83, -1137.71, 1050.63}   // Lowrider kuca
};

new VelikeKuce[][kuca_interijer_data] = {
    {"Vila Richman", 15, 327.91, 1477.51, 1084.43},     // Velika vila
    {"Moderni Dvorac", 7, 225.63, 1022.47, 1084.01}     // Madd Dogg vila stil
};

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

stock SacuvajKucu(id)
{
    if(id == -1 || Kuca[id][kId] == 0) return 0;

    new query[1024]; // 1024 je sasvim dovoljno
    mysql_format(g_SQL, query, sizeof(query), 
        "UPDATE `Kuce` SET `vlasnik`='%e', `opis`='%e', `cena`=%d, `level`=%d, `kupljena`=%d, `zakljucana`=%d, `racunVreme`=%d, `virtualWorld`=%d, `imaSef`=%d, `sefNovac`=%d, `sefDroga`=%d, `sefOruzje`=%d WHERE `id`=%d",
        Kuca[id][kVlasnik],
        Kuca[id][kOpis],
        Kuca[id][kCena],
        Kuca[id][kLevel],
        Kuca[id][kKupljena],
        Kuca[id][kZakljucana],
        Kuca[id][kRacunVreme],
        Kuca[id][kVW],
        Kuca[id][kImaSef],
        Kuca[id][kSefNovac],
        Kuca[id][kSefDroga],
        Kuca[id][kSefOruzje],
        Kuca[id][kId]
    );

    // Koristimo sinhroni upit (mysql_query) samo za ovaj test da vidimo gresku odmah
    mysql_query(g_SQL, query); 
    
    if(mysql_errno(g_SQL) != 0)
    {
        new error[200];
        mysql_error(error, sizeof(error), g_SQL);
        printf("!!! MySQL GRESKA kod kuce ID %d: %s", Kuca[id][kId], error);
    }
    else
    {
        printf(">>> Kuca ID %d uspesno sacuvana. (Novac: %d)", Kuca[id][kId], Kuca[id][kSefNovac]);
    }
    return 1;
}

forward PronadjiVlasnikaKuce(playerid);
stock PronadjiVlasnikaKuce(playerid)
{
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));

    for(new i = 0; i < MAX_KUCA; i++)
    {
        if(Kuca[i][kId] != 0 && strcmp(Kuca[i][kVlasnik], name, true) == 0)
        {
            return i; // Vracamo index kuce
        }
    }
    return -1; // Nije pronadjena kuca
}

forward LoadHouses();
public LoadHouses()
{
    new rows = cache_num_rows();
    if(rows == 0) return printf("[ House System | Info ]: Nema kuca u bazi podataka.");

    for(new i = 0; i < rows; i++)
    {
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
        cache_get_value_name_int(i, "imaSef", Kuca[i][kImaSef]);
        cache_get_value_name_int(i, "sefNovac", Kuca[i][kSefNovac]);
        cache_get_value_name_int(i, "sefDroga", Kuca[i][kSefDroga]);
        cache_get_value_name_int(i, "sefOruzje", Kuca[i][kSefOruzje]);
        OsveziKucu(i);
    }
    printf("[ House System | Info ]: Uspesno ucitano %d kuca iz baze.", rows);
    return 1;
}

stock OsveziKucu(id)
{
    // 1. KORISTIMO STREAMER FUNKCIJE ZA BRISANJE
    if(Kuca[id][kLabel] != Text3D:INVALID_3DTEXT_ID) 
    {
        DestroyDynamic3DTextLabel(Kuca[id][kLabel]);
        Kuca[id][kLabel] = Text3D:INVALID_3DTEXT_ID;
    }
    
    if(Kuca[id][kPickup] != -1) 
    {
        DestroyDynamicPickup(Kuca[id][kPickup]);
        Kuca[id][kPickup] = -1;
    }

    new labelStr[256];

    if(Kuca[id][kKupljena] == 0)
    {
        format(labelStr, sizeof(labelStr), "{00FF00}[ KUCA NA PRODAJU ]\nID: %d\n{FFFFFF}Opis: %s\nCena: {00FF00}%d$\n{FFFFFF}Level: %d\nKoristite /kupikucu", 
            Kuca[id][kId], Kuca[id][kOpis], Kuca[id][kCena], Kuca[id][kLevel]);
        
        // 2. KORISTIMO DYNAMIC VERZIJE ZA KREIRANJE
        Kuca[id][kPickup] = CreateDynamicPickup(1273, 1, Kuca[id][kUlazX], Kuca[id][kUlazY], Kuca[id][kUlazZ], 0, 0); // (Model, Tip, X, Y, Z, VW, Interior)
        Kuca[id][kLabel] = CreateDynamic3DTextLabel(labelStr, -1, Kuca[id][kUlazX], Kuca[id][kUlazY], Kuca[id][kUlazZ] + 0.5, 20.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0);
    }
    else
    {
        new status[20];
        if(Kuca[id][kZakljucana] == 1) status = "{FF0000}Zakljucano";
        else status = "{00FF00}Otkjlucano";

        format(labelStr, sizeof(labelStr), "{0080FF}[ KUCA ]\nID: %d\n{FFFFFF}Vlasnik: {0080FF}%s\n{FFFFFF}Opis: %s\nStatus: %s", 
            Kuca[id][kId], Kuca[id][kVlasnik], Kuca[id][kOpis], status);
        
        Kuca[id][kPickup] = CreateDynamicPickup(1272, 1, Kuca[id][kUlazX], Kuca[id][kUlazY], Kuca[id][kUlazZ], 0, 0);
        Kuca[id][kLabel] = CreateDynamic3DTextLabel(labelStr, -1, Kuca[id][kUlazX], Kuca[id][kUlazY], Kuca[id][kUlazZ] + 0.5, 20.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0);
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

    format(str, sizeof(str), "1) Cena: %s\n2) Level kuce: %s\n3) Tip i Enterijer: %s\n{FFFFFF}------------------\n{00FF00}>> ZAVRSI SA KREIRANJEM <<", 
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

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if(newkeys & KEY_SECONDARY_ATTACK) // Taster F ili Enter
    {
        if(GetPlayerInterior(playerid) == 0) // Ako je napolju, pokusaj ulaz
        {
            cmd_enter(playerid, "");
        }
        else // Ako je unutra, pokusaj izlaz
        {
            cmd_exit(playerid, "");
        }
    }
    return 1;
}

forward OnHouseCreated(playerid);
public OnHouseCreated(playerid)
{
    new id = -1;
    for(new i = 0; i < MAX_KUCA; i++) {
        if(Kuca[i][kId] == 0) { 
            id = i;
            break;
        }
    }

    if(id != -1)
    {
        Kuca[id][kId] = cache_insert_id();
        
        // Debug: Proveri da li dobijas validan ID
        printf("DEBUG: Kuca kreirana. DB ID: %d dodeljen slotu: %d", Kuca[id][kId], id);

        new query[128];
        mysql_format(g_SQL, query, sizeof(query), "SELECT * FROM Kuce WHERE id = %d", Kuca[id][kId]);
        
        mysql_tquery(g_SQL, query, "LoadSingleHouse", "i", id);
        
        SendClientMessage(playerid, 0x00FF00FF, "[ House System ]: Kuca je uspesno kreirana!");
    }
    else
    {
        SendClientMessage(playerid, -1, "{FF0000}[ House System ]: Nema slobodnih slotova!");
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

forward UnfreezePlayer(playerid);
public UnfreezePlayer(playerid)
{
    TogglePlayerControllable(playerid, true);
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
            case 3: return PrikaziGlavniMeniKuce(playerid);
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

    if(dialogid == HS_KUCA_MENU)
    {
        if(!response) return 1;

        new house_idx = PronadjiVlasnikaKuce(playerid);
        if(house_idx == -1) return SendClientMessage(playerid, ERROR_BOJA, "{FF0000}[ House System | Greska ]: {FFFFFF}Niste vlasnik kuce!");

        switch(listitem)
        {
            case 0: // 1) Informacije o kuci
            {
                new string[512];
                format(string, sizeof(string), 
                    "{0080FF}ID: {FFFFFF}%d\n{0080FF}Cena: {FFFFFF}%d$\n{0080FF}Level: {FFFFFF}%d\n{0080FF}Status: %s\n{0080FF}Racun: {FFFFFF}%dh", 
                    Kuca[house_idx][kId], Kuca[house_idx][kCena], Kuca[house_idx][kLevel], 
                    Kuca[house_idx][kZakljucana] ? ("{FF0000}Zakljucana") : ("{00FF00}Otkljucana"),
                    Kuca[house_idx][kRacunVreme]);

                SPD(playerid, HS_KUCA_INFO, DIALOG_STYLE_MSGBOX, "Informacije", string, "U redu", "");
            }
            case 1: // 2) Zakljucaj/Otkljucaj
            {
                Kuca[house_idx][kZakljucana] = !Kuca[house_idx][kZakljucana];
                OsveziKucu(house_idx);
                SacuvajKucu(house_idx);

                if(Kuca[house_idx][kZakljucana]) SendClientMessage(playerid, -1, "{FF0000}[ House System | Info ]: {FFFFFF}Zakljucali ste kucu.");
                else SendClientMessage(playerid, -1, "{00FF00}[ House System | Info ]: {FFFFFF}Otkljucali ste kucu.");
            }
            case 2: // 3) Renta informacije
            {
                // Ovde mozes dodati dijalog za podesavanje cene rente 
                // ili listu stanara ako planiras sistem sa vise ljudi
                SendClientMessage(playerid, -1, "{0080FF}[Renta]: {FFFFFF}Sistem rente je u izradi.");
            }
            case 3: // 4) Prodaj kucu
            {
                // Ovde pozivas novi dijalog za potvrdu prodaje
                new str[128];
                new prodajnaCena = Kuca[house_idx][kCena] / 2; // Prodaje kucu drzavi za 50% cene, dodati kasnije da moze da se proda i drugom igracu
                format(str, sizeof(str), "{FFFFFF}Da li ste sigurni da zelite da prodate kucu drzavi za {00FF00}%d$?", prodajnaCena);
                
                SPD(playerid, HS_KUCA_PRODAJA, DIALOG_STYLE_MSGBOX, "Prodaja Kuce", str, "Prodaj", "Odustani");
            }
            case 4: // 5) Informacije o sefu ukoliko postoji
            {
                if(Kuca[house_idx][kImaSef] == 0) return SendClientMessage(playerid, -1, "Ova kuca nema sef!");
                new info[128];
                format(info, sizeof(info), "Novac: %d$\nDroga: %dg\nOruzije: %d", Kuca[house_idx][kSefNovac], Kuca[house_idx][kSefDroga], Kuca[house_idx][kSefOruzje]);
                SPD(playerid, HS_KUCA_SEF, DIALOG_STYLE_LIST, "Kucni Sef", "Ostavi novac\nUzmi novac\nOstavi drogu\nUzmi drogu\nOstavi oruzije\nUzmi oruzije", "Izaberi", "Nazad");
            }
        }
        return 1;
    }
    if(dialogid == HS_KUCA_PRODAJA)
    {
        if(!response) return 1;

        new house_idx = PronadjiVlasnikaKuce(playerid);

        new cenaPovrat = Kuca[house_idx][kCena] / 2;
        BankovniRacun[playerid][bNovac] += cenaPovrat;

        // Reset podataka
        format(Kuca[house_idx][kVlasnik], 24, "Niko");
        Kuca[house_idx][kKupljena] = 0;
        Kuca[house_idx][kZakljucana] = 0;
        Kuca[house_idx][kRacunVreme] = 0;

        SacuvajKucu(house_idx); // Tvoja funkcija sve upisuje u bazu
        OsveziKucu(house_idx); // Menja label u "Na prodaju" i menja pickup

        SendClientMessage(playerid, -1, "{00FF00}[ House System | Info ]: {FFFFFF}Uspesno ste prodali kucu drzavi.");
        SacuvajIgraca(playerid);
        return 1;
    }
    if(dialogid == HS_KUCA_SEF)
    {
        if(!response) return 1;
        new house_idx = PronadjiVlasnikaKuce(playerid);
        if(house_idx == -1) return 1;

        switch(listitem)
        {
            case 0: // Ostavi novac
                SPD(playerid, HS_KUCA_SEF_NOVAC_O, DIALOG_STYLE_INPUT, "Sef | Ostavi novac", "Unesite kolicinu novca koju zelite da OSTAVITE u sef:", "Ostavi", "Nazad");
            case 1: // Uzmi novac
                SPD(playerid, HS_KUCA_SEF_NOVAC_U, DIALOG_STYLE_INPUT, "Sef | Uzmi novac", "Unesite kolicinu novca koju zelite da UZMETE iz sefa:", "Uzmi", "Nazad");
            // case 2 i 3 bi bili za drogu...
        }
    }
    // --- OSTAVLJANJE NOVCA U SEF ---
    if(dialogid == HS_KUCA_SEF_NOVAC_O)
    {
        if(!response) return 1; // Ako klikne nazad
        new kolicina = strval(inputtext);
        new house_idx = PronadjiVlasnikaKuce(playerid);

        if(kolicina <= 0 || kolicina > 10000000) return SendClientMessage(playerid, -1, "Nevazeca kolicina!");
        
        if(GetPlayerMoney(playerid) < kolicina) 
            return SendClientMessage(playerid, ERROR_BOJA, "Nemate toliko novca kod sebe!");

        // Transakcija
        GivePlayerMoney(playerid, -kolicina);
        Kuca[house_idx][kSefNovac] += kolicina;

        // Cuvanje
        SacuvajKucu(house_idx);
        SacuvajIgraca(playerid);

        new str[128];
        format(str, sizeof(str), "Ostavili ste $%d u sef. Novo stanje: $%d", kolicina, Kuca[house_idx][kSefNovac]);
        SendClientMessage(playerid, 0x00FF00FF, str);
        printf("DEBUG: Pokusavam sacuvati kucu index: %d | SQL ID: %d | Novac: %d", house_idx, Kuca[house_idx][kId], Kuca[house_idx][kSefNovac]);
        return 1;
    }

    // --- UZIMANJE NOVCA ---
    if(dialogid == HS_KUCA_SEF_NOVAC_U)
    {
        if(!response) return 1;
        new kolicina = strval(inputtext);
        new house_idx = PronadjiVlasnikaKuce(playerid);

        if(kolicina <= 0) return SendClientMessage(playerid, -1, "Nevazeca kolicina!");
        
        // Provera da li ima toliko para u sefu
        if(Kuca[house_idx][kSefNovac] < kolicina) 
            return SendClientMessage(playerid, -1, "U sefu nema toliko novca!");

        // Transakcija
        Kuca[house_idx][kSefNovac] -= kolicina;
        GivePlayerMoney(playerid, kolicina);

        // Cuvanje
        SacuvajKucu(house_idx);
        SacuvajIgraca(playerid);

        new str[128];
        format(str, sizeof(str), "Uzeli ste $%d iz sefa.", kolicina);
        SendClientMessage(playerid, 0x00FF00FF, str);
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

    if(id == -1) return SendClientMessage(playerid, ERROR_BOJA, "{FF0000}[ House System | Admin ]: {FFFFFF}Morate biti pored ulaza u kucu!");
    if(strcmp(Kuca[id][kVlasnik], "Niko") != 0) 
        return SendClientMessage(playerid, ERROR_BOJA, "{FF0000}[ House System | Admin ]: {FFFFFF}Ne mozete obrisati kucu koja ima vlasnika!");

    new string[128], dbID = Kuca[id][kId];
    format(string, sizeof(string), "SQL ID: %d | Vlasnik: %s", dbID, Kuca[id][kVlasnik]);

    new query[128];
    mysql_format(g_SQL, query, sizeof(query), "DELETE FROM Kuce WHERE id = %d", dbID);
    mysql_tquery(g_SQL, query);

    if(Kuca[id][kLabel] != Text3D:INVALID_3DTEXT_ID) 
        DestroyDynamic3DTextLabel(Kuca[id][kLabel]);

    if(Kuca[id][kPickup] != -1) 
        DestroyDynamicPickup(Kuca[id][kPickup]);

    Kuca[id][kId] = 0;
    Kuca[id][kLabel] = Text3D:INVALID_3DTEXT_ID;
    Kuca[id][kPickup] = -1;
    Kuca[id][kVlasnik][0] = '\0';
    Kuca[id][kOpis][0] = '\0';

    SendClientMessage(playerid, ADMIN_BOJA, "[ House System | Admin]: Kuca je uspesno obrisana.");
    LogAdminAction(playerid, INVALID_PLAYER_ID, "Obrisana kuca (/obrisikucu)", string);
    return 1;
}

CMD:gotokuca(playerid, params[])
{
    if(!AdminProvera(playerid, 1)) return 1;
    if(!ProveriAdminDuznost(playerid)) return 1;

    new targetID;
    if(sscanf(params, "i", targetID)) return SendClientMessage(playerid, ADMIN_BOJA, "{FF0000}[ House System | Admin ]: {FFFFFF}/gotokuca [ID Kuce]");

    new house_idx = -1;

    for(new i = 0; i < MAX_KUCA; i++)
    {
        if(Kuca[i][kId] == targetID)
        {
            house_idx = i;
            break;
        }
    }

    if(house_idx == -1) 
        return SendClientMessage(playerid, ERROR_BOJA, "{FF0000}[ House System | Admin ]: {FFFFFF}Kuca sa tim SQL ID-om nije ucitana ili ne postoji!");

    SetPlayerPos(playerid, Kuca[house_idx][kUlazX], Kuca[house_idx][kUlazY], Kuca[house_idx][kUlazZ]);
    SetPlayerVirtualWorld(playerid, 0);
    SetPlayerInterior(playerid, 0);

    new msg[128];
    format(msg, sizeof(msg), "{00FF00}[ House System | Admin ]: {FFFFFF}Teleportovani ste do kuce ID: %d (Vlasnik: %s).", targetID, Kuca[house_idx][kVlasnik]);
    SendClientMessage(playerid, ADMIN_BOJA, msg);
    return 1;
}

CMD:kupikucu(playerid, params[])
{
    new house_idx = -1;

    for(new i = 0; i < MAX_KUCA; i++)
    {
        if(Kuca[i][kId] != 0 && IsPlayerInRangeOfPoint(playerid, 3.0, Kuca[i][kUlazX], Kuca[i][kUlazY], Kuca[i][kUlazZ]))
        {
            house_idx = i;
            break;
        }
    }

    if(house_idx == -1) 
        return SendClientMessage(playerid, ERROR_BOJA, "{FF0000}[ House System | Greska ]: {FFFFFF}Niste blizu ulaza u kucu!");

    new cena = Kuca[house_idx][kCena];

    if(Kuca[house_idx][kKupljena] == 1) 
        return SendClientMessage(playerid, ERROR_BOJA, "{FF0000}[ House System | Greska ]: {FFFFFF}Ova kuca je vec prodata!");
    
    if(Igrac[playerid][Level] < Kuca[house_idx][kLevel]) 
        return SendClientMessage(playerid, ERROR_BOJA, "{FF0000}[ House System | Greska ]: {FFFFFF}Nemate potreban level da kupite ovu kucu!");
    
    if(BankovniRacun[playerid][bNovac] < cena) 
        return SendClientMessage(playerid, ERROR_BOJA, "{FF0000}[ House System | Greska ]: {FFFFFF}Nemate dovoljno novca na bankovnom racunu!");

    if(PronadjiVlasnikaKuce(playerid) != -1) 
        return SendClientMessage(playerid, ERROR_BOJA, "{FF0000}[ House System | Greska ]: {FFFFFF}Vec posedujete kucu!");

    BankovniRacun[playerid][bNovac] -= cena;

    GetPlayerName(playerid, Kuca[house_idx][kVlasnik], 24);
    Kuca[house_idx][kKupljena] = 1;
    Kuca[house_idx][kRacunVreme] = 24; 

    new query[256];
    mysql_format(g_SQL, query, sizeof(query), 
        "UPDATE Kuce SET vlasnik = '%e', kupljena = 1, racunVreme = 24 WHERE id = %d", 
        Kuca[house_idx][kVlasnik], Kuca[house_idx][kId]);
    mysql_tquery(g_SQL, query);

    OsveziKucu(house_idx);

    new msg[128];
    format(msg, sizeof(msg), "{00FF00}[ House System | Info ]: {FFFFFF}Cestitamo! Kupili ste kucu ID: %d za $%d.", Kuca[house_idx][kId], cena);
    SendClientMessage(playerid, -1, msg);

    SacuvajIgraca(playerid);
    SacuvajBanku(playerid);
    SacuvajKucu(house_idx);
    return 1;
}

CMD:kuca(playerid, params[])
{
    new house_idx = PronadjiVlasnikaKuce(playerid);

    if(house_idx == -1) 
        return SendClientMessage(playerid, -1, "{FF0000}[ House System | Greska ]: {FFFFFF}Niste vlasnik kuce!");

    if(!IsPlayerInRangeOfPoint(playerid, 5.0, Kuca[house_idx][kUlazX], Kuca[house_idx][kUlazY], Kuca[house_idx][kUlazZ]) || !IsPlayerInRangeOfPoint(playerid, 50.0, Kuca[house_idx][kIzlazX], Kuca[house_idx][kIzlazY], Kuca[house_idx][kIzlazZ]))
        return SendClientMessage(playerid, -1, "{FF0000}[ House System | Greska ]: {FFFFFF}Morate biti blizu svoje kuce ili u kuci da biste koristili meni!");

    new menuStr[64], str[256];
    format(menuStr, sizeof(menuStr), "{0080FF}Menu kuce ID: %d", Kuca[house_idx][kId]);
    format(str, sizeof(str), "1) Informacije o kuci\n2) Zakljucaj/Otkljucaj\n3) Renta informacije\n4) Prodaj kucu");
    
    if(Kuca[house_idx][kImaSef] == 1) format(str, sizeof(str), "%s\n5) Sef", str);

    SPD(playerid, HS_KUCA_MENU, DIALOG_STYLE_LIST, menuStr, str, "Izaberi", "Zatvori");
    return 1;
}

CMD:kupisef(playerid, params[])
{
    new house_idx = PronadjiVlasnikaKuce(playerid);

    if(house_idx == -1) 
        return SendClientMessage(playerid, ERROR_BOJA, "{FF0000}[ House System | Greska ]: {FFFFFF}Niste vlasnik kuce!");

    if(Kuca[house_idx][kImaSef] == 1) 
        return SendClientMessage(playerid, ERROR_BOJA, "{FF0000}[ House System | Greska ]: {FFFFFF}Vec imate sef u kuci!");

    if(BankovniRacun[playerid][bNovac] < 1000) 
        return SendClientMessage(playerid, ERROR_BOJA, "{FF0000}[ House System | Greska ]: {FFFFFF}Nemate dovoljno novca na bankovnom racunu da kupite sef! Cena sefa je 1000$.");

    Kuca[house_idx][kImaSef] = 1;
    BankovniRacun[playerid][bNovac] -= 1000; // Cena sefa

    new query[128];
    mysql_format(g_SQL, query, sizeof(query), "UPDATE Kuce SET imaSef = 1 WHERE id = %d", Kuca[house_idx][kId]);
    mysql_tquery(g_SQL, query);

    OsveziKucu(house_idx);
    SendClientMessage(playerid, 0x00FF00FF, "{00FF00}[ House System | Info ]: Uspesno ste kupili sef za vasu kucu!");
    SacuvajKucu(house_idx);
    SacuvajIgraca(playerid);
    return 1;
}

CMD:enter(playerid, params[])
{
    for(new i = 0; i < MAX_KUCA; i++)
    {
        if(Kuca[i][kId] != 0) // Ako kuca postoji
        {
            if(IsPlayerInRangeOfPoint(playerid, 3.0, Kuca[i][kUlazX], Kuca[i][kUlazY], Kuca[i][kUlazZ]))
            {
                if(Kuca[i][kZakljucana] == 1) 
                    return SendClientMessage(playerid, ERROR_BOJA, "{FF0000}[ House System | Greska ]: {FFFFFF}Ova kuca je zakljucana!");

                // Teleportacija unutra
                SetPlayerPos(playerid, Kuca[i][kIzlazX], Kuca[i][kIzlazY], Kuca[i][kIzlazZ]);
                SetPlayerInterior(playerid, Kuca[i][kEnterijer]);
                SetPlayerVirtualWorld(playerid, Kuca[i][kVW]);
                TogglePlayerControllable(playerid, false);
                SetTimerEx("UnfreezePlayer", 1000, false, "i", playerid);
                
                SetPVarInt(playerid, "U_KUCI", i); // Pamtimo u kojoj je kuci igrac
                return 1;
            }
        }
    }
    return 1;
}

CMD:exit(playerid, params[])
{
    new i = GetPVarInt(playerid, "U_KUCI"); // Uzimamo ID kuce u kojoj je igrac
    
    if(IsPlayerInRangeOfPoint(playerid, 3.0, Kuca[i][kIzlazX], Kuca[i][kIzlazY], Kuca[i][kIzlazZ]))
    {
        SetPlayerPos(playerid, Kuca[i][kUlazX], Kuca[i][kUlazY], Kuca[i][kUlazZ]);
        SetPlayerInterior(playerid, 0); // Vracamo na spoljni svet
        SetPlayerVirtualWorld(playerid, 0);
        
        DeletePVar(playerid, "U_KUCI"); // Brisemo podatak da je unutra
    }
    return 1;
}