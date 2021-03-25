#include <xc.inc>

extrn   LCD_Set_Position, LCD_Write_Character, LCD_Write_Low_Nibble, LCD_delay_ms
global  Display_ALARM, Display_Snooze, Display_error, Display_zeros, Display_no_alarm, Display_New, Write_colon
global  ADC_Setup, ADC_Read   

psect	adc_code, class=CODE
    
ADC_Setup:
	bsf	TRISA, 4, A;PORTA_RA0_POSN, A  ; pin RA0==AN0 input
	bsf	ANSEL3	    ; set AN0 to analog
	movlw   00001101B   ; select AN0 for measurement
	movwf   ADCON0, A   ; and turn ADC on
	movlw   0x30	    ; Select 4.096V positive reference
	movwf   ADCON1,	A   ; 0V for -ve reference and -ve input
	movlw   0xF6	    ; Right justified output
	movwf   ADCON2, A   ; Fosc/64 clock and acquisition times
	return

ADC_Read:
	bsf	GO	    ; Start conversion by setting GO bit in ADCON0
adc_loop:
	btfsc   GO	    ; check to see if finished
	bra	adc_loop
	return

Display_ALARM:				    ;write the words 'time:' before displaying the time
	;call delay
	movlw	11000000B
	call	LCD_Set_Position	    ;set position in LCD to first line, first character
	movlw	0x41
	call	LCD_Write_Character	;write 'A'
	movlw	0x4C
	call	LCD_Write_Character	;write 'L'
	movlw	0x41
	call	LCD_Write_Character	;write 'A'
	movlw	0x52
	call	LCD_Write_Character	;write 'R'
	movlw   0x4D
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
	
 Display_Snooze:				    ;write the words 'time:' before displaying the time
	movlw	11000000B
	call	LCD_Set_Position	    ;set position in LCD to first line, first character
	movlw	0x53
	call	LCD_Write_Character	;write 'S'
	movlw	0x6E
	call	LCD_Write_Character	;write 'n'
	movlw	0x6F
	call	LCD_Write_Character	;write 'o'
	movlw	0x6F
	call	LCD_Write_Character	;write 'o'
	movlw   0x7A
	call    LCD_Write_Character	;write 'z'
	movlw   0x65
	call    LCD_Write_Character	;write 'e'
	
	call	Write_space
	call	Write_space
	call	Write_space
	call	Write_space
	call	Write_space
	
	call delay	
	return	   

Display_error:
	
	movlw	0x45
	call	LCD_Write_Character	;write 'E'
	movlw	0x72
	call	LCD_Write_Character	;write 'r'
	movlw	0x72
	call	LCD_Write_Character	;write 'r'
	movlw	0x6F
	call	LCD_Write_Character	;write 'o'
	movlw	0x72
	call	LCD_Write_Character	;write 'r'  
	
	return
	
Display_zeros:
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
	
Display_no_alarm:
	call delay
	;movlw	11000110B
	;call	LCD_Set_Position	    ;set position in LCD to first line, first character
	movlw   0x4E
	call    LCD_Write_Character	;write 'N'
	movlw   0x6F
	call    LCD_Write_Character	;write 'o'
	call	Write_space
	movlw	0x41
	call	LCD_Write_Character	;write 'A'
	movlw	0x6C
	call	LCD_Write_Character	;write 'l'
	movlw	0x61
	call	LCD_Write_Character	;write 'a'
	movlw	0x72
	call	LCD_Write_Character	;write 'r'
	movlw   0x6D
	call    LCD_Write_Character	;write 'm'
	call	Write_space
	return	

Display_New:
	movlw	0x4E		    ;character 'N'
	call	LCD_Write_Character
	movlw	0x65		    ;character 'e'
	call	LCD_Write_Character
	movlw	0x77		    ;character 'w'
	call	LCD_Write_Character
	call	Write_colon
	call	Write_space
	return

Write_colon:
	movlw	0x3A		    ;character ':'
	call	LCD_Write_Character
	return
	
Write_space:
	movlw   0x20
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
	
end


