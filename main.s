#include <xc.inc>

extrn	Clock_Setup, Clock, LCD_Setup
extrn  UART_Setup, UART_Transmit_Message

psect	code, abs
	
rst:	org	0x0	; reset vector
	goto	start
	org	0x100

;int_hi:	org	0x0008	; high vector, no low vector
;	goto	Clock
	
start:	movlw	0x00
	movwf	TRISJ
	movlw	0xff
	movwf	LATJ, A
	call	UART_Setup
	call	LCD_Setup
	
	call	Clock_Setup
	;goto	$	; Sit in infinite loop
    
	end	rst
