new AdminCPList[MAX_PLAYERS][MAX_CHECKPOINTA_PO_POSLU];
new bool:AdminCPVisible[MAX_PLAYERS];

// ID-ovi poslova iz baze podataka
#define POSAO_DOSTAVLJAC    12

enum pJobData {
    pPosaoID,
    pUgovor,
    pPlata
}
new PosaoData[MAX_PLAYERS][pJobData];

enum job_locations_data {
    jlPostoji,
    jlPosaoID,
    jlIme[32],
    // Zaposlenje
    Float:jlX, Float:jlY, Float:jlZ,
    // Oprema/Duznost
    Float:jlOpremaX, Float:jlOpremaY, Float:jlOpremaZ,
    jlModelPickupa,
    jlSkinID,
    jlPotrebanUgovor,
    jlPickupID[2], 
    Text3D:jlLabelID[2]
}
new JobData[MAX_POSLOVA][job_locations_data];

enum ENUM_CP_DATA {
    cpID,
    cpPosaoID,
    Float:cpX,
    Float:cpY,
    Float:cpZ,
    cpTipFaza
}
new JobCP[MAX_POSLOVA][MAX_CHECKPOINTA_PO_POSLU][ENUM_CP_DATA];
new JobCPCount[MAX_POSLOVA];


forward UcitajPoslove();
public UcitajPoslove()
{
    mysql_tquery(g_SQL, "SELECT * FROM poslovi_lista", "OnPosloviLoaded");
    return 1;
}

forward OcistiPosloveSaMape();
public OcistiPosloveSaMape()
{
    for(new i = 0; i < MAX_POSLOVA; i++)
    {
        // Brišemo bez obzira na jlPostoji, za svaki slučaj ako je streamer ostao "siroče"
        if(IsValidDynamicPickup(JobData[i][jlPickupID][0])) DestroyDynamicPickup(JobData[i][jlPickupID][0]);
        if(IsValidDynamicPickup(JobData[i][jlPickupID][1])) DestroyDynamicPickup(JobData[i][jlPickupID][1]);
        
        if(IsValidDynamic3DTextLabel(JobData[i][jlLabelID][0])) DestroyDynamic3DTextLabel(JobData[i][jlLabelID][0]);
        if(IsValidDynamic3DTextLabel(JobData[i][jlLabelID][1])) DestroyDynamic3DTextLabel(JobData[i][jlLabelID][1]);
        
        // Resetujemo ID-ove na INVALID da ne bi bilo dupliranja
        JobData[i][jlPickupID][0] = -1;
        JobData[i][jlPickupID][1] = -1;
        JobData[i][jlLabelID][0] = Text3D:-1;
        JobData[i][jlLabelID][1] = Text3D:-1;
        
        JobData[i][jlPostoji] = 0; 
    }
    return 1;
}

forward OnPosloviLoaded();
public OnPosloviLoaded()
{
    OcistiPosloveSaMape(); // Brisemo stare oznake sa mape pre ucitavanja novih

    for(new i = 0; i < MAX_POSLOVA; i++)
    {
        JobData[i][jlPostoji] = 0;
        JobData[i][jlPosaoID] = 0;
        JobData[i][jlIme][0] = '\0';
        JobData[i][jlPickupID][0] = -1;
        JobData[i][jlPickupID][1] = -1;
    }

    new rows = cache_num_rows();
    if(rows > 0)
    {
        for(new i = 0; i < rows; i++)
        {
            cache_get_value_name_int(i, "id", JobData[i][jlPosaoID]);
            cache_get_value_name(i, "ime", JobData[i][jlIme], 32);
            cache_get_value_name_float(i, "posao_x", JobData[i][jlX]);
            cache_get_value_name_float(i, "posao_y", JobData[i][jlY]);
            cache_get_value_name_float(i, "posao_z", JobData[i][jlZ]);
            cache_get_value_name_float(i, "oprema_x", JobData[i][jlOpremaX]);
            cache_get_value_name_float(i, "oprema_y", JobData[i][jlOpremaY]);
            cache_get_value_name_float(i, "oprema_z", JobData[i][jlOpremaZ]);
            cache_get_value_name_int(i, "pickup_model", JobData[i][jlModelPickupa]);
            cache_get_value_name_int(i, "skin_id", JobData[i][jlSkinID]);
            cache_get_value_name_int(i, "ugovor_ture", JobData[i][jlPotrebanUgovor]);
            JobData[i][jlPostoji] = 1;

            // --- KLJUČNI DEO: Učitavanje CP-ova za ovaj posao ---
            OsveziCheckpointovePosla(i); 

            // Point 1: Zaposlenje
            JobData[i][jlPickupID][0] = CreateDynamicPickup(JobData[i][jlModelPickupa], 1, JobData[i][jlX], JobData[i][jlY], JobData[i][jlZ]);
            new label1[128];
            format(label1, sizeof(label1), "[ POSAO: %s ]\n{FFFFFF}Kucajte {FFFF00}/posao {FFFFFF}za ugovor", JobData[i][jlIme]);
            JobData[i][jlLabelID][0] = CreateDynamic3DTextLabel(label1, 0xFFFF00FF, JobData[i][jlX], JobData[i][jlY], JobData[i][jlZ] + 0.5, 20.0);

            // Point 2: Oprema
            JobData[i][jlPickupID][1] = CreateDynamicPickup(1275, 1, JobData[i][jlOpremaX], JobData[i][jlOpremaY], JobData[i][jlOpremaZ]);
            new label2[128];
            format(label2, sizeof(label2), "[ OPREMA: %s ]\n{FFFFFF}Kucajte {FFFF00}/oprema {FFFFFF}za uniformu", JobData[i][jlIme]);
            JobData[i][jlLabelID][1] = CreateDynamic3DTextLabel(label2, 0xFFFF00FF, JobData[i][jlOpremaX], JobData[i][jlOpremaY], JobData[i][jlOpremaZ] + 0.5, 20.0);
        }
        printf("[ Poslovi System ]: Ucitano %d poslova iz baze.", rows);
    }
    else
    {
        printf("[ Poslovi System ]: Nema poslova za ucitavanje u bazi.");
    }
    return 1;
}

