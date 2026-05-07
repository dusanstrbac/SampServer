#include <a_samp>
#include <a_mysql>


stock AdminProvera(playerid, potreban_nivo)
{
    if(Igrac[playerid][Admin] < potreban_nivo || Igrac[playerid][Admin] == -1 )
    {
        SendClientMessage(playerid, -1, "Niste ovlasceni da koristite ovu komandu");
        return 0;
    }
    return 1;
}

stock SacuvajIgraca(playerid)
{
    if(!Igrac[playerid][LoggedIn]) return 0;

    Igrac[playerid][Novac] = GetPlayerMoney(playerid);
    Igrac[playerid][Level] = GetPlayerScore(playerid);

    GetPlayerPos(playerid, Igrac[playerid][X], Igrac[playerid][Y], Igrac[playerid][Z]);
    GetPlayerFacingAngle(playerid, Igrac[playerid][R]);

    new sys_query[512];
    mysql_format(g_SQL, sys_query, sizeof(sys_query),
        "UPDATE Igraci SET novac=%d, level=%d, skin=%d, zatvorVreme=%d, admin=%d, adminDuty=%d, slotoviInventara=%d, x=%f, y=%f, z=%f, r=%f, serverMuted=%d, licnaKarta=%d, ugovor=%d, posao=%d, Telefon=%d, telefonKredit=%d, telfonBroj=%d WHERE id=%d",
        Igrac[playerid][Novac], Igrac[playerid][Level], Igrac[playerid][Skin], Igrac[playerid][ZatvorVreme], Igrac[playerid][Admin], Igrac[playerid][AdminDuty], Igrac[playerid][SlotoviInventara], 
        Igrac[playerid][X], Igrac[playerid][Y], Igrac[playerid][Z], Igrac[playerid][R], Igrac[playerid][ServerMuted], Igrac[playerid][LicnaKarta], 
        Igrac[playerid][pUgovor],
        Igrac[playerid][pPosaoID], Igrac[playerid][Telefon], Igrac[playerid][TelefonKredit], Igrac[playerid][TelefonBroj],
        Igrac[playerid][IgracId]
    );

    mysql_tquery(g_SQL, sys_query);
    return 1;
}

stock UcitajIgraca(playerid)
{
    cache_get_value_name_int(0, "id", Igrac[playerid][IgracId]);
    cache_get_value_name_int(0, "novac", Igrac[playerid][Novac]);
    cache_get_value_name_int(0, "level", Igrac[playerid][Level]);
    cache_get_value_name_int(0, "skin", Igrac[playerid][Skin]);
    cache_get_value_name_int(0, "zatvorVreme", Igrac[playerid][ZatvorVreme]);
    cache_get_value_name_int(0, "admin", Igrac[playerid][Admin]);
    cache_get_value_name_int(0, "adminDuty", Igrac[playerid][AdminDuty]);
    cache_get_value_name_int(0, "slotoviInventara", Igrac[playerid][SlotoviInventara]);

    cache_get_value_name_float(0, "x", Igrac[playerid][X]);
    cache_get_value_name_float(0, "y", Igrac[playerid][Y]);
    cache_get_value_name_float(0, "z", Igrac[playerid][Z]);
    cache_get_value_name_float(0, "r", Igrac[playerid][R]);

    cache_get_value_name_int(0, "serverMuted", Igrac[playerid][ServerMuted]);
    cache_get_value_name_int(0, "licnaKarta", Igrac[playerid][LicnaKarta]);
    cache_get_value_name_int(0, "ugovor", Igrac[playerid][pUgovor]);
    cache_get_value_name_int(0, "posao", Igrac[playerid][pPosaoID]);

    cache_get_value_name_int(0, "Telefon", Igrac[playerid][Telefon]);
    cache_get_value_name_int(0, "telefonKredit", Igrac[playerid][TelefonKredit]);
    cache_get_value_name_int(0, "telfonBroj", Igrac[playerid][TelefonBroj]);

    Igrac[playerid][LoggedIn] = true;

    if(Igrac[playerid][ZatvorVreme] > 0)
    {
        SetPlayerPos(playerid, 197.6661, 173.8179, 1003.0234); 
        SetPlayerInterior(playerid, 3);
        SendClientMessage(playerid, -1, "{FF0000}[Zatvor]: {FFFFFF}Vratili ste se u zatvor da odsluzite ostatak kazne.");
    }
    return 1;
}

forward AutoSave();
public AutoSave()
{
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i)) continue;
        if(!Igrac[i][LoggedIn]) continue;

        SacuvajIgraca(i);
    }
    return 1;
}
