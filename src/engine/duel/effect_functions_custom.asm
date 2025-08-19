; Custom Card Effects
; This file contains custom card effects and related functions
; Created to provide dedicated space for future card implementations

; Test function to verify cross-section calling works
; This can be removed once we confirm the infrastructure is working
TestCustomEffect::  ; Note: using :: to make it globally visible
	farcall ShuffleCardsInDeck
 	ret

; Future custom card effects will be added here
; Each new card effect should be documented with:
; - Card name and effect description
; - Input/output parameters
; - Any special considerations