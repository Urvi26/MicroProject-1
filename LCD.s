#include <xc.inc>

global  LCD_Setup, LCD_Write_Hex, LCD_Set_Position, LCD_Send_Byte_D, LCD_Send_Byte_I
global	LCD_Write_Character, LCD_Write_Low_Nibble, LCD_Clear, LCD_Write_High_Nibble
global	LCD_delay_ms, LCD_delay_x4us, delay
global  Write_ALARM, Write_Snooze, Write_Error, Write_zeros, Write_no_alarm, Write_New, Write_colon, Write_space, Write_Time, Write_Temp, Write_Alarm
global	LCD_cursor_on, LCD_cursor_off, LCD_Line1, LCD_Line2
    
psect	udata_acs   ; named variables in access ram
LCD_cnt_l:	ds 1	; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h:	ds 1	; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms:	ds 1	; reserve 1 byte for ms counter
LCD_tmp:	ds 1	; reserve 1 byte for temporary use
LCD_counter:	ds 1	; reserve 1 byte for counting through nessage
counter_Time:	ds  1
counter_Temp:	ds  1
counter_Alarm:	ds  1
    
psect	udata_bank4
myArrayTime:    ds 0x80
myArrayTemp:    ds 0x80
    
psect	udata_bank5
myArrayAlarm:    ds 0x80

PSECT	udata_acs_ovr,space=1,ovrld,class=COMRAM
LCD_hex_tmp:	ds 1    ; reserve 1 byte for variable LCD_hex_tmp

	LCD_E	EQU 5	; LCD enable bit
    	LCD_RS	EQU 4	; LCD register select bit

psect	lcd_code,class=CODE
LCD_Clear: 
	movlw   40
	call	LCD_delay_ms
	movlw	00000001B	; display clear
	call	LCD_Send_Byte_I
	movlw	2		; wait 2ms
	call	LCD_delay_ms
	return	
	   
LCD_Setup:
	clrf    LATB, A
	movlw   11000000B	    ; RB0:5 all outputs
	movwf	TRISB, A
	movlw   40
	call	LCD_delay_ms	; wait 40ms for LCD to start up properly
	movlw	00110000B	; Function set 4-bit
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00101000B	; 2 line display 5x8 dot characters
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00101000B	; repeat, 2 line display 5x8 dot characters
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00001100B	; display on, cursor off, blinking ofF
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	movlw	00000001B	; display clear
	call	LCD_Send_Byte_I
	movlw	2		; wait 2ms
	call	LCD_delay_ms
	movlw	00000110B	; entry mode incr by 1 no shift
	call	LCD_Send_Byte_I
	movlw	10		; wait 40us
	call	LCD_delay_x4us
	return

LCD_cursor_off:
	movlw	00001100B
	call    LCD_Send_Byte_I	;set cursor off
	return
	
LCD_cursor_on:
	movlw	00001111B
	call    LCD_Send_Byte_I	;set cursor on
	return
	
LCD_Line1:
    movlw   10000000B
    call    LCD_Set_Position	;set cursor on
    return
    
LCD_Line2:
    movlw   11000000B
    call    LCD_Set_Position	;set cursor on
    return
	
LCD_Write_Character:	;send ascii code to LCD to display character
	call	LCD_Send_Byte_D
	movlw	10	    ; delay 40us
	call	LCD_delay_x4us
	return	
	
LCD_Set_Position:	;set position at which inputs will be displayed  
	call    LCD_Send_Byte_I
	movlw   10		; wait 40us
	call    LCD_delay_x4us
	return
	
LCD_Write_Hex:			; Writes byte stored in W as hex
	movwf	LCD_hex_tmp, A
	swapf	LCD_hex_tmp, W, A	; high nibble first
	call	LCD_Hex_Nib
	movf	LCD_hex_tmp, W, A	; then low nibble
LCD_Hex_Nib:			; writes low nibble as hex character
	andlw	0x0F
	movwf	LCD_tmp, A
	movlw	0x0A
	cpfslt	LCD_tmp, A
	addlw	0x07		; number is greater than 9 
	addlw	0x26
	addwf	LCD_tmp, W, A
	call	LCD_Send_Byte_D ; write out ascii
	return	

