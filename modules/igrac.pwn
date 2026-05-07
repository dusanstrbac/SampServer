#define CENA_TELEFONA 500
#define CENA_KARTICE 150
#define CENA_POZIVA 100 
#define CENA_PORUKE 5   
#define MIN_UPLATA 100
#define MAX_UPLATA 2000

new PozivUpucen[MAX_PLAYERS] = {INVALID_PLAYER_ID, ...}; 
new NaVeziSa[MAX_PLAYERS] = {INVALID_PLAYER_ID, ...};   

hook OnPlayerConnect(playerid)
{
    Igrac[playerid][Telefon] = 0;
    Igrac[playerid][TelefonBroj] = 0;
    Igrac[playerid][TelefonKredit] = 0;
    NaVeziSa[playerid] = INVALID_PLAYER_ID;
    PozivUpucen[playerid] = INVALID_PLAYER_ID;
}

hook OnPlayerDisconnect@Igrac(playerid, reason)
{
    if(NaVeziSa[playerid] != INVALID_PLAYER_ID)
    {
        new tid = NaVeziSa[playerid];
        SendClientMessage(tid, -1, "{FF0000}[Mobilni]: {FFFFFF}Veza prekinuta (sagovornik izasao).");
        NaVeziSa[tid] = INVALID_PLAYER_ID;
    }
    SacuvajIgraca(playerid);
    return 1;
}

// --- KOMANDE ---

CMD:kupitelefon(playerid, params[])
{
    if(Igrac[playerid][Telefon] == 1) 
        return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Vec imate mobilni telefon!");

    if(GetPlayerMoney(playerid) < CENA_TELEFONA)
        return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Nemate dovoljno novca ($500)!");

    GivePlayerMoney(playerid, -CENA_TELEFONA);
    Igrac[playerid][Telefon] = 1;
    
    SacuvajIgraca(playerid); // Koristimo tvoju postojecu funkciju

    SendClientMessage(playerid, -1, "{00FF00}[Prodavnica]: {FFFFFF}Kupili ste mobilni telefon. Sada kupite SIM karticu.");
    return 1;
}

CMD:kupikarticu(playerid, params[])
{
    if(Igrac[playerid][Telefon] == 0)
        return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Morate prvo kupiti telefon!");

    if(Igrac[playerid][TelefonBroj] != 0)
        return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Vec imate SIM karticu u telefonu!");

    if(GetPlayerMoney(playerid) < CENA_KARTICE)
        return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Nemate dovoljno novca ($150)!");

    GivePlayerMoney(playerid, -CENA_KARTICE);
    GenerisiBroj(playerid); 
    
    SendClientMessage(playerid, -1, "{00FF00}[Prodavnica]: {FFFFFF}Kupili ste SIM karticu. Vas broj se generise...");
    return 1;
}

CMD:uplatikredit(playerid, params[])
{
    if(Igrac[playerid][TelefonBroj] == 0)
        return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Nemate SIM karticu!");

    new iznos;
    if(sscanf(params, "i", iznos)) 
        return SendClientMessage(playerid, -1, "{FFFF00}Koristite: {FFFFFF}/uplatikredit [iznos]");

    if(iznos < MIN_UPLATA || iznos > MAX_UPLATA)
        return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Minimalna uplata je $100, a maksimalna $2000!");

    if(GetPlayerMoney(playerid) < iznos)
        return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Nemate dovoljno novca!");

    GivePlayerMoney(playerid, -iznos);
    Igrac[playerid][TelefonKredit] += iznos;
    SacuvajIgraca(playerid);

    new str[128];
    format(str, sizeof(str), "{00FF00}[Mobilni]: {FFFFFF}Uplatili ste $%d kredita. Novo stanje: {FFFF00}$%d.", iznos, Igrac[playerid][TelefonKredit]);
    SendClientMessage(playerid, -1, str);
    return 1;
}

