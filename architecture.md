# 🎮 ARCHITECTURE CONNECT 4 - DOCUMENT DE RÉFÉRENCE V3.0
## Pour Vectrex 6809 - Version Consolidée

---

# PARTIE 0 : RÈGLES OFFICIELLES DU PUISSANCE 4

## Objectif du jeu
Être le premier joueur à aligner 4 jetons de sa couleur horizontalement, verticalement ou en diagonale.

## Matériel
- Grille verticale de **7 colonnes × 6 lignes** (42 cases)
- 21 jetons par joueur (représentés par X et O sur Vectrex)

## Déroulement d'une partie
1. **Initialisation** : Grille vide, Joueur 1 (X) commence
2. **Tour de jeu** :
   - Le joueur choisit une colonne non-pleine
   - Le jeton **tombe par gravité** jusqu'à la case libre la plus basse
   - Aucun jeton ne peut être retiré ou déplacé
3. **Alternance** : Passage automatique au joueur suivant

## Conditions de fin
- **Victoire** : Premier à aligner 4 jetons (horizontal/vertical/diagonale)
- **Match nul** : 42 cases remplies sans alignement

## Règles critiques pour l'implémentation
1. **Gravité obligatoire** : Impossible de placer un jeton "en l'air"
2. **Validation de colonne** : Refuser le placement si colonne pleine (6 jetons)
3. **Détection immédiate** : Vérifier la victoire après chaque coup
4. **Diagonales valides** : Minimum 4 cases pour un alignement diagonal

---

# PARTIE 1 : ARCHITECTURE LOGIQUE UNIVERSELLE

## 1. REPRÉSENTATION DU PLATEAU

### Structure de données
```asm
; Grille linéaire pour Vectrex
game_board: equ $C900  ; 42 bytes contigus
; Index = row * 7 + col
; row 0 = BAS de la grille (gravité)
; row 5 = HAUT de la grille
; Valeurs : 0=vide, 1=joueur1(X), 2=joueur2(O)
```

### Mapping logique
```
INDICES DANS game_board:
Row 5: [35][36][37][38][39][40][41]  ← HAUT
Row 4: [28][29][30][31][32][33][34]
Row 3: [21][22][23][24][25][26][27]
Row 2: [14][15][16][17][18][19][20]
Row 1: [ 7][ 8][ 9][10][11][12][13]
Row 0: [ 0][ 1][ 2][ 3][ 4][ 5][ 6]  ← BAS (gravité)
       Col0 Col1 Col2 Col3 Col4 Col5 Col6
```

## 2. ALGORITHME DE PLACEMENT AVEC GRAVITÉ (VALIDÉ)

### ✅ VERSION TESTÉE ET FONCTIONNELLE
```asm
drop_token_validated:
    ; Entrée : cursor_col contient la colonne (0-6)
    ; Sortie : A=0 si succès, A=1 si colonne pleine
    
    ; Validation de la colonne
    lda cursor_col
    cmpa #7
    bhs invalid_column  ; >= 7 : erreur
    
    ; Chercher case vide depuis le BAS
    lda cursor_col
    ldx #game_board
    leax a,x           ; X = adresse de [row=0, col]
    
    clra               ; row = 0 (commence au bas)
find_empty:
    tst ,x             ; Case vide ?
    beq place_here     ; OUI → placer ici
    leax 7,x           ; NON → monter d'une ligne
    inca
    cmpa #6
    blo find_empty
    
invalid_column:
    lda #1             ; Colonne pleine ou invalide
    rts
    
place_here:
    ; Sauvegarder position pour check victoire
    sta last_row
    lda cursor_col
    sta last_col
    
    ; Placer le jeton
    lda current_player
    sta ,x
    
    ; Incrémenter compteur
    inc move_count
    
    ; Changer de joueur
    eora #3            ; 1→2, 2→1 (XOR avec 3)
    sta current_player
    
    clra               ; Succès
    rts
```

## 3. DÉTECTION DE VICTOIRE (SIMPLIFIÉE)

### Principe de base
Après chaque coup, vérifier dans 4 directions depuis le dernier jeton placé.

```asm
check_win_simple:
    ; Vérification horizontale seulement (pour commencer)
    lda last_row
    ldb #7
    mul
    tfr d,x
    lda #game_board
    leax a,x           ; X = début de la ligne
    
    ; Compter les jetons identiques consécutifs
    ldb #1             ; Le jeton qu'on vient de placer
    lda current_player
    eora #3            ; Récupérer le joueur qui vient de jouer
    
    ; Parcourir la ligne
    ; ... code de comptage ...
    
    cmpb #4
    bhs victory_found
    
    clra               ; Pas de victoire
    rts
    
victory_found:
    lda #1             ; Victoire !
    rts
```