hook OnDialogResponse@Poslovi(playerid, dialogid, response, listitem, inputtext[])
{
    // --- LISTA POSLOVA ZA EDITOVANJE ---
    if(dialogid == A_POSAO_UREDJIVANJE)
    {
        if(!response) return cmd_aposao(playerid, "");
        
        new count = 0, selectedID = -1;
        for(new i = 0; i < MAX_POSLOVA; i++) {
            if(JobData[i][jlPostoji]) {
                if(count == listitem) {
                    selectedID = i;
                    break;
                }
                count++;
            }
        }
        
        if(selectedID != -1) {
            SetPVarInt(playerid, "EditingJobID", selectedID);
            new str[256];
            format(str, sizeof(str), "1. Promeni skin (ID: %d)\n2. Promeni ugovor (Ture: %d)\n3. Postavi lokaciju "TEXT_ZELENA"ZAPOSLENJA"TEXT_BELA" ovde\n4. Postavi lokaciju "TEXT_ZELENA"OPREME"TEXT_BELA" ovde\n5) Posao checkpointovi\n{FF0000}5. Obrisi posao",                
            JobData[selectedID][jlSkinID], JobData[selectedID][jlPotrebanUgovor]);
            
            SPD(playerid, 25, DIALOG_STYLE_LIST, JobData[selectedID][jlIme], str, "Odaberi", "Nazad");
        }
        return 1;
    }

    // --- OPCIJE ZA ODREDJENI POSAO ---
    if(dialogid == A_POSAO_UREDI_OPCIJE)
    {
        if(!response) return cmd_aposao(playerid, ""); 
        
        new id = GetPVarInt(playerid, "EditingJobID");
        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);
        new query[256];
        
        if(listitem == 0) // Promena skina
        {
            SetPVarInt(playerid, "EditType", 1); 
            ShowPlayerDialog(playerid, A_POSAO_INPUT_VAL, DIALOG_STYLE_INPUT, "Izmena Skina", "Unesite novi ID skina za ovaj posao:", "Sacuvaj", "Nazad");
        }
        else if(listitem == 1) // Promena ugovora
        {
            SetPVarInt(playerid, "EditType", 2); 
            ShowPlayerDialog(playerid, A_POSAO_INPUT_VAL, DIALOG_STYLE_INPUT, "Izmena Ugovora", "Unesite broj tura potrebnih za ugovor:", "Sacuvaj", "Nazad");
        }
        else if(listitem == 2) // Nova lokacija ZAPOSLENJA
        {
            // 1. Uništi stare oznake
            if(IsValidDynamicPickup(JobData[id][jlPickupID][0])) 
            {
                // Pomeramo ga u pod pre uništenja (sigurnosni trik za klijent render)
                Streamer_SetFloatData(STREAMER_TYPE_PICKUP, JobData[id][jlPickupID][0], E_STREAMER_Z, -100.0);
                DestroyDynamicPickup(JobData[id][jlPickupID][0]);
                JobData[id][jlPickupID][0] = -1;
            }
            if(IsValidDynamic3DTextLabel(JobData[id][jlLabelID][0])) 
            {
                DestroyDynamic3DTextLabel(JobData[id][jlLabelID][0]);
                JobData[id][jlLabelID][0] = Text3D:-1;
            }
            
            // 2. Ažuriraj koordinate
            JobData[id][jlX] = x; JobData[id][jlY] = y; JobData[id][jlZ] = z;
            
            // 3. Napravi novi pickup i label
            JobData[id][jlPickupID][0] = CreateDynamicPickup(JobData[id][jlModelPickupa], 1, x, y, z, -1, -1);
            
            new label[128];
            format(label, sizeof(label), "[ POSAO: %s ]\n{FFFFFF}Kucajte {FFFF00}/posao {FFFFFF}za ugovor", JobData[id][jlIme]);
            JobData[id][jlLabelID][0] = CreateDynamic3DTextLabel(label, 0xFFFF00FF, x, y, z + 0.5, 20.0);
            
            // 4. Update u bazi
            mysql_format(g_SQL, query, sizeof(query), "UPDATE poslovi_lista SET posao_x = %f, posao_y = %f, posao_z = %f WHERE id = %d", x, y, z, JobData[id][jlPosaoID]);
            mysql_tquery(g_SQL, query);

            // 5. Agresivno osvežavanje za admina
            Streamer_UpdateEx(playerid, x, y, z, .type = STREAMER_TYPE_PICKUP);
            Streamer_UpdateEx(playerid, x, y, z, .type = STREAMER_TYPE_3D_TEXT_LABEL);
            
            SendClientMessage(playerid, -1, "{00FF00}[ Admin ]: Lokacija zaposlenja pomerena.");
        }
        else if(listitem == 3) // Nova lokacija OPREME
        {
            // 1. Uništi stare oznake za OPREMU (index 1)
            if(IsValidDynamicPickup(JobData[id][jlPickupID][1])) 
            {
                Streamer_SetFloatData(STREAMER_TYPE_PICKUP, JobData[id][jlPickupID][1], E_STREAMER_Z, -100.0);
                DestroyDynamicPickup(JobData[id][jlPickupID][1]);
                JobData[id][jlPickupID][1] = -1;
            }
            if(IsValidDynamic3DTextLabel(JobData[id][jlLabelID][1])) 
            {
                DestroyDynamic3DTextLabel(JobData[id][jlLabelID][1]);
                JobData[id][jlLabelID][1] = Text3D:-1;
            }

            // 2. Ažuriraj koordinate opreme
            JobData[id][jlOpremaX] = x; JobData[id][jlOpremaY] = y; JobData[id][jlOpremaZ] = z;

            // 3. Napravi novi pickup i label za opremu
            JobData[id][jlPickupID][1] = CreateDynamicPickup(1275, 1, x, y, z, -1, -1);
            
            new label2[128];
            format(label2, sizeof(label2), "[ OPREMA: %s ]\n{FFFFFF}Kucajte {FFFF00}/oprema {FFFFFF}za uniformu", JobData[id][jlIme]);
            JobData[id][jlLabelID][1] = CreateDynamic3DTextLabel(label2, 0xFFFF00FF, x, y, z + 0.5, 20.0);

            // 4. Update u bazi
            mysql_format(g_SQL, query, sizeof(query), "UPDATE poslovi_lista SET oprema_x = %f, oprema_y = %f, oprema_z = %f WHERE id = %d", x, y, z, JobData[id][jlPosaoID]);
            mysql_tquery(g_SQL, query);

            // 5. Agresivno osvežavanje
            Streamer_UpdateEx(playerid, x, y, z, .type = STREAMER_TYPE_PICKUP);
            Streamer_UpdateEx(playerid, x, y, z, .type = STREAMER_TYPE_3D_TEXT_LABEL);

            SendClientMessage(playerid, -1, "{00FF00}[ Admin ]: Lokacija opreme pomerena.");
        }
        else if(listitem == 4) // Checkpointovi
        {
            new hStr[256];
            format(hStr, sizeof(hStr), "1. Prikazi sve checkpointove\n2. Dodaj novi checkpoint (Trenutna lokacija)\n3. Obrisi checkpoint (Trenutna lokacija)");
            ShowPlayerDialog(playerid, A_POSAO_CP_GLAVNI, DIALOG_STYLE_LIST, "Checkpoint Meni", hStr, "Izaberi", "Nazad");
        }
        else if(listitem == 5) // Brisanje
        {
            new str[128];
            format(str, sizeof(str), "{FFFFFF}Da li ste sigurni da zelite da obrisete posao {FF0000}%s?", JobData[id][jlIme]);
            ShowPlayerDialog(playerid, A_POSAO_OBRISI, DIALOG_STYLE_MSGBOX, "Potvrda brisanja", str, "Obrisi", "Odustani");
        }
        return 1;
    }

    // --- UNIVERZALNI INPUT ZA IZMENE  ---
    if(dialogid == A_POSAO_INPUT_VAL)
    {
        if(!response) return cmd_aposao(playerid, "");

        new id = GetPVarInt(playerid, "EditingJobID");
        new type = GetPVarInt(playerid, "EditType");
        new val = strval(inputtext);
        new query[156];

        if(type == 1) // Update skina
        {
            JobData[id][jlSkinID] = val;
            mysql_format(g_SQL, query, sizeof(query), "UPDATE poslovi_lista SET skin_id = %d WHERE id = %d", val, JobData[id][jlPosaoID]);
            SendClientMessage(playerid, -1, "[ Posao System | Admin ]: Skin posla uspesno promenjen.");
        }
        else if(type == 2) // Update ugovora
        {
            JobData[id][jlPotrebanUgovor] = val;
            mysql_format(g_SQL, query, sizeof(query), "UPDATE poslovi_lista SET ugovor_ture = %d WHERE id = %d", val, JobData[id][jlPosaoID]);
            SendClientMessage(playerid, -1, "[ Posao System | Admin ]: Duzina ugovora uspesno promenjena.");
        }

        mysql_tquery(g_SQL, query);
        return 1;
    }
    if(dialogid == A_POSAO_OBRISI)
    {
        if(!response) return cmd_aposao(playerid, "");

        new id = GetPVarInt(playerid, "EditingJobID"); // Ovo je index u JobData nizu
        new query[128];
        
        // 1. Prvo obrišemo markere iz memorije pre nego što izgubimo podatke
        if(IsValidDynamicPickup(JobData[id][jlPickupID][0])) DestroyDynamicPickup(JobData[id][jlPickupID][0]);
        if(IsValidDynamicPickup(JobData[id][jlPickupID][1])) DestroyDynamicPickup(JobData[id][jlPickupID][1]);
        if(IsValidDynamic3DTextLabel(JobData[id][jlLabelID][0])) DestroyDynamic3DTextLabel(JobData[id][jlLabelID][0]);
        if(IsValidDynamic3DTextLabel(JobData[id][jlLabelID][1])) DestroyDynamic3DTextLabel(JobData[id][jlLabelID][1]);

        // 2. Obrišemo iz baze
        mysql_format(g_SQL, query, sizeof(query), "DELETE FROM poslovi_lista WHERE id = %d", JobData[id][jlPosaoID]);
        mysql_tquery(g_SQL, query);

        // 3. Oslobodimo slot u nizu da drugi poslovi mogu da nastave da rade
        JobData[id][jlPostoji] = 0;
        JobData[id][jlPosaoID] = 0;
        JobData[id][jlIme][0] = '\0';

        SendClientMessage(playerid, -1, "[ Posao System | Admin ]: Posao je obrisan samo za taj ID. Ostali poslovi rade neometano.");
        return 1;
    }
    // --- GLAVNI ADMIN MENI (/aposao) ---
    if(dialogid == A_POSAO_KREIRAJ)
    {
        if(!response) return 1;
        if(listitem == 0)
        {
            SPD(playerid, 24, DIALOG_STYLE_INPUT, "Kreiranje: Korak 1", "Unesite ime novog posla (npr. Dostavljac):", "Dalje", "Odustani");
        }
        else if(listitem == 1) // "Lista i uredjivanje"
        {
            new listStr[1024], count = 0;
            for(new i = 0; i < MAX_POSLOVA; i++) {
                if(JobData[i][jlPostoji]) {
                    // Prikazujemo ime posla, a u pozadini ćemo znati koji je to slot
                    format(listStr, sizeof(listStr), "%s%s\n", listStr, JobData[i][jlIme]);
                    count++;
                }
            }
            if(count == 0) return SendClientMessage(playerid, -1, "{FF0000}[ Greška ]: Nema kreiranih poslova.");
            
            ShowPlayerDialog(playerid, A_POSAO_UREDJIVANJE, DIALOG_STYLE_LIST, "Izaberi posao", listStr, "Uredi", "Nazad");
        }
        return 1;
    }

    // --- KORAK 1: UNOS IMENA ---
    if(dialogid == A_POSAO_IME)
    {
        if(!response || isnull(inputtext)) return cmd_aposao(playerid, "");

        SetPVarString(playerid, "TempJobName", inputtext);
        
        // Automatski uzimamo trenutnu poziciju admina za tacku zaposlenja
        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);
        SetPVarFloat(playerid, "TempJobX", x);
        SetPVarFloat(playerid, "TempJobY", y);
        SetPVarFloat(playerid, "TempJobZ", z);

        SPD(playerid, 27, DIALOG_STYLE_MSGBOX, "Kreiranje: Korak 2", 
            "{FFFFFF}Lokacija za zaposlenje je sacuvana na vasoj poziciji.\n\nSada idite do mesta gde zelite da bude {FFFF00}OPREMA/UNIFORMA {FFFFFF}i kliknite 'Ovde'.", "Ovde", "Odustani");
        return 1;
    }

    // --- KORAK 2: LOKACIJA OPREME I SNIMANJE (ID 27) ---
    if(dialogid == A_POSAO_KORAK2)
    {
        if(!response) return cmd_aposao(playerid, "");

        new Float:ox, Float:oy, Float:oz, name[32];
        GetPlayerPos(playerid, ox, oy, oz);
        GetPVarString(playerid, "TempJobName", name, 32);

        new query[512];
        mysql_format(g_SQL, query, sizeof(query), 
            "INSERT INTO poslovi_lista (ime, posao_x, posao_y, posao_z, oprema_x, oprema_y, oprema_z, pickup_model, skin_id, ugovor_ture) \
            VALUES ('%e', %f, %f, %f, %f, %f, %f, 1239, 26, 10)", 
            name, 
            GetPVarFloat(playerid, "TempJobX"), GetPVarFloat(playerid, "TempJobY"), GetPVarFloat(playerid, "TempJobZ"), 
            ox, oy, oz);

        mysql_tquery(g_SQL, query, "OnAdminJobCreated", "i", playerid);
        
        // Brisanje privremenih varijabli
        DeletePVar(playerid, "TempJobName");
        DeletePVar(playerid, "TempJobX");
        DeletePVar(playerid, "TempJobY");
        DeletePVar(playerid, "TempJobZ");
        return 1;
    }

    // --- KORAK 3: CHECKPOINT MENI (ID 28) ---
    if(dialogid == A_POSAO_CP_GLAVNI)
    {
        if(!response) return cmd_aposao(playerid, ""); 

        new id = GetPVarInt(playerid, "EditingJobID"); // ID posla koji uređujemo

        switch(listitem)
        {
            case 0: // Prikazi sve checkpointove (Vizuelno + Lista)
            {
                if(JobCPCount[id] == 0) return SendClientMessage(playerid, -1, "{FF0000}[ Posao System | Greska ]: Nema kreiranih CP za ovaj posao.");
                
                // 1. Prvo ih stvorimo vizuelno da admin može da ih vidi u svijetu
                ObrisiAdminCP(playerid); // Ciste se stari CP-ovi ako postoje, da ne bi bilo dupliranja
                for(new i = 0; i < JobCPCount[id]; i++) 
                {
                    // Koristimo RaceCP (tip 1 - krug sa strelicom) jer se najbolje vidi
                    AdminCPList[playerid][i] = CreateDynamicRaceCP(1, JobCP[id][i][cpX], JobCP[id][i][cpY], JobCP[id][i][cpZ], 0.0, 0.0, 0.0, 3.0, .playerid = playerid);
                }
                AdminCPVisible[playerid] = true;                
                SendClientMessage(playerid, -1, "{FFFF00}[ Posao System | Admin ]: CP su sada vidljivi u svetu (plavi krugovi).");
            }
            case 1: // Dodaj novi CP
            {
                ShowPlayerDialog(playerid, A_POSAO_CP_TIP, DIALOG_STYLE_INPUT, "Nova Faza", "Unesite broj faze (0, 1, 2...):", "Dodaj", "Nazad");
            }
            case 2: // Obrisi CP na lokaciji
            {
                new Float:px, Float:py, Float:pz;
                GetPlayerPos(playerid, px, py, pz);
                
                new found = -1;
                for(new i = 0; i < JobCPCount[id]; i++)
                {
                    // Proveravamo da li je admin blizu neke tačke (udaljenost manja od 3 metra)
                    if(IsPlayerInRangeOfPoint(playerid, 3.0, JobCP[id][i][cpX], JobCP[id][i][cpY], JobCP[id][i][cpZ]))
                    {
                        found = i;
                        break;
                    }
                }

                if(found != -1)
                {
                    new query[128];
                    mysql_format(g_SQL, query, sizeof(query), "DELETE FROM poslovi_checkpointi WHERE id = %d", JobCP[id][found][cpID]);
                    mysql_tquery(g_SQL, query);
                    
                    SendClientMessage(playerid, -1, "{FF0000}[ Posao System | Admin ]: Checkpoint obrisan. Osvezite listu da vidite promene.");
                    OsveziCheckpointovePosla(id);
                }
                else SendClientMessage(playerid, -1, "{FF0000}[ Posao System | Greska ]: Ne nalazite se u blizini checkpointa.");
            }
        }
        return 1;
    }
    if(dialogid == A_POSAO_CP_TIP)
    {
        if(!response) return ShowPlayerDialog(playerid, A_POSAO_CP_GLAVNI, DIALOG_STYLE_LIST, "Checkpoint Meni", "1. Prikazi sve checkpointove\n2. Dodaj novi checkpoint (Trenutna lokacija)\n3. Obrisi checkpoint (Trenutna lokacija)", "Izaberi", "Nazad");

        new faza;
        if(sscanf(inputtext, "d", faza)) return ShowPlayerDialog(playerid, A_POSAO_CP_TIP, DIALOG_STYLE_INPUT, "Nova Faza", "{FF0000}Greska: Morate uneti broj!\n{FFFFFF}Unesite broj faze (0, 1, 2...):", "Dodaj", "Nazad");

        new id = GetPVarInt(playerid, "EditingJobID");
        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);

        new query[256];
        mysql_format(g_SQL, query, sizeof(query), "INSERT INTO poslovi_checkpointi (posao_id, cp_x, cp_y, cp_z, tip_faza) VALUES (%d, %f, %f, %f, %d)", 
            JobData[id][jlPosaoID], x, y, z, faza);
        
        mysql_tquery(g_SQL, query, "OnCheckpointAdded", "dd", playerid, id);
        return 1;
    }
    return 0;
}

