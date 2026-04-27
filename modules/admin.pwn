stock ProveriAdminDuznost(playerid)
{
    if(Igrac[playerid][AdminDuty] == false)
    {
        SendClientMessage(playerid, -1, "[Admin Duznost]: Nisi na duznosti. Kucaj /aduznost i ponovi komandu.");
        return 0;
    }
    return 1;
}

stock LogAdminAction(adminid, targetid, const action[], const reason[])
{
    new admin_query[512];
    new targetName[MAX_PLAYER_NAME];

    if(targetid != INVALID_PLAYER_ID)
    {
        format(targetName, sizeof(targetName), "%s", Igrac[targetid][ImeIgraca]);
    } else
    {
        format(targetName, sizeof(targetName), "N/A");
    }

    mysql_format(g_SQL, admin_query, sizeof(admin_query), 
        "INSERT INTO AdminLogovi (adminIme, targetIme, akcija, razlog) VALUES ('%e', '%e', '%e', '%e')",
        Igrac[adminid][ImeIgraca],
        targetName,
        action,
        reason
    );
    mysql_tquery(g_SQL, admin_query);

    printf("[ADMIN LOG]: %s je uradio [%s] nad %s. Razlog: %s", Igrac[adminid][ImeIgraca], action, targetName, reason);
    return 1;
}

forward OnAdminLogsLoad(playerid);
public OnAdminLogsLoad(playerid)
{
    new rows = cache_num_rows();
    if(rows == 0) return SendClientMessage(playerid, -1, "{FF0000}[Info]: {FFFFFF}Nema pronađenih logova za to ime.");

    new string[1024], aName[50], aAkcija[100], aTarget[50], aDatum[32];
    
    format(string, sizeof(string), "Admin\tAkcija\tMeta\tDatum\n");

    for(new i = 0; i < rows; i++)
    {
        cache_get_value_name(i, "adminIme", aName);
        cache_get_value_name(i, "akcija", aAkcija);
        cache_get_value_name(i, "targetIme", aTarget);
        cache_get_value_name(i, "datum", aDatum);

        format(string, sizeof(string), "%s%s\t%s\t%s\t{AAAAAA}%s\n", 
            string, aName, aAkcija, aTarget, aDatum);
    }

    SPD(playerid, 0, DIALOG_STYLE_TABLIST_HEADERS, "{FF0000}Admin Revizija (Poslednjih 10)", string, "Zatvori", "");
    return 1;
}

CMD:asultan(playerid, params[])
{
    if(!AdminProvera(playerid, 1)) return 1;
    if(!ProveriAdminDuznost(playerid)) return 1;

    if(Igrac[playerid][AdminVozilo] != -1) { DestroyVehicle(Igrac[playerid][AdminVozilo]); }

    new Float:x, Float:y, Float:z, Float:a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);

    new vehid = CreateVehicle(560, x, y, z, a, 1, 1, -1);
    
    Igrac[playerid][AdminVozilo] = vehid;
    PutPlayerInVehicle(playerid, vehid, 0);
    
    new str[32];
    format(str, sizeof(str), "ADMIN %d", playerid);
    SetVehicleNumberPlate(vehid, str);

    SendClientMessage(playerid, -1, "{FF0000}[Admin System] {FFFFFF}Stvorili ste Admin Sultan. Vozilo ce biti obrisano kada odete off-duty.");
    LogAdminAction(playerid, INVALID_PLAYER_ID, "Stvorio Admin Sultan", "N/A");
    return 1;
}

CMD:afix(playerid, params[])
{
    if(!AdminProvera(playerid, 1)) return 1;
    if(!ProveriAdminDuznost(playerid)) return 1;
    if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Morate biti u vozilu.");
    if(GetPlayerVehicleSeat(playerid) != 0) return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Morate biti na mestu vozaca da biste popravili vozilo.");

    new vehid = GetPlayerVehicleID(playerid);
    SetVehicleHealth(vehid, 1000.0);
    RepairVehicle(vehid);
    SendClientMessage(playerid, -1, "{FF0000}[Admin]: {FFFFFF}Vozilo je uspesno popravljeno.");
    LogAdminAction(playerid, INVALID_PLAYER_ID, "Popravka vozila (/afix)", "N/A");
    return 1;
}

