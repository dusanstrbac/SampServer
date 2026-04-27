#include                                                    <a_samp>

#define ADMIN_BOJA                                          0xFFA500AA

#define MAX_ADMIN_LEVEL                                     6
#define MAX_INV_SLOTOVA                                     20
#define MAX_TEZGI                                           500
#define MAX_KUCA                                            1000

#define TEZGA_TIP_RANAC                                     1

#define SPD                                                 ShowPlayerDialog

#define D_REGISTER                                          1
#define D_LOGIN                                             2
#define D_INVENTORY                                         3
#define D_INVENTORY_OPTIONS                                 4
#define D_PIJACA_RANAC                                      5
#define HS_KREIRANJE_KUCE                                   10
#define HS_K_CENA                                           11
#define HS_K_LEVEL                                          12
#define HS_K_KAT                                            13
#define HS_K_ENT_IZBOR                                      14

stock DajAdminNaziv(level)
{
    new naziv[24];
    switch(level)
    {
        case 1: naziv = "Admin lvl 1";
        case 2: naziv = "Admin lvl 2";
        case 3: naziv = "Admin lvl 3";
        case 4: naziv = "Admin lvl 4";
        case 5: naziv = "Direktor";
        case 6: naziv = "Vlasnik";
    }
    return naziv;
}