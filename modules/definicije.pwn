#include                                                    <a_samp>


#define ADMIN_BOJA                                          0xFFA500AA
#define ERROR_BOJA                                          0xFF0000AA
#define BANKA_ZELENA_BOJA                                   0x00FF00AA

#define TEXT_ZELENA                                         "{00FF00}"
#define TEXT_CRVENA                                         "{FF0000}"
#define TEXT_BELA                                           "{FFFFFF}"



#define MAX_ADMIN_LEVEL                                     6
#define MAX_INV_SLOTOVA                                     20
#define MAX_TEZGI                                           500
#define MAX_KUCA                                            1000
#define MAX_BANKOMATA                                       500
#define MAX_POSLOVA                                         50
#define MAX_CHECKPOINTA_PO_POSLU                            200

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
#define D_BANKA_MENU                                        15
#define D_BANKA_PODIZANJE                                   16
#define D_BANKA_OSTAVLJANJE                                 17
#define A_POSAO                                             20
#define A_POSAO_KREIRAJ                                     21
#define A_POSAO_UREDJIVANJE                                 22
#define A_POSAO_OBRISI                                      23
#define A_POSAO_IME                                         24
#define A_POSAO_UREDI_OPCIJE                                25
#define A_POSAO_INPUT_VAL                                   26
#define A_POSAO_KORAK2                                      27
#define A_POSAO_CP_GLAVNI                                   28
#define A_POSAO_CP_DODAJ                                    29
#define A_POSAO_CP_OBRISI                                   30
#define A_POSAO_CP_TIP                                      31
#define HS_KUCA_MENU                                        40
#define HS_KUCA_INFO                                        41
#define HS_KUCA_PRODAJA                                     42
#define HS_KUCA_SEF                                         43
#define HS_KUCA_SEF_NOVAC_O                                 44
#define HS_KUCA_SEF_NOVAC_U                                 45

stock DajAdminNaziv(level)
{
    new naziv[24];
    switch(level)
    {
        case 1: format(naziv, sizeof(naziv), "Admin lvl 1");
        case 2: format(naziv, sizeof(naziv), "Admin lvl 2");
        case 3: format(naziv, sizeof(naziv), "Admin lvl 3");
        case 4: format(naziv, sizeof(naziv), "Admin lvl 4");
        case 5: format(naziv, sizeof(naziv), "Direktor");
        case 6: format(naziv, sizeof(naziv), "Vlasnik");
        default: format(naziv, sizeof(naziv), "Igrac"); // Uvek dodaj default
    }
    return naziv;
}

// ================================================================================================================================================================================= //
// ---                                                                      BANKA                                                                                                --- //
// ================================================================================================================================================================================= //
#define BANKA_OTVARANJE_RACUNA_X                            1645.9429
#define BANKA_OTVARANJE_RACUNA_Y                            -2261.0151
#define BANKA_OTVARANJE_RACUNA_Z                            13.5469
#define BANKA_OTVARANJE_RACUNA_ANGLE                        182.5704
#define BANKA_OTVARANJE_RACUNA_ICON                         1239
#define BANKA_OTVARANJE_RACUNA_LABEL                        "Koristite ~g~/otvoriracun~w~\n da otvorite bankovni racun."
#define BANKA_OTVARANJE_RACUNA_RADIUS                       3.0
#define BANKA_OTVARANJE_RACNA_CENA                          3000

#define BANKA_PODIZANJE_KARTICE_X                           1639.8992
#define BANKA_PODIZANJE_KARTICE_Y                           -2261.2439
#define BANKA_PODIZANJE_KARTICE_Z                           13.4848
#define BANKA_PODIZANJE_KARTICE_ANGLE                       178.2562
#define BANKA_PODIZANJE_KARTICE_ICON                        1239
#define BANKA_PODIZANJE_KARTICE_LABEL                       "Koristite ~g~/banka~w~\n da preistupite banci."
#define BANKA_PODIZANJE_KARTICE_RADIUS                      3.0
#define BANKA_PODIZANJE_KARTICE_CENA                        500

#define BANKOMAT_LABEL_TEXT                                 ""TEXT_ZELENA"[ Bankomat ID: %d ]\n{FFFFFF}Koristite 'LALT'\nda pristupite bankomatu"


// ================================================================================================================================================================================= //
// ---                                                                      OPSTINA                                                                                              --- //
// ================================================================================================================================================================================= //
#define LICNA_KARTA_CENA                                    1000
#define LICNA_KARTA_VADJENJE_LABEL                          "Koristite ~g~/izvadilicnu~w~\n da izvadite licnu kartu."
#define LICNA_KARTA_VADJENJE_X                              1691.2292
#define LICNA_KARTA_VADJENJE_Y                              -2312.0266
#define LICNA_KARTA_VADJENJE_Z                              13.5469
#define LICNA_KARTA_VADJENJE_RADIUS                         3.0
#define LICNA_KARTA_VADJENJE_ICON                           1239