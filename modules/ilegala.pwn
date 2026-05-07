
// --- Definisanje ---
#define MAX_DILERA          50
#define D_ADILER_MAIN       5556
#define D_ILEGALA_MENU      5557
#define VREME_PROMENE       30 // 30 minuta

#define CENA_SEME_MARIHUANE     250
#define CENA_ZIP_KESICA         50
#define CENA_PAJSER             1200

#define ITEM_SEME_MARIHUANE     "Seme Marihuane"
#define ITEM_ZIP_KESICA         "Zip Kesica"
#define ITEM_PAJSER             "Pajser"

#define MAX_DOUSNIKA 10
#define CENA_INFORMACIJE 200

enum dousnikData {
    dID,
    Float: dX,
    Float: dY,
    Float: dZ,
    dActor,
    bool: dPostavljen
};

new DousnikInfo[MAX_DOUSNIKA][dousnikData];

enum ilegalaData {
    iID,
    Float: iX,
    Float: iY,
    Float: iZ,
    Float: iR,
    bool: iPostavljen // Pomocna varijabla da znamo da li je slot zauzet u memoriji
};

new IlegalaInfo[MAX_DILERA][ilegalaData];
new AktivniDilerActor = -1;
new Text3D:AktivniDilerLabel = Text3D:INVALID_3DTEXT_ID;
new TrenutnaLokacijaID = -1;
new bool:DilerSistemAktivan = true;
new Zaliha_Seme, Zaliha_Zip, Zaliha_Pajser;
new RobaNaPopustu = -1; // -1: nema popusta, 0: seme, 1: zip, 2: pajser

// --- Hookovi ---

forward UcitajIlegaluSistem();
public UcitajIlegaluSistem()
{
    print("[Ilegala System] Ucitavanje potencijalnih lokacija...");
    mysql_tquery(g_SQL, "SELECT * FROM Ilegala", "UcitajSveDilere");

    mysql_tquery(g_SQL, "SELECT * FROM Dousnici", "UcitajSveDousnike");
    
    // Tajmer koji svakih 30 minuta menja poziciju
    SetTimer("PromeniLokacijuDilera", VREME_PROMENE*60*1000, true);
    return 1;
}
    
// --- Komande ---

CMD:adiler(playerid, params[])
{
    if(!AdminProvera(playerid, 5)) return 1;

    new menuStr[256];
    format(menuStr, sizeof(menuStr), "Opcija\tStatus\n\
        Dodaj novu lokaciju (ovde)\t{00FF00}>\n\
        Status Sistema\t%s\n\
        Obrisi trenutnog NPC-a (sa mape)\t{FF0000}X", 
        (DilerSistemAktivan ? ("{00FF00}AKTIVAN") : ("{FF0000}STOPIRAN")));

    SPD(playerid, D_ADILER_MAIN, DIALOG_STYLE_TABLIST_HEADERS, "Admin Ilegala - Control", menuStr, "Izaberi", "Izlaz");
    return 1;
}

