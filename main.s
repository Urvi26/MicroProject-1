#include <xc.inc>

extrn	Clock_Setup, Clock, operation
extrn	LCD_Setup
extrn	Keypad, keypad_val, keypad_ascii
  
global	operation_check
    
psect	udata_acs
operation_check:	ds  1	;reserving byte to store second time in hex   
    
psect	code, abs
	
main:	org	0x0	; reset vector
	goto	start
	;org	0x100

int_hi:	org	0x0008	; high vector, no low vector
	goto	Clock
	
start:
	call	LCD_Setup
	call	Clock_Setup
	
	bcf	operation_check, 0 
	
settings_clock:
	call	Keypad
	movlw	0x0f
	CPFSEQ	keypad_val
	goto	settings_clock
	bsf	operation_check, 0
	call	operation
	bcf	operation_check, 0
	goto	settings_clock	; Sit in infinite loop
    
	end	main
