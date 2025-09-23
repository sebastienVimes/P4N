; =========================================
; PUISSANCE 4 VECTREX - VERSION CORRIGÉE
; Corrections appliquées selon autotest
; =========================================

	include "vectrex.i"
	
	org     0
	
; === EN-TÊTE CARTRIDGE ===
	db      "g GCE 2024", $80
	dw      $F600
	db      $F8, $50, $20, -$50
	db      "PUISSANCE 4", $80
	db      0

; === VARIABLES RAM (TOUTES EN EQU) ===
cursor_col	equ	$C880	; Position curseur (0-6)
current_player	equ	$C881	; Joueur actuel (1 ou 2)
move_count	equ	$C882	; Compteur de coups
; Variables temporaires pour draw_all_tokens
temp_row	equ	$C883	; Pour éviter pile complexe
temp_col	equ	$C884
temp_type	equ	$C885
; game_board en zone sûre
game_board	equ	$C900	; Grille 7x6 = 42 octets

; =========================================
; PROGRAMME PRINCIPAL
; =========================================
main:
	; Initialisation
	lda	#3
	sta	cursor_col	; Curseur au centre
	
	lda	#1
	sta	current_player	; Joueur 1 commence
	
	clr	move_count	; 0 coups
	
	; Effacer la grille
	ldx	#game_board
	ldb	#42
clear_loop:
	clr	,x+
	decb
	bne	clear_loop
	
main_loop:
	jsr     Wait_Recal
	
	jsr	handle_controls
	
	lda     #$7f
	jsr     Intensity_a
	
	jsr	draw_grid
	jsr	draw_cursor
	
	; PAS D'INTERLACING - Toujours affichage normal
	jsr	draw_all_tokens
	
	bra     main_loop

; =========================================
; DESSINER LA GRILLE (INCHANGÉ)
; =========================================
draw_grid:
	jsr	Reset0Ref
	ldb     #-60
	lda     #-50
	jsr     Moveto_d
	
	; Rectangle externe
	ldb     #120
	lda     #0
	jsr     Draw_Line_d
	
	ldb     #0
	lda     #100
	jsr     Draw_Line_d
	
	ldb     #-120
	lda     #0
	jsr     Draw_Line_d
	
	ldb     #0
	lda     #-100
	jsr     Draw_Line_d
	
	; Lignes horizontales
	jsr     Reset0Ref
	ldb     #-60
	lda     #-33
	jsr     Moveto_d
	ldb     #120
	lda     #0
	jsr     Draw_Line_d
	
	jsr     Reset0Ref
	ldb     #-60
	lda     #-16
	jsr     Moveto_d
	ldb     #120
	lda     #0
	jsr     Draw_Line_d
	
	jsr     Reset0Ref
	ldb     #-60
	lda     #0
	jsr     Moveto_d
	ldb     #120
	lda     #0
	jsr     Draw_Line_d
	
	jsr     Reset0Ref
	ldb     #-60
	lda     #17
	jsr     Moveto_d
	ldb     #120
	lda     #0
	jsr     Draw_Line_d
	
	jsr     Reset0Ref
	ldb     #-60
	lda     #33
	jsr     Moveto_d
	ldb     #120
	lda     #0
	jsr     Draw_Line_d
	
	; Lignes verticales
	jsr     Reset0Ref
	ldb     #-43
	lda     #-50
	jsr     Moveto_d
	ldb     #0
	lda     #100
	jsr     Draw_Line_d
	
	jsr     Reset0Ref
	ldb     #-26
	lda     #-50
	jsr     Moveto_d
	ldb     #0
	lda     #100
	jsr     Draw_Line_d
	
	jsr     Reset0Ref
	ldb     #-9
	lda     #-50
	jsr     Moveto_d
	ldb     #0
	lda     #100
	jsr     Draw_Line_d
	
	jsr     Reset0Ref
	ldb     #9
	lda     #-50
	jsr     Moveto_d
	ldb     #0
	lda     #100
	jsr     Draw_Line_d
	
	jsr     Reset0Ref
	ldb     #26
	lda     #-50
	jsr     Moveto_d
	ldb     #0
	lda     #100
	jsr     Draw_Line_d
	
	jsr     Reset0Ref
	ldb     #43
	lda     #-50
	jsr     Moveto_d
	ldb     #0
	lda     #100
	jsr     Draw_Line_d
	
	rts