CMD:ilegala(playerid, params[])
{
    if(!DilerSistemAktivan || TrenutnaLokacijaID == -1) 
        return SendClientMessage(playerid, -1, "{FF0000}[Ilegala]: {FFFFFF}Diler trenutno nije dostupan.");

    if(!IsPlayerInRangeOfPoint(playerid, 3.0, IlegalaInfo[TrenutnaLokacijaID][iX], IlegalaInfo[TrenutnaLokacijaID][iY], IlegalaInfo[TrenutnaLokacijaID][iZ]))
        return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Nisi blizu dilera!");

    new menuStr[600], pStr[3][64];
    
    // Logika za prikaz popusta (npr. 20% popusta)
    for(new i = 0; i < 3; i++) {
        if(RobaNaPopustu == i) format(pStr[i], 64, "{FFFF00}(POPUST!) ");
        else format(pStr[i], 64, "");
    }

    format(menuStr, sizeof(menuStr), 
        "Artikal\tCena\tZaliha\n\
        %s%s\t{00FF00}$%d\t%d\n\
        %s%s\t{00FF00}$%d\t%d\n\
        %s%s\t{00FF00}$%d\t%d",
        pStr[0], ITEM_SEME_MARIHUANE, (RobaNaPopustu == 0 ? floatround(CENA_SEME_MARIHUANE * 0.8) : CENA_SEME_MARIHUANE), Zaliha_Seme,
        pStr[1], ITEM_ZIP_KESICA, (RobaNaPopustu == 1 ? floatround(CENA_ZIP_KESICA * 0.8) : CENA_ZIP_KESICA), Zaliha_Zip,
        pStr[2], ITEM_PAJSER, (RobaNaPopustu == 2 ? floatround(CENA_PAJSER * 0.8) : CENA_PAJSER), Zaliha_Pajser
    );

    SPD(playerid, D_ILEGALA_MENU, DIALOG_STYLE_TABLIST_HEADERS, "Crno Trziste", menuStr, "Kupi", "Izlaz");
    return 1;
}

CMD:kreirajdousnika(playerid, params[])
{
    if(!AdminProvera(playerid, 5)) return 1;

    new Float:x, Float:y, Float:z, Float:a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);

    new query[256];
    mysql_format(g_SQL, query, sizeof(query), "INSERT INTO Dousnici (posX, posY, posZ, angle) VALUES ('%f', '%f', '%f', '%f')", x, y, z, a);
    mysql_tquery(g_SQL, query, "OnDousnikDodat", "i", playerid);
    return 1;
}

CMD:dousnik(playerid, params[])
{
    new blizuID = -1;
    // Trazimo da li je igrac blizu bilo kog dousnika
    for(new i = 0; i < MAX_DOUSNIKA; i++)
    {
        if(DousnikInfo[i][dPostavljen] && IsPlayerInRangeOfPoint(playerid, 3.0, DousnikInfo[i][dX], DousnikInfo[i][dY], DousnikInfo[i][dZ]))
        {
            blizuID = i;
            break;
        }
    }

    if(blizuID == -1) 
        return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Nisi blizu nijednog dousnika!");

    if(GetPlayerMoney(playerid) < CENA_INFORMACIJE)
    {
        new greskaStr[64];
        format(greskaStr, sizeof(greskaStr), "{FF0000}[Dousnik]: {FFFFFF}Informacija kosta $%d, gubi se!", CENA_INFORMACIJE);
        return SendClientMessage(playerid, -1, greskaStr);
    }

    if(TrenutnaLokacijaID == -1 || !DilerSistemAktivan)
        return SendClientMessage(playerid, -1, "{FF0000}[Dousnik]: {FFFFFF}Cujem da je diler pao ili je pobegao iz grada. Nema informacija.");

    // Uzimamo novac igracu
    GivePlayerMoney(playerid, -CENA_INFORMACIJE);

    // Odredjivanje imena artikla koji je na popustu
    new artikalPopust[32];
    switch(RobaNaPopustu) {
        case 0: artikalPopust = ITEM_SEME_MARIHUANE;
        case 1: artikalPopust = ITEM_ZIP_KESICA;
        case 2: artikalPopust = ITEM_PAJSER;
        default: artikalPopust = "Nema nista";
    }

    // Poruke igracu
    SendClientMessage(playerid, -1, "{FFFF00}[Dousnik]: {FFFFFF}Slusaj pazljivo, necu ponavljati...");
    
    new msg[144];
    // Hint preko koordinata (zaokruzeno na jednu decimalu radi lakseg snalazenja na mapi)
    format(msg, sizeof(msg), "{FFFF00}[Dousnik]: {FFFFFF}Diler je primecen u blizini koordinata: {00FF00}X: %.1f | Y: %.1f", 
        IlegalaInfo[TrenutnaLokacijaID][iX], IlegalaInfo[TrenutnaLokacijaID][iY]);
    SendClientMessage(playerid, -1, msg);

    // Informacija o popustu
    if(RobaNaPopustu != -1)
    {
        format(msg, sizeof(msg), "{FFFF00}[Dousnik]: {FFFFFF}Cuo sam da danas daje {00FF00}%s {FFFFFF}ispod cene, vredi proveriti.", artikalPopust);
        SendClientMessage(playerid, -1, msg);
    }

    // Provera zaliha (da mu kaze da li uopste vredi ici)
    if(Zaliha_Seme == 0 && Zaliha_Zip == 0 && Zaliha_Pajser == 0)
    {
        SendClientMessage(playerid, -1, "{FFFF00}[Dousnik]: {FFFFFF}Ali pozuri, kazu da mu je roba skoro skroz otisla!");
    }

    return 1;
}

