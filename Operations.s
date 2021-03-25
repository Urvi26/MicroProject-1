#include <xc.inc>
	
extrn	Write_Decimal_to_LCD
extrn	LCD_Clear, LCD_Write_Character, LCD_Write_Hex, operation_check
extrn	LCD_Write_Time, LCD_Write_Temp, LCD_Write_Alarm
extrn	LCD_Send_Byte_I, LCD_Send_Byte_D, LCD_Set_Position
extrn	LCD_Write_Low_Nibble, LCD_Write_High_Nibble, LCD_delay_x4us, LCD_delay_ms
extrn	Keypad, keypad_val, keypad_ascii
extrn	rewrite_clock
extrn	clock_sec, clock_min, clock_hrs  
extrn	hex_A, hex_B, hex_C, hex_D, hex_E, hex_F, hex_null

    
extrn	alarm_hrs, alarm_min, alarm_sec, Display_Alarm_Time, alarm, alarm_on    
    
global	temporary_hrs, temporary_min, temporary_sec
    
global	Clock, Clock_Setup, operation
    
psect	udata_acs
check_60:	ds  1	;reserving byte to store decimal 60 in hex
check_24:	ds  1	;reserving byte to store decimal 24 in hex
    
set_time_hrs1: ds 1
set_time_hrs2: ds 1  
set_time_min1: ds 1
set_time_min2: ds 1
set_time_sec1: ds 1
set_time_sec2: ds 1
    
temporary_hrs: ds 1
temporary_min: ds 1
temporary_sec: ds 1

timer_start_value_1: ds 1
timer_start_value_2: ds 1
    
skip_byte:	ds 1

    
	
    
psect	Operations_code, class=CODE


operation:
	bsf	operation_check, 0, A
	call	delay
check_keypad:
	call	Keypad
	movf	keypad_val, W, A
	CPFSEQ	hex_null, A	
	bra	check_alarm
	bra	check_keypad ;might get stuck
check_alarm:	
	CPFSEQ	hex_A, A
	bra check_set_time
	bra set_alarm
check_set_time:
	CPFSEQ	hex_B, A
	bra check_cancel
	bra set_time
check_cancel:
	CPFSEQ	hex_C, A
	bra	check_keypad
	return

set_alarm:
	;call LCD_Clear
	movlw	00001111B
	call    LCD_Send_Byte_I
	
	movlw	11000000B	    ;set cursor to first line
	call	LCD_Set_Position
	
	call	Display_Set_Alarm
	
	movlw	11000000B	    ;set cursor to first line
	call	LCD_Set_Position
	
	movlw	0x4E		    ;character 'N'
	call	LCD_Write_Character
	movlw	0x65		    ;character 'e'
	call	LCD_Write_Character
	movlw	0x77		    ;character 'w'
	call	LCD_Write_Character

	movlw	0x3A		    ;character ':'
	call	LCD_Write_Character
	movlw	0x20		    ;character ' '
	call	LCD_Write_Character
	
	;call	LCD_Write_Alarm	    ;write 'Time: ' to LCD
	
	bsf	alarm, 0, A
	
	bra set_time_clear	
	
set_time: 
	movlw	00001111B
	call    LCD_Send_Byte_I
    
	movlw	10000000B	    ;set cursor to first line
	call	LCD_Set_Position
	
	call	Display_Set_Time
	
	movlw	10000000B	    ;set cursor to first line
	call	LCD_Set_Position
	
	call	LCD_Write_Time	    ;write 'Time: ' to LCD
	
	bcf	alarm, 0, A
	
set_time_clear:	
	clrf	set_time_hrs1, A
	clrf	set_time_hrs2, A
	clrf	set_time_min1, A
	clrf	set_time_min2, A
	clrf	set_time_sec1, A
	clrf	set_time_sec2, A
	
	clrf	temporary_hrs, A
	clrf	temporary_min, A
	clrf	temporary_sec, A
	
	bcf	skip_byte,  0, A	    ;set skip byte to zero to be used to skip lines later
	
set_time1:	
	call input_check	
	
	CPFSEQ	hex_C, A
	btfsc	skip_byte, 0, A
	bra	cancel
	CPFSEQ	hex_D, A
	btfsc	skip_byte, 0, A
	bra	delete
	CPFSEQ	hex_E, A
	btfsc	skip_byte, 0, A
	bra	enter_time
	
	movff	keypad_val, set_time_hrs1
	
	call	Write_keypad_val
	call delay
