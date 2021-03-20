#include <xc.inc>

extrn	Clock_setup, Clock
extrn	operation
extrn	LCD_Setup
extrn	Keypad, keypad_val

global  operation_check
	
psect	udata_acs   
operation_check:	ds  1
	
psect	code, abs
	
main:	org	0x0000	; reset vector
	goto	start

int_hi:	org	0x0008	; high vector, no low vector
	goto	Clock

start:	call	LCD_Setup
	call	Clock_setup
	clrf	operation_check
	
settings_clock:
	call Keypad	; check what is pressed
	
	movlw	0x0f
	CPFSEQ	keypad_val
	
	bra settings_clock	;check again if F isnt pressed
	
	call operation		; go to operation if F is pressed
	
	goto settings_clock 

	end	main