// Callback koji se poziva nakon INSERT-a
forward OnDousnikDodat(playerid);
public OnDousnikDodat(playerid)
{
    SendClientMessage(playerid, -1, "{00FF00}[Dousnik System]: {FFFFFF}Novi dousnik je postavljen i sacuvan u bazi.");
    // Osvezavamo listu dousnika
    mysql_tquery(g_SQL, "SELECT * FROM Dousnici", "UcitajSveDousnike");
    return 1;
}

// --- Dialog Response ---

hook OnDialogResponse@ilegala(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == D_ADILER_MAIN)
    {
        if(!response) return 1;
        switch(listitem)
        {
            case 0: // Dodaj lokaciju
            {
                new Float:x, Float:y, Float:z, Float:a;
                GetPlayerPos(playerid, x, y, z);
                GetPlayerFacingAngle(playerid, a);

                new query[256];
                mysql_format(g_SQL, query, sizeof(query), "INSERT INTO Ilegala (posX, posY, posZ, angle) VALUES ('%f', '%f', '%f', '%f')", x, y, z, a);
                mysql_tquery(g_SQL, query, "OnLokacijaDodata", "i", playerid);
            }
            case 1: // Stopiraj/Aktiviraj
            {
                DilerSistemAktivan = !DilerSistemAktivan;
                if(!DilerSistemAktivan) {
                    UkloniDileraSaMape();
                    SendClientMessage(playerid, -1, "[Ilegala | Diler System]: Sistem je {FF0000}ugasen {FFFFFF}i diler je uklonjen.");
                } else {
                    PromeniLokacijuDilera();
                    SendClientMessage(playerid, -1, "[Ilegala | Diler System]: Sistem je {00FF00}upaljen {FFFFFF}i diler je postavljen.");
                }
            }
            case 2: // TRAJNO BRISANJE LOKACIJE IZ BAZE
            {
                if(TrenutnaLokacijaID == -1) 
                    return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Nijedan diler trenutno nije aktivan na mapi.");

                new query[128];
                // Brisemo iz baze preko ID-a koji je trenutno ucitan u memoriju
                mysql_format(g_SQL, query, sizeof(query), "DELETE FROM Ilegala WHERE id = %d", IlegalaInfo[TrenutnaLokacijaID][iID]);
                mysql_tquery(g_SQL, query);

                SendClientMessage(playerid, -1, "{00FF00}[Ilegala | Diler System]: {FFFFFF}Trenutna lokacija je trajno obrisana iz baze.");
                
                // Sklanjamo ga sa mape
                UkloniDileraSaMape();
                
                // Osvezavamo memoriju (ucitavamo ponovo bez te obrisane tacke)
                for(new i = 0; i < MAX_DILERA; i++) {
                    IlegalaInfo[i][iID] = 0;
                    IlegalaInfo[i][iPostavljen] = false;
                }
                mysql_tquery(g_SQL, "SELECT * FROM Ilegala", "UcitajSveDilere");
            }
        }
        return 1;
    }
    
    if(dialogid == D_ILEGALA_MENU)
    {
        if(!response) return 1;

        new cena, naziv[32], kolicina = 1;

        switch(listitem)
        {
            case 0: // Seme Marihuane
            {
                if(Zaliha_Seme <= 0) return SendClientMessage(playerid, -1, "{FF0000}[Diler]: {FFFFFF}Nemam vise semena, sve sam prodao!");
                
                // Ako je ovaj artikal na popustu, cena je 20% niza
                if(RobaNaPopustu == 0) cena = floatround(CENA_SEME_MARIHUANE * 0.8);
                else cena = CENA_SEME_MARIHUANE;
                
                format(naziv, sizeof(naziv), ITEM_SEME_MARIHUANE);
            }
            case 1: // Zip Kesice
            {
                if(Zaliha_Zip <= 0) return SendClientMessage(playerid, -1, "{FF0000}[Diler]: {FFFFFF}Nestalo mi je kesica, svratite kasnije.");
                
                if(RobaNaPopustu == 1) cena = floatround(CENA_ZIP_KESICA * 0.8);
                else cena = CENA_ZIP_KESICA;
                
                format(naziv, sizeof(naziv), ITEM_ZIP_KESICA);
            }
            case 2: // Pajser
            {
                if(Zaliha_Pajser <= 0) return SendClientMessage(playerid, -1, "{FF0000}[Diler]: {FFFFFF}Pajseri su planuli, nema vise na stanju.");
                
                if(RobaNaPopustu == 2) cena = floatround(CENA_PAJSER * 0.8);
                else cena = CENA_PAJSER;
                
                format(naziv, sizeof(naziv), ITEM_PAJSER);
            }
            default: return 1;
        }

        // Provera novca
        if(GetPlayerMoney(playerid) < cena)
        {
            return SendClientMessage(playerid, -1, "{FF0000}[Diler]: {FFFFFF}Nemas dovoljno para, ne gubi mi vreme!");
        }

        // Pokusaj pakovanja u inventar
        if(SpakujUInv(playerid, naziv, kolicina))
        {
            // Oduzimanje novca
            GivePlayerMoney(playerid, -cena);
            
            // SMANJIVANJE ZALIHA (Ovo je sustina 5. stavke)
            if(listitem == 0) Zaliha_Seme--;
            else if(listitem == 1) Zaliha_Zip--;
            else if(listitem == 2) Zaliha_Pajser--;

            // Poruka o uspesnoj kupovini
            new msg[128];
            format(msg, sizeof(msg), "{44FF44}[Diler]: {FFFFFF}Uspesno si kupio %s za {00FF00}$%d{FFFFFF}. (Preostalo: %d)", 
                naziv, cena, (listitem == 0 ? Zaliha_Seme : (listitem == 1 ? Zaliha_Zip : Zaliha_Pajser)));
            
            SendClientMessage(playerid, -1, msg);
            PlayerPlaySound(playerid, 1083, 0.0, 0.0, 0.0);
        }
        else 
        {
            // Poruka ako SpakujUInv vrati 0 (nema mesta u rancu)
            SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Nemas mesta u rancu, isprazni nesto pa se vrati.");
        }
        return 1;
    }

    return 0;
}

