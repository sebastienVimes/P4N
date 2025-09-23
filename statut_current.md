# STATUT PROJET CONNECT FOUR VECTREX
## Session du 23 Décembre 2025

---

## 📍 OÙ ON EN EST

### Fonctionnel ✅
- **Grille 7x6** complète et affichée correctement
- **Curseur triangulaire** mobile (touches F/D/Q)
- **Gravité des jetons** corrigée et fonctionnelle
- **Alternance joueurs** (1→2→1...) opérationnelle
- **Affichage X et O** distinct sur émulateur VIDE
- **42 jetons** affichables (grille complète possible)
- **Structure mémoire** stabilisée ($C900 pour game_board)

### Problèmes résolus ✅
- ~~Bug du 3ème jeton~~ → Corrigé (gravité fixée)
- ~~Crash au remplissage~~ → Résolu avec bonne adresse mémoire
- ~~Algorithme gravité inversé~~ → Maintenant parcourt depuis row=0

### Bugs actuels 🔴
- **Jetons identiques sur hardware** : Tous apparaissent comme des carrés sur Vextreme/Vectrexy (OK sur VIDE)
- **Surcharge au-delà de 20 jetons** : La Vectrex "grogne", performance dégradée
- **Interlacing non fonctionnel** : Implementation buggée, chaos au 20ème jeton

### À implémenter ⏳
1. **MOTEUR DE JEU** (priorité absolue)
   - Détection victoire horizontale
   - Détection victoire verticale  
   - Détection victoire diagonale
   - Détection match nul
2. **États de jeu** (victoire/défaite/nul)
3. **Écran titre et menu**
4. **Sons** (placement, victoire)
5. **Message de fin de partie**
6. **Option rejouer**

---

## 📝 HISTORIQUE RÉCENT

### Sessions Septembre 2025
- Création du triptyque initial
- Bug persistant du 3ème jeton identifié
- Multiple tentatives de résolution

### Sessions Décembre 2025  
- **Gravité corrigée** définitivement
- **Interlacing testé** mais échoué
- **Triptyque V3.0** créé avec réserves
- **Sur-optimisation** causant régression
- **Retour au code simple** qui fonctionne

---

## ⚠️ NOTES CRITIQUES

### NE PAS FAIRE
- **Éviter l'interlacing** - Concept théorique OK mais implémentation buggée
- **Ne pas déclarer en FCB** les variables modifiables (utiliser EQU en RAM)
- **Ne pas optimiser prématurément** - KISS principe
- **Ne pas toucher** au code d'affichage qui marche

### FAIRE
- **Garder simple** - Pas plus de 2 lignes par forme de jeton
- **Tester sur Vectrexy** après chaque modification
- **game_board à $C900** - Adresse validée qui fonctionne
- **Utiliser le code original** Tokens.asm comme base

### Différences émulateurs
- **VIDE** : Permissif, bon pour développement rapide
- **Vectrexy** : Strict, proche du hardware réel
- **Vextreme** : Hardware réel, arbitre final

---

## 📊 MÉTRIQUES

### Completion globale : **~70%**
- Affichage : 100% ✅
- Contrôles : 100% ✅
- Mécanique placement : 90% ✅
- Moteur de jeu : 0% ❌
- Polish (sons, menus) : 0% ❌

### Performance
- **Stable** : jusqu'à 20 jetons
- **Dégradée** : 20-42 jetons  
- **Limite** : ~250 vecteurs/frame

### Code
- **Taille actuelle** : ~1200 lignes ASM
- **ROM utilisée** : ~4KB
- **RAM utilisée** : ~100 bytes

---

## 🎯 PROCHAINE ÉTAPE IMMÉDIATE

**IMPLÉMENTER LE MOTEUR DE JEU**

Commencer par la détection horizontale (plus simple) :
```asm
; Pseudo-code à implémenter
check_horizontal:
    ; Pour chaque ligne
    ; Pour chaque séquence de 4
    ; Vérifier si 4 identiques
    ; Retourner victoire si trouvé
```

Une fois horizontal OK, ajouter vertical puis diagonales.

---

## 📁 FICHIERS CLÉS

### Code qui marche
- `Tokens_original.asm` - Version avec X/O distincts
- `Grid.asm` - Affichage grille stable

### Documentation à jour  
- `bible_vectrex_v3.md` - Référence technique
- `architecture_v3.md` - Logique du jeu (80% valide)
- `adaptation_v3.md` - Implementation (ignorer interlacing)

### À éviter
- Toute version avec "interlaced" dans le nom
- Code avec filter_type en FCB

---

## 💭 CONTEXTE NARRATIF

Projet inscrit dans création plus large :
- Roman avec Paul Allen Newell (PAN)
- Hommage à l'héritage IA (Allen Newell → PAN)
- Connect Four = pont entre IA académique et gaming rétro

---

## ✅ DÉCISION STRATÉGIQUE

**Le visuel fonctionne. Stop l'optimisation graphique.**

**FOCUS TOTAL sur le moteur de jeu.**

Sans détection de victoire, on n'a pas de jeu. C'est LA priorité absolue.

---

*Document de liaison - Triptyque Connect Four Vectrex*  
*Dernière mise à jour : 23 décembre 2025*  
*État : Visuel OK, Moteur manquant*  
*Prochain objectif : Détection victoire horizontale*