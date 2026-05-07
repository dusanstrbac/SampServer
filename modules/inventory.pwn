#include <YSI_Coding\y_hooks>

enum InvData {
    invId,
    InvIme[50],
    InvKolicina
};
new IgracInventory[MAX_PLAYERS][MAX_INV_SLOTOVA][InvData];

hook OnPlayerSpawn(playerid)
{
    UcitajInventar(playerid);
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    for(new i = 0; i < MAX_INV_SLOTOVA; i++)
    {
        IgracInventory[playerid][i][invId] = 0;
        IgracInventory[playerid][i][InvKolicina] = 0;
        IgracInventory[playerid][i][InvIme][0] = '\0'; // Brzi nacin za ciscenje stringa
    }
    return 1;
}

stock UcitajInventar(playerid)
{
    if(Igrac[playerid][IgracId] <= 0) return 0; // Sigurnosna provera

    new query[128];
    mysql_format(g_SQL, query, sizeof(query), "SELECT * FROM Inventar WHERE vlasnik_id = %d LIMIT %d", Igrac[playerid][IgracId], MAX_INV_SLOTOVA);
    mysql_tquery(g_SQL, query, "OnInventarLoaded", "i", playerid);
    return 1;
}

forward OnInventarLoaded(playerid);
public OnInventarLoaded(playerid)
{
    if(!IsPlayerConnected(playerid)) return 0;

    new rows = cache_num_rows();
    if(rows > 0)
    {
        for(new i = 0; i < rows && i < MAX_INV_SLOTOVA; i++)
        {
            cache_get_value_name_int(i, "id", IgracInventory[playerid][i][invId]);
            cache_get_value_name(i, "predmet_ime", IgracInventory[playerid][i][InvIme], 50);
            cache_get_value_name_int(i, "predmet_kolicina", IgracInventory[playerid][i][InvKolicina]);
            
            printf("[INV]: Ucitano %s (x%d) u slot %d za igraca %d", IgracInventory[playerid][i][InvIme], IgracInventory[playerid][i][InvKolicina], i, playerid);
        }
    }
    return 1;
}

CMD:inv(playerid, params[])
{
    return cmd_inventory(playerid, params);
}

CMD:inventory(playerid, params[])
{
    if(!Igrac[playerid][LoggedIn]) return 1;

    new listString[1024], naslov[64];
    format(naslov, sizeof(naslov), "Inventar (%d/%d slotova)", GetZauzetiSlotovi(playerid), Igrac[playerid][SlotoviInventara]);

    for(new i = 0; i < MAX_INV_SLOTOVA; i++)
    {
        if(i < Igrac[playerid][SlotoviInventara])
        {
            if(IgracInventory[playerid][i][invId] != 0)
            {
                format(listString, sizeof(listString), "%s%d. %s (x%d)\n", listString, i+1, IgracInventory[playerid][i][InvIme], IgracInventory[playerid][i][InvKolicina]);
            } else 
            {
                format(listString, sizeof(listString), "%s%d. {AAAAAA}[Prazan Slot]\n", listString, i+1);
            }
        } else
        {
            format(listString, sizeof(listString), "%s%d. {FF0000}[ZAKLJUCANO - Kupite ranac]\n", listString, i+1);
        }
    }
    SPD(playerid, D_INVENTORY, DIALOG_STYLE_LIST, naslov, listString, "Izaberi", "Zatvori");
    return 1;
}

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == D_INVENTORY)
    {
        if(!response) return 1;
        if(IgracInventory[playerid][listitem][invId] == 0) return 1;

        SetPVarInt(playerid, "IzabranSlot", listitem);

        new naslov[64];
        format(naslov, sizeof(naslov), "Opcije: %s", IgracInventory[playerid][listitem][InvIme]);
        
        SPD(playerid, D_INVENTORY_OPTIONS, DIALOG_STYLE_LIST, naslov, "1. Koristi\n2. Baci predmet", "Odaberi", "Nazad");
        return 1;
    }

    if(dialogid == D_INVENTORY_OPTIONS)
    {
        if(!response) 
        {
            new szEmpty[1]; szEmpty[0] = '\0';
            return cmd_inventory(playerid, szEmpty);
        }

        new slot = GetPVarInt(playerid, "IzabranSlot");
        if(slot < 0 || slot >= MAX_INV_SLOTOVA) return 1;

        new ime[50];
        format(ime, sizeof(ime), "%s", IgracInventory[playerid][slot][InvIme]);

        if(listitem == 0)
        {
            new baseID = DajItemBaseID(ime); 
            if(baseID == -1) return SendClientMessage(playerid, -1, "Predmet nije u bazi");

            switch(ServerItems[baseID][itemTip])
            {
                case 1:
                {
                    new Float:hp; GetPlayerHealth(playerid, hp);
                    new Float:healAmt = ServerItems[baseID][itemHeal];
                    SetPlayerHealth(playerid, (hp + healAmt > 100.0) ? 100.0 : hp + healAmt);
                    
                    new msg[128];
                    format(msg, sizeof(msg), "{00FF00}[Inventory System]: {FFFFFF}Iskoristili ste %s.", ime);
                    SendClientMessage(playerid, -1, msg);
                    OduzmiItem(playerid, ime, 1);
                }
                case 2:
                {
                    new dodatniSlotovi = floatround(ServerItems[baseID][itemHeal]);
                    if(Igrac[playerid][SlotoviInventara] >= (5 + dodatniSlotovi))  return SendClientMessage(playerid, -1, "{FF0000}[Inventory System]: {FFFFFF}Vec imate ranac te velicine ili veci.");

                    Igrac[playerid][SlotoviInventara] += dodatniSlotovi;
                    
                    new msg[128];
                    format(msg, sizeof(msg), "{00FF00}[Inv]: {FFFFFF}Iskoristili ste %s. Sada imate %d slotova.", ime, Igrac[playerid][SlotoviInventara]);
                    SendClientMessage(playerid, -1, msg);

                    OduzmiItem(playerid, ime, 1);
                    SacuvajIgraca(playerid);
                }
                default: SendClientMessage(playerid, -1, "Ovaj predmet nema funkciju");  
            }
        }
        else if(listitem == 1)
        {
            new str[128];
            format(str, sizeof(str), "{FFAA00}[Inv]: {FFFFFF}Bacili ste %s (x%d).", ime, IgracInventory[playerid][slot][InvKolicina]);
            SendClientMessage(playerid, -1, str);
            OduzmiItem(playerid, ime, IgracInventory[playerid][slot][InvKolicina]); 
        }
        return 1;
    }
    return 0;
}