CMD:goto(playerid, params[])
{
    new target;
    if(!AdminProvera(playerid, 1)) return 1;
    if(sscanf(params, "u", target)) return SendClientMessage(playerid, -1, "Koristi: /goto [ID Igraca]");
    if(target == INVALID_PLAYER_ID) return SendClientMessage(playerid, -1, "Igrac nije na serveru.");

    new Float:x, Float:y, Float:z;
    GetPlayerPos(target, x, y, z);
    
    SetPlayerPos(playerid, x + 1.0, y + 1.0, z);
    SetPlayerInterior(playerid, GetPlayerInterior(target));
    SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(target));

    new str[128], str1[128];
    format(str, sizeof(str), "[ Admin System | Info ] Uspesno ste se teleportovali do igraca %s", Igrac[target][ImeIgraca]);
    format(str1, sizeof(str1), "[ Server | Info ] Administrator %s, se teleportovao do vas.", Igrac[playerid][ImeIgraca]);
    SendClientMessage(playerid, -1, str);
    SendClientMessage(target, -1, str1);
    return 1;
}

CMD:aporuka(playerid, params[])
{
    new target, poruka[64];
    
    if(!AdminProvera(playerid, 1)) return 1;
    if(sscanf(params, "us[64]", target, poruka)) return SendClientMessage(playerid, ADMIN_BOJA, "[ Admin System | Info ] Koristi /aporuka [ID Igraca] [Poruka]");
    if(target == INVALID_PLAYER_ID) return SendClientMessage(playerid, -1, "[ Admin System | Greska ] Taj igrac nije na serveru");
    format(poruka, sizeof(poruka), params);

    new str[64], str1[64];
    format(str, sizeof(str), "[ Admin System | Pouka ] Poslali ste poruku igracu %s, Poruka: %s", Igrac[target][ImeIgraca], poruka);
    format(str1, sizeof(str1), "[ Server | Poruka ] Dobili ste poruku od Administratora %s. Poruka: %s", Igrac[playerid][ImeIgraca], poruka);
    SendClientMessage(playerid, ADMIN_BOJA, str);
    SendClientMessage(target, -1, str1);
    return 1;
}

CMD:aobavestenje(playerid, params[])
{
    new obavestenje[128], str[128];
    if(!AdminProvera(playerid, 1)) return 1;
    if(!ProveriAdminDuznost(playerid)) return 1;

    format(obavestenje, sizeof(obavestenje), params);
    format(str, sizeof(str), "Obavestenje poslato od strane %s", Igrac[playerid][ImeIgraca]);

    SendClientMessageToAll(-1, "=======================");
    SendClientMessageToAll(-1, "     Obavestenje");
    SendClientMessageToAll(-1, obavestenje);
    SendClientMessageToAll(-1, str);
    SendClientMessageToAll(-1, "=======================");
    LogAdminAction(playerid, INVALID_PLAYER_ID, "Obavestenje (/aobavestenje)", obavestenje);
    return 1;
}

CMD:amute(playerid, params[])
{
    new target, razlog[64], vreme;
    if(!AdminProvera(playerid, 1)) return 1;
    if(sscanf(params, "uS[64]i", target, razlog, vreme)) return SendClientMessage(playerid, ADMIN_BOJA, "[ Admin System | Info ] Koristi /amute [ID Igraca] [Razlog] [Vreme(U minutima)]");
    if(target == INVALID_PLAYER_ID) return SendClientMessage(playerid, -1, "[ Admin System | Greska ] Taj igrac nije na serveru");
    if(Igrac[target][Admin] >= 1) return SendClientMessage(playerid, -1, "[ Admin System | Greska ] Ne mozes mutirati administratora");
    if(vreme < 1 || vreme > 3000) return SendClientMessage(playerid, -1, "[ Admin System | Greska ] Vreme mora biti izmeju 1 i 3000 minuta");

    Igrac[target][ServerMuted] = vreme * 60;

    new str[144], str1[144];
    format(str, sizeof(str), "[ Admin System | Info ] Utisali ste igraca %s na %d min. Razlog: %s", Igrac[target][ImeIgraca], vreme, razlog);
    format(str1, sizeof(str1), "{FF0000}[ Server | Info ]: {FFFFFF}Administrator %s vas je utisao %d min. Razlog: %s", Igrac[playerid][ImeIgraca], vreme, razlog);
    SendClientMessage(playerid, ADMIN_BOJA, str);
    SendClientMessage(target, -1, str1);
    
    new admin_query[128];
    mysql_format(g_SQL, admin_query, sizeof(admin_query), "UPDATE Igraci SET serverMute = %d WHERE id = %d", vreme, Igrac[target][IgracId]);
    mysql_tquery(g_SQL, admin_query);
    LogAdminAction(playerid, target, "Server mute (/amute)", razlog);
    return 1;
}

