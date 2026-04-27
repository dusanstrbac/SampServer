#include <YSI_Coding\y_hooks>

enum tezgaData {
    tID,
    tTip,
    Float: tX,
    Float: tY,
    Float: tZ,
    Float: tR,
    Text3D:tLabelID,
    tPickupID,
    tActorID
};
new TezgaInfo[MAX_TEZGI][tezgaData];

hook OnGameModeInit()
{
    print("[Tezga System] Ucitavanje tezgi iz sistema");
    mysql_tquery(g_SQL, "SELECT * FROM Tezge", "UcitajSveTezge");
    return 1;
}

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == D_PIJACA_RANAC)
    {
        if(!response) return 1;

        new cena, naziv[50];
        switch(listitem)
        {
            case 0: { cena = CENA_MALI_RANAC; format(naziv, 50, ITEM_MALI_RANAC); }
            case 1: { cena = CENA_SREDNJI_RANAC; format(naziv, 50, ITEM_SREDNJI_RANAC); }
            case 2: { cena = CENA_VELIKI_RANAC; format(naziv, 50, ITEM_VELIKI_RANAC); }
        }

        if(GetPlayerMoney(playerid) < cena) 
            return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Nemas dovoljno novca!");

        if(SpakujUInv(playerid, naziv, 1))
        {
            GivePlayerMoney(playerid, -cena);
            new msg[128];
            format(msg, sizeof(msg), "{00FF00}[Pijaca]: {FFFFFF}Uspesno ste kupili %s za $%d.", naziv, cena);
            SendClientMessage(playerid, -1, msg);
        }
        return 1;
    }
    return 0;
}

CMD:kreirajtezgu(playerid, params[])
{
    if(!AdminProvera(playerid, 1)) return 1;

    new tip;
    if(sscanf(params, "d", tip)) return SendClientMessage(playerid, -1, "[Tezga System] Koristi /kreirajtezgu [tip (1-Rancevi, 2-Povrce)]");

    new Float:t_PosX, Float:t_PosY, Float:t_PosZ, Float:t_Angle;
    GetPlayerPos(playerid, t_PosX, t_PosY, t_PosZ);
    GetPlayerFacingAngle(playerid, t_Angle);

    new tezge_query[256];
    mysql_format(g_SQL, tezge_query, sizeof(tezge_query), "INSERT INTO Tezge(tip, posX, posY, posZ, angle) VALUES (%d, '%f', '%f', '%f', '%f')", tip, t_PosX, t_PosY, t_PosZ, t_Angle);
    mysql_tquery(g_SQL, tezge_query, "onTezgaKreirana", "idffff", playerid, tip, t_PosX, t_PosY, t_PosZ, t_Angle);

    SendClientMessage(playerid, -1, "[Tezga System] Tezga uspesno kreirana");
    return 1;
}

CMD:obrisitezgu(playerid, params[])
{
    if(!AdminProvera(playerid, 4)) return 1;

    new id = -1;
    for(new i = 0; i < MAX_TEZGI; i++)
    {
        if(TezgaInfo[i][tID] != 0)
        {
            if(IsPlayerInRangeOfPoint(playerid, 2.0, TezgaInfo[i][tX], TezgaInfo[i][tY], TezgaInfo[i][tZ]))
            {
                id = i;
                break;
            }
        }
    }

    if(id == -1) return SendClientMessage(playerid, -1, "{FF0000}[Greska]: {FFFFFF}Niste blizu nijedne tezge.");

    new tezge_query[128];
    mysql_format(g_SQL, tezge_query, sizeof(tezge_query), "DELETE FROM Tezge WHERE id = %d", TezgaInfo[id][tID]);
    mysql_tquery(g_SQL, tezge_query);

    DestroyDynamicActor(TezgaInfo[id][tActorID]);
    DestroyDynamic3DTextLabel(TezgaInfo[id][tLabelID]);
    DestroyDynamicPickup(TezgaInfo[id][tPickupID]);

    TezgaInfo[id][tID] = 0;
    TezgaInfo[id][tTip] = 0;
    
    SendClientMessage(playerid, -1, "{00FF00}[Tezga System]: {FFFFFF}Tezga je uspesno obrisana iz baze i sa mape.");
    return 1;
}