stock SpakujUInv(playerid, const naziv[], kolicina)
{
    if(!Igrac[playerid][LoggedIn]) return 0;

    new slot = -1;
    for(new i = 0; i < Igrac[playerid][SlotoviInventara]; i++)
    {
        if(IgracInventory[playerid][i][invId] != 0 && !strcmp(IgracInventory[playerid][i][InvIme], naziv))
        {
            slot = i;
            break;
        }
    }

    new inv_query[256];
    if(slot != -1)
    {
        IgracInventory[playerid][slot][InvKolicina] += kolicina;
        mysql_format(g_SQL, inv_query, sizeof(inv_query), "UPDATE Inventar SET predmet_kolicina = %d WHERE id = %d", IgracInventory[playerid][slot][InvKolicina], IgracInventory[playerid][slot][invId]);
        mysql_tquery(g_SQL, inv_query);
        SendClientMessage(playerid, -1, "{00FF00}[Inventory System] {FFFFFF}Kolicina predmeta azurirana.");
    }
    else
    {
        new prazanSlot = -1;
        for(new i = 0; i < Igrac[playerid][SlotoviInventara]; i++)
        {
            if(IgracInventory[playerid][i][invId] == 0)
            {
                prazanSlot = i;
                break;
            }
        }
        if(prazanSlot == -1) 
        {
            SendClientMessage(playerid, -1, "{FF0000}[Greska] {FFFFFF}Nemate slobodnih slotova!");
            return 0;
        }

        IgracInventory[playerid][prazanSlot][InvKolicina] = kolicina;
        format(IgracInventory[playerid][prazanSlot][InvIme], 50, "%s", naziv);

        mysql_format(g_SQL, inv_query, sizeof(inv_query), "INSERT INTO Inventar (vlasnik_id, predmet_ime, predmet_kolicina) VALUES (%d, '%e', %d)", Igrac[playerid][IgracId], naziv, kolicina);
        mysql_tquery(g_SQL, inv_query, "OnItemAddedToInv", "ii", playerid, prazanSlot);
    }
    return 1;
}

stock ImaItemUInv(playerid, const naziv[])
{
    for(new i = 0; i < Igrac[playerid][SlotoviInventara]; i++)
    {
        if(IgracInventory[playerid][i][invId] != 0 && !strcmp(IgracInventory[playerid][i][InvIme], naziv))
        {
            return 1; // Ima item u inventaru
        }
    }
    return 0; // Nema item u inventaru
}

stock OduzmiItem(playerid, const naziv[], kolicina)
{
    for(new i = 0; i < MAX_INV_SLOTOVA; i++)
    {
        if(IgracInventory[playerid][i][invId] != 0 && !strcmp(IgracInventory[playerid][i][InvIme], naziv))
        {
            IgracInventory[playerid][i][InvKolicina] -= kolicina;
            new inv_query[128];

            if(IgracInventory[playerid][i][InvKolicina] <= 0)
            {
                mysql_format(g_SQL, inv_query, sizeof(inv_query), "DELETE FROM Inventar WHERE id = %d", IgracInventory[playerid][i][invId]);
                mysql_tquery(g_SQL, inv_query);

                IgracInventory[playerid][i][invId] = 0;
                IgracInventory[playerid][i][InvKolicina] = 0;
                format(IgracInventory[playerid][i][InvIme], 50, "");
            }
            else
            {
                mysql_format(g_SQL, inv_query, sizeof(inv_query), "UPDATE Inventar SET predmet_kolicina = %d WHERE id = %d", IgracInventory[playerid][i][InvKolicina], IgracInventory[playerid][i][invId]);
                mysql_tquery(g_SQL, inv_query);
            }
            return 1;
        }
    }
    return 0;
}

stock GetZauzetiSlotovi(playerid)
{
    new count = 0;
    for(new i = 0; i < MAX_INV_SLOTOVA; i++)
    {
        if(IgracInventory[playerid][i][invId] != 0) count++;
    }
    return count;
}

forward OnItemAddedToInv(playerid, slot);
public OnItemAddedToInv(playerid, slot)
{
    IgracInventory[playerid][slot][invId] = cache_insert_id();
    return 1;
}