CMD:aunmute(playerid, params[])
{
    new target;
    if(!AdminProvera(playerid, 1)) return 1;
    if(sscanf(params, "u", target)) return SendClientMessage(playerid, ADMIN_BOJA, "[ Admin System | Info ] Koristi /aunmute [ID Igraca]");
    if(target == INVALID_PLAYER_ID) return SendClientMessage(playerid, -1, "[ Admin System | Greska ] Taj igrac nije na serveru");
    if(Igrac[target][ServerMuted] == 0) return SendClientMessage(playerid, -1, "[ Admin System | Greska ] Taj igrac nije mutiran");

    Igrac[target][ServerMuted] = 0;

    new str[128], str1[128];
    format(str, sizeof(str), "[ Admin System | Info ] Uspesno ste odmutirali igraca %s", Igrac[target][ImeIgraca]);
    format(str1, sizeof(str1), "[ Server | Info ] Administrator %s, vas je odmutirao sada mozete pricati", Igrac[playerid][ImeIgraca]);
    SendClientMessage(playerid, ADMIN_BOJA, str);
    SendClientMessage(target, -1, str1);

    new admin_query[128];
    mysql_format(g_SQL, admin_query, sizeof(admin_query), "UPDATE Igraci SET serverMute = 0 WHERE id = %d", Igrac[target][IgracId]);
    mysql_tquery(g_SQL, admin_query);
    LogAdminAction(playerid, target, "Server unmute (/aunmute)", "N/A");
    return 1;
}

CMD:checklogs(playerid, params[])
{
    if(!AdminProvera(playerid, 5)) return 1;

    new target[24];
    if(sscanf(params, "s[24]", target)) return SendClientMessage(playerid, -1, "[Admin System] Koristi /checklogs [Ime_Prezime]");

    new admin_query[256];
    mysql_format(g_SQL, admin_query, sizeof(admin_query), "SELECT adminIme, akcija, targetIme, datum FROM AdminLogs WHERE adminIme = '%e' OR targetIme = '%e' ORDER BY datum DESC LIMIT 10", playerid, target);
    mysql_tquery(g_SQL, admin_query, "OnAdminLogsLoad", "i", playerid);
    return 1;
}

CMD:aslap(playerid, params[])
{
    if(!AdminProvera(playerid, 1)) return 1;

    new targetid, razlog[64];
    if(sscanf(params, "uS(Bez razloga)[64]", targetid, razlog)) return SendClientMessage(playerid, ADMIN_BOJA, "[Admin System] Koristi /aslap [Id igraca] [Razlog(opciono)]");
    if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, -1, "[Admin System] Igrac nije na serveru.");

    new Float:x, Float:y, Float:z;
    GetPlayerPos(targetid, x, y, z);
    SetPlayerPos(targetid, x, y, z + 5.0);

    new str[128];
    format(str, sizeof(str), "{FF0000}[Server Info]: {FFFFFF}Administrator %s vas je osamario. Razlog: %s", Igrac[playerid][ImeIgraca], razlog);
    SendClientMessage(targetid, -1, str);

    format(str, sizeof(str), "{FF0000}[Admin System]: {FFFFFF}Osamarili ste igraca %s. Razlog: %s", Igrac[targetid][ImeIgraca], razlog);
    SendClientMessage(playerid, -1, str);
    LogAdminAction(playerid, targetid, "Slap", razlog);
    return 1;
}

CMD:ac(playerid, params[])
{
    if(!AdminProvera(playerid, 1)) return 1; 
    if(isnull(params)) return SendClientMessage(playerid, -1, "Koristi: /ac [Poruka]");

    new string[144];
    format(string, sizeof(string), "{FF0000}[A-Chat] %s %s: {FFFFFF}%s", DajAdminNaziv(Igrac[playerid][Admin]), Igrac[playerid][ImeIgraca], params);

    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i) && Igrac[i][Admin] >= 1)
        {
            SendClientMessage(i, ADMIN_BOJA, string);
        }
    }
    return 1;
}