set_time2:
	call input_check	  

	CPFSEQ	hex_C, A
	btfsc	skip_byte, 0, A
	bra	cancel
	CPFSEQ	hex_D, A
	btfsc	skip_byte, 0, A
	bra	delete
	CPFSEQ	hex_E, A
	btfsc	skip_byte, 0, A
	bra	enter_time
	
	movff	keypad_val, set_time_hrs2
	
	call Write_keypad_val
	movlw	0x3A		    ;write ':' to LCD
	call	LCD_Write_Character 
	call delay
set_time3:
	call input_check	  
	
	CPFSEQ	hex_C, A
	btfsc	skip_byte, 0, A
	bra	cancel
	CPFSEQ	hex_D, A
	btfsc	skip_byte, 0, A
	bra	delete
	CPFSEQ	hex_E, A
	btfsc	skip_byte, 0, A
	bra	enter_time
	
	movff	keypad_val, set_time_min1
	
	call Write_keypad_val
	call delay
set_time4:
	call input_check	  
	
	CPFSEQ	hex_C, A
	btfsc	skip_byte, 0, A
	bra	cancel
	CPFSEQ	hex_D, A
	btfsc	skip_byte, 0, A
	bra	delete
	CPFSEQ	hex_E, A
	btfsc	skip_byte, 0, A
	bra	enter_time
	
	movff	keypad_val, set_time_min2
	
	call	Write_keypad_val
	movlw	0x3A		    ;write ':' to LCD
	call	LCD_Write_Character 
	call delay
set_time5:
	call input_check	  
	
	CPFSEQ	hex_C, A
	btfsc	skip_byte, 0, A
	bra	cancel
	CPFSEQ	hex_D, A
	btfsc	skip_byte, 0, A
	bra	delete
	CPFSEQ	hex_E, A
	btfsc	skip_byte, 0, A
	bra	enter_time
	
	movff	keypad_val, set_time_sec1
	
	call Write_keypad_val
	call delay
set_time6:
	call input_check	  
	
	CPFSEQ	hex_C, A
	btfsc	skip_byte, 0, A
	bra	cancel
	CPFSEQ	hex_D, A
	btfsc	skip_byte, 0, A
	bra	delete
	CPFSEQ	hex_E, A
	btfsc	skip_byte, 0, A
	bra	enter_time
	
	movff	keypad_val, set_time_sec2
	
	call Write_keypad_val
	call delay

check_enter:
	call input_check
	
	CPFSEQ	hex_C, A
	btfsc	skip_byte, 0, A
	bra	cancel
	CPFSEQ	hex_D, A
	btfsc	skip_byte, 0, A
	bra	delete
	CPFSEQ	hex_E, A
	btfsc	skip_byte, 0, A
	bra	enter_time
	bra	check_enter
	
enter_time:
	call input_sort
	
	;call LCD_Clear
	
	movlw	00001100B
	call    LCD_Send_Byte_I
	
	bcf	operation_check, 0, A
	bcf	alarm, 0, A
	
	call	LCD_Clear
	
	return
	
cancel:
	
	movlw	00001100B
	call    LCD_Send_Byte_I
	
	bcf	operation_check, 0, A
	bcf	alarm, 0, A
	
	call LCD_Clear
	
	return
	
delete:
	btfss	alarm, 0, A
	bra	cancel
	bcf	alarm_on, 0, A
	bra	cancel
  
input_check:
	call Keypad
	movf	keypad_val, W, A
	CPFSEQ	hex_null, A
	bra keypad_input_A
	bra input_check
keypad_input_A:
	CPFSEQ	hex_A, A
	bra keypad_input_B
	bra input_check
keypad_input_B:
	CPFSEQ	hex_B, A
	bra keypad_input_F;bra keypad_input_D
	bra input_check
;keypad_input_D:
;	CPFSEQ	hex_D
;	bra keypad_input_F
;	bra input_check
keypad_input_F:
	CPFSEQ	hex_F, A
	return
	bra input_check
	
	
Display_Set_Time:
    	movlw	10000000B	    ;set cursor to first line
	call	LCD_Set_Position
	call	LCD_Write_Time	    ;write 'Time: ' to LCD
	call	Display_zeros
	movlw	11000000B	    ;set cursor to first line
	call	LCD_Set_Position
	call	LCD_Write_Temp	    ;write 'Temp: ' to LCD
				    ;Here will write temperature to LCD
	return
	