public OnPlayerEnterDynamicCP(playerid, checkpointid)
{
    if(checkpointid == Igrac[playerid][pAktivniCP])
    {
        new jid = Igrac[playerid][pPosaoID];
        
        // Grananje po poslovima
        switch(jid)
        {
            case POSAO_DOSTAVLJAC: PosaoDostava(playerid);
        }
        return 1;
    }
    return 0;
}

forward OsveziCheckpointovePosla(job_idx);
public OsveziCheckpointovePosla(job_idx)
{
    new query[128];
    JobCPCount[job_idx] = 0; // Resetujemo brojač u memoriji pre punjenja
    
    // Tražimo checkpointove koji pripadaju jlPosaoID (ID iz baze)
    mysql_format(g_SQL, query, sizeof(query), "SELECT * FROM poslovi_checkpointi WHERE posao_id = %d", JobData[job_idx][jlPosaoID]);
    mysql_tquery(g_SQL, query, "OnCPRefreshInternal", "d", job_idx);
    return 1;
}

forward OnCPRefreshInternal(job_idx);
public OnCPRefreshInternal(job_idx)
{
    new rows = cache_num_rows();
    if(rows > 0)
    {
        for(new i = 0; i < rows; i++)
        {
            if(i >= MAX_CHECKPOINTA_PO_POSLU) break; // Sigurnosna kočnica
            
            cache_get_value_name_int(i, "id", JobCP[job_idx][i][cpID]);
            cache_get_value_name_float(i, "cp_x", JobCP[job_idx][i][cpX]);
            cache_get_value_name_float(i, "cp_y", JobCP[job_idx][i][cpY]);
            cache_get_value_name_float(i, "cp_z", JobCP[job_idx][i][cpZ]);
            cache_get_value_name_int(i, "tip_faza", JobCP[job_idx][i][cpTipFaza]);
            
            JobCPCount[job_idx]++;
        }
    }
    return 1;
}

