enum IgracData {
    IgracId,
    ImeIgraca[24],
    Lozinka[50],
    Novac,
    Level,
    Skin,
    ZatvorVreme,
    Admin,
    bool:AdminDuty,
    AdminVozilo,
    SlotoviInventara,
    Float:X,
    Float:Y,
    Float:Z,
    Float:R,
    ServerMuted,
    LicnaKarta,
    bool:obukaoUniformu,
    zapoceoPosao,
    pAktivniCP,
    pPosaoFaza,
    pPreostaloTura,
    pUgovor,
    pPosaoID,
    bool:pRadiPosao,
    bool:LoggedIn
};
new Igrac[MAX_PLAYERS][IgracData];

hook OnPlayerConnect(playerid) {
    
    GetPlayerName(playerid, Igrac[playerid][ImeIgraca], 25);

    Igrac[playerid][LoggedIn] = false;
    Igrac[playerid][IgracId] = -1;
    Igrac[playerid][Novac] = 0;
    Igrac[playerid][Level] = 1;
    Igrac[playerid][Skin] = 0;
    Igrac[playerid][Admin] = -1;
    Igrac[playerid][AdminDuty] = false;
    Igrac[playerid][AdminVozilo] = -1;

    SetTimerEx("ProveriNalogTajmer", 500, false, "d", playerid);
    return 1;
}


hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch(dialogid)
    {
        case D_REGISTER:
        {
            if(!response) return Kick(playerid);
            if(strlen(inputtext) < 4) return ShowPlayerDialog(playerid, D_REGISTER, DIALOG_STYLE_INPUT, "Greska!", "Lozinka mora imati bar 4 karaktera!\nUnesite ponovo:", "Registruj", "Izlaz");

            new Pquery[256];
            mysql_format(g_SQL, Pquery, sizeof(Pquery), 
                "INSERT INTO Igraci (imeIgraca, lozinka, novac, level, skin, admin, slotoviInventara) VALUES ('%e', '%e', 0, 1, 0, -1, 3)", 
                Igrac[playerid][ImeIgraca], inputtext);
            mysql_tquery(g_SQL, Pquery);

            SendClientMessage(playerid, -1, "Uspesno ste se registrovali. Sada se ulogujte.");
            ShowPlayerDialog(playerid, D_LOGIN, DIALOG_STYLE_PASSWORD, "Prijava", "Sada unesite lozinku koju ste malopre registrovali:", "Prijava", "Izlaz");
        }
        case D_LOGIN:
        {
            if(!response) return Kick(playerid);
            
            new Pquery[256];
            mysql_format(g_SQL, Pquery, sizeof(Pquery), 
                "SELECT * FROM Igraci WHERE imeIgraca='%e' AND lozinka='%e' LIMIT 1", 
                Igrac[playerid][ImeIgraca], inputtext);
            mysql_tquery(g_SQL, Pquery, "OnPlayerLogin", "d", playerid);
        }
    }
    return 1;
}

forward ProveriNalogTajmer(playerid);
public ProveriNalogTajmer(playerid) {
    new queryna[128];
    mysql_format(g_SQL, queryna, sizeof(queryna), "SELECT * FROM `Igraci` WHERE `imeIgraca` = '%e' LIMIT 1", Igrac[playerid][ImeIgraca]);
    printf("DEBUG: Saljem upit za %s", Igrac[playerid][ImeIgraca]);
    mysql_tquery(g_SQL, queryna, "OnPlayerCheckAccount", "i", playerid);
    return 1;
}

forward OnPlayerCheckAccount(playerid);
public OnPlayerCheckAccount(playerid) {
    printf("DEBUG: Callback OnPlayerCheckAccount se uspesno pokrenuo za ID %d!", playerid);    
    new rows = cache_num_rows();


    if(rows > 0) {
        ShowPlayerDialog(playerid, D_LOGIN, DIALOG_STYLE_PASSWORD, "{00FFFF}Prijava", "Nalog je pronadjen.\nUnesite vasu sifru ispod", "Prijava", "Izlaz");
    } else {
        ShowPlayerDialog(playerid, D_REGISTER, DIALOG_STYLE_INPUT, "{00FF00}Registracija", "Nalog nije pronadjen.\nUnesite lozinku za registraciju", "Registracija", "Izlaz");   
    }
    return 1;
}

forward OnPlayerLogin(playerid);
public OnPlayerLogin(playerid) {

    if(cache_num_rows() == 1) {
        
        UcitajIgraca(playerid);
        UcitajBankovniRacun(playerid);
        GivePlayerMoney(playerid, Igrac[playerid][Novac]);
        SetPlayerScore(playerid, Igrac[playerid][Level]);
        SetSpawnInfo(playerid, NO_TEAM, Igrac[playerid][Skin], Igrac[playerid][X], Igrac[playerid][Y], Igrac[playerid][Z], Igrac[playerid][R], 0, 0, 0, 0, 0, 0);
        SpawnPlayer(playerid);
        SendClientMessage(playerid, -1, "Uspesno si se ulogovao");
    } else {
        SendClientMessage(playerid, -1, "Pogresna lozinka");
        SPD(playerid, D_LOGIN, DIALOG_STYLE_PASSWORD, "{00FFFF}Prijava", "Pogresna lozinka.\nUnesite vasu sifru ispod", "Prijava", "Izlaz");
    }
    return 1;
}


CMD:izvadilicnu(playerid, params[])
{
    if(!IsPlayerInRangeOfPoint(playerid, LICNA_KARTA_VADJENJE_RADIUS, LICNA_KARTA_VADJENJE_X, LICNA_KARTA_VADJENJE_Y, LICNA_KARTA_VADJENJE_Z))
        return SendClientMessage(playerid, ERROR_BOJA, "[ Opstina | Greska ]: Niste na mestu za vadjenje licne karte!");

    if(Igrac[playerid][LicnaKarta] == 1)
        return SendClientMessage(playerid, ERROR_BOJA, "[ Opstina | Greska ]: Vec imate licnu kartu.");


    if(Igrac[playerid][Novac] < LICNA_KARTA_CENA)
        return SendClientMessage(playerid, ERROR_BOJA, "[ Opstina | Greska ]: Nemate dovoljno novca za vadjenje licne karte. Cena je 1000$.");

    Igrac[playerid][LicnaKarta] = 1;
    GivePlayerMoney(playerid, (LICNA_KARTA_CENA) * -1);
    SendClientMessage(playerid, -1, "[ Opstina | Info ]: Uspesno ste izvadili licnu kartu.");
    SacuvajIgraca(playerid);
    return 1;
}

CMD:licna(playerid, params[])
{
    if(Igrac[playerid][LicnaKarta] == 0)
        return SendClientMessage(playerid, ERROR_BOJA, "[ Opstina | Greska ]: Nemate licnu kartu. Mozete je izvaditi na opstini.");

    new info[128];
    format(info, sizeof(info), "Ime: %s\nNovac: %d$\nLevel: %d\n", Igrac[playerid][ImeIgraca], Igrac[playerid][Novac], Igrac[playerid][Level]);
    SendClientMessage(playerid, -1, info);
    return 1;
}

CMD:dajpajser(playerid, params[])
{
    SendClientMessage(playerid, -1, "Dobili ste pajser.");
    SpakujUInv(playerid, "Pajser", 1);
    return 1;
}