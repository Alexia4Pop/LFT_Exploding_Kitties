%{
#include <stdio.h>
#include <stdlib.h>

void yyerror(const char *s);
int yylex();

/* Importăm variabilele și funcțiile din partea de C (Persoana 1) [cite: 144, 165] */
extern int currentPlayer, nrofTurns, state;
extern char *cardNames[];
extern void start_action();
extern void extract_card();
extern int playerHasCard(int cardType);
extern void deleteCard(int cardType);
extern int playerHasTwoCards(int cardType);
extern void futureFile();

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
    PLAY carte_speciala 
    | PLAY tip_pisica {
        /* Permitem PLAY CATTERMELON, dar de obicei pisicile nu fac nimic singure */
        if (playerHasCard($2)) {
            printf("Chatbot: Ai jucat %s, dar nu are niciun efect singura. Ai nevoie de o pereche!\n", cardNames[$2]);
        }
    }
    | EXTRACT {
        if (state == 1) extract_card(); // Trage o carte si verifica daca e bomba [cite: 52, 61]
    }
    | PAIR tip_pisica {
        /* Verificăm dacă are cel puțin 2 cărți de același fel */
        if (playerHasTwoCards($2)) { 
            deleteCard($2);
            deleteCard($2);
            printf("Chatbot: Ai jucat o PERECHE de %s! Poti fura o carte.\n", cardNames[$2]);
        } else {
            printf("Chatbot: Nu ai doua carti de acest fel pentru a forma o pereche!\n");
        }
    }
    ;

tip_pisica:
    TACO_CAT { $$ = 7; }
    | POTATO_CAT { $$ = 8; }
    | RAINBOW_CAT { $$ = 9; }
    | BEARD_CAT { $$ = 10; }
    | CATTERMELON { $$ = 11; }
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
    | SKIP {
        if (playerHasCard(3)) { 
            deleteCard(3); 
            nrofTurns--; 
            if (nrofTurns <= 0) {
                currentPlayer = (currentPlayer == 1) ? 2 : 1;
                nrofTurns = 1;
            }
            printf("Chatbot: Ai folosit SKIP. Randul tau s-a terminat.\n");
        } else {
            printf("Chatbot: Nu ai cartea SKIP in mana!\n");
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
            state = 2; // Trece în starea WAIT_DONE [cite: 144]
            futureFile(); // <--- ACEASTA LINIE GENEREAZĂ FIȘIERUL!
            printf("Player %d a folosit SEE FUTURE.\n", currentPlayer);
        } else {
            printf("Nu ai aceasta carte!\n");
        }
    }
    | FAVOR {
        if (playerHasCard(4)) {
            deleteCard(4);
            state = 3; // WAIT_GIVE (trebuie definit in enum)
            printf("Chatbot: Player %d, alege ce carte sa dai (GIVE <nume_carte>).\n", (currentPlayer == 1) ? 2 : 1);
        }
    }
    ;

gestionare_bomba:
    DONE {
       if (state == 2) { // Dacă suntem în starea WAIT_DONE 
            state = 1;    // Revenim la WAIT_COMMAND 
            
            /* Putem apela o funcție pentru a goli sau șterge fișierul  */
            remove("future.txt"); 
            
            printf("Chatbot: Am inteles. Acum poti continua jocul (PLAY sau EXTRACT).\n");
            printf("Player %d, look at your cards in file pl%d.txt and give a command\n", currentPlayer, currentPlayer);
        }
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