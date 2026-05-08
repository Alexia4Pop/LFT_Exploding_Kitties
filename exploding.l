%{
#include "exploding.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* --- PROTOTIPURI --- */
void start_action();
void extract_card();
int playerHasCard(int cardType);
void deleteCard(int cardType);
void writeCardsToFile();
void futureFile();

/* --- VARIABILE GLOBALE --- */
enum states { START_S, WAIT_COMMAND, WAIT_DONE, WAIT_GIVE, WAIT_PLACEMENT };
enum states state = START_S; 

int deck[50]; 
int player1[30], player2[30]; 
int deckSize = 0, p1Size = 0, p2Size = 0; 
int currentPlayer = 1; 
int nrofTurns = 1;

/* Numele cartilor pentru afisarea in fisiere [cite: 147, 160] */
char *cardNames[] = {"EXPLODE", "DEFUSE", "ATTACK", "SKIP", "FAVOR", "SHUFFLE", "SEE_FUTURE", "TACO_CAT", "POTATO_CAT", "RAINBOW_CAT", "BEARD_CAT", "CATTERMELON"};
%}

%%

[ \t\r\n]+              ;

"START"                 { return START; }
"EXTRACT"               { return EXTRACT; }
"DONE"                  { return DONE; }
"CHOOSE"                { return CHOOSE; }
"PLAY"                  { return PLAY; }
"PAIR"                  { return PAIR; }
"GIVE"                  { return GIVE; }

"DEFUSE"                { return DEFUSE; }
"ATTACK"                { return ATTACK; }
"SKIP"                  { return SKIP; }
"FAVOR"                 { return FAVOR; }
"SHUFFLE"               { return SHUFFLE; }
"SEE_FUTURE"            { return SEE_FUTURE; }

"TACO_CAT"              { return TACO_CAT; }
"POTATO_CAT"            { return POTATO_CAT; }
"RAINBOW_CAT"           { return RAINBOW_CAT; }
"BEARD_CAT"             { return BEARD_CAT; }
"CATTERMELON"           { return CATTERMELON; }

"top"                   { return TOP; }
"middle"                { return MIDDLE; }
"bottom"                { return BOTTOM; }
[0-9]+                  { return NUMBER; }

.                       { printf("Caracter necunoscut: %s\n", yytext); }

%%

int yywrap() {
    return 1;
}

/* --- IMPLEMENTARE FUNCTII C --- */

int playerHasCard(int cardType) {
    int *hand = (currentPlayer == 1) ? player1 : player2;
    int size = (currentPlayer == 1) ? p1Size : p2Size;
    for (int i = 0; i < size; i++) {
        if (hand[i] == cardType) return 1;
    }
    return 0;
}

void deleteCard(int cardType) {
    int *hand = (currentPlayer == 1) ? player1 : player2;
    int *size = (currentPlayer == 1) ? &p1Size : &p2Size;
    for (int i = 0; i < *size; i++) {
        if (hand[i] == cardType) {
            for (int j = i; j < *size - 1; j++) hand[j] = hand[j+1];
            (*size)--;
            break;
        }
    }
    /* Actualizam fisierele dupa ce o carte a fost jucata [cite: 190] */
    writeCardsToFile();
}

int playerHasTwoCards(int cardType) {
    int count = 0;
    int *hand = (currentPlayer == 1) ? player1 : player2;
    int size = (currentPlayer == 1) ? p1Size : p2Size;
    for (int i = 0; i < size; i++) {
        if (hand[i] == cardType) count++;
    }
    return (count >= 2);
}

void start_action() {
    srand(time(NULL));
    p1Size = 8;
    p2Size = 8;
    
    // Oferă fiecărui jucător un DEFUSE obligatoriu 
    player1[0] = 1; 
    player2[0] = 1; 

    // Umple restul mâinii cu cărți RANDOM (de la index 2 la 11)
    for(int i = 1; i < 8; i++) {
        player1[i] = (rand() % 10) + 2; // Sări peste EXPLODE (0) și DEFUSE (1)
        player2[i] = (rand() % 10) + 2;
    }
    
    // Inițializează pachetul de pe masă cu cărți diverse
    deckSize = 30; 
    for(int i = 0; i < deckSize; i++) {
        deck[i] = (rand() % 11) + 1; // Fără bombe în pachetul inițial pentru test
    }
    
    // Pune o singură bombă undeva la mijloc
    deck[deckSize / 2] = 0; 

    state = 1; // WAIT_COMMAND [cite: 144]
    writeCardsToFile();
    printf("Jocul a inceput! Verificati pl1.txt pentru noua lista de carti.\n");
}

void extract_card() {
    if (deckSize <= 0) {
        printf("Nu mai sunt carti in pachet!\n");
        return;
    }

    int card = deck[--deckSize]; 
    printf("Player %d a extras o carte.\n", currentPlayer);

    if (card == 0) { // EXPLODE [cite: 149]
        if (playerHasCard(1)) { // DEFUSE [cite: 150]
            printf("BUM! Dar ai avut DEFUSE. Pune bomba inapoi (CHOOSE <pozitie>).\n"); 
            deleteCard(1); 
            state = WAIT_PLACEMENT; 
        } else {
            printf("GAME OVER! Player %d a explodat. Player %d castiga!\n", currentPlayer, (currentPlayer == 1) ? 2 : 1); 
            exit(0); 
        }
    } else {
        /* Adaugam cartea in mana jucatorului */
        if (currentPlayer == 1) player1[p1Size++] = card;
        else player2[p2Size++] = card;

        nrofTurns--;
        if (nrofTurns <= 0) {
            printf("Tura jucatorului %d s-a terminat.\n", currentPlayer); 
            currentPlayer = (currentPlayer == 1) ? 2 : 1; 
            nrofTurns = 1;
        }
    }
    writeCardsToFile(); 
}

void writeCardsToFile() {
    FILE *f1 = fopen("pl1.txt", "w");
    FILE *f2 = fopen("pl2.txt", "w");
    
    if (f1 == NULL || f2 == NULL) return;

    fprintf(f1, "Cartile tale (Player 1):\n");
    for (int i = 0; i < p1Size; i++) {
        fprintf(f1, "- %s\n", cardNames[player1[i]]);
    }

    fprintf(f2, "Cartile tale (Player 2):\n");
    for (int i = 0; i < p2Size; i++) {
        fprintf(f2, "- %s\n", cardNames[player2[i]]);
    }

    fclose(f1);
    fclose(f2);
}

void futureFile() {
    FILE *f = fopen("future.txt", "w");
    if (f == NULL) return;

    fprintf(f, "Top 3 carti din pachet:\n"); 
    for (int i = 1; i <= 3 && (deckSize - i) >= 0; i++) {
        fprintf(f, "%d. %s\n", i, cardNames[deck[deckSize - i]]); 
    }
    
    fclose(f);
    printf("Te poti uita in viitor (future.txt). Scrie DONE cand termini.\n"); 
}