CMD:ajail(playerid, params[])
{
    if(!AdminProvera(playerid, 3)) return 1;
    if(!ProveriAdminDuznost(playerid)) return 1;

    new targetid, vreme, razlog[64];
    if(sscanf(params, "uiS(Bez razloga)[64]", targetid, vreme, razlog)) return SendClientMessage(playerid, -1, "{AAAAAA}Koristi: /ajail [ID] [Minuti] [Razlog]");    
    if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Igrac nije na serveru.");
    if(vreme < 1 || vreme > 3000) return SendClientMessage(playerid, -1, "[Admin System] Vreme mora biti izmeju 1 i 3000 minuta");

    Igrac[targetid][ZatvorVreme] = vreme * 60;
    SetPlayerPos(targetid, 197.6661, 173.8179, 1003.0234);
    SetPlayerInterior(targetid, 3);

    new str[144];
    format(str, sizeof(str), "{FF0000}[Zatvor]: {FFFFFF}Admin %s je zatvorio igraca %s na %d min. Razlog: %s", Igrac[playerid][ImeIgraca], Igrac[targetid][ImeIgraca], vreme, razlog);
    SendClientMessageToAll(-1, str);

    new admin_query[128];
    mysql_format(g_SQL, admin_query, sizeof(admin_query), "UPDATE Igraci SET zatvorenVreme = %d WHERE id = %d", vreme, Igrac[targetid][IgracId]);
    mysql_tquery(g_SQL, admin_query);
    LogAdminAction(playerid, targetid, "Zatvor(Jail)", razlog);

    return 1;
}

CMD:aduznost(playerid, params[])
{
    if(!AdminProvera(playerid, 1)) return 1;

    if(!Igrac[playerid][AdminDuty])
    {
        Igrac[playerid][AdminDuty] = true;
        SetPlayerColor(playerid, ADMIN_BOJA);
        SetPlayerHealth(playerid, 9999.9);
        SetPlayerArmour(playerid, 9999.9);

        new str[128];
        format(str, sizeof(str), "{FF0000}[Admin Duznost] {FFFFFF}Administrator %s, se postavio na duznost", Igrac[playerid][ImeIgraca]);
        SendClientMessageToAll(-1, str);

        for(new i = 0; i < 20; i++) SendClientMessage(playerid, -1, " ");
        SendClientMessage(playerid, -1, "{FF0000}[Admin Duznost] {FFFFFF}Sada ste na duznosti. Aktiviran vam je GOD MODE");
    }
    else
    {
        Igrac[playerid][AdminDuty] = false;
        SetPlayerColor(playerid, 0xFFFFFFFF);
        SetPlayerHealth(playerid, 100.0);

        new str[128];
        format(str, sizeof(str), "{FF0000}[Admin Duznost] Administrator %s, vise nije na duznosti", Igrac[playerid][ImeIgraca]);
        SendClientMessageToAll(-1, str);
    }
    return 1;
}

CMD:postaviadmina(playerid, params[])
{
    if(!AdminProvera(playerid, MAX_ADMIN_LEVEL)) return 1;
    if(!ProveriAdminDuznost(playerid)) return 1;

    new id, nivo;
    if(sscanf(params, "ui", id, nivo)) 
        return SendClientMessage(playerid, -1, "Koristi: /postaviadmina [ID/Ime] [Nivo]");

    if(!IsPlayerConnected(id)) 
        return SendClientMessage(playerid, -1, "[Admin System] Igrac nije na serveru!");

    if(nivo < -1 || nivo > MAX_ADMIN_LEVEL) 
        return SendClientMessage(playerid, -1, "[Admin System] Nevazeci nivo ( -1 do 6 )");

    Igrac[id][Admin] = nivo;
    SacuvajIgraca(id);

    new str[128];
    format(str, sizeof(str), "[Admin System] Postavio si igracu %s admin nivo %d", Igrac[id][ImeIgraca], nivo);
    SendClientMessage(playerid, ADMIN_BOJA, str);

    format(str, sizeof(str), "[Admin System] Admin %s ti je postavio admin nivo %d", Igrac[playerid][ImeIgraca], nivo);
    SendClientMessage(id, ADMIN_BOJA, str);
    LogAdminAction(playerid, id, "postaviadmina", "");
    return 1;
}
