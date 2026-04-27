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
    bool:LoggedIn
};
new Igrac[MAX_PLAYERS][IgracData];

hook OnPlayerConnect(playerid) {
    
    GetPlayerName(playerid, Igrac[playerid][ImeIgraca], 25);

    Igrac[playerid][LoggedIn] = false;
    Igrac[playerid][Novac] = 0;
    Igrac[playerid][Level] = 1;
    Igrac[playerid][Skin] = 0;
    Igrac[playerid][IgracId] = -1;
    Igrac[playerid][Admin] = -1;
    Igrac[playerid][AdminDuty] = false;
    Igrac[playerid][AdminVozilo] = -1;
    Igrac[playerid][SlotoviInventara] = 0;

    new queryna[128];
    format(queryna, sizeof(queryna), "SELECT * FROM Igraci WHERE imeIgraca = '%s'", Igrac[playerid][ImeIgraca]);
    mysql_tquery(g_SQL, queryna, "OnPlayerCheckAccount", "%d", playerid);
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
                "INSERT INTO Igraci (imeIgraca, lozinka, novac, level, skin, admin) VALUES ('%e', '%e', 0, 1, 0, -1)", 
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

forward OnPlayerCheckAccount(playerid);
public OnPlayerCheckAccount(playerid) {
    
    if(cache_num_rows() > 0) {
        SPD(playerid, D_LOGIN, DIALOG_STYLE_PASSWORD, "{00FFFF}Prijava", "Nalog je pronadjen.\nUnesite vasu sifru ispod", "Prijava", "Izlaz");
    } else {
        SPD(playerid, D_REGISTER, DIALOG_STYLE_INPUT, "{00FF00}Registracija", "Nalog nije pronadjen.\nUnesite lozinku za registraciju", "Registracija", "Izlaz");   
    }
    return 1;
}

forward OnPlayerLogin(playerid);
public OnPlayerLogin(playerid) {

    if(cache_num_rows() == 1) {
        
        UcitajIgraca(playerid);
        GivePlayerMoney(playerid, Igrac[playerid][Novac]);
        SetPlayerScore(playerid, Igrac[playerid][Level]);
        SetSpawnInfo(playerid, NO_TEAM, Igrac[playerid][Skin], Igrac[playerid][X], Igrac[playerid][Y], Igrac[playerid][Z], Igrac[playerid][R], 0, 0, 0, 0, 0, 0);
        SpawnPlayer(playerid);
        SendClientMessage(playerid, -1, "Uspesno si se ulogovao");
    } else {
        SendClientMessage(playerid, -1, "Pogresna lozinka");
    }
    return 1;
}

CMD:register(playerid, params[]) 
{
    if(Igrac[playerid][LoggedIn]) return SendClientMessage(playerid, -1, "Greska: Vec si ulogovan!");

    new lozinka[50];
    if(sscanf(params, "s[50]", lozinka)) 
        return SendClientMessage(playerid, -1, "Koristi: /register [lozinka]");

    if(strlen(lozinka) < 4) 
        return SendClientMessage(playerid, -1, "Greska: Lozinka mora imati bar 4 karaktera!");

    new acc_query[256];
    mysql_format(g_SQL, acc_query, sizeof(acc_query), 
        "INSERT INTO Igraci (imeIgraca, lozinka, novac, level, skin, admin) VALUES ('%e', '%e', 0, 1, 0, -1)", 
        Igrac[playerid][ImeIgraca], lozinka);

    mysql_tquery(g_SQL, acc_query);
    
    SendClientMessage(playerid, -1, "Uspesno si se registrovao. Sada mozes koristiti /login [lozinka]");
    return 1;
}

CMD:login(playerid, params[])
{
    if(Igrac[playerid][LoggedIn]) return SendClientMessage(playerid, -1, "Greska: Vec si ulogovan!");

    new lozinka[50];
    if(sscanf(params, "s[50]", lozinka)) 
        return SendClientMessage(playerid, -1, "Koristi: /login [lozinka]");

    new acc_query[256];
    mysql_format(g_SQL, acc_query, sizeof(acc_query), 
        "SELECT * FROM Igraci WHERE imeIgraca='%e' AND lozinka='%e' LIMIT 1", 
        Igrac[playerid][ImeIgraca], lozinka);

    mysql_tquery(g_SQL, acc_query, "OnPlayerLogin", "d", playerid);
    return 1;
}