CMD:call(playerid, params[])
{
    if(Igrac[playerid][Telefon] == 0) return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Nemate telefon!");
    if(Igrac[playerid][TelefonBroj] == 0) return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Nemate SIM karticu!");
    if(Igrac[playerid][TelefonKredit] < CENA_POZIVA) return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Nemate dovoljno kredita ($100)!");
    if(NaVeziSa[playerid] != INVALID_PLAYER_ID) return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Vec ste u pozivu!");

    new targetbroj;
    if(sscanf(params, "i", targetbroj)) return SendClientMessage(playerid, -1, "{FFFF00}Koristite: {FFFFFF}/call [broj telefona]");

    if(targetbroj == Igrac[playerid][TelefonBroj]) return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Ne mozete zvati sami sebe!");

    new targetid = INVALID_PLAYER_ID;
    foreach(new i : Player)
    {
        if(Igrac[i][TelefonBroj] == targetbroj && Igrac[i][TelefonBroj] != 0)
        {
            targetid = i;
            break;
        }
    }

    if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, -1, "{FF0000}[Mobilni]: {FFFFFF}Pretplatnik trenutno nije dostupan.");
    if(NaVeziSa[targetid] != INVALID_PLAYER_ID || PozivUpucen[targetid] != INVALID_PLAYER_ID) 
        return SendClientMessage(playerid, -1, "{FF0000}[Mobilni]: {FFFFFF}Linija je zauzeta.");

    PozivUpucen[playerid] = targetid;
    
    new str[128];
    format(str, sizeof(str), "{FFFF00}[Mobilni]: {FFFFFF}Pozivate broj %d... (sacekajte odgovor)", targetbroj);
    SendClientMessage(playerid, -1, str);

    format(str, sizeof(str), "{FFFF00}[Mobilni]: {FFFFFF}Telefon vam zvoni! Poziv od: {FFFF00}%d {FFFFFF}(/answer za javljanje)", Igrac[playerid][TelefonBroj]);
    SendClientMessage(targetid, -1, str);
    
    PlayerPlaySound(targetid, 1167, 0.0, 0.0, 0.0); 
    return 1;
}

CMD:answer(playerid, params[])
{
    new callerid = INVALID_PLAYER_ID;
    foreach(new i : Player)
    {
        if(PozivUpucen[i] == playerid)
        {
            callerid = i;
            break;
        }
    }

    if(callerid == INVALID_PLAYER_ID) return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Niko vas ne zove.");

    NaVeziSa[playerid] = callerid;
    NaVeziSa[callerid] = playerid;
    PozivUpucen[callerid] = INVALID_PLAYER_ID;

    Igrac[callerid][TelefonKredit] -= CENA_POZIVA;

    SendClientMessage(playerid, -1, "{00FF00}[Mobilni]: {FFFFFF}Javili ste se. Sada mozete pricati direktno u chat.");
    SendClientMessage(callerid, -1, "{00FF00}[Mobilni]: {FFFFFF}Sagovornik se javio. Sada mozete pricati direktno u chat.");
    
    PlayerPlaySound(playerid, 1083, 0.0, 0.0, 0.0);
    PlayerPlaySound(callerid, 1083, 0.0, 0.0, 0.0);

    // Pustanje tajmera koji ce proveriti da li je poziv jos uvek aktivan i prekinuti ga ako je sagovornik ostao bez kredita
    SetTimerEx("TajmerPoziva", 60000, true, "ii", playerid, callerid); // Proverava svakih 60 sekundi

    // SQL update za smanjenje kredita
    new query[128];
    mysql_format(g_SQL, query, sizeof(query), "UPDATE Igraci SET telefonKredit = %d WHERE id = %d", Igrac[callerid][TelefonKredit], Igrac[callerid][IgracId]);
    mysql_tquery(g_SQL, query);
    
    SacuvajIgraca(callerid);

    return 1;
}

