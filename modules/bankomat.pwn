new TajmerZaPljacku[MAX_BANKOMATA];
new PlayerRobCooldown[MAX_PLAYERS];

enum atm_data {
    atmID,
    Float:atmX,
    Float:atmY,
    Float:atmZ,
    Float:atmR,
    atmObjekat,
    Text3D:atmLabel
}
new ATM[MAX_BANKOMATA][atm_data];

stock PronadjiSlobodanATMSlot() {
    for(new i = 0; i < MAX_BANKOMATA; i++) {
        if(ATM[i][atmID] == 0) return i;
    }
    return -1;
}

stock UcitajBankomate()
{
    mysql_tquery(g_SQL, "SELECT * FROM bankomati", "OnBankomatiUcitani");
    return 1;
}

stock IsPlayerNearATM(playerid)
{
    for(new i = 0; i < MAX_BANKOMATA; i++)
    {
        if(ATM[i][atmID] != 0)
        {
            if(IsPlayerInRangeOfPoint(playerid, 2.5, ATM[i][atmX], ATM[i][atmY], ATM[i][atmZ]))
            {
                return 1;
            }
        }
    }
    return 0;
}

forward OnBankomatiUcitani();
public OnBankomatiUcitani()
{
    new rows = cache_num_rows();
    if(rows > 0)
    {
        for(new i = 0; i < rows; i++)
        {
            new id = i; 
            
            cache_get_value_name_int(i, "id", ATM[id][atmID]);
            cache_get_value_name_float(i, "x", ATM[id][atmX]);
            cache_get_value_name_float(i, "y", ATM[id][atmY]);
            cache_get_value_name_float(i, "zr", ATM[id][atmZ]);
            cache_get_value_name_float(i, "r", ATM[id][atmR]);

            ATM[id][atmObjekat] = CreateDynamicObject(19526, ATM[id][atmX], ATM[id][atmY], ATM[id][atmZ], 0.0, 0.0, ATM[id][atmR]);

            new labelStr[128];
            format(labelStr, sizeof(labelStr), BANKOMAT_LABEL_TEXT, id);
            ATM[id][atmLabel] = CreateDynamic3DTextLabel(labelStr, -1, ATM[id][atmX], ATM[id][atmY], ATM[id][atmZ] + 1.2, 10.0);
        }
        printf("[ Bankomat System ]: Uspesno ucitano %d bankomata.", rows);
    }
    else
    {
        print("[ Bankomat System ]: Nema bankomata u bazi podataka.");
    }
    return 1;
}


forward OnATMInsert(atmid);
public OnATMInsert(atmid) {
    ATM[atmid][atmID] = cache_insert_id(); 
    return 1;
}

hook OnPlayerEditDynObj@ATM(playerid, objectid, response, Float:x, Float:y, Float:z, Float:rx, Float:ry, Float:rz)
{
    if(GetPVarInt(playerid, "KreiraNoviATM") == 1)
    {
        if(response == EDIT_RESPONSE_FINAL)
        {
            new id = GetPVarInt(playerid, "ATM_SlotID");

            ATM[id][atmX] = x;
            ATM[id][atmY] = y;
            ATM[id][atmZ] = z;
            ATM[id][atmR] = rz;
            ATM[id][atmObjekat] = objectid;

            new query[256];
            mysql_format(g_SQL, query, sizeof(query), 
                "INSERT INTO bankomati (x, y, zr, r) VALUES (%f, %f, %f, %f)", 
                x, y, z, rz);
            mysql_tquery(g_SQL, query, "OnATMInsert", "i", id);

            new labelStr[128];
            format(labelStr, sizeof(labelStr), ""TEXT_ZELENA"[ Bankomat ID: %d ]\n{FFFFFF}Koristite 'H'\nda pristupite bankomatu", id);
            ATM[id][atmLabel] = CreateDynamic3DTextLabel(labelStr, -1, x, y, z + 1.2, 10.0);

            DeletePVar(playerid, "KreiraNoviATM");
            DeletePVar(playerid, "ATM_SlotID");
            SendClientMessage(playerid, ADMIN_BOJA, "[ Bankomat System | Admin ]: Bankomat uspesno kreiran i sacuvan u bazi.");
        }
        else if(response == EDIT_RESPONSE_CANCEL)
        {
            DestroyDynamicObject(objectid);
            DeletePVar(playerid, "KreiraNoviATM");
            DeletePVar(playerid, "ATM_SlotID");
            SendClientMessage(playerid, ERROR_BOJA, "[ Bankomat System ]: Kreiranje bankomata otkazano.");
        }
    }
    return 1;
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if ((newkeys & KEY_WALK) && !(oldkeys & KEY_WALK))
    {
        if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER || GetPlayerState(playerid) == PLAYER_STATE_PASSENGER) return 1;

        new id = -1;
        for(new i = 0; i < MAX_BANKOMATA; i++)
        {
            if(ATM[i][atmID] != 0)
            {
                if(IsPlayerInRangeOfPoint(playerid, 2.0, ATM[i][atmX], ATM[i][atmY], ATM[i][atmZ]))
                {
                    id = i;
                    break;
                }
            }
        }
        if(id != -1)
        {
            OtvoriBankaMeni(playerid); 
        }
    }
    return 1;
}

