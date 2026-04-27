enum banka_data {
    bIgracID,
    bImaRacun,
    bNovac,
    bKredit,
    bool:bUcitano
}
new BankovniRacun[MAX_PLAYERS][banka_data];

hook OnPlayerConnect(playerid)
{
    BankovniRacun[playerid][bImaRacun] = 0;
    BankovniRacun[playerid][bNovac] = 0;
    BankovniRacun[playerid][bKredit] = 0;
    BankovniRacun[playerid][bUcitano] = false;
    return 1;
}

stock UcitajBankovniRacun(playerid)
{
    new b_query[128];
    mysql_format(g_SQL, b_query, sizeof(b_query), "SELECT * FROM IgracBanka WHERE igracID = %d LIMIT 1", Igrac[playerid][IgracId]);
    mysql_tquery(g_SQL, b_query, "OnBankDataLoad", "i", playerid);
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
        mysql_format(g_SQL, b_query, sizeof(b_query), "INSERT INTO IgracBanka (igracID, imaRacun, novcaUBanci, kredit) VALUES (%d, 0, 0, 0)", Igrac[playerid][IgracId]);
        mysql_tquery(g_SQL, b_query);
        
        BankovniRacun[playerid][bImaRacun] = 0;
        BankovniRacun[playerid][bNovac] = 0;
        BankovniRacun[playerid][bKredit] = 0;
        BankovniRacun[playerid][bUcitano] = true;
    }
    return 1;
}