forward TajmerPoziva(playerid, callerid);
public TajmerPoziva(playerid, callerid)
{
    // Provera da li su obojica i dalje online i na vezi jedan sa drugim
    if(NaVeziSa[playerid] != callerid || NaVeziSa[callerid] != playerid)
    {
        return 0; 
    }

    // Provera kredita kod onoga ko je zvao (callerid)
    if(Igrac[callerid][TelefonKredit] < CENA_POZIVA)
    {
        SendClientMessage(callerid, -1, "{FF0000}[ Mobilni ]: {FFFFFF}Nemate vise kredita. Veza je prekinuta.");
        SendClientMessage(playerid, -1, "{FF0000}[ Mobilni ]: {FFFFFF}Veza je prekinuta (sagovornik je ostao bez kredita).");
        
        NaVeziSa[playerid] = INVALID_PLAYER_ID;
        NaVeziSa[callerid] = INVALID_PLAYER_ID;
        return 0; // Gasi tajmer
    }

    // Skidanje kredita na svakih minut
    Igrac[callerid][TelefonKredit] -= CENA_POZIVA;

    // SQL update kredita
    new query[128];
    mysql_format(g_SQL, query, sizeof(query), "UPDATE Igraci SET telefonKredit = %d WHERE id = %d", 
        Igrac[callerid][TelefonKredit], Igrac[callerid][IgracId]);
    mysql_tquery(g_SQL, query);
    return 1;
}

CMD:h(playerid, params[])
{
    if(NaVeziSa[playerid] == INVALID_PLAYER_ID && PozivUpucen[playerid] == INVALID_PLAYER_ID) 
        return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Niste u pozivu niti koga probate dobiti.");

    new targetid = NaVeziSa[playerid];
    if(targetid != INVALID_PLAYER_ID)
    {
        SendClientMessage(playerid, -1, "{FFFF00}[Mobilni]: {FFFFFF}Prekinuli ste vezu.");
        SendClientMessage(targetid, -1, "{FFFF00}[Mobilni]: {FFFFFF}Sagovornik je prekinuo vezu.");
        NaVeziSa[playerid] = INVALID_PLAYER_ID;
        NaVeziSa[targetid] = INVALID_PLAYER_ID;
    }
    else
    {
        new ringing = PozivUpucen[playerid];
        SendClientMessage(playerid, -1, "{FFFF00}[Mobilni]: {FFFFFF}Prekinuli ste pozivanje.");
        if(IsPlayerConnected(ringing)) SendClientMessage(ringing, -1, "{FFFF00}[Mobilni]: {FFFFFF}Propusten poziv.");
        PozivUpucen[playerid] = INVALID_PLAYER_ID;
    }
    return 1;
}

CMD:sms(playerid, params[])
{
    if(Igrac[playerid][Telefon] == 0) return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Nemate telefon!");
    if(Igrac[playerid][TelefonBroj] == 0) return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Nemate SIM karticu!");
    if(Igrac[playerid][TelefonKredit] < CENA_PORUKE) return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Nemate dovoljno kredita ($5)!");

    new targetbroj, poruka[128];
    if(sscanf(params, "is[128]", targetbroj, poruka)) return SendClientMessage(playerid, -1, "{FFFF00}Koristite: {FFFFFF}/sms [broj] [tekst]");

    new targetid = INVALID_PLAYER_ID;
    foreach(new i : Player)
    {
        if(Igrac[i][TelefonBroj] == targetbroj && Igrac[i][TelefonBroj] != 0)
        {
            targetid = i;
            break;
        }
    }

    if(targetid == INVALID_PLAYER_ID) return SendClientMessage(playerid, -1, "{FF0000}[Mobilni]: {FFFFFF}Poruka nije isporucena. Pretplatnik nije dostupan.");

    Igrac[playerid][TelefonKredit] -= CENA_PORUKE;

    new str[256];
    format(str, sizeof(str), "{FFFF00}[SMS poslat - %d]: {FFFFFF}%s", targetbroj, poruka);
    SendClientMessage(playerid, -1, str);

    format(str, sizeof(str), "{FFFF00}[SMS poruka - %d]: {FFFFFF}%s", Igrac[playerid][TelefonBroj], poruka);
    SendClientMessage(targetid, -1, str);

    PlayerPlaySound(targetid, 1052, 0.0, 0.0, 0.0);

    // SQL update za smanjenje kredita
    new query[128];
    mysql_format(g_SQL, query, sizeof(query), "UPDATE Igraci SET telefonKredit = %d WHERE id = %d", Igrac[playerid][TelefonKredit], Igrac[playerid][IgracId]);
    mysql_tquery(g_SQL, query);

    SacuvajIgraca(playerid);
    return 1;
}

