#include <xc.inc>
	
extrn	Write_Decimal_to_LCD, operation_check
extrn	LCD_Write_Character, LCD_Set_Position, LCD_Send_Byte_I, LCD_Clear, LCD_delay_ms
extrn	Keypad, keypad_val, keypad_ascii
extrn	check_60, check_24, alarm_sec, alarm_min, alarm_hrs, clock_sec, clock_min, clock_hrs, delay, rewrite_clock
    
global	operation, write_alarm, write_time, alarm_on
    
psect	udata_acs   
alarm:		ds 1
alarm_on:	ds 1
skip_byte:	ds 1
    
hex_A: ds 1
hex_B: ds 1
hex_C: ds 1
hex_D: ds 1
hex_E: ds 1
hex_F: ds 1
hex_null: ds 1

set_time_hrs1: ds 1
set_time_hrs2: ds 1    
set_time_min1: ds 1
set_time_min2: ds 1
set_time_sec1: ds 1
set_time_sec2: ds 1

temporary_hrs: ds 1
temporary_min: ds 1
temporary_sec: ds 1  

psect	Clock_timer_code, class=CODE

setup:	movlw	0x0A
	movwf	hex_A
	movlw	0x0B
	movwf	hex_B
	movlw	0x0C
	movwf	hex_C
	movlw	0x0D
	movwf	hex_D
	movlw	0x0E
	movwf	hex_E
	movlw	0x0F
	movwf	hex_F
	movlw	0xff
	movwf	hex_null
	
	clrf	skip_byte
	return
    
operation:
	bsf operation_check, 0
	call delay
check_keypad:	
	call	setup
	call	Keypad
	movf	keypad_val, W
	CPFSEQ	hex_null		    ;keep checking until something is pressed
	bra	check_set_alarm 
	bra	check_keypad 
check_set_alarm:	
	CPFSEQ	hex_A
	bra	check_set_time	
	bra	set_alarm	;go to set alarm if A is pressed
check_set_time:
	CPFSEQ	hex_B
	bra	check_cancel
	bra	set_time	;go to set time if B is pressed
check_cancel:
	CPFSEQ	hex_C
	bra	check_keypad   
	return		;clear LCD and return if cancel is pressed	

set_alarm:
	movlw	00001111B
	call    LCD_Send_Byte_I
	call	delay
	
	movlw	11000000B
	call    LCD_Set_Position
	
	call	write_alarm
	call	Display_Set_Alarm
	
	movlw	11000110B
	call    LCD_Set_Position
	
	bsf	alarm, 0
	bra set_time_clear
	    
set_time: 
	movlw	00001111B
	call    LCD_Send_Byte_I
	call delay
	
	movlw	10000110B
	call    LCD_Set_Position
	
	bcf	alarm, 0
set_time_clear:
	movlw	0x00
	movwf	set_time_hrs1
	movwf	set_time_hrs2
	movwf	set_time_min1
	movwf	set_time_min2
	movwf	set_time_sec1
	movwf	set_time_sec2
set_time1:	
	call input_check
	
	CPFSEQ	hex_C
	btfsc	skip_byte, 0
	bra	cancel
	CPFSEQ	hex_D
	btfsc	skip_byte, 0
	bra	delete
	CPFSEQ	hex_E
	btfsc	skip_byte, 0
	bra	enter_time
	
	call set_time_write
	movff	keypad_val, set_time_hrs1
set_time2:
	call input_check	
	
	CPFSEQ	hex_C
	btfsc	skip_byte, 0
	bra	cancel
	CPFSEQ	hex_D
	btfsc	skip_byte, 0
	bra	delete
	CPFSEQ	hex_E
	btfsc	skip_byte, 0
	bra	enter_time
	
	call set_time_write
	
	movlw   0x3A
	call    LCD_Write_Character	;write ':'
	
	movff	keypad_val, set_time_hrs2
set_time3:
	call input_check	  
	
	CPFSEQ	hex_C
	btfsc	skip_byte, 0
	bra	cancel
	CPFSEQ	hex_D
	btfsc	skip_byte, 0
	bra	delete
	CPFSEQ	hex_E
	btfsc	skip_byte, 0
	bra	enter_time
	
	call set_time_write
	movff	keypad_val, set_time_min1
set_time4:
	call input_check	  
	
	CPFSEQ	hex_C
	btfsc	skip_byte, 0
	bra	cancel
	CPFSEQ	hex_D
	btfsc	skip_byte, 0
	bra	delete
	CPFSEQ	hex_E
	btfsc	skip_byte, 0
	bra	enter_time
	
	call set_time_write
	
	movlw   0x3A
	call    LCD_Write_Character	;write ':'
	
	movff	keypad_val, set_time_min2
