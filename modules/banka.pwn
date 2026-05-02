enum banka_data {
    bIgracID,
    bImaRacun,
    bNovac,
    bKredit,
    bool:bUcitano
}
new BankovniRacun[MAX_PLAYERS][banka_data];

hook OnPlayerConnect@Banka(playerid)
{
    BankovniRacun[playerid][bImaRacun] = 0;
    BankovniRacun[playerid][bNovac] = 0;
    BankovniRacun[playerid][bKredit] = 0;
    BankovniRacun[playerid][bUcitano] = false;
    return 1;
}

hook OnDialogResponse@Banka(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == D_BANKA_MENU)
    {
        if(!response)
        {
            ClearAnimations(playerid);
            return 1;
        }
        switch(listitem)
        {
            case 0: {
                new str[128];
                format(str, sizeof(str), ""TEXT_ZELENA"Trenutno stanje na racunu: $%d\n1) Podizanje novca\n2) Ostavljanje novca", BankovniRacun[playerid][bNovac]);
                SPD(playerid, D_BANKA_MENU, DIALOG_STYLE_LIST, "Banka", str, "Izaberi", "Zatvori");
                return 1;
            }
            case 1: // Podizanje novca
                SPD(playerid, D_BANKA_PODIZANJE, DIALOG_STYLE_INPUT, "Podizanje novca", "Unesite iznos koji zelite podici:", "Podigni", "Otkazi");
            case 2: // Ostavljanje novca
                SPD(playerid, D_BANKA_OSTAVLJANJE, DIALOG_STYLE_INPUT, "Ostavljanje novca", "Unesite iznos koji zelite ostaviti:", "Ostavi", "Otkazi");
        }
    }
    if(dialogid == D_BANKA_PODIZANJE)
    {
        if(!response)
        {
            ClearAnimations(playerid);
            return 1;
        }
        new iznos = strval(inputtext);

        if(iznos <= 0) {
            SendClientMessage(playerid, ERROR_BOJA, "[ Banka System | Greska ] Unesite validan iznos.");
            SPD(playerid, D_BANKA_PODIZANJE, DIALOG_STYLE_INPUT, "Podizanje novca", "Unesite iznos koji zelite podici:", "Podigni", "Otkazi");
            return 1;
        }

        if(iznos > BankovniRacun[playerid][bNovac] ) {
            SendClientMessage(playerid, ERROR_BOJA, "[ Banka System | Greska ] Nemate toliko novca u banci.");
            SPD(playerid, D_BANKA_PODIZANJE, DIALOG_STYLE_INPUT, "Podizanje novca", "Unesite iznos koji zelite podici:", "Podigni", "Otkazi");
            return 1;
        }
        BankovniRacun[playerid][bNovac] -= iznos;
        GivePlayerMoney(playerid, iznos);
        SacuvajBanku(playerid);
        ClearAnimations(playerid);
        SendClientMessage(playerid, BANKA_ZELENA_BOJA, "============================================");
        new novostanje[128];
        format(novostanje, sizeof(novostanje), "Stanje na racunu: %d$", BankovniRacun[playerid][bNovac]);
        SendClientMessage(playerid, BANKA_ZELENA_BOJA, "[ Banka System | Info ] Uspesno ste podigli novac.");
        SendClientMessage(playerid, BANKA_ZELENA_BOJA, novostanje);
        SendClientMessage(playerid, BANKA_ZELENA_BOJA, "============================================");
        return 1;
    }
    if(dialogid == D_BANKA_OSTAVLJANJE)
    {
        if(!response) {
            ClearAnimations(playerid);
            return 1;
        }
        new iznos = strval(inputtext);

        if(iznos <= 0) {
            SendClientMessage(playerid, ERROR_BOJA, "[ Banka System | Greska ] Unesite validan iznos.");
            SPD(playerid, D_BANKA_OSTAVLJANJE, DIALOG_STYLE_INPUT, "Ostavljanje novca", "Unesite iznos koji zelite ostaviti:", "Ostavi", "Otkazi");
            return 1;
        }

        if(iznos > GetPlayerMoney(playerid)) {
            SendClientMessage(playerid, ERROR_BOJA, "[ Banka System | Greska ] Nemate toliko novca kod sebe.");
            SPD(playerid, D_BANKA_OSTAVLJANJE, DIALOG_STYLE_INPUT, "Ostavljanje novca", "Unesite iznos koji zelite ostaviti:", "Ostavi", "Otkazi");
            return 1;
        }
        BankovniRacun[playerid][bNovac] += iznos;
        GivePlayerMoney(playerid, (iznos) * -1);
        SacuvajBanku(playerid);
        ClearAnimations(playerid);
        SendClientMessage(playerid, BANKA_ZELENA_BOJA, "============================================");
        SendClientMessage(playerid, BANKA_ZELENA_BOJA, "[ Banka System | Info ] Uspesno ste ostavili novac.");
        new novostanje[128];
        format(novostanje, sizeof(novostanje), "Stanje na racunu: %d$", BankovniRacun[playerid][bNovac]);
        SendClientMessage(playerid, BANKA_ZELENA_BOJA, novostanje);
        SendClientMessage(playerid, BANKA_ZELENA_BOJA, "============================================");
        return 1;
    }
    return 0;
}