CMD:proverikredit(playerid, params[])
{
    if(Igrac[playerid][Telefon] == 0) return SendClientMessage(playerid, -1, "Nemate telefon.");
    if(Igrac[playerid][TelefonBroj] == 0) return SendClientMessage(playerid, -1, "Nemate SIM karticu.");

    new str[128];
    format(str, sizeof(str), "{00FF00}[Mobilni]: {FFFFFF}Vase trenutno stanje kredita je: {FFFF00}$%d.", Igrac[playerid][TelefonKredit]);
    SendClientMessage(playerid, -1, str);
    return 1;
}

// --- CALLBACKS ---

hook OnPlayerText(playerid, text[])
{
    if(NaVeziSa[playerid] != INVALID_PLAYER_ID)
    {
        new targetid = NaVeziSa[playerid];
        new str[144];
        
        // 1. Poruka tebi (ZUTA) - ti je vidis kao potvrdu da si nesto rekao
        format(str, sizeof(str), "{FFFF00}(u telefon) %s: {FFFFFF}%s", Igrac[playerid][ImeIgraca], text);
        SendClientMessage(playerid, -1, str);

        // 2. Poruka sagovorniku (ZUTA) - on cuje sta mu pricas
        format(str, sizeof(str), "{FFFF00}(telefon - sagovornik) %s: {FFFFFF}%s", Igrac[playerid][ImeIgraca], text);
        SendClientMessage(targetid, -1, str);

        // 3. Poruka okolini (SIVA) - ProxDetector
        // BITNO: Moramo paziti da ProxDetector ne posalje poruku TEBI ponovo
        format(str, sizeof(str), "%s kaze (u telefon): %s", Igrac[playerid][ImeIgraca], text);
        
        // Pozivamo ProxDetector sa dometom
        // col1 do col5 su nijanse sive (od svetle ka tamnoj)
        ProxDetector(15.0, playerid, str, 0xE6E6E6FF, 0xC8C8C8FF, 0xAAAAAAAAFF, 0x8C8C8CFF, 0x6E6E6EFF);

        // KLJUČNA STVAR: vracamo 0 da SA-MP ne bi poslao tvoju originalnu belu poruku u chat!
        return 0; 
    }
    return 1; 
}

// --- FUNKCIJE ZA BROJ ---

forward GenerisiBroj(playerid);
public GenerisiBroj(playerid)
{
    // Generiše broj od 6 cifara (100000 - 999999)
    new randBroj = 100000 + random(900000); 
    new query[128];
    
    // PROVERI: Da li se kolona u bazi zove "telfonBroj" ili "TelefonBroj"? 
    // Mora biti identično kao u tabeli 'Igraci'
    mysql_format(g_SQL, query, sizeof(query), "SELECT telfonBroj FROM Igraci WHERE telfonBroj = %d LIMIT 1", randBroj);
    mysql_tquery(g_SQL, query, "ProveriBrojCB", "ii", playerid, randBroj);
    return 1;
}

forward ProveriBrojCB(playerid, broj);
public ProveriBrojCB(playerid, broj)
{
    if(!IsPlayerConnected(playerid)) return 1;

    if(cache_num_rows() > 0) 
    {
        return GenerisiBroj(playerid); 
    }
    
    // Dodeli broj igraču
    Igrac[playerid][TelefonBroj] = broj;
    Igrac[playerid][Telefon] = 1; // Pretpostavljam da mu ovime aktiviraš posedovanje telefona/kartice
    
    // Sačuvaj odmah u bazu
    SacuvajIgraca(playerid);

    new str[128];
    format(str, sizeof(str), "{00FF00}[Mobilni]: {FFFFFF}Uspesno ste aktivirali karticu. Vas broj: {FFFF00}%d", broj);
    SendClientMessage(playerid, -1, str);
    
    printf("[DEBUG]: Igrac %s je dobio broj %d", Igrac[playerid][ImeIgraca], broj);
    return 1;
}