stock ZapocniPljackuATM(playerid, atmid)
{
    ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.1, 1, 0, 0, 1, 0, 1);
    
    // Upisivanje logova adminima ==== Prosiriti kasnije za logove igraca
    new poruka[128];
    format(poruka, sizeof(poruka), "[ Admin System | Log ]: Igrac %s je zapoceo pljacku bankomata ID: %d", Igrac[playerid][ImeIgraca], ATM[atmid][atmID]);
    LiveAdminLog(ADMIN_BOJA, poruka);

    // Postavljanje cooldown-a 30 minuta  za koliko se bankomat ponovo moze opljackati
    new timer = 30 * 60; // tajmer u sekundama
    TajmerZaPljacku[atmid] = gettime() + timer;

    // Pokrecemo tajmer za zavrsetak 
    new trajanjePljacke = 20 * 1000; // trajanje pljacke u milisekundama
    SetTimerEx("KrajPljackeATM", trajanjePljacke, false, "ii", playerid, atmid);
    
    SendClientMessage(playerid, BANKA_ZELENA_BOJA, "[ ATM ]: Pljacka je pocela, ne mrdajte 20 sekundi...");
    return 1;
}

forward KrajPljackeATM(playerid, atmid);
public KrajPljackeATM(playerid, atmid)
{
    // Sprecavanje abus-a ako igrac izadje iz blizine bankomata ili umre tokom pljacke
    new Float:phealth;
    GetPlayerHealth(playerid, phealth);
    if(!IsPlayerConnected(playerid) || IsPlayerInAnyVehicle(playerid) || phealth <= 0.0)
    {
        SendClientMessage(playerid, ERROR_BOJA, "[ Bankomat System | Info ]: Pljacka neuspesna, niste ispunili uslove!");
        PlayerRobCooldown[playerid] = gettime() + 3600; // 1 sat cooldown za pljacku nakon neuspesne pljacke
        ClearAnimations(playerid);
        OduzmiItem(playerid, "Pajser", 1); // Oduzimamo pajser bez obzira na ishod pljacke
        return 1;
    }

    if(atmid < 0 || atmid >= MAX_BANKOMATA) {
        return 1;
    }

    if(!IsPlayerInRangeOfPoint(playerid, 5.0, ATM[atmid][atmX], ATM[atmid][atmY], ATM[atmid][atmZ])) 
    {
        SendClientMessage(playerid, ERROR_BOJA, "[ Bankomat System | Info ]: Pljacka neuspesna, udaljili ste se!");
        PlayerRobCooldown[playerid] = gettime() + 3600; // 1 sat cooldown za pljacku nakon neuspesne pljacke
        ClearAnimations(playerid);
        OduzmiItem(playerid, "Pajser", 1); // Oduzimamo pajser bez obzira na ishod pljacke
        return 1;
    }

    PlayerRobCooldown[playerid] = gettime() + 3600; // 1 sat cooldown za pljacku nakon uspesne pljacke
    TajmerZaPljacku[atmid] = gettime() + 1800; // 30 min

    // Isplata novca igracu izmedju 1000 i 5000 dolara
    new iznos = 1000 + random(4001); 
    GivePlayerMoney(playerid, iznos);
    ClearAnimations(playerid);

    new poruka[128];
    format(poruka, sizeof(poruka), "[ Bankomat System | Info ]: Uspesno ste ukrali $%d sa bankomata!", iznos);
    SendClientMessage(playerid, BANKA_ZELENA_BOJA, poruka);
    OduzmiItem(playerid, "Pajser", 1); // Oduzimamo pajser nakon uspesne pljacke
    
    SacuvajIgraca(playerid);
    
    // Log za admine
    new logPoruka[144];
    format(logPoruka, sizeof(logPoruka), "[ Admin System | Log ]: %s je uspesno opljackao $%d sa bankomata %d.", Igrac[playerid][ImeIgraca], iznos, ATM[atmid][atmID]);
    LiveAdminLog(ADMIN_BOJA, logPoruka);
    
    return 1;
}