set_time5:
	call input_check	  
	
	CPFSEQ	hex_C
	btfsc	skip_byte, 0
	bra	cancel
	CPFSEQ	hex_D
	btfsc	skip_byte, 0
	bra	delete
	CPFSEQ	hex_E
	btfsc	skip_byte, 0
	bra	enter_time
	
	call set_time_write
	movff	keypad_val, set_time_sec1
set_time6:
	call input_check	  
	
	CPFSEQ	hex_C
	btfsc	skip_byte, 0
	bra	cancel
	CPFSEQ	hex_D
	btfsc	skip_byte, 0
	bra	delete
	CPFSEQ	hex_E
	btfsc	skip_byte, 0
	bra	enter_time
	
	call set_time_write
	movff	keypad_val, set_time_sec2
	
	movlw	00001100B
	call    LCD_Send_Byte_I
check_enter:
	call input_check	  
	
	CPFSEQ	hex_C
	btfsc	skip_byte, 0
	bra	cancel
	CPFSEQ	hex_D
	btfsc	skip_byte, 0
	bra	delete
	CPFSEQ	hex_E
	bra	check_enter
	bra	enter_time
	
enter_time:
	call delay
	bra input_prepare
	return
	
cancel:
	call LCD_Clear
	
	movlw	00001100B
	call    LCD_Send_Byte_I
	
	bcf	operation_check, 0
	;bcf	alarm, 0
	
	return
	
delete:
	btfss	alarm, 0
	bra	cancel
	bcf	alarm_on, 0
	bra	cancel

input_check:
	call Keypad
	movf	keypad_val, W
	CPFSEQ	hex_null
	bra keypad_input_A
	bra input_check
keypad_input_A:
	CPFSEQ	hex_A
	bra keypad_input_B
	bra input_check
keypad_input_B:
	CPFSEQ	hex_B
	bra keypad_input_F
	bra input_check
;keypad_input_D:
;	CPFSEQ	hex_D
;	bra keypad_input_F
;	bra input_check
keypad_input_F:
	CPFSEQ	hex_F
	return
	bra input_check
	
Display_Set_Alarm:
	movf	alarm_hrs, W
	call Write_Decimal_to_LCD
	movlw	0x3A
	call LCD_Write_Character
	movf	alarm_min, W
	call Write_Decimal_to_LCD
	movlw	0x3A
	call LCD_Write_Character
	movf	alarm_sec, W
	call Write_Decimal_to_LCD
	return	
	
set_time_write:
	movf	keypad_ascii, W
	call	LCD_Write_Character
	return

input_prepare:
	movf	set_time_hrs1, W
	mullw	0x0A
	movf	PRODL, W
	addwf	set_time_hrs2, 0
	CPFSGT	check_24
	bra	output_error
	movwf	temporary_hrs
	
	movf	set_time_min1, W
	mullw	0x0A
	movf	PRODL, W
	addwf	set_time_min2, 0
	CPFSGT	check_60
	bra	output_error
	movwf	temporary_min
	
	movf	set_time_sec1, W
	mullw	0x0A
	movf	PRODL, W
	addwf	set_time_sec2, 0
	CPFSGT	check_60
	bra	output_error
	movwf	temporary_sec
	
	btfss	alarm, 0
	call input_into_clock
	call input_into_alarm
	
	return
	
input_into_clock:
	movff	temporary_hrs, clock_hrs
	movff	temporary_min, clock_min
	movff	temporary_sec, clock_sec
	call	rewrite_clock		
	return

input_into_alarm:
	movff	temporary_hrs, alarm_hrs
	movff	temporary_min, alarm_min
	movff	temporary_sec, alarm_sec
	call	LCD_Clear
	bsf	alarm_on, 0
	bcf	operation_check, 0
	;call	rewrite_clock
	return

output_error:
    call	LCD_Clear
    call delay
    movlw	10000000B
    call	LCD_Set_Position	    ;set position in LCD to first line, first character
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
    movlw	0xff
    call	LCD_delay_ms
    call	LCD_Clear
    return

write_time:				    ;write the words 'time:' before displaying the time
	call delay
	movlw	10000000B
	call	LCD_Set_Position	    ;set position in LCD to first line, first character
	movlw	0x54
	call	LCD_Write_Character	;write 'T'
	movlw	0x69
	call	LCD_Write_Character	;write 'i'
	movlw	0x6D
	call	LCD_Write_Character	;write 'm'
	movlw	0x65
	call	LCD_Write_Character	;write 'e'
	movlw   0x3A
	call    LCD_Write_Character	;write ':'
	return
write_alarm:				    ;write the words 'time:' before displaying the time
	call delay
	movlw	11000000B
	call	LCD_Set_Position	    ;set position in LCD to first line, first character
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
	movlw   0x3A
	call    LCD_Write_Character	;write ':'
	return	
	
end