// CMD:testdiler(playerid, params[])
// {
//     SendClientMessage(playerid, -1, "{FFFF00}[Test]: {FFFFFF}Popunjavam testne lokacije i pokrecem sistem...");

//     new Float:x, Float:y, Float:z, Float:a;
//     GetPlayerPos(playerid, x, y, z);
//     GetPlayerFacingAngle(playerid, a);

//     // Ručno punimo 3 lokacije u memoriju (oko tebe) za test
//     // Lokacija 1: Tacno gde stojis
//     IlegalaInfo[0][iID] = 1;
//     IlegalaInfo[0][iX] = x;
//     IlegalaInfo[0][iY] = y + 2.0; // Malo ispred tebe
//     IlegalaInfo[0][iZ] = z;
//     IlegalaInfo[0][iR] = a + 180.0;

//     // Lokacija 2: Malo levo
//     IlegalaInfo[1][iID] = 2;
//     IlegalaInfo[1][iX] = x + 5.0;
//     IlegalaInfo[1][iY] = y;
//     IlegalaInfo[1][iZ] = z;
//     IlegalaInfo[1][iR] = a;

//     // Lokacija 3: Malo desno
//     IlegalaInfo[2][iID] = 3;
//     IlegalaInfo[2][iX] = x - 5.0;
//     IlegalaInfo[2][iY] = y;
//     IlegalaInfo[2][iZ] = z;
//     IlegalaInfo[2][iR] = a;

