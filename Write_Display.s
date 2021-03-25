#include <xc.inc>

extrn	LCD_Write_Character, LCD_Set_Position, LCD_Line1, LCD_Line2, LCD_Write_Low_Nibble, LCD_delay_ms
    
global  Write_ALARM, Write_Snooze, Write_Error, Write_no_alarm, Write_New, Write_Time, Write_Temp, Write_Alarm
global	Write_colon, Write_space,delay, Write_zeros
    
psect	Write_Display_code, class=CODE 


Write_ALARM:				    ;write the words 'time:' before displaying the time
	;call delay
	call	LCD_Line1
	movlw	'A'
	call	LCD_Write_Character	;write 'A'
	movlw	'L'
	call	LCD_Write_Character	;write 'L'
	movlw	'A'
	call	LCD_Write_Character	;write 'A'
	movlw	'R'
	call	LCD_Write_Character	;write 'R'
	movlw   'M'
	call    LCD_Write_Character	;write 'M'
	
	call	Write_space
	call	Write_space
	call	Write_space
	call	Write_space
	call	Write_space
	call	Write_space
	call	Write_space
	call	Write_space
	call	Write_space
	return	
	
 Write_Snooze:				    ;write the words 'time:' before displaying the time
	call LCD_Line2
	movlw	'S'
	call	LCD_Write_Character	;write 'S'
	movlw	'n'
	call	LCD_Write_Character	;write 'n'
	movlw	'o'
	call	LCD_Write_Character	;write 'o'
	movlw	'o'
	call	LCD_Write_Character	;write 'o'
	movlw   'z'
	call    LCD_Write_Character	;write 'z'
	movlw   'e'
	call    LCD_Write_Character	;write 'e'
	
	call	Write_space
	call	Write_space
	call	Write_space
	call	Write_space
	call	Write_space
	
	call delay	
	return	   

Write_error:
	
	movlw	'E'
	call	LCD_Write_Character	;write 'E'
	movlw	'r'
	call	LCD_Write_Character	;write 'r'
	movlw	'r'
	call	LCD_Write_Character	;write 'r'
	movlw	'o'
	call	LCD_Write_Character	;write 'o'
	movlw	'r'
	call	LCD_Write_Character	;write 'r'  
	
	return
	
Write_Error:
	
	movlw	'E'
	call	LCD_Write_Character	;write 'E'
	movlw	'r'
	call	LCD_Write_Character	;write 'r'
	movlw	'r'
	call	LCD_Write_Character	;write 'r'
	movlw	'o'
	call	LCD_Write_Character	;write 'o'
	movlw	'r'
	call	LCD_Write_Character	;write 'r'  
	call delay
	return
	
Write_Time:
	
	movlw	'T'
	call	LCD_Write_Character	;write 'T'
	movlw	'i'
	call	LCD_Write_Character	;write 'i'
	movlw	'm'
	call	LCD_Write_Character	;write 'm'
	movlw	'e'
	call	LCD_Write_Character	;write 'e'
	    
	call	Write_colon		;write ':'
	
	return
	
Write_Temp:
	movlw	'T'
	call	LCD_Write_Character	;write 'T'
	movlw	'e'
	call	LCD_Write_Character	;write 'e'
	movlw	'm'
	call	LCD_Write_Character	;write 'm'
	movlw	'p'
	call	LCD_Write_Character	;write 'p'
	    
	call	Write_colon		;write ':'
	
	return
	
Write_Alarm:
	movlw	'A'
	call	LCD_Write_Character	;write 'A'
	movlw	'l'
	call	LCD_Write_Character	;write 'l'
	movlw	'a'
	call	LCD_Write_Character	;write 'a'
	movlw	'r'
	call	LCD_Write_Character	;write 'r'
	movlw   'm'
	call    LCD_Write_Character	;write 'm'
	
	call	Write_colon		;write ':'
	
	return
	
Write_zeros:
	movlw	0x0
	call	LCD_Write_Low_Nibble
	movlw	0x0
	call	LCD_Write_Low_Nibble
	call	Write_colon 
	movlw	0x0
	call	LCD_Write_Low_Nibble
	movlw	0x0
	call	LCD_Write_Low_Nibble
	call	Write_colon
	movlw	0x0
	call	LCD_Write_Low_Nibble
	movlw	0x0
	call	LCD_Write_Low_Nibble
	return
	
Write_no_alarm:
	call delay
	;movlw	11000110B
	;call	LCD_Set_Position	    ;set position in LCD to first line, first character
	movlw   'N'
	call    LCD_Write_Character	;write 'N'
	movlw   'o'
	call    LCD_Write_Character	;write 'o'
	call	Write_space
	movlw	'A'
	call	LCD_Write_Character	;write 'A'
	movlw	'l'
	call	LCD_Write_Character	;write 'l'
	movlw	'a'
	call	LCD_Write_Character	;write 'a'
	movlw	'r'
	call	LCD_Write_Character	;write 'r'
	movlw   'm'
	call    LCD_Write_Character	;write 'm'
	call	Write_space
	return	

Write_New:
	movlw	'N'		    ;character 'N'
	call	LCD_Write_Character
	movlw	'e'		    ;character 'e'
	call	LCD_Write_Character
	movlw	'w'		    ;character 'w'
	call	LCD_Write_Character
	call	Write_colon
	call	Write_space
	return

Write_colon:
	movlw	':'		    ;character ':'
	call	LCD_Write_Character
	return
	
Write_space:
	movlw   ' '
	call    LCD_Write_Character	;write ' '
	return

	
delay:	
	movlw	0x64
	call	LCD_delay_ms
	movlw	0x64
	call	LCD_delay_ms
	movlw	0x64
	call	LCD_delay_ms
	movlw	0x64
	call	LCD_delay_ms
	return


