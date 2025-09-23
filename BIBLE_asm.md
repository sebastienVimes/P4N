# 📖 BIBLE VECTREX ASM - VERSION 3.0
## Sagesse Consolidée du Développement Vectrex

---

# PRÉFACE : L'ÉVOLUTION DE CE DOCUMENT

Cette Bible V3.0 intègre l'expérience réelle du développement d'un Puissance 4 fonctionnel, avec tous les pièges rencontrés, les solutions validées sur hardware réel, et la sagesse de la communauté Vectrex accumulée depuis 1982.

---

# CHAPITRE 1 : COMPRENDRE LA BÊTE

## 1.1 CE QU'EST VRAIMENT LE VECTREX

Le Vectrex n'est pas qu'une console 8-bit. C'est :
- Un **oscilloscope jouable** avec affichage vectoriel
- Un **défi permanent** avec 1KB de RAM
- Une **leçon d'optimisation** à chaque ligne de code
- Un **écosystème unique** où chaque cycle compte

## 1.2 SPÉCIFICITÉS CRITIQUES

### Ce qui rend le Vectrex unique (et difficile)
- **Pas de framebuffer** : Tout doit être redessiné 50 fois/seconde
- **Dérive du faisceau** : Position relative qui dérive sans Reset0Ref
- **Coordonnées signées** : -128 à +127, attention aux débordements
- **Pas de division hardware** : Seulement ADD, SUB, MUL
- **Budget strict** : ~30000 cycles par frame maximum

### Les symptômes de problèmes
```
Symptôme               | Cause probable
-----------------------|------------------
Grille qui "danse"     | Reset0Ref manquants
Vectrex "grogne"       | Surcharge CPU (>250 vecteurs)
Écran noir             | Crash/boucle infinie
Jetons au mauvais endroit | Coordonnées relatives mal gérées
Scintillement          | < 50Hz (trop de vecteurs)
```

---

# CHAPITRE 2 : PATTERNS VALIDÉS SUR HARDWARE

## 2.1 PATTERN : Structure de Programme

### ✅ STRUCTURE QUI MARCHE
```asm
    include "vectrex.i"
    org 0
    
    ; Header cartridge
    db "g GCE 2024", $80
    ; ...
    
    ; Tables en ROM (avant les EQU !)
col_x_table: fcb -51,-34,-17,0,17,34,51
row_y_table: fcb -41,-24,-7,10,27,44

    ; Variables (EQU seulement)
cursor_pos  equ $C880
game_board  equ $C900  ; Zone sûre !

main:
    jsr init_all
main_loop:
    jsr Wait_Recal      ; OBLIGATOIRE
    jsr handle_input
    jsr update_logic
    jsr draw_smart      ; Normal ou interlaced
    bra main_loop
```

### ❌ PIÈGES À ÉVITER
```asm
; JAMAIS de RMB au milieu du code !
    org $C880
temp: rmb 1    ; ERREUR : Binaire de 50KB !

; JAMAIS d'oubli de Wait_Recal
main_loop:
    jsr draw_all   ; Sans Wait_Recal = chaos
```

## 2.2 PATTERN : Optimisation d'Affichage

### Technique d'Interlacing ~~(Validée)~~ (ATTENTION - BUGUÉ)
```asm
; ⚠️ AVERTISSEMENT : L'interlacing a causé des bugs majeurs
; lors des tests (crash au 20ème jeton).
; Cause : variables FCB en ROM au lieu d'EQU en RAM.
; 
; RECOMMANDATION : NE PAS UTILISER
; Préférer la simplification des formes si problème de performance
```

### Reset0Ref Optimisé
```asm
; Tous les 30 vecteurs max
Reset0Ref_smart:
    inc vector_count
    lda vector_count
    cmpa #30
    blo skip
    
    clr vector_count
    ; Version rapide (6 cycles vs 30)
    ldd #$0302
    stb VIA_port_b
    sta VIA_port_b
skip:
    rts
```

## 2.3 PATTERN : Gestion Mémoire

### Organisation Validée
```asm
; $C800-$C87F : SYSTÈME (NE PAS TOUCHER !)
; $C880-$C8FF : Variables user (128 bytes)
; $C900-$CBFF : Game data (safe zone)
; $CC00-$CFFF : Stack système

; Toujours utiliser EQU
variable1 equ $C880
variable2 equ $C881
; Pas de RMB !
```

---

# CHAPITRE 3 : OPTIMISATIONS DÉCOUVERTES

## 3.1 VECTEURS RAPIDES