stock PostaviSledeciCP(playerid)
{
    new jid = Igrac[playerid][pPosaoID]; // ID iz baze (npr. 1 za Dostavljaca)
    new job_idx = -1;
    
    // 1. Pronalazimo index posla u JobData nizu
    for(new i = 0; i < MAX_POSLOVA; i++) {
        if(JobData[i][jlPostoji] && JobData[i][jlPosaoID] == jid) {
            job_idx = i;
            break;
        }
    }
    if(job_idx == -1) return 0;

    // 2. Tražimo sve CP-ove koji odgovaraju trenutnoj fazi igraca
    new dostupni[MAX_CHECKPOINTA_PO_POSLU], count = 0;
    new trenutnaFaza = Igrac[playerid][pPosaoFaza];

    for(new i = 0; i < JobCPCount[job_idx]; i++) {
        if(JobCP[job_idx][i][cpTipFaza] == trenutnaFaza) {
            dostupni[count] = i;
            count++;
        }
    }

    if(count > 0) {
        new rand = random(count);
        new cp_idx = dostupni[rand];
        
        // Uništavamo stari CP ako postoji
        if(Igrac[playerid][pAktivniCP] != -1) DestroyDynamicCP(Igrac[playerid][pAktivniCP]);

        // Kreiramo novi CP (samo za tog igrača)
        Igrac[playerid][pAktivniCP] = CreateDynamicCP(JobCP[job_idx][cp_idx][cpX], JobCP[job_idx][cp_idx][cpY], JobCP[job_idx][cp_idx][cpZ], 3.0, .playerid = playerid);
        return 1;
    }
    return 0;
}