Display_Set_Alarm:
	;call	LCD_Clear
    
    	movlw	10000000B	    ;set cursor to first line
	call	LCD_Set_Position
	
	call	LCD_Write_Alarm	    ;write 'Alarm: ' to LCD
	
	;call	Display_zeros
	btfss	alarm_on,0, A
	call	write_no_alarm
	btfss	skip_byte,0, A
	call	Display_Alarm_Time
	
	movlw	11000000B	    ;set cursor to first line
	call	LCD_Set_Position
	
	movlw	0x4E		    ;character 'N'
	call	LCD_Write_Character
	movlw	0x65		    ;character 'e'
	call	LCD_Write_Character
	movlw	0x77		    ;character 'w'
	call	LCD_Write_Character
	
	movlw	0x3A		    ;character ':'
	call	LCD_Write_Character
	movlw	0x20		    ;character ' '
	call	LCD_Write_Character
	
	;call	LCD_Write_Alarm	    ;write 'Time: ' to LCD
	call	Display_zeros
	;movlw	11000000B	    ;set cursor to first line
	;call	LCD_Set_Position
	;call	LCD_Write_Temp	    ;write 'Temp: ' to LCD
				    ;Here will write temperature to LCD
	return
	
Display_zeros:
	movlw	0x0
	call	LCD_Write_Low_Nibble
	movlw	0x0
	call	LCD_Write_Low_Nibble
	movlw	0x3A		    ;write ':' to LCD
	call	LCD_Write_Character 
	movlw	0x0
	call	LCD_Write_Low_Nibble
	movlw	0x0
	call	LCD_Write_Low_Nibble
	movlw	0x3A		    ;write ':' to LCD
	call	LCD_Write_Character
	movlw	0x0
	call	LCD_Write_Low_Nibble
	movlw	0x0
	call	LCD_Write_Low_Nibble
	return
	
write_no_alarm:
	call delay
	;movlw	11000110B
	;call	LCD_Set_Position	    ;set position in LCD to first line, first character
	movlw   0x4E
	call    LCD_Write_Character	;write 'N'
	movlw   0x6F
	call    LCD_Write_Character	;write 'o'
	movlw   0x20
	call    LCD_Write_Character	;write ' '
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
	movlw   0x20
	call    LCD_Write_Character	;write ' '
	return	
	
Write_keypad_val:
	;movf	keypad_ascii, W
	;call	LCD_Write_Character
	movf	keypad_val, A
	call	LCD_Write_Low_Nibble
	return
    
input_sort:
	movlw	0x3C		;setting hex values for decimal 24 and 60 for comparison
	movwf	check_60, A
	movlw	0x18
	movwf	check_24, A
	
	movf	set_time_hrs1, W, A
	mullw	0x0A
	movf	PRODL, W, A
	addwf	set_time_hrs2, 0, 0
	CPFSGT	check_24, A
	bra	output_error
	movwf	temporary_hrs, A
	
	movf	set_time_min1, W, A
	mullw	0x0A
	movf	PRODL, W, A
	addwf	set_time_min2, 0, 0
	CPFSGT	check_60, A
	bra	output_error
	movwf	temporary_min, A
	
	movf	set_time_sec1, W, A
	mullw	0x0A
	movf	PRODL, W, A
	addwf	set_time_sec2, 0, 0
	CPFSGT	check_60, A
	bra	output_error
	movwf	temporary_sec, A
	
	btfss	alarm, 0, A
	bra	input_into_clock
	bra	input_into_alarm
	
input_into_clock:
	movff	temporary_hrs, clock_hrs
	movff	temporary_min, clock_min
	movff	temporary_sec, clock_sec
	;call	rewrite_clock		
	return

input_into_alarm:
	movff	temporary_hrs, alarm_hrs
	movff	temporary_min, alarm_min
	movff	temporary_sec, alarm_sec
	
	bsf	alarm_on, 0, A
	;call	rewrite_clock
	return
	
	
	
output_error:
	movlw	00001100B
	call    LCD_Send_Byte_I ;turn off cursor and blinking

	call	LCD_Clear
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
	movlw	0x64
	call	delay
	call	delay
	call	delay
	bra	    cancel
    
    
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


