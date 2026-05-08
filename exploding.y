%{
#include <stdio.h>
#include <stdlib.h>

void yyerror(const char *s);
int yylex();

/* Importăm variabilele și funcțiile din partea de C (Persoana 1) [cite: 144, 165] */
extern int currentPlayer, nrofTurns, state;
extern void start_action();
extern void extract_card();
extern int playerHasCard(int cardType);
extern void deleteCard(int cardType);

/* Definirea indexului pentru fiecare tip de carte conform cerintei [cite: 145] */
#define C_DEFUSE 1
#define C_ATTACK 2
#define C_SKIP 3
#define C_FAVOR 4
#define C_SHUFFLE 5
#define C_SEE_FUTURE 6
%}

%token START EXTRACT DONE CHOOSE PLAY PAIR GIVE
%token DEFUSE ATTACK SKIP FAVOR SHUFFLE SEE_FUTURE
%token TACO_CAT POTATO_CAT RAINBOW_CAT BEARD_CAT CATTERMELON
%token TOP MIDDLE BOTTOM NUMBER

%%

joc: 
    | joc linie
    ;

linie:
    comanda_start
    | actiune_joc
    | gestionare_bomba
    ;

comanda_start:
    START { 
        if (state == 0) start_action(); // Seteaza starea la WAIT_COMMAND [cite: 144, 188]
    }
    ;

actiune_joc:
    PLAY carte_speciala {
        if (state == 1) { // WAIT_COMMAND [cite: 144]
            /* Aici se apeleaza logica de joc pentru fiecare carte [cite: 196] */
            printf("Jucatorul %d a jucat o carte.\n", currentPlayer);
        }
    }
    | EXTRACT {
        if (state == 1) extract_card(); // Trage o carte si verifica daca e bomba [cite: 52, 61]
    }
    ;

carte_speciala:
    ATTACK { 
        if (playerHasCard(C_ATTACK)) {
            deleteCard(C_ATTACK);
            nrofTurns = 2; // Forteaza urmatorul jucator la 2 ture [cite: 20]
            currentPlayer = (currentPlayer == 1) ? 2 : 1;
            printf("Atac! Jucatorul %d are 2 ture.\n", currentPlayer);
        }
    }
    | SHUFFLE {
        if (playerHasCard(C_SHUFFLE)) {
            deleteCard(C_SHUFFLE);
            printf("Pachetul a fost amestecat.\n"); // [cite: 28, 130]
        }
    }
    | SEE_FUTURE {
        if (playerHasCard(C_SEE_FUTURE)) {
            deleteCard(C_SEE_FUTURE);
            state = 2; // WAIT_DONE [cite: 144]
            printf("Vizualizeaza viitorul in future.txt. Scrie DONE cand termini.\n"); // [cite: 107]
        }
    }
    ;

gestionare_bomba:
    DONE {
        if (state == 2) state = 1; // Revine la comenzi dupa See Future [cite: 54, 109]
    }
    | CHOOSE NUMBER {
        if (state == 4) { // WAIT_PLACEMENT (dupa Defuse) [cite: 144, 226]
            printf("Bomba a fost plasata la pozitia %d. Jocul continua.\n", $2);
            state = 1; // Inapoi la joc normal [cite: 54]
        }
    }
    ;

%%

/* Implementarea functiei de eroare obligatorie [cite: 187] */
void yyerror(const char *s) {
    printf("Eroare: Comanda invalida sau neasteptata!\n");
}

/* FUNCTIA MAIN - Punctul de intrare in program */
int main() {
    printf("=== EXPLODING KITTENS - LFT PROJECT ===\n");
    printf("Introdu comanda 'START' pentru a initializa jocul.\n");
    
    // yyparse() porneste analizorul sintactic si asteapta input
    yyparse(); 
    
    return 0;
}