forward OnCheckpointAdded(playerid, id);
public OnCheckpointAdded(playerid, id)
{
    SendClientMessage(playerid, -1, "{00FF00}[ Posao System | Admin ]: Checkpoint uspesno dodat u bazu.");
    OsveziCheckpointovePosla(id);
    SendClientMessage(playerid, -1, "{FFFF00}[ Info ]: Ponovo kliknite 'Prikazi' da vidite novi marker na mapi.");
    return 1;
}


stock GetJobSlot(db_id)
{
    for(new i = 0; i < MAX_POSLOVA; i++)
    {
        if(JobData[i][jlPostoji] && JobData[i][jlPosaoID] == db_id) return i;
    }
    return -1;
}

stock ObrisiAdminCP(playerid)
{
    for(new i = 0; i < MAX_CHECKPOINTA_PO_POSLU; i++)
    {
        if(IsValidDynamicRaceCP(AdminCPList[playerid][i]))
        {
            DestroyDynamicRaceCP(AdminCPList[playerid][i]);
            AdminCPList[playerid][i] = -1;
        }
    }
    AdminCPVisible[playerid] = false;
    return 1;
}

forward OnAdminJobCreated(playerid);
public OnAdminJobCreated(playerid)
{
    SendClientMessage(playerid, -1, "[ Posao System | Admin ]: Posao uspesno kreiran i upisan u bazu!");
    UcitajPoslove();
    return 1;
}