CMD:kupiranac(playerid, params[])
{
    new slot = -1;
    
    for(new i = 0; i < MAX_TEZGI; i++)
    {
        if(TezgaInfo[i][tID] != 0 && TezgaInfo[i][tTip] == TEZGA_TIP_RANAC)
        {
            if(IsPlayerInRangeOfPoint(playerid, 3.0, TezgaInfo[i][tX], TezgaInfo[i][tY], TezgaInfo[i][tZ]))
            {
                slot = i;
                break;
            }
        }
    }
    if(slot == -1) return 1;

    new menuStr[256];
    format(menuStr, sizeof(menuStr), 
        "Artikal\tCena\n\
        %s\t{00FF00}$%d\n\
        %s\t{00FF00}$%d\n\
        %s\t{00FF00}$%d", 
        ITEM_MALI_RANAC, CENA_MALI_RANAC,
        ITEM_SREDNJI_RANAC, CENA_SREDNJI_RANAC,
        ITEM_VELIKI_RANAC, CENA_VELIKI_RANAC
    );

    SPD(playerid, D_PIJACA_RANAC, DIALOG_STYLE_TABLIST_HEADERS, "Pijaca - Rancevi", menuStr, "Kupi", "Izlaz");
    return 1;
}

forward onTezgaKreirana(playerid, tip, Float:x, Float:y, Float:z, Float:r);
public onTezgaKreirana(playerid, tip, Float:x, Float:y, Float:z, Float:r)
{
    new dbID = cache_insert_id();
    new slot = -1;

    for(new i = 0; i < MAX_TEZGI; i++)
    {
        if(TezgaInfo[i][tID] == 0) { slot = i; break; }
    }

    if(slot != -1)
    {
        TezgaInfo[slot][tID] = dbID;
        TezgaInfo[slot][tTip] = tip;
        TezgaInfo[slot][tX] = x;
        TezgaInfo[slot][tY] = y;
        TezgaInfo[slot][tZ] = z;
        TezgaInfo[slot][tR] = r;
        
        new skinID = (tip == 1) ? 157 : 158;
        TezgaInfo[slot][tActorID] = CreateDynamicActor(skinID, x, y, z, r, .invulnerable = 1, .worldid = 0);

        new labelString[128];
        if(tip == 1) { format(labelString, sizeof(labelString), "Rancevi\nPritisnite F da zapocnete kupovinu"); }
        else { format(labelString, sizeof(labelString), "Tezga\nPritisnite F za interakciju"); }

        TezgaInfo[slot][tLabelID] = CreateDynamic3DTextLabel(labelString, -1, x, y, z + 0.5, 10.0);
        TezgaInfo[slot][tPickupID] = CreateDynamicPickup(1239, 1, x, y, z);

        SendClientMessage(playerid, -1, "[Tezga System] Tezga je uspesno aktivirana na vasoj poziciji.");

        if(tip == 1)
        {
            ApplyDynamicActorAnimation(TezgaInfo[slot][tActorID], "DEALER", "DEALER_IDLE", 4.1, 1, 0, 0, 0, 0);
        }
        else
        {
            ApplyDynamicActorAnimation(TezgaInfo[slot][tActorID], "PED", "IDLE_STANCE", 4.1, 1, 0, 0, 0, 0);
        }
    }
    return 1;
}

forward UcitajSveTezge();
public UcitajSveTezge()
{
    new rows = cache_num_rows();
    if(rows == 0) return print("[Tezga System] Nema sacuvanih tezgi u sistemu");

    for(new i = 0; i < rows; i++)
    {
        if(i >= MAX_TEZGI)
        {
            printf("[Tezga System] Dostegnut MAX_TEZGI (%d). Neke tezge nisu ucitane", MAX_TEZGI);
            break;
        }

        cache_get_value_name_int(i, "id", TezgaInfo[i][tID]);
        cache_get_value_name_int(i, "tip", TezgaInfo[i][tTip]);
        cache_get_value_name_float(i, "posX", TezgaInfo[i][tX]);
        cache_get_value_name_float(i, "posY", TezgaInfo[i][tY]);
        cache_get_value_name_float(i, "posZ", TezgaInfo[i][tZ]);
        cache_get_value_name_float(i, "angle", TezgaInfo[i][tR]);

        new skinID = (TezgaInfo[i][tTip] == TEZGA_TIP_RANAC) ? 157 : 158;
        TezgaInfo[i][tActorID] = CreateDynamicActor(skinID, TezgaInfo[i][tX], TezgaInfo[i][tY], TezgaInfo[i][tZ], TezgaInfo[i][tR], 1, 100.0, 0);

        new labelString[128];
        if(TezgaInfo[i][tTip] == 1) 
        {
            format(labelString, sizeof(labelString), "Rancevi\nPritisnite F da zapocnete kupovinu");
        } else 
        {
            format(labelString, sizeof(labelString), "Tezga\nPritisnite F za interakciju");
        }

        TezgaInfo[i][tLabelID] = CreateDynamic3DTextLabel(labelString, -1, TezgaInfo[i][tX], TezgaInfo[i][tY], TezgaInfo[i][tZ] + 0.5, 10.0);
        TezgaInfo[i][tPickupID] = CreateDynamicPickup(1239, 1, TezgaInfo[i][tX], TezgaInfo[i][tY], TezgaInfo[i][tZ]);
    }
    printf("[Tezga System] Uspesno ucitano %d tezgi", rows);
    return 1;
}