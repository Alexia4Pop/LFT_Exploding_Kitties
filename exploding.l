%{
#include "exploding.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* --- PROTOTIPURI --- */
/* Acestea trebuie declarate aici pentru a fi vizibile in tot fisierul */
void start_action();
void extract_card();
int playerHasCard(int cardType);
void deleteCard(int cardType);

/* --- VARIABILE GLOBALE --- */
/* Definim stările și structurile conform documentației [cite: 143, 144] */
enum states { START_S, WAIT_COMMAND, WAIT_DONE, WAIT_GIVE, WAIT_PLACEMENT };
enum states state = START_S; 

int deck[50]; 
int player1[30], player2[30]; 
int deckSize = 0, p1Size = 0, p2Size = 0; 
int currentPlayer = 1; 
int nrofTurns = 1;
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
/* Toate functiile se scriu in ultima sectiune a fisierului Lex */

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
}

void start_action() {
    srand(time(NULL));
    p1Size = 8;
    p2Size = 8; 
    
    player1[0] = 1; // Atribuim DEFUSE jucatorilor [cite: 185]
    player2[0] = 1; 
    
    deckSize = 20; 
    state = WAIT_COMMAND;
    printf("Jocul a inceput! Player 1, este randul tau.\n");
}

void extract_card() {
    if (deckSize <= 0) {
        printf("Nu mai sunt carti in pachet!\n");
        return;
    }

    int card = deck[--deckSize]; 
    printf("Ai extras: %d\n", card);

    if (card == 0) { // 0 = EXPLODE [cite: 149]
        if (playerHasCard(1)) { // 1 = DEFUSE [cite: 150]
            printf("BUM! Dar ai avut DEFUSE. Pune bomba inapoi.\n"); 
            deleteCard(1); 
            state = WAIT_PLACEMENT;
        } else {
            printf("GAME OVER! Player %d a explodat.\n", currentPlayer); 
            exit(0); 
        }
    } else {
        nrofTurns--;
        if (nrofTurns <= 0) {
            currentPlayer = (currentPlayer == 1) ? 2 : 1;
            nrofTurns = 1;
        }
    }
}

void writeCardsToFile() {
    FILE *f1 = fopen("pl1.txt", "w");
    FILE *f2 = fopen("pl2.txt", "w");
    
    if (f1 == NULL || f2 == NULL) {
        printf("Eroare la deschiderea fisierelor de carti!\n");
        return;
    }

    // Scriem cartile pentru Player 1
    fprintf(f1, "Cartile tale (Player 1):\n");
    for (int i = 0; i < p1Size; i++) {
        fprintf(f1, "%d ", player1[i]); // Poti inlocui %d cu numele cartii dintr-un array de string-uri
    }

    // Scriem cartile pentru Player 2
    fprintf(f2, "Cartile tale (Player 2):\n");
    for (int i = 0; i < p2Size; i++) {
        fprintf(f2, "%d ", player2[i]);
    }

    fclose(f1);
    fclose(f2);
}

void futureFile() {
    FILE *f = fopen("future.txt", "w");
    if (f == NULL) return;

    fprintf(f, "Viitorul pachetului:\n");
    for (int i = 1; i <= 3 && (deckSize - i) >= 0; i++) {
        fprintf(f, "%d. Cartea cu ID: %d\n", i, deck[deckSize - i]);
    }
    
    fclose(f);
}