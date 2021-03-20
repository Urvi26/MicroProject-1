#include <xc.inc>

extrn	clock_setup, clock
extrn	operation, delay
extrn	LCD_Setup , LCD_Send_Byte_I, LCD_Clear
extrn	Keypad, keypad_val

global  operation_check
	
psect	udata_acs   
operation_check:	ds  1
	
psect	code, abs
	
main:	org	0x0000	; reset vector
	goto	start

int_hi:	org	0x0008	; high vector, no low vector
	goto	clock

;int_alarm: org	0x0018
;	   goto keypad_int
;	  
start:	call	LCD_Setup
	call	clock_setup
	;goto	$	; Sit in infinite loop
	
settings_clock:
	call Keypad	; check what is pressed
	
	movlw	0x0f
	CPFSEQ	keypad_val
	
	goto settings_clock	;check again if F isnt pressed
	
	bsf operation_check,0	;bit that is 1 if F is pressed
	call operation		; go to operation if F is pressed
	
	call LCD_Clear
	bcf operation_check,0	;clear operation_check
	goto settings_clock 

	end	main