CMD:kreirajbankomat(playerid, params[])
{
    if(!AdminProvera(playerid, 1)) return 1;

    new id = PronadjiSlobodanATMSlot();
    if(id == -1) return SendClientMessage(playerid, ERROR_BOJA, "[ Bankomat System | Greska ]: Dostignut maksimalan broj bankomata.");

    new Float:x, Float:y, Float:z, Float:a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);

    // Kreiramo privremeni objekat (Model 19526 - Bankomat)
    new tempObj = CreateDynamicObject(19526, x + 1.0, y + 1.0, z, 0.0, 0.0, a);
    EditDynamicObject(playerid, tempObj);
    
    SetPVarInt(playerid, "KreiraNoviATM", 1);
    SetPVarInt(playerid, "ATM_SlotID", id);

    SendClientMessage(playerid, ADMIN_BOJA, "[ Bankomat System | Admin ]: Pomerajte bankomat strelicama. Kliknite na 'Disketicu' da zavrsite.");
    return 1;
}

CMD:obrisibankomat(playerid, params[])
{
    if(Igrac[playerid][Admin] < 6) return SendClientMessage(playerid, ERROR_BOJA, "[ Admin System | Greska ]: Niste ovlasceni.");

    new id;
    if(sscanf(params, "i", id)) return SendClientMessage(playerid, ADMIN_BOJA, "[ Admin System | Info ]: /obrisibankomat [ID Slota]");
    
    if(id < 0 || id >= MAX_BANKOMATA || ATM[id][atmID] == 0) 
        return SendClientMessage(playerid, ERROR_BOJA, "[ Bankomat System | Greska ]: Taj bankomat ne postoji.");

    new query[128];
    mysql_format(g_SQL, query, sizeof(query), "DELETE FROM bankomati WHERE id = %d", ATM[id][atmID]);
    mysql_tquery(g_SQL, query);

    DestroyDynamicObject(ATM[id][atmObjekat]);
    DestroyDynamic3DTextLabel(ATM[id][atmLabel]);

    ATM[id][atmID] = 0;
    ATM[id][atmX] = 0.0;
    ATM[id][atmY] = 0.0;
    ATM[id][atmZ] = 0.0;
    ATM[id][atmObjekat] = -1;
    
    SendClientMessage(playerid, ADMIN_BOJA, "[ Bankomat System | Admin ]: Bankomat uspesno obrisan iz baze i sa mape.");
    return 1;
}

CMD:rob(playerid, params[])
{
    new id = -1;
    
    for(new i = 0; i < MAX_BANKOMATA; i++)
    {
        if(ATM[i][atmID] != 0 && IsPlayerInRangeOfPoint(playerid, 2.0, ATM[i][atmX], ATM[i][atmY], ATM[i][atmZ]))
        {
            id = i;
            break; 
        }
    }

    if(id == -1) return 1; // Nije blizu nijednog bankomata

    // Provera da li ima pajser u inventaru
    if(!ImaItemUInv(playerid, "Pajser")) 
        return SendClientMessage(playerid, ERROR_BOJA, "[ Bankomat System ]: Nemate pajser u inventaru da biste obili bankomat.");

    // Provera coldown-a da li igrac moze ponovo da pljacka ili je nedavno opljackao neki bankomat
    if(PlayerRobCooldown[playerid] > gettime())
    {
        new preostalo = PlayerRobCooldown[playerid] - gettime();
        new str[128];
        format(str, sizeof(str), "[ Bankomat System ]: Ne mozete pljackati tako brzo. Sacekajte jos %d minuta.", preostalo / 60);
        return SendClientMessage(playerid, ERROR_BOJA, str);
    }

    // Provera da li je bankomat nedavno opljackan i da li je prazan
    if(TajmerZaPljacku[id] > gettime())
        return SendClientMessage(playerid, ERROR_BOJA, "[ Bankomat System ]: Ovaj bankomat je prazan (nedavno opljackan).");

    // Ukoliko su svi uslovi ispunjeni
    ZapocniPljackuATM(playerid, id);
    return 1;
}