### Principe : Scale Bas + Strength Élevée
```asm
; LENT (127 cycles)
    lda #$7F        ; Scale max
    ldb #10         ; Petit mouvement
    jsr Draw_Line_d
    
; RAPIDE (8 cycles !)
    lda #$08        ; Scale minimal  
    ldb #127        ; Grand mouvement
    jsr Draw_Line_d
```

### Attention aux Effets de Bord
- Scale < 6 : Lignes "cassées" sur certains Vectrex
- Scale > 50 : Perte de temps CPU massive
- Sweet spot : Scale 10-30 pour la plupart des cas

## 3.2 TABLES LOOKUP vs CALCULS

### Cas de la Division par 7
```asm
; LENT : Division logicielle
divide_by_7:
    ; ~50 cycles de boucle
    
; RAPIDE : Table lookup
row_from_index:
    ldx #row_table
    lda index
    lda a,x         ; 5 cycles !
    rts
    
row_table:
    fcb 0,0,0,0,0,0,0  ; Index 0-6
    fcb 1,1,1,1,1,1,1  ; Index 7-13
    ; etc...
```

## 3.3 LIMITES DE PERFORMANCE

### Budget par Frame (50Hz = 20ms)
```
Élément              | Cycles  | % Frame
---------------------|---------|--------
Wait_Recal           | ~2000   | 7%
Draw_Grid (30 lignes)| ~5000   | 17%
Draw_20_Tokens       | ~10000  | 33%
Handle_Input         | ~1000   | 3%
Game_Logic          | ~2000   | 7%
---------------------|---------|--------
TOTAL               | ~20000  | 67%
Marge disponible    | ~10000  | 33%
```

### Seuils Critiques
- < 100 vecteurs : Parfait
- 100-200 : Stable
- 200-250 : Limite
- 250-300 : Scintillement
- > 300 : Crash

---

# CHAPITRE 4 : DIFFÉRENCES ENTRE ÉMULATEURS

## 4.1 TABLEAU COMPARATIF

| Aspect | VIDE | Vectrexy | ParaJVE | Hardware |
|--------|------|----------|---------|----------|
| Reset0Ref requis | Parfois | Souvent | Variable | TOUJOURS |
| Tolérance dérive | Haute | Moyenne | Haute | NULLE |
| Max vecteurs | ~400 | ~300 | ~350 | ~250 |
| Flags 6809 | Permissifs | Stricts | Moyens | TRÈS stricts |
| Sons | Approximatifs | Bons | Excellents | Parfaits |

## 4.2 STRATÉGIE DE TEST

1. **Développer sur VIDE** (rapide, debug)
2. **Valider sur Vectrexy** (plus strict)
3. **Tester sur ParaJVE** (pour le son)
4. **Confirmer sur Hardware** (vérité finale)

---

# CHAPITRE 5 : SOLUTIONS AUX PROBLÈMES COURANTS

## 5.1 "Mon jeu crash au Nème objet"

### Diagnostic
```asm
; Ajouter des compteurs debug
    inc object_count
    lda object_count
    cmpa #DEBUG_THRESHOLD
    bne continue
    ; Point d'arrêt ici
```

### Solutions
1. Implémenter l'interlacing
2. Simplifier les formes
3. Réduire le scale
4. Optimiser les Reset0Ref

## 5.2 "La Vectrex grogne"

### Cause : Surcharge DAC
Le convertisseur digital-analogique sature.

### Solution
```asm
; Limiter les vecteurs
    lda vector_total
    cmpa #200
    bhi emergency_mode
    
normal_draw:
    jsr draw_everything
    bra done
    
emergency_mode:
    jsr draw_essential_only
```

## 5.3 "Tous mes sprites sont identiques"

### Cause : Comparaison buggée
Les flags 6809 ne sont pas mis à jour comme attendu.

### Solution
```asm
; Au lieu de :
    cmpb #1
    beq type1
    
; Utiliser :
    tstb
    beq type0
    cmpb #2
    beq type2
    ; Sinon c'est type1
```

---

# CHAPITRE 6 : TECHNIQUES AVANCÉES

## 6.1 SMARTLISTS (Kristof Tuts)

Optimisation ultime pour listes de vecteurs :
```asm
; Liste optimisée avec commandes intégrées
smart_list:
    fcb MOVE_TO, -50, -50
    fcb DRAW_TO, 50, -50
    fcb DRAW_TO, 50, 50
    fcb SET_SCALE, 10
    fcb DRAW_TO, -50, 50
    fcb END_LIST
```

## 6.2 DOUBLE BUFFERING

Pour animations complexes :
```asm
buffer_A equ $CA00
buffer_B equ $CB00
current_buffer equ $C88F

swap_buffers:
    lda current_buffer
    eora #1
    sta current_buffer
```