; =========================================
; DESSINER LE CURSEUR (INCHANGÉ)
; =========================================
draw_cursor:
	jsr     Reset0Ref
	
	; Position X = -51 + (cursor_col * 17)
	lda	cursor_col
	ldb	#17
	mul
	addb	#-51
	lda     #58
	jsr     Moveto_d
	
	; Triangle
	lda     #$5f
	jsr     Intensity_a
	
	ldb     #-5
	lda     #0
	jsr     Moveto_d
	
	ldb     #10
	lda     #0
	jsr     Draw_Line_d
	
	ldb     #-5
	lda     #-7
	jsr     Draw_Line_d
	
	ldb     #-5
	lda     #7
	jsr     Draw_Line_d
	
	rts

; =========================================
; GESTION DES CONTRÔLES (INCHANGÉ)
; =========================================
handle_controls:
	jsr	Read_Btns
	
	; Tester gauche (F = $04)
	pshs	a
	anda	#$04
	beq	test_right
	
	ldb	cursor_col
	beq	wait_rel	; Déjà à gauche
	decb
	stb	cursor_col
	bra	wait_rel
	
test_right:
	puls	a
	pshs	a
	anda	#$08		; D = $08
	beq	test_fire
	
	ldb	cursor_col
	cmpb	#6
	beq	wait_rel	; Déjà à droite
	incb
	stb	cursor_col
	bra	wait_rel
	
test_fire:
	puls	a
	pshs	a
	anda	#$01		; Q = $01
	beq	done_controls
	
	jsr	drop_token
	
wait_rel:
	jsr	Read_Btns
	bne	wait_rel
	
done_controls:
	puls	a
	rts

; =========================================
; PLACER UN JETON (GRAVITÉ CORRECTE)
; =========================================
drop_token:
	; Chercher case vide depuis le BAS
	lda	cursor_col
	ldx	#game_board
	leax	a,x		; X pointe sur [row=0, col]
	
	clra			; row = 0
find_empty:
	tst	,x		; Case vide ?
	beq	found_empty	; Trouvé !
	leax	7,x		; Monter d'une ligne
	inca
	cmpa	#6
	blo	find_empty
	
	; Colonne pleine
	rts
	
found_empty:
	; Placer le jeton
	ldb	current_player
	stb	,x
	
	; Incrémenter compteur
	inc	move_count
	
	; Changer de joueur
	ldb	current_player
	eorb	#3		; 1→2, 2→1
	stb	current_player
	
	rts

; =========================================
; DESSINER TOUS LES JETONS (VERSION SIMPLIFIÉE)
; =========================================
draw_all_tokens:
	clra			; row = 0
	sta	temp_row
	
next_row:
	clra			; col = 0
	sta	temp_col
	
next_col:
	; Calculer index = row * 7 + col
	lda	temp_row
	ldb	#7
	mul
	addb	temp_col
	
	; Lire la case
	ldx	#game_board
	abx
	ldb	,x		; Type de jeton
	beq	skip_draw	; Si 0, case vide
	
	; Sauver type
	stb	temp_type
	
	jsr	Reset0Ref
	
	; X écran = -51 + col * 17
	lda	temp_col
	ldb	#17
	mul
	addb	#-51
	pshs	b		; Sauver X
	
	; Y écran = -41 + row * 17
	lda	temp_row
	ldb	#17
	mul
	addb	#-41
	tfr	b,a		; Y dans A
	puls	b		; X dans B
	
	jsr	Moveto_d
	
	; Dessiner selon type (LOGIQUE ORIGINALE)
	ldb	temp_type
	cmpb	#1
	bne	draw_p2
	jsr	draw_x
	bra	skip_draw
draw_p2:
	jsr	draw_o
	
skip_draw:
	; Col suivante
	inc	temp_col
	lda	temp_col
	cmpa	#7
	blo	next_col
	
	; Row suivante
	inc	temp_row
	lda	temp_row
	cmpa	#6
	blo	next_row
	
	rts

; =========================================
; DESSINER X (INCHANGÉ)
; =========================================
draw_x:
	lda	#$4f
	jsr	Intensity_a
	
	ldb	#-5
	lda	#-5
	jsr	Moveto_d
	ldb	#10
	lda	#10
	jsr	Draw_Line_d
	
	ldb	#-10
	lda	#0
	jsr	Moveto_d
	ldb	#10
	lda	#-10
	jsr	Draw_Line_d
	
	rts

; =========================================
; DESSINER O (INCHANGÉ)
; =========================================
draw_o:
	lda	#$4f
	jsr	Intensity_a
	
	ldb	#-5
	lda	#-5
	jsr	Moveto_d
	
	ldb	#10
	lda	#0
	jsr	Draw_Line_d
	
	ldb	#0
	lda	#10
	jsr	Draw_Line_d
	
	ldb	#-10
	lda	#0
	jsr	Draw_Line_d
	
	ldb	#0
	lda	#-10
	jsr	Draw_Line_d
	
	rts

; =========================================
; FIN - PAS DE FCB, PAS D'INTERLACING
; =========================================
	end     main