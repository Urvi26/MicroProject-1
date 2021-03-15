#include <xc.inc>

extrn	Clock_Setup, Clock, LCD_Setup, LCD_Write_Character, LCD_Clear, LCD_Set_Position
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
	
	;movlw	0x35
	;call	LCD_Write_Character
	;movlw	11000000B
	;call	LCD_Set_Position
	;movlw	0x35
	;call	LCD_Write_Character
	call	Clock_Setup
	goto	$	; Sit in infinite loop
    
	end	main