LCD_Write_Low_Nibble:
	movwf	LCD_hex_tmp, A
	swapf	LCD_hex_tmp, W, A	; high nibble first
	movf	LCD_hex_tmp, W, A	; then low nibble
	call	LCD_Hex_Nib
	return
	
LCD_Write_High_Nibble:
	movwf	LCD_hex_tmp, A
	swapf	LCD_hex_tmp, W, A	; high nibble first
	call	LCD_Hex_Nib
	return
	
	
LCD_Write_Message:	    ; Message stored at FSR2, length stored in W
	movwf   LCD_counter, A
LCD_Loop_message:
	movf    POSTINC2, W, A
	call    LCD_Send_Byte_D
	decfsz  LCD_counter, A
	bra	LCD_Loop_message
	return

LCD_Send_Byte_I:	    ; Transmits byte stored in W to instruction reg
	movwf   LCD_tmp, A
	swapf   LCD_tmp, W, A   ; swap nibbles, high nibble goes first
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bcf	LATB, LCD_RS, A	; Instruction write clear RS bit
	call    LCD_Enable  ; Pulse enable Bit 
	movf	LCD_tmp, W, A   ; swap nibbles, now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bcf	LATB, LCD_RS, A	; Instruction write clear RS bit
        call    LCD_Enable  ; Pulse enable Bit 
	return

LCD_Send_Byte_D:	    ; Transmits byte stored in W to data reg
	movwf   LCD_tmp, A
	swapf   LCD_tmp, W, A	; swap nibbles, high nibble goes first
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bsf	LATB, LCD_RS, A	; Data write set RS bit
	call    LCD_Enable  ; Pulse enable Bit 
	movf	LCD_tmp, W, A	; swap nibbles, now do low nibble
	andlw   0x0f	    ; select just low nibble
	movwf   LATB, A	    ; output data bits to LCD
	bsf	LATB, LCD_RS, A	; Data write set RS bit	    
        call    LCD_Enable  ; Pulse enable Bit 
	movlw	10	    ; delay 40us
	call	LCD_delay_x4us
	return

LCD_Enable:	    ; pulse enable bit LCD_E for 500ns
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bsf	LATB, LCD_E, A	    ; Take enable high
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	bcf	LATB, LCD_E, A	    ; Writes data to LCD
	return
    
; ** a few delay routines below here as LCD timing can be quite critical ****
LCD_delay_ms:		    ; delay given in ms in W
	movwf	LCD_cnt_ms, A
lcdlp2:	movlw	250	    ; 1 ms delay
	call	LCD_delay_x4us	
	decfsz	LCD_cnt_ms, A
	bra	lcdlp2
	return
    
LCD_delay_x4us:		    ; delay given in chunks of 4 microsecond in W
	movwf	LCD_cnt_l, A	; now need to multiply by 16
	swapf   LCD_cnt_l, F, A	; swap nibbles
	movlw	0x0f	    
	andwf	LCD_cnt_l, W, A ; move low nibble to W
	movwf	LCD_cnt_h, A	; then to LCD_cnt_h
	movlw	0xf0	    
	andwf	LCD_cnt_l, F, A ; keep high nibble in LCD_cnt_l
	call	LCD_delay
	return

LCD_delay:			; delay routine	4 instruction loop == 250ns	    
	movlw 	0x00		; W=0
lcdlp1:	decf 	LCD_cnt_l, F, A	; no carry when 0x00 -> 0xff
	subwfb 	LCD_cnt_h, F, A	; no carry when 0x00 -> 0xff
	bc 	lcdlp1		; carry, then loop again
	return			; carry reset so return

 
Write_ALARM:				    ;write the words 'time:' before displaying the time
	;call delay
	movlw	11000000B
	call	LCD_Set_Position	    ;set position in LCD to first line, first character
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
	movlw	11000000B
	call	LCD_Set_Position	    ;set position in LCD to first line, first character
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
	
	
end