forward OnJobDeleted(playerid);
public OnJobDeleted(playerid)
{
    SendClientMessage(playerid, -1, "[ Posao System | Admin ]: Posao uspesno obrisan iz baze. Osvezavam mapu...");
    UcitajPoslove();
    return 1;
}

CMD:oprema(playerid, params[])
{
    new id = Igrac[playerid][pPosaoID];
    if(id == 0)
        return SendClientMessage(playerid, ERROR_BOJA, "[ Posao ]: {FFFFFF}Niste zaposleni nigde.");

    new bool:naMestu = false;
    new skinZaSetovanje = -1;

    for(new i = 0; i < MAX_POSLOVA; i++)
    {
        if(!JobData[i][jlPostoji]) continue; // Preskacemo prazne slotove
        
        if(JobData[i][jlPosaoID] == id) // Proveravamo da li je to ID posla koji igrac radi
        {
            if(IsPlayerInRangeOfPoint(playerid, 3.0, JobData[i][jlOpremaX], JobData[i][jlOpremaY], JobData[i][jlOpremaZ]))
            {
                naMestu = true;
                skinZaSetovanje = JobData[i][jlSkinID];
                break;
            }
        }
    }

    if(!naMestu)
        return SendClientMessage(playerid, ERROR_BOJA, "[ Posao ]: {FFFFFF}Niste na mestu za opremu svog posla!");


    if(Igrac[playerid][obukaoUniformu] == true)
    {
        Igrac[playerid][obukaoUniformu] = false;
        SetPlayerSkin(playerid, Igrac[playerid][Skin]);
        SendClientMessage(playerid, -1, "[ POSAO ]: {FFFFFF}Skin vracen na default. Obucite uniformu ponovo ako zelite da radite.");
    }
    else 
    {
        // Setovanje skina i poruka
        Igrac[playerid][obukaoUniformu] = true;
        SetPlayerSkin(playerid, skinZaSetovanje);
        SendClientMessage(playerid, -1, "[ POSAO ]: {FFFFFF}Preuzeli ste opremu i obukli uniformu. Srecno sa radom!");
    }

    return 1;
}

