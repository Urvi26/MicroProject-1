#include <xc.inc>

extrn	Clock_Setup, Clock, LCD_Setup, LCD_Write_Character, LCD_Clear, LCD_Set_Position, Keypad, operation
extrn  UART_Setup, UART_Transmit_Message

psect	code, abs
	
main:	org	0x0	; reset vector
	goto	start
	;org	0x100

int_hi:	org	0x0008	; high vector, no low vector
	goto	Clock
	
start:
	call	UART_Setup
	call	LCD_Setup
	call	Clock_Setup
	
settings_clock:
	call	Keypad
	movlw	0x0f
	CPFSEQ	keypad_val, A
	goto	settings_clock
	call	operation
	goto	settings_clock	; Sit in infinite loop
    
	end	main