//     DilerSistemAktivan = true;
    
//     // Pozivamo funkciju da nasumicno izabere jednu od ove tri i stvori NPC-a
//     PromeniLokacijuDilera();

//     SendClientMessage(playerid, -1, "{00FF00}[Test]: {FFFFFF}Lokacije ucitane! Diler je stvoren na jednoj od 3 tacke.");
//     SendClientMessage(playerid, -1, "{00FF00}[Test]: {FFFFFF}Sada mozes testirati /ilegala ili /adiler.");
//     return 1;
// }

// CMD:testdousnik(playerid, params[])
// {
//     new Float:x, Float:y, Float:z, Float:a;
//     GetPlayerPos(playerid, x, y, z);
//     GetPlayerFacingAngle(playerid, a);

//     // Nalazimo prvi slobodan slot u memoriji
//     new slot = -1;
//     for(new i = 0; i < MAX_DOUSNIKA; i++) {
//         if(!DousnikInfo[i][dPostavljen]) {
//             slot = i;
//             break;
//         }
//     }

//     if(slot == -1) return SendClientMessage(playerid, -1, "Nema slobodnih slotova za test dousnike.");

//     // Postavljamo ga u memoriju (privremeno dok se server ne ugasi)
//     DousnikInfo[slot][dX] = x;
//     DousnikInfo[slot][dY] = y;
//     DousnikInfo[slot][dZ] = z;
//     DousnikInfo[slot][dPostavljen] = true;

//     // Kreiramo glumca
//     DousnikInfo[slot][dActor] = CreateDynamicActor(230, x, y, z, a, 1);
//     ApplyDynamicActorAnimation(DousnikInfo[slot][dActor], "MISC", "IDLE_CHAT_02", 4.1, 1, 0, 0, 1, 0);

//     SendClientMessage(playerid, -1, "{00FF00}[Test]: {FFFFFF}Dousnik kreiran lokalno! Sada kucaj /dousnik.");
//     return 1;
// }

// CMD:novac(playerid, params[])
// {
//     // Dodajemo 50,000 dolara igraču
//     GivePlayerMoney(playerid, 50000);

//     return 1;
// }

// --- Funkcije i Callbackovi ---

forward UcitajSveDilere();
public UcitajSveDilere()
{
    new rows = cache_num_rows();
    for(new i = 0; i < rows && i < MAX_DILERA; i++)
    {
        cache_get_value_name_int(i, "id", IlegalaInfo[i][iID]);
        cache_get_value_name_float(i, "posX", IlegalaInfo[i][iX]);
        cache_get_value_name_float(i, "posY", IlegalaInfo[i][iY]);
        cache_get_value_name_float(i, "posZ", IlegalaInfo[i][iZ]);
        cache_get_value_name_float(i, "angle", IlegalaInfo[i][iR]);
        IlegalaInfo[i][iPostavljen] = true;
    }
    printf("[ Ilegala | Diler System ] Ucitano %d lokacija.", rows);
    if(rows > 0) PromeniLokacijuDilera(); // Postavi prvog dilera odmah
    return 1;
}

forward OnLokacijaDodata(playerid);
public OnLokacijaDodata(playerid)
{
    SendClientMessage(playerid, -1, "{00FF00}[Ilegala | Diler System]: {FFFFFF}Uspesno dodata nova lokacija u bazu.");
    // Osvezavamo memoriju iz baze
    for(new i = 0; i < MAX_DILERA; i++) IlegalaInfo[i][iID] = 0; 
    mysql_tquery(g_SQL, "SELECT * FROM Ilegala", "UcitajSveDilere");
    return 1;
}

