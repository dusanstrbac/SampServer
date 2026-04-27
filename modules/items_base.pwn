enum ItemInfo {
    itemNaziv[50],
    itemCena,
    Float:itemHeal,
    itemTip
};

// Hrana, sluzi za helovanje -- Tip 1

#define ITEM_SOK                                            "Vocni sok"
#define HEAL_SOK                                            20.0
#define CENA_SOK                                            50

#define ITEM_HLEB                                           "Hleb"
#define HEAL_HLEB                                           10.0
#define CENA_HLEB                                           25

// Rancevi, prosiranje inventorija -- Tip 2

#define ITEM_MALI_RANAC                                     "Mali ranac"
#define CENA_MALI_RANAC                                     5000
#define SLOTOVI_MALI_RANAC                                  5.0

#define ITEM_SREDNJI_RANAC                                  "Srednji ranac"
#define CENA_SREDNJI_RANAC                                  9000
#define SLOTOVI_SREDNJI_RANAC                               9.0

#define ITEM_VELIKI_RANAC                                   "Srednji ranac"
#define CENA_VELIKI_RANAC                                   14000
#define SLOTOVI_VELIKI_RANAC                                12.0

#define ITEM_LICNA_KARTA                                    "Licna karta"
#define CENA_LICNA_KARTA                                    1000

#define ITEM_VOZACKA_DOZVOLA                                "Vozacka dozvola"
#define CENA_VOZACKA_DOZVOLA                                5000

#define ITEM_BIZNIS_KARTA                                   "Biznis kartica"




new const ServerItems[][ItemInfo] = {
    {ITEM_SOK, CENA_SOK, HEAL_SOK, 1},
    {ITEM_HLEB, CENA_HLEB, HEAL_HLEB, 1},
    {ITEM_MALI_RANAC, CENA_MALI_RANAC, SLOTOVI_MALI_RANAC, 2},
    {ITEM_SREDNJI_RANAC, CENA_SREDNJI_RANAC, SLOTOVI_SREDNJI_RANAC, 2},
    {ITEM_VELIKI_RANAC, CENA_VELIKI_RANAC, SLOTOVI_VELIKI_RANAC, 2}
};

stock DajItemBaseID(const naziv[])
{
    for(new i = 0; i < sizeof(ServerItems); i++)
    {
        if(!strcmp(ServerItems[i][itemNaziv], naziv)) return i;
    }
    return -1;
}

stock Float:DajArtikalHeal(const naziv[])
{
    for(new i = 0; i < sizeof(ServerItems); i++)
    {
        if(!strcmp(ServerItems[i][itemNaziv], naziv)) return ServerItems[i][itemHeal];
    }
    return 0.0;
}

stock DajCenuArtikla(const naziv[])
{
    for(new i = 0; i < sizeof(ServerItems); i++)
    {
        if(!strcmp(ServerItems[i][itemNaziv], naziv)) 
        {
            return ServerItems[i][itemCena];
        }
    }
    return 0;
}
