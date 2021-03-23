#include <xc.inc>

extrn	Clock_Setup, Clock
extrn	operation
extrn	LCD_Setup, LCD_Clear
extrn	Keypad, keypad_val, keypad_ascii
  
global	operation_check
    
psect	udata_acs
operation_check:	ds  1	;reserving byte   
    
psect	code, abs
	
main:	org	0x0	; reset vector
	goto	start
	;org	0x100

int_hi:	org	0x0008	; high vector, no low vector
	goto	Clock
	
start:
	call	LCD_Setup
	call	Clock_Setup
	
	clrf	operation_check
	
settings_clock:
	call	Keypad
	movlw	0x0f
	CPFSEQ	keypad_val
	bra	settings_clock
	
	call	operation

	
	goto	settings_clock	; Sit in infinite loop
    
	end	main