stock UcitajBankovniRacun(playerid)
{
    new b_query[128];
    mysql_format(g_SQL, b_query, sizeof(b_query), "SELECT * FROM igracBanka WHERE igracID = %d LIMIT 1", Igrac[playerid][IgracId]);
    mysql_tquery(g_SQL, b_query, "OnBankDataLoad", "i", playerid);
    return 1;
}

stock SacuvajBanku(playerid)
{
    if(!Igrac[playerid][LoggedIn] || !BankovniRacun[playerid][bUcitano]) return 0;

    new b_query[256];
    mysql_format(g_SQL, b_query, sizeof(b_query), 
        "UPDATE igracBanka SET imaRacun = %d, novcaUBanci = %d, kredit = %d WHERE igracID = %d",
        BankovniRacun[playerid][bImaRacun],
        BankovniRacun[playerid][bNovac],
        BankovniRacun[playerid][bKredit],
        Igrac[playerid][IgracId]
    );
    mysql_tquery(g_SQL, b_query);
    return 1;
}

forward OnBankDataLoad(playerid);
public OnBankDataLoad(playerid)
{
    if(cache_num_rows() > 0)
    {
        cache_get_value_name_int(0, "imaRacun", BankovniRacun[playerid][bImaRacun]);
        cache_get_value_name_int(0, "novcaUBanci", BankovniRacun[playerid][bNovac]);
        cache_get_value_name_int(0, "kredit", BankovniRacun[playerid][bKredit]);
        BankovniRacun[playerid][bUcitano] = true;
    }
    else 
    {
        new b_query[128];
        mysql_format(g_SQL, b_query, sizeof(b_query), "INSERT INTO igracBanka (igracID, imaRacun, novcaUBanci, kredit) VALUES (%d, 0, 0, 0)", Igrac[playerid][IgracId]);
        mysql_tquery(g_SQL, b_query);
        
        BankovniRacun[playerid][bImaRacun] = 0;
        BankovniRacun[playerid][bNovac] = 0;
        BankovniRacun[playerid][bKredit] = 0;
        BankovniRacun[playerid][bUcitano] = true;
    }
    return 1;
}

stock OtvoriBankaMeni(playerid)
{
    if(BankovniRacun[playerid][bImaRacun] == 0) {
        SendClientMessage(playerid, ERROR_BOJA, "[ Banka System | Greska ] Nemate otvoren bankovni racun.");
        return 1;
    }

    ApplyAnimation(playerid, "PED", "parky_loop", 4.1, 0, 1, 1, 1, 0, 1);

    new str[256];
    format(str, sizeof(str), 
        ""TEXT_ZELENA"Trenutno stanje na racunu: $%d\n" \
        "{FFFFFF}1) Podizanje novca\n" \
        "2) Ostavljanje novca", 
        BankovniRacun[playerid][bNovac]
    );

    SPD(playerid, D_BANKA_MENU, DIALOG_STYLE_LIST, "Banka", str, "Izaberi", "Zatvori");
    return 1;
}

CMD:otvoriracun(playerid, params[])
{
    if(!IsPlayerInRangeOfPoint(playerid, BANKA_OTVARANJE_RACUNA_RADIUS, BANKA_OTVARANJE_RACUNA_X, BANKA_OTVARANJE_RACUNA_Y, BANKA_OTVARANJE_RACUNA_Z))
    {
        SendClientMessage(playerid, ERROR_BOJA, "[ Banka System | Greska ] Niste u blizini saltera za otvaranje racuna.");
        return 1;
    }

    if(BankovniRacun[playerid][bImaRacun] == 1) {
        SendClientMessage(playerid, ERROR_BOJA, "[ Banka System | Greska ] Vec imate otvoren bankovni racun.");
        return 1;
    }

    if(GetPlayerMoney(playerid) < BANKA_OTVARANJE_RACNA_CENA) {
        SendClientMessage(playerid, ERROR_BOJA, "[ Banka System | Greska ] Nemate dovoljno novca da otvorite bankovni racun.");
        return 1;
    }
    
    BankovniRacun[playerid][bImaRacun] = 1;
    GivePlayerMoney(playerid, (BANKA_OTVARANJE_RACNA_CENA) * -1);
    
    new b_query[128];
    mysql_format(g_SQL, b_query, sizeof(b_query), "UPDATE igracbanka SET imaRacun = 1, novcaUBanci = 0, kredit = 0 WHERE igracID = %d", Igrac[playerid][IgracId]);
    mysql_tquery(g_SQL, b_query);
    SacuvajIgraca(playerid);
    SendClientMessage(playerid, BANKA_ZELENA_BOJA, "[ Banka System | Info ] Uspesno ste otvorili bankovni racun.");
    return 1;
}

CMD:banka(playerid, params[])
{
    if(BankovniRacun[playerid][bImaRacun] == 0) {
        SendClientMessage(playerid, ERROR_BOJA, "[ Banka System | Greska ]: Nemate otvoren bankovni racun.");
        return 1;
    }

    if(IsPlayerInRangeOfPoint(playerid, 3.0, BANKA_PODIZANJE_KARTICE_X, BANKA_PODIZANJE_KARTICE_Y, BANKA_PODIZANJE_KARTICE_Z))
    {
        return OtvoriBankaMeni(playerid);
    }

    if(IsPlayerNearATM(playerid))
    {
        return OtvoriBankaMeni(playerid);
    }

    SendClientMessage(playerid, ERROR_BOJA, "[ Banka System | Info ]: Morate biti u banci ili kod bankomata.");
    return 1;
}