forward PromeniLokacijuDilera();
public PromeniLokacijuDilera()
{
    if(!DilerSistemAktivan) return 0;

    UkloniDileraSaMape();

    new dostupni[MAX_DILERA], count = 0;
    for(new i = 0; i < MAX_DILERA; i++) {
        if(IlegalaInfo[i][iID] != 0) {
            dostupni[count] = i;
            count++;
        }
    }

    if(count == 0) return 0;

    new randIdx = dostupni[random(count)];
    TrenutnaLokacijaID = randIdx;

    // --- NOVO: Restock i Popust ---
    Zaliha_Seme = 7 + random(4);   // 7-10 komada
    Zaliha_Zip = 40 + random(21); // 40-60 komada
    Zaliha_Pajser = 5 + random(6); // 5-10 komada
    RobaNaPopustu = random(3);    // Nasumično bira jedan artikal za popust
    // ------------------------------

    AktivniDilerActor = CreateDynamicActor(29, IlegalaInfo[randIdx][iX], IlegalaInfo[randIdx][iY], IlegalaInfo[randIdx][iZ], IlegalaInfo[randIdx][iR], 1);
    AktivniDilerLabel = CreateDynamic3DTextLabel("{FF0000}[ Crno Trziste ]\n{FFFFFF}Koristi /ilegala", -1, IlegalaInfo[randIdx][iX], IlegalaInfo[randIdx][iY], IlegalaInfo[randIdx][iZ] + 1.1, 15.0);
    ApplyDynamicActorAnimation(AktivniDilerActor, "GANGS", "DEALER_IDLE", 3, 1, 0, 0, 1, 0);
    
    return 1;
}

stock UkloniDileraSaMape()
{
    if(IsValidDynamicActor(AktivniDilerActor)) {
        DestroyDynamicActor(AktivniDilerActor);
        AktivniDilerActor = -1;
    }
    if(AktivniDilerLabel != Text3D:INVALID_3DTEXT_ID) {
        DestroyDynamic3DTextLabel(AktivniDilerLabel);
        AktivniDilerLabel = Text3D:INVALID_3DTEXT_ID;
    }
    TrenutnaLokacijaID = -1;
}

// --- Funkcije za Dousnike ---

forward UcitajSveDousnike();
public UcitajSveDousnike()
{
    new rows = cache_num_rows();
    if(rows == 0) return print("[Dousnik System]: Nema dousnika u bazi.");

    for(new i = 0; i < rows && i < MAX_DOUSNIKA; i++)
    {
        // Ako je actor vec postojao, unisti ga pre ponovnog stvaranja (refresh)
        if(DousnikInfo[i][dPostavljen]) 
        {
            DestroyDynamicActor(DousnikInfo[i][dActor]);
            DousnikInfo[i][dPostavljen] = false;
        }

        cache_get_value_name_int(i, "id", DousnikInfo[i][dID]);
        cache_get_value_name_float(i, "posX", DousnikInfo[i][dX]);
        cache_get_value_name_float(i, "posY", DousnikInfo[i][dY]);
        cache_get_value_name_float(i, "posZ", DousnikInfo[i][dZ]);
        
        new Float:angle;
        cache_get_value_name_float(i, "angle", angle);

        // Kreiramo NPC-a (Skin 230 - prosjak)
        DousnikInfo[i][dActor] = CreateDynamicActor(230, DousnikInfo[i][dX], DousnikInfo[i][dY], DousnikInfo[i][dZ], angle, 1);
        ApplyDynamicActorAnimation(DousnikInfo[i][dActor], "MISC", "IDLE_CHAT_02", 4.1, 1, 0, 0, 1, 0);
        
        DousnikInfo[i][dPostavljen] = true;
    }
    printf("[Dousnik System]: Ucitano %d dousnika iz baze.", rows);
    return 1;
}