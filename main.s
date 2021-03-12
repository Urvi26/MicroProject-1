#include <xc.inc>

extrn	Clock_Setup, Clock, LCD_Setup

	psect	code, abs
	
rst:	org	0x0000	; reset vector
	goto	start

int_hi:	org	0x0008	; high vector, no low vector
	goto	Clock
	
start:	call	Clock_Setup
	call	LCD_Setup
	goto	$	; Sit in infinite loop
    
	end	rst
