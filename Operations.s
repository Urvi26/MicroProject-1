#include <xc.inc>
	
extrn	Write_Decimal_to_LCD
extrn	LCD_Clear, LCD_Write_Character, LCD_Write_Hex
extrn	LCD_Write_Time, LCD_Write_Temp, LCD_Write_Alarm
extrn	LCD_Send_Byte_I, LCD_Send_Byte_D, LCD_Set_Position
extrn	LCD_Write_Low_Nibble, LCD_Write_High_Nibble, LCD_delay_x4us, LCD_delay_ms
extrn	Keypad, keypad_val, keypad_ascii
extrn	rewrite_clock
extrn	operation_check
extrn	clock_sec, clock_min, clock_hrs  
extrn	hex_A, hex_B, hex_C, hex_D, hex_E, hex_F, hex_null, check_60, check_24
extrn	alarm_hrs, alarm_min, alarm_sec, Display_Alarm_Time, alarm, alarm_on    
    
global	temporary_hrs, temporary_min, temporary_sec
global	Clock, Clock_Setup, operation
    
psect	udata_acs
;check_60:	ds  1	;reserving byte to store decimal 60 in hex
;check_24:	ds  1	;reserving byte to store decimal 24 in hex
    
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
	bsf	operation_check, 0  ;if operation is pressed, then use this bit to make sure clock isnt displayed while settings are used
	call	delay
check_keypad:
	call	Keypad
	movf	keypad_val, W
	CPFSEQ	hex_null	
	bra	check_alarm
	bra	check_keypad 
check_alarm:	
	CPFSEQ	hex_A
	bra check_set_time
	bra set_alarm
check_set_time:
	CPFSEQ	hex_B
	bra check_cancel
	bra set_time
check_cancel:
	CPFSEQ	hex_C
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

	bsf	alarm, 0	    ;if we are setting alarm then set alarm,0
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
	
	bcf	alarm, 0	;if we are setting the time then clear alarm,0
	
set_time_clear:	
	movlw	0x0		;move 0x00 to following bytes 
	movwf	set_time_hrs1
	movwf	set_time_hrs2
	movwf	set_time_min1
	movwf	set_time_min2
	movwf	set_time_sec1
	movwf	set_time_sec2
	
	movwf	temporary_hrs
	movwf	temporary_min
	movwf	temporary_sec
	
	bcf	skip_byte,  0	    ;set skip byte to zero to be used to skip lines later
set_time1:	
	call input_check	;checks what is input and returns with a number, E, D or C
	
	CPFSEQ	hex_C
	btfsc	skip_byte, 0
	bra	cancel		;if C is pressed then cancel
	CPFSEQ	hex_D
	btfsc	skip_byte, 0
	bra	delete		;if D is pressed then go to delete
	CPFSEQ	hex_E
	btfsc	skip_byte, 0
	bra	enter_time	;if E is pressed then go to enter time
	
	movff	keypad_val, set_time_hrs1   ;move whatever is pressed on keypad to set_time_hrs1
	
	call	Write_keypad_val	    ;write this value onto the LCD temporarily
	call delay
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
	
	movff	keypad_val, set_time_hrs2
	
	call Write_keypad_val
	movlw	0x3A		    ;write ':' to LCD
	call	LCD_Write_Character 
	call delay
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
	
	movff	keypad_val, set_time_min1
	
	call Write_keypad_val
	call delay
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
	
	movff	keypad_val, set_time_min2
	
	call	Write_keypad_val
	movlw	0x3A		    ;write ':' to LCD
	call	LCD_Write_Character 
	call delay
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
	
	movff	keypad_val, set_time_sec1
	
	call Write_keypad_val
	call delay
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
	
	movff	keypad_val, set_time_sec2
	
	call Write_keypad_val
	call delay

check_enter:
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
	bra	check_enter
	
enter_time:
	call input_sort		;call input_sort to convert entered values to meaningful numbers to output and check against 60 or 24
	
	;call LCD_Clear
	
	movlw	00001100B
	call    LCD_Send_Byte_I	;set cursor off
	
	bcf	operation_check, 0
	bcf	alarm, 0
	
	call	LCD_Clear
	
	return
cancel:
	
	movlw	00001100B	;set cursor off
	call    LCD_Send_Byte_I
	
	bcf	operation_check, 0
	bcf	alarm, 0
		
	call LCD_Clear
	
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
	bra keypad_input_F;bra keypad_input_D
	bra input_check
;keypad_input_D:
;	CPFSEQ	hex_D
;	bra keypad_input_F
;	bra input_check
keypad_input_F:
	CPFSEQ	hex_F
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
	btfss	alarm_on,0
	call	write_no_alarm
	btfss	skip_byte,0
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
	movf	keypad_val
	call	LCD_Write_Low_Nibble
	return
    
input_sort:
	movlw	0x3C		;setting hex values for decimal 24 and 60 for comparison
	movwf	check_60
	movlw	0x18
	movwf	check_24
	
	movf	set_time_hrs1, W	
	mullw	0x0A		    ;multiply first dig entered to 0x0A
	movf	PRODL, W
	addwf	set_time_hrs2, 0    ;add to second dig to get hours
	CPFSGT	check_24	    ;check that 24 is greater than hours	
	bra	output_error	    ;ouput error if not
	movwf	temporary_hrs	    ;move value to temporary_hrs if it is
	
	movf	set_time_min1, W
	mullw	0x0A		    ;multiply first dig of minutes entered to 0x0A
	movf	PRODL, W	
	addwf	set_time_min2, 0    ;add that value to second digit
	CPFSGT	check_60	    ;check if 60 is greater than the minutes
	bra	output_error	    ;output error if not
	movwf	temporary_min	    ;move value to temporary_min if it is
	
	movf	set_time_sec1, W
	mullw	0x0A		    ;multiply first digit of seconds entered to 0x0A
	movf	PRODL, W
	addwf	set_time_sec2, 0    ;add that value to second digit
	CPFSGT	check_60	;check if 60 is greater than the seconds
	bra	output_error	;output error if not
	movwf	temporary_sec	;move value to temporary_sec if it is
	
	btfss	alarm, 0	    ;check if bit alarm,0 is set
	bra	input_into_clock    ;input temporary_hrs,_sec and _min into clock if bit is not set
	bra	input_into_alarm    ;input into alarm if set
	
input_into_clock:			    ;input temporary_hrs, temporary_sec, temporary_min into clock
	movff	temporary_hrs, clock_hrs
	movff	temporary_min, clock_min
	movff	temporary_sec, clock_sec
	;call	rewrite_clock		
	return

input_into_alarm:			    ;input temporary_hrs, temporary_sec, temporary_min into clock
	movff	temporary_hrs, alarm_hrs
	movff	temporary_min, alarm_min
	movff	temporary_sec, alarm_sec
	
	bsf	alarm_on, 0		    ;turn alarm on by setting alarm_on,0
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


