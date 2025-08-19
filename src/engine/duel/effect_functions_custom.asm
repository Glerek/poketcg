; Custom Card Effect Functions
; This file contains all custom card effects and related functions
; Created to provide dedicated space for future card implementations

CustomCardEffectBegin::

; During your next turn, cannot attack
CannotAttackNextTurnEffect:
	ld a, [wTempTurnDuelistCardID]
	cp MIRAIDONEX
	ret nz
	ld a, SUBSTATUS1_NEXT_TURN_CANNOT_ATTACK
	farcall ApplySubstatus1ToDefendingCard
	ret

TandemUnit_PlayerSelection:
	; check available bench space to determine max selections
	ld a, DUELVARS_NUMBER_OF_POKEMON_IN_PLAY_AREA
	call GetTurnDuelistVariable
	ld a, MAX_PLAY_AREA_POKEMON
	sub [hl]  ; available bench space
	jr z, .no_pkmn  ; no bench space available
	cp 2
	jr c, .set_max_one  ; if only 1 space, limit to 1
	ld a, 2  ; can select up to 2
	jr .store_max
.set_max_one
	ld a, 1  ; can only select 1
.store_max
	ldh [hTempList], a  ; store max selections allowed
	
	; create list of all Pokemon cards in deck to search for
	call CreateDeckCardList
	ldtx hl, ChooseBasicLightningPokemonToPlaceOnBenchText
	ldtx bc, BasicLightingPokemonText
	lb de, SEARCHEFFECT_BASIC_LIGHTNING, 0
	farcall LookForCardsInDeck
 	jr c, .no_pkmn ; return if Player chose not to check deck

; handle input
	bank1call InitAndDrawCardListScreenLayout_WithSelectCheckMenu
	ldtx hl, ChooseBasicLightningPokemonCardText
	ldtx de, DuelistDeckText
	bank1call SetCardListHeaderText
	
	; initialize selection tracking
	xor a
	ldh [hTempList + 3], a  ; current number of selected cards
	ld a, $ff
	ldh [hTempList + 1], a  ; first selected card (invalid initially)
	ldh [hTempList + 2], a  ; second selected card (invalid initially)
	
.read_input
	bank1call DisplayCardList
	jr c, .done_selecting ; B was pressed, proceed with current selections
	ldh a, [hTempCardIndex_ff98]
	call LoadCardDataToBuffer2_FromDeckIndex
	ld a, [wLoadedCard2Type]
	cp TYPE_ENERGY
	jr nc, .play_sfx ; can't select non-Pokemon card
	
	; check if this card was already selected
	ldh a, [hTempCardIndex_ff98]
	ld b, a
	ldh a, [hTempList + 1]  ; first selected card
	cp b
	jr z, .play_sfx         ; already selected
	ldh a, [hTempList + 2]  ; second selected card
	cp b
	jr z, .play_sfx         ; already selected
	
	; check if we can select more
	ldh a, [hTempList + 3]  ; current selection count
	ld b, a
	ldh a, [hTempList]      ; max allowed selections
	cp b
	jr z, .play_sfx         ; already at max, play error sound
	jr c, .play_sfx         ; current > max somehow, play error sound
	
	; store the selected card
	ldh a, [hTempCardIndex_ff98]
	ld c, a                 ; save card index
	ldh a, [hTempList + 3]  ; current selection count
	ld b, a                 ; save current count
	inc a
	ldh [hTempList + 3], a  ; increment selection count
	ld a, b                 ; restore original count for comparison
	or a                    ; check if first selection (count was 0)
	jr nz, .store_second
	
	; store first card (b was 0)
	ld a, c                 ; restore card index
	ldh [hTempList + 1], a
	jr .check_if_done
	
.store_second
	; store second card (b was 1)  
	ld a, c                 ; restore card index
	ldh [hTempList + 2], a
	
.check_if_done
	ldh a, [hTempList + 3]  ; current selections
	ld b, a
	ldh a, [hTempList]      ; max selections
	cp b
	jr nz, .read_input      ; can select more
	; reached max, auto-proceed
	or a
	ret
	
.done_selecting
	or a
	ret

.no_pkmn
	xor a
	ldh [hTempList + 3], a  ; no selections
	or a
	ret

.play_sfx
	call PlaySFX_InvalidChoice
	jr .read_input

TandemUnit_PlaceInPlayAreaEffect:
 	ldh a, [hTempList + 3]  ; number of selected cards
 	or a
 	jr z, .done ; skip if no Pokemon was chosen

	; place first card if selected
 	ldh a, [hTempList + 1]
 	cp $ff
 	jr z, .check_second  ; no first card
 	call SearchCardInDeckAndAddToHand
 	call AddCardToHand
	call PutHandPokemonCardInPlayArea
	ldh a, [hTempList + 1]  ; restore deck index for display
	ldtx hl, PlacedOnTheBenchText
	bank1call DisplayCardDetailScreen

.check_second
	; place second card if selected  
 	ldh a, [hTempList + 2]
 	cp $ff
 	jr z, .done  ; no second card
 	call SearchCardInDeckAndAddToHand
 	call AddCardToHand
	call PutHandPokemonCardInPlayArea
	ldh a, [hTempList + 2]  ; restore deck index for display
	ldtx hl, PlacedOnTheBenchText
	bank1call DisplayCardDetailScreen

.done
	farcall ShuffleCardsInDeck
 	ret

CustomCardEffectEnd::