CMD:posao(playerid, params[])
{
    // Proveravamo da li je već zaposlen koristeći Igrac niz
    if(Igrac[playerid][pPosaoID] != 0)
        return SendClientMessage(playerid, ERROR_BOJA, "[ Posao ]: {FFFFFF}Vec ste zaposleni.");

    new bool:naMestu = false;
    new posaoIndex = -1;

    for(new i = 0; i < MAX_POSLOVA; i++)
    {
        if(!JobData[i][jlPostoji]) continue; 
        if(IsPlayerInRangeOfPoint(playerid, 3.0, JobData[i][jlX], JobData[i][jlY], JobData[i][jlZ]))
        {
            naMestu = true;
            posaoIndex = i;
            break;
        }
    }

    if(!naMestu)
        return SendClientMessage(playerid, ERROR_BOJA, "[ Posao ]: {FFFFFF}Niste na mestu za zaposlenje!");

    Igrac[playerid][pPosaoID] = JobData[posaoIndex][jlPosaoID];
    Igrac[playerid][pUgovor] = JobData[posaoIndex][jlPotrebanUgovor];

    new string[256];
    format(string, sizeof(string), "[ POSAO ]: {FFFFFF}Cestitamo! Potpisali ste ugovor za posao %s. Kucajte {FFFF00}/oprema {FFFFFF}da preuzmete opremu. Da biste ispunili ugovor, morate obaviti %d tura.", 
        JobData[posaoIndex][jlIme], Igrac[playerid][pUgovor]);
    
    SendClientMessage(playerid, -1, string);

    SacuvajIgraca(playerid);
    return 1;
}

CMD:otkaz(playerid, params[])
{
    if(Igrac[playerid][pPosaoID] == 0)
        return SendClientMessage(playerid, ERROR_BOJA, "[ Posao ]: {FFFFFF}Niste zaposleni nigde.");

    if(Igrac[playerid][pUgovor] > 0)
    {
        new str[256];
        format(str, sizeof(str), "[ Posao ]: {FFFFFF}Ne mozete dati otkaz dok ne ispunite uslove ugovora. Trenutno vam preostaje jos %d tura da ispunite ugovor.", Igrac[playerid][pUgovor]);
        return SendClientMessage(playerid, ERROR_BOJA, str);
    }
    
    if(Igrac[playerid][pAktivniCP] != -1) 
    {
        DestroyDynamicCP(Igrac[playerid][pAktivniCP]);
        Igrac[playerid][pAktivniCP] = -1;
    }

    // Uklanjanje posla
    PosaoData[playerid][pPosaoID] = 0;
    PosaoData[playerid][pUgovor] = 0;
    PosaoData[playerid][pPlata] = 0;
    Igrac[playerid][pPosaoID] = 0;
    Igrac[playerid][pUgovor] = 0;
    Igrac[playerid][pRadiPosao] = false;
    Igrac[playerid][pPosaoFaza] = 0;

    // Skidanje uniforme ako je obucena
    if(Igrac[playerid][obukaoUniformu] == true)
    {
        Igrac[playerid][obukaoUniformu] = false;
        SetPlayerSkin(playerid, Igrac[playerid][Skin]);
        SendClientMessage(playerid, -1, "[ POSAO ]: {FFFFFF}Skin vracen na default.");
    }

    SendClientMessage(playerid, -1, "[ POSAO ]: {FFFFFF}Otkazali ste svoj posao. Mozete se ponovo zaposliti kad god zelite.");
    SacuvajIgraca(playerid);
    return 1;
}

