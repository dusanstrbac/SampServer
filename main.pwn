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
#include "modules/sistem.pwn"
#include "modules/admin.pwn"
#include "modules/inventory.pwn"
#include "modules/tezge.pwn"
#include "modules/house.pwn"
#include "modules/banka.pwn"


main()
{
	print("RP Server je pokrenut!");
}

public OnGameModeInit()
{
    print("DEBUG: Skripta je pokrenula OnGameModeInit");
	g_SQL = mysql_connect("localhost", "root", "SampServer", "");

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
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	if(Igrac[playerid][LoggedIn] == true) {
		SacuvajIgraca(playerid);
	}
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

public OnPlayerText(playerid, text[])
{
    // --- UKOLIKO JE IGRAC MUTIRAN --- //
    if(Igrac[playerid][ServerMuted] > 0)
    {
        new str[64];
        format(str, sizeof(str), "[ Server | Info ]: Ne mozete pricati jos %d min.", Igrac[playerid][ServerMuted]);
        SendClientMessage(playerid, -1, str);
        return 0;
    }
    return 1;
}