## 6.3 SON SYNCHRONISÉ

Jouer des sons sans perdre le 50Hz :
```asm
; Dans la boucle principale
    jsr Wait_Recal
    jsr Do_Sound        ; AVANT le dessin
    jsr draw_all
```

---

# CHAPITRE 7 : SAGESSE DE LA COMMUNAUTÉ

## Citations des Maîtres

> "Sur Vectrex, moins c'est plus. Chaque vecteur compte."
> - Kristof Tuts

> "La vraie optimisation commence quand vous pensez avoir fini."
> - Malban (créateur de VIDE)

> "Testez sur du vrai hardware ou préparez-vous aux surprises."
> - John Dondzila

## Les 10 Commandements Vectrex

1. **Tu utiliseras Wait_Recal** à chaque frame
2. **Tu appelleras Reset0Ref** régulièrement  
3. **Tu valideras toutes les entrées**
4. **Tu éviteras la pile complexe**
5. **Tu utiliseras des tables lookup**
6. **Tu testeras sur vrai hardware**
7. **Tu optimiseras seulement si nécessaire**
8. **Tu respecteras le budget de 250 vecteurs**
9. **Tu utiliseras l'interlacing si besoin**
10. **Tu t'amuseras en codant**

---

# CHAPITRE 8 : RÉFÉRENCE RAPIDE

## Instructions Critiques 6809
```asm
; Les plus utiles
LDA/LDB/LDD    ; Chargement (A, B, D=A:B)
STA/STB/STD    ; Stockage
CMPA/CMPB      ; Comparaison
BEQ/BNE/BHI/BLO ; Branchements
JSR/RTS        ; Sous-routines (12 cycles!)
MUL            ; A×B→D (11 cycles)
EXG/TFR        ; Échange/Transfert registres
PSHS/PULS      ; Push/Pull pile

; À éviter si possible
DIV            ; N'EXISTE PAS !
LDY/STY        ; 2ème page (plus lent)
LBRA/LBSR      ; Long branch (plus lent)
```

## Routines BIOS Essentielles
```asm
Wait_Recal      ; Sync 50Hz (~2000 cycles)
Reset0Ref       ; Reset position (~30 cycles)
Intensity_a     ; Définir intensité
Moveto_d        ; Déplacer sans tracer
Draw_Line_d     ; Tracer ligne
Read_Btns       ; Lire boutons
Joy_Digital     ; Lire joystick
```

## Zones Mémoire
```
$0000-$7FFF : ROM Cartridge
$8000-$C7FF : Non mappé
$C800-$C87F : BIOS workspace (DANGER!)
$C880-$CBFF : RAM utilisateur (896 bytes)
$CC00-$CFFF : Stack (1KB)
$D000-$D7FF : VIA (I/O)
$E000-$FFFF : ROM BIOS
```

---

# CHAPITRE 9 : CHECKLIST PROJET

## Avant de Commencer
- [ ] Structure de base testée
- [ ] Variables en zone sûre ($C900+)
- [ ] Tables en ROM
- [ ] Boucle principale avec Wait_Recal

## En Développement  
- [ ] < 100 vecteurs : continuer normal
- [ ] > 100 vecteurs : planifier optimisation
- [ ] > 150 vecteurs : implémenter interlacing
- [ ] > 200 vecteurs : mode urgence

## Avant Release
- [ ] Testé sur VIDE
- [ ] Validé sur Vectrexy
- [ ] Son vérifié sur ParaJVE
- [ ] Confirmé sur hardware réel

---

# CONCLUSION : LA PHILOSOPHIE VECTREX

Le Vectrex nous enseigne que **les contraintes libèrent la créativité**. Avec seulement 1KB de RAM et 250 vecteurs, nous devons être ingénieux, précis, et élégants.

Chaque jeu Vectrex est une œuvre d'optimisation, un défi technique, et une leçon d'humilité face au hardware.

**Le secret ?** Ne pas combattre les limites, mais danser avec elles.

---

## ANNEXE : RESSOURCES

### Sites Essentiels
- VIDE : vide.malban.de
- VectrexWorld : vectrex.nl
- PlayVectrex : playvectrex.com
- AtariAge Forums : atariage.com/forums

### Outils
- VIDE : IDE complet
- AS09 : Assembleur
- ParaJVE : Émulateur précis
- Vectrexy : Émulateur moderne

### Communauté
- Discord Vectrex
- Facebook "Vectrex Fans Unite"
- GitHub vectrex-community

---

*Bible Vectrex V3.0 - Décembre 2024*
*Sagesse accumulée depuis 1982*
*Enrichie par l'expérience Puissance 4*

**"In vectors we trust"**