CMD:aposao(playerid, params[])
{
    if(!AdminProvera(playerid, 5)) return 1;
    SPD(playerid, A_POSAO_KREIRAJ, DIALOG_STYLE_LIST, 
        "{FFFF00}Admin: Upravljanje Poslovima", 
        "1. Kreiraj novi posao\n2. Lista i uredjivanje postojecih", 
        "Odaberi", "Zatvori");
    return 1;
}

CMD:zapocni(playerid, params[])
{
    new jid = Igrac[playerid][pPosaoID];
    
    // 1. Osnovne provere
    if(jid == 0) 
        return SendClientMessage(playerid, -1, "{FF0000}[ Greška ]: {FFFFFF}Niste zaposleni nigde. Idite do biroa ili lokacije posla.");

    if(Igrac[playerid][obukaoUniformu] == false) 
        return SendClientMessage(playerid, -1, "{FF0000}[ Greška ]: {FFFFFF}Morate obuci uniformu (kucajte /oprema) da biste poceli sa radom.");

    if(Igrac[playerid][pRadiPosao] == true)
        return SendClientMessage(playerid, -1, "{FF0000}[ Greška ]: {FFFFFF}Vec ste zapoceli radni ciklus. Pratite marker!");

    // 2. Inicijalizacija rada
    Igrac[playerid][pPosaoFaza] = 1; // Svaki posao uvek kreće od faze 1 (npr. restoran, baza, garaža)
    Igrac[playerid][pRadiPosao] = true;
    
    // Ukoliko je igrac dostavljac
    if(jid == POSAO_DOSTAVLJAC) { Igrac[playerid][pPreostaloTura] = 5; }


    // 3. Pokretanje prvog checkpointa
    if(PostaviSledeciCP(playerid))
    {
        new str[128];
        format(str, sizeof(str), "{FFFF00}[ %s ]: {FFFFFF}Zapoceli ste radnu smenu. Pratite marker na mapi.", JobData[GetJobSlot(jid)][jlIme]);
        SendClientMessage(playerid, -1, str);
    }
    else
    {
        // Ako sistem ne nađe ni jedan CP za tu fazu u bazi
        Igrac[playerid][pRadiPosao] = false;
        SendClientMessage(playerid, -1, "{FF0000}[ Greška ]: {FFFFFF}Ovaj posao jos uvek nema definisane checkpointove. Kontaktirajte admina.");
    }
    return 1;
}

stock PosaoDostava(playerid)
{
    if(Igrac[playerid][pPosaoFaza] == 1) // Stigao u restoran po hranu
    {
        SendClientMessage(playerid, -1, "{FFFF00}[ Dostava ]: Preuzeli ste hranu. Dostavite je na oznacenu lokaciju.");
        Igrac[playerid][pPosaoFaza] = 2; // Prebacujemo na fazu dostave (kuće)
        PostaviSledeciCP(playerid); // Dobija random kuću
                
                // Opciono: Dodaj mu objekat kutije u ruke ili na motor
    }
    else if(Igrac[playerid][pPosaoFaza] == 2) // Stigao do kuće
    {
        new plata = 500 + random(200);
        GivePlayerMoney(playerid, plata);
                
        // Smanjujemo broj preostalih tura
        Igrac[playerid][pPreostaloTura]--;

        if(Igrac[playerid][pPreostaloTura] > 0)
        {
            // Ima još da radi
            new str[128];
            format(str, sizeof(str), "{00FF00}[ Dostava ]: Hrana dostavljena! Zarada: $%d. Preostalo tura do kraja smene: %d.", plata, Igrac[playerid][pPreostaloTura]);
            SendClientMessage(playerid, -1, str);

            Igrac[playerid][pPosaoFaza] = 1; // Vrati ga u restoran
            PostaviSledeciCP(playerid);
        }
        else 
        {
            // ZAVRŠETAK SMENE
            SendClientMessage(playerid, -1, "{FFFF00}[ Dostava ]: Završili ste vašu radnu smenu! Odvezite motor nazad do restorana.");
                    
            Igrac[playerid][pPosaoFaza] = 3; // Vrati ga nazad u restoran, ali faza 3 znači da je smena gotova
            Igrac[playerid][pPreostaloTura] = 0;
            PostaviSledeciCP(playerid);
        }
    }
    else if(Igrac[playerid][pPosaoFaza] == 3) // Stigao nazad u restoran posle smene
    {
        // Resetovanje svega
        if(Igrac[playerid][pAktivniCP] != -1) 
        {
            DestroyDynamicCP(Igrac[playerid][pAktivniCP]);
            Igrac[playerid][pAktivniCP] = -1;     
        }
        Igrac[playerid][pRadiPosao] = false;
        Igrac[playerid][pPreostaloTura] = 0;
        Igrac[playerid][pUgovor]--;
        RemovePlayerFromVehicle(playerid);
        SendClientMessage(playerid, -1, "{FF0000}[ Dostava ]: Zavrsili ste sa poslom.");
        SacuvajIgraca(playerid);
    }
}