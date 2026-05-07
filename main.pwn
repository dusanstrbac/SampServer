#pragma warning disable 239

#include <a_samp>
#include <a_mysql>
#include <streamer>
#include <zcmd>
#include "sscanf2.inc"
#include <YSI_Coding/y_hooks>
#include <YSI_Data\y_iterate>

new MySQL:g_SQL;

#include "modules/definicije.pwn"
#include "modules/items_base.pwn"
#include "modules/accounts.pwn"
#include "modules/banka.pwn"
#include "modules/sistem.pwn"
#include "modules/admin.pwn"
#include "modules/inventory.pwn"
#include "modules/tezge.pwn"
#include "modules/house.pwn"
#include "modules/bankomat.pwn"
#include "modules/poslovi.pwn"
#include "modules/ilegala.pwn"
#include "modules/farming.pwn"
#include "modules/igrac.pwn"

main()
{
	print("RP Server je pokrenut!");
}

public OnGameModeInit()
{
    DisableInteriorEnterExits();
    g_SQL = mysql_connect("127.0.0.1", "root", "", "SampServer");

	if(mysql_errno(g_SQL) != 0) {
		print("MySQL konekcija: Neuspela");
	} else {
		print("MySQL konekcija: Uspela");
	}
    
    mysql_tquery(g_SQL, "SELECT * FROM Kuce", "LoadHouses");

	SetGameModeText("My RP Server");
	SetTimer("AutoSaveTimer", 6000 * 5, true);
	SetTimer("SekundarniTimer", 1000, true);
	AddPlayerClass(0, 1682.0, -2334.0, 13.5, 0.0, 0, 0, 0, 0, 0, 0);

    // Ucitavanje sistema
    UcitajPointove();
    UcitajBankomate();
    UcitajPoslove();
    UcitajIlegaluSistem();
    mysql_tquery(g_SQL, "SELECT * FROM Biljke", "UcitajSveBiljke");
	return 1;
}

public OnPlayerConnect(playerid)
{
	SendClientMessage(playerid, -1, "Dobrodosao na RP server!");
	return 1;
}

public OnPlayerSpawn(playerid)
{
	SetPlayerPos(playerid, 1682.0, -2334.0, 13.5);
    SetPlayerVirtualWorld(playerid, 0);
    SetPlayerInterior(playerid, 0);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	if(Igrac[playerid][LoggedIn] == true) {
		SacuvajIgraca(playerid);
	}
	return 1;
}

forward UcitajPointove();
public UcitajPointove()
{
    // --- BANKA --- //
    CreateDynamicPickup(BANKA_OTVARANJE_RACUNA_ICON, 1, BANKA_OTVARANJE_RACUNA_X, BANKA_OTVARANJE_RACUNA_Y, BANKA_OTVARANJE_RACUNA_Z, 0, 0, -1, 100.0);
    CreateDynamic3DTextLabel(BANKA_OTVARANJE_RACUNA_LABEL, 0x00FF00FF, BANKA_OTVARANJE_RACUNA_X, BANKA_OTVARANJE_RACUNA_Y, BANKA_OTVARANJE_RACUNA_Z + 0.5, 30.0);
    CreateDynamicPickup(BANKA_PODIZANJE_KARTICE_ICON, 1, BANKA_PODIZANJE_KARTICE_X, BANKA_PODIZANJE_KARTICE_Y, BANKA_PODIZANJE_KARTICE_Z, 0, 0, -1, 100.0);
    CreateDynamic3DTextLabel(BANKA_PODIZANJE_KARTICE_LABEL, 0x00FF00FF, BANKA_PODIZANJE_KARTICE_X, BANKA_PODIZANJE_KARTICE_Y, BANKA_PODIZANJE_KARTICE_Z + 0.5, 30.0);

    // --- OPSTINA --- //
    CreateDynamicPickup(LICNA_KARTA_VADJENJE_ICON, 1, LICNA_KARTA_VADJENJE_X, LICNA_KARTA_VADJENJE_Y, LICNA_KARTA_VADJENJE_Z, 0, 0, -1, 100.0);
    CreateDynamic3DTextLabel(LICNA_KARTA_VADJENJE_LABEL, 0x00FF00FF, LICNA_KARTA_VADJENJE_X, LICNA_KARTA_VADJENJE_Y, LICNA_KARTA_VADJENJE_Z + 0.5, 30.0);

    return 1;
}

forward SekundarniTimer();
public SekundarniTimer()
{
    foreach(new i : Player)
    {
        // --- LOGIKA ZA ZATVOR --- //
        if(Igrac[i][ZatvorVreme] > 0)
        {
            Igrac[i][ZatvorVreme]--;

            // Obaveštenje na svakih 30 sekundi preko GameTexta (manje spama u chatu)
            if(Igrac[i][ZatvorVreme] % 30 == 0 && Igrac[i][ZatvorVreme] > 0)
            {
                new str[64];
                format(str, sizeof(str), "~w~Zatvor: ~r~%d sek", Igrac[i][ZatvorVreme]);
                GameTextForPlayer(i, str, 3000, 3);
            }

            if(Igrac[i][ZatvorVreme] <= 0)
            {
                Igrac[i][ZatvorVreme] = 0;
                
                SetPlayerPos(i, 1529.6, -1691.2, 13.3); // Spawn ispred LSPD
                SetPlayerInterior(i, 0);
                SetPlayerVirtualWorld(i, 0);
                
                SendClientMessage(i, -1, "{00FF00}[Zatvor]: {FFFFFF}Vasa kazna je istekla. Slobodni ste!");
                
                new query[128];
                mysql_format(g_SQL, query, sizeof(query), "UPDATE Accounts SET zatvorVreme = 0 WHERE id = %d", Igrac[i][IgracId]);
                mysql_tquery(g_SQL, query);
            }
        }

        // --- LOGIKA ZA MUTIRANOG IGRACA --- //
        if(Igrac[i][ServerMuted] > 0)
        {
            Igrac[i][ServerMuted]--;

            if(Igrac[i][ServerMuted] == 0)
            {
                SendClientMessage(i, -1, "[ Server | Info ] Vasa kazna je istekla, sada ponovo mozete pricati.");

                new query[128];
                mysql_format(g_SQL, query, sizeof(query), "UPDATE Accounts SET serverMute = 0 WHERE id = %d", Igrac[i][IgracId]);
                mysql_tquery(g_SQL, query);
            }
        }

        // --- ADMIN DUTY NOTIFIKACIJA ---
        // Ako je admin na duznosti, mozemo mu staviti mali podsetnik na ekranu
        if(Igrac[i][AdminDuty])
        {
            // Opciono: GameText ili TextDraw koji stoji dok je na duznosti
            // GameTextForPlayer(i, "~r~Admin na duznosti", 1500, 1);
        }
    }
    return 1;
}

forward ProxDetector(Float:radi, playerid, string[], col1, col2, col3, col4, col5);
public ProxDetector(Float:radi, playerid, string[], col1, col2, col3, col4, col5)
{
    if(!IsPlayerConnected(playerid)) return 0;

    new Float:posx, Float:posy, Float:posz;
    GetPlayerPos(playerid, posx, posy, posz);

    new Float:dist;
    new vw = GetPlayerVirtualWorld(playerid);
    new intid = GetPlayerInterior(playerid);

    foreach(new i : Player)
    {
        // DODATO: Ako je 'i' zapravo igrač koji priča, preskoči ga da mu ne duplira poruku
        if(i == playerid) continue; 

        if(IsPlayerConnected(i) && GetPlayerVirtualWorld(i) == vw && GetPlayerInterior(i) == intid)
        {
            dist = GetPlayerDistanceFromPoint(i, posx, posy, posz);
            if(dist < radi / 16) SendClientMessage(i, col1, string);
            else if(dist < radi / 8) SendClientMessage(i, col2, string);
            else if(dist < radi / 4) SendClientMessage(i, col3, string);
            else if(dist < radi / 2) SendClientMessage(i, col4, string);
            else if(dist < radi) SendClientMessage(i, col5, string);
        }
    }
    return 1;
}

public OnPlayerText(playerid, text[])
{
    // Ukoliko je igrac na pozivu sa nekim, ne dozvoljavamo mu da koristi chat dok je u pozivu i nece se formatirati poruka
    if(NaVeziSa[playerid] != INVALID_PLAYER_ID) return 0; 

    // --- UKOLIKO JE IGRAC MUTIRAN --- //
    if(Igrac[playerid][ServerMuted] > 0)
    {
        new str[64];
        format(str, sizeof(str), "[ Server | Info ]: Ne mozete pricati jos %d min.", Igrac[playerid][ServerMuted]);
        SendClientMessage(playerid, ERROR_BOJA, str);
        return 0;
    }

    // --- FORMATIRANJE CHATA --- //
    new chatStr[144], ime[MAX_PLAYER_NAME], prefix[32];
    GetPlayerName(playerid, ime, sizeof(ime));

    if(Igrac[playerid][Admin] > 0)
    {
        format(prefix, sizeof(prefix), "[%s] ", DajAdminNaziv(Igrac[playerid][Admin]));
    }
    else prefix = ""; // Bolje ostaviti prazno za igrace nego da pise "Igrac" ispred svakog

    format(chatStr, sizeof(chatStr), "[%d] %s%s: %s", playerid, prefix, ime, text);

    new Float:posX, Float:posY, Float:posZ;
    GetPlayerPos(playerid, posX, posY, posZ);

    foreach(new i : Player)
    {
        // Koristimo virtual world i interior proveru da se chat ne bi mesao kroz zidove/svetove
        if(GetPlayerVirtualWorld(i) == GetPlayerVirtualWorld(playerid) && GetPlayerInterior(i) == GetPlayerInterior(playerid))
        {
            if(IsPlayerInRangeOfPoint(i, 20.0, posX, posY, posZ))
            {
                SendClientMessage(i, -1, chatStr);
            }
        }
    }
    
    // Obavezno return 0 ovde jer si vec rucno poslao poruku preko SendClientMessage
    // Ako ostavis 1, SA-MP ce poslati i trecu, sistemsku poruku.
    return 0;
}