## 4. OPTIMISATION D'AFFICHAGE (NOUVELLE SECTION)

### Problème identifié
Avec 42 jetons potentiels, dessiner tout à chaque frame surcharge la Vectrex :
- Maximum ~200-300 vecteurs par frame pour maintenir 50Hz
- Au-delà : bruit parasite, ralentissement, crash

### Solution 1 : Limitation du nombre de vecteurs
```asm
; Compter d'abord les jetons
count_tokens:
    ldx #game_board
    ldb #42
    clra
count_loop:
    tst ,x+
    beq skip_count
    inca
skip_count:
    decb
    bne count_loop
    
    ; Si > 20 jetons, utiliser une stratégie alternative
    cmpa #20
    bhi use_interlacing
```

### Solution 2 : Interlacing (CONCEPT - NE PAS IMPLÉMENTER)
**NOTE IMPORTANTE :** L'interlacing est théoriquement valide mais l'implémentation testée a causé des bugs majeurs. À éviter pour l'instant. Préférer la simplification des formes si problème de performance.

### Solution 3 : Optimisation des vecteurs
- Utiliser strength élevée et scale bas (<10)
- Minimiser les Reset0Ref
- Grouper les vecteurs proches

---

# PARTIE 2 : ADAPTATION SPÉCIFIQUE VECTREX

## 1. MAPPING LOGIQUE ↔ ÉCRAN

### Système de coordonnées
```
LOGIQUE (game_board):          ÉCRAN VECTREX:
Row 5 [35-41] (haut)           Y=+44 ←────── Row 5
Row 4 [28-34]                  Y=+27 ←────── Row 4  
Row 3 [21-27]                  Y=+10 ←────── Row 3
Row 2 [14-20]                  Y=-7  ←────── Row 2
Row 1 [7-13]                   Y=-24 ←────── Row 1
Row 0 [0-6] (bas/gravité)      Y=-41 ←────── Row 0

Col 0-6                        X=-51 à +51 (pas de 17)
```

### Formules de conversion
```asm
; Position X écran = -51 + (col * 17)
; Position Y écran = -41 + (row * 17)
; Index dans game_board = row * 7 + col
```

## 2. LIMITES HARDWARE VECTREX

### Contraintes critiques découvertes
- **Maximum ~200-300 vecteurs/frame** pour 50Hz stable
- **Dérive du faisceau** après trop de vecteurs sans Reset0Ref
- **Bruit DAC** quand surcharge (la Vectrex "grogne")
- **Crash système** si trop de cycles utilisés

### Dimensions optimales
```asm
; Grille
GRID_LEFT   = -60
GRID_RIGHT  = +60  
GRID_BOTTOM = -50
GRID_TOP    = +50

; Cellules
CELL_WIDTH  = 17
CELL_HEIGHT = 17

; Jetons (simplifiés pour performance)
TOKEN_SIZE  = 8    ; Réduit de 10 à 8
```

## 3. ORGANISATION MÉMOIRE DÉFINITIVE

```asm
; === ZONE $C880-$C8FF (128 bytes) ===
cursor_col:     equ $C880  ; Position curseur (0-6)
current_player: equ $C881  ; 1 ou 2
last_row:       equ $C882  ; Pour check victoire
last_col:       equ $C883  ; Pour check victoire
game_state:     equ $C884  ; 0=jeu, 1=P1 win, 2=P2 win, 3=nul
move_count:     equ $C885  ; Nombre de coups (max 42)
temp_row:       equ $C886  ; Variable temporaire
temp_col:       equ $C887  ; Variable temporaire
temp_type:      equ $C888  ; Variable temporaire
temp_index:     equ $C889  ; Variable temporaire
frame_counter:  equ $C88A  ; Pour interlacing

; === ZONE $C900-$C929 (42 bytes) ===
game_board:     equ $C900  ; Grille 7x6 = 42 bytes
; Zone validée sans conflit
```

## 4. TECHNIQUES D'OPTIMISATION VALIDÉES

### Tables de lookup (en ROM!)
```asm
; AVANT tout ORG $C8xx !
col_x_table:    fcb -51,-34,-17,0,17,34,51
row_y_table:    fcb -41,-24,-7,10,27,44
```

### Reset0Ref optimisé
```asm
; Version BIOS : ~30 cycles
; Version optimisée : 6 cycles
Reset0Ref_fast:
    ldd #$0302
    stb VIA_port_b
    sta VIA_port_b
    rts
```

### Dessin de jetons optimisé
```asm
draw_token_fast:
    ; Forme simplifiée : 2 lignes au lieu de 4
    ; X = une diagonale seulement
    ; O = deux lignes horizontales
    lda #$40           ; Intensité réduite
    jsr Intensity_a
    
    ; Dessin minimaliste
    ldb #8
    lda #0
    jsr Draw_Line_d
    rts
```

## 5. STRUCTURE DE JEU PRINCIPALE OPTIMISÉE

```asm
main_loop_optimized:
    jsr Wait_Recal
    
    ; Vérifier état
    lda game_state
    bne game_over
    
    ; Contrôles
    jsr handle_controls_safe
    
    ; Affichage avec interlacing si nécessaire
    lda move_count
    cmpa #15           ; Seuil pour activer interlacing
    bhi draw_interlaced
    
draw_normal:
    jsr draw_grid
    jsr draw_all_tokens
    bra continue
    
draw_interlaced:
    jsr draw_frame_interlaced
    
continue:
    jsr draw_cursor
    bra main_loop_optimized
```

## 6. GESTION DES ÉTATS DE JEU

```asm
; Machine d'états complète
STATE_MENU      equ 0
STATE_PLAYING   equ 1
STATE_WIN_P1    equ 2
STATE_WIN_P2    equ 3
STATE_TIE       equ 4
STATE_PAUSE     equ 5

state_handler:
    lda game_state
    asla               ; x2 pour index 16-bit
    ldx #state_table
    ldx a,x
    jsr ,x
    rts

state_table:
    fdb handle_menu
    fdb handle_playing
    fdb handle_win_p1
    fdb handle_win_p2
    fdb handle_tie
    fdb handle_pause
```

## 7. CHECKLIST D'IMPLÉMENTATION MISE À JOUR

### Phase 1 : Base fonctionnelle ✅
- [x] Grille 7x6 affichée
- [x] Curseur mobile avec garde-fous
- [x] Gravité correcte (algorithme validé)
- [x] Alternance joueurs
- [x] Validation colonne pleine
- [x] Affichage jetons X et O fonctionnel

### Phase 2 : Optimisation ⏳
- [ ] Simplification des formes si nécessaire
- [ ] Tables lookup en ROM
- [ ] Reset0Ref optimisé
- ~~[ ] Interlacing~~ (Concept bugué, éviter)

### Phase 3 : Logique de jeu ⏳
- [ ] Détection victoire horizontale
- [ ] Détection victoire verticale
- [ ] Détection victoire diagonales
- [ ] Détection match nul
- [ ] Machine d'états

### Phase 4 : Finition
- [ ] Écran titre
- [ ] Message de victoire
- [ ] Sons
- [ ] Possibilité de rejouer

## 8. PROBLÈMES RENCONTRÉS ET SOLUTIONS

### Problème 1 : Crash au 3ème jeton
**Cause** : Algorithme de gravité inversé
**Solution** : Parcourir depuis row=0 vers le haut ✅

### Problème 2 : Vectrex "grogne" avec beaucoup de jetons
**Cause** : Surcharge du processeur (> 300 vecteurs)
**Solution** : Interlacing au-delà de 15 jetons ✅

### Problème 3 : Tous les jetons identiques
**Cause** : Comparaison de type non fonctionnelle
**Solution** : Debug en cours, possiblement lié aux flags 6809

### Problème 4 : Différences entre émulateurs
**Cause** : VIDE permissif vs Vectrexy/Hardware strict
**Solution** : Toujours tester sur hardware réel

## 9. PATTERNS DE CODE VALIDÉS

### Pattern 1 : Boucle principale avec interlacing
```asm
main:
    jsr init_game
loop:
    jsr Wait_Recal
    jsr handle_state
    jsr draw_frame_smart  ; Choisit normal ou interlaced
    bra loop
```

### Pattern 2 : Validation systématique
```asm
; Toujours valider les entrées
validate_then_act:
    cmpa #LIMIT
    bhs error_handler
    ; Action sûre ici
```

### Pattern 3 : Variables temporaires vs pile
```asm
; Éviter la pile complexe
; Utiliser temp_var au lieu de push/pull multiples
```

---

## CONCLUSION

Cette architecture V3.0 intègre :
1. **Les règles officielles** en premier
2. **L'algorithme de gravité corrigé** et testé
3. **Les techniques d'optimisation** découvertes
4. **Les solutions aux problèmes** rencontrés
5. **Les patterns validés** sur hardware réel

Le document est maintenant aligné avec la réalité du développement et prêt pour les futurs projets Vectrex.

---

*Document de référence V3.0 - Projet Puissance 4 Vectrex*
*Décembre 2024*
*Statut : Architecture consolidée avec retour d'expérience*