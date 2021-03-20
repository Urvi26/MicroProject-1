#include <xc.inc>

extrn	Clock_setup, Clock
extrn	operation, delay
extrn	LCD_Setup , LCD_Clear
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
	
	bra settings_clock ;or goto?	;check again if F isnt pressed
	
	;bsf operation_check,0	;bit that is 1 if F is pressed
	call operation		; go to operation if F is pressed
	
	;call LCD_Clear
	;bcf operation_check,0	;clear operation_check
	goto settings_clock 

	end	main

