#include <xc.inc>
	
extrn	Write_Decimal_to_LCD
extrn	LCD_Clear, operation_check
extrn	LCD_Write_Low_Nibble, delay
    
extrn	Keypad, keypad_val

extrn	Rewrite_Clock
extrn	clock_sec, clock_min, clock_hrs  
extrn	hex_A, hex_B, hex_C, hex_D, hex_E, hex_F, hex_null
    
extrn	alarm_hrs, alarm_min, alarm_sec
extrn	alarm_on    
extrn	Write_Error, Write_no_alarm, Write_zeros, Write_Time, Write_Temp, Write_Alarm, Write_New
extrn	Write_colon, Write_space, LCD_cursor_on, LCD_cursor_off, LCD_Line1, LCD_Line2
global	temporary_hrs, temporary_min, temporary_sec
global	Clock, Clock_Setup, operation, Operation_Setup, skip_byte, check_60, check_24
    

    
    
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

    
alarm: ds 1      
    
psect	Operations_code, class=CODE

Operation_Setup:
	bcf	alarm, 0, A
	bcf	skip_byte,  0, A	    ;set skip byte to zero to be used to skip lines later
	return

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
	bra	check_set_time
	bra	set_alarm
check_set_time:
	CPFSEQ	hex_B, A
	bra	check_cancel
	bra	Set_Time
check_cancel:
	CPFSEQ	hex_C, A
	bra	check_keypad
	return

set_alarm:
	;call LCD_Clear
	call	LCD_cursor_on
	
	call	LCD_Line2
	
	call	Display_Set_Alarm
	
	call	LCD_Line2
	
	call	Write_New
	
	;call	Write_Alarm	    ;write 'Time: ' to LCD
	
	bsf	alarm, 0, A
	
	bra	Set_Time_Clear	
	
Set_Time: 
	call	LCD_cursor_on
    
	call	LCD_Line1
	
	call	Display_Time_Setup
	
	call	LCD_Line1
	
	call	Write_Time	    ;write 'Time: ' to LCD
	
	bcf	alarm, 0, A
	
Set_Time_Clear:	
	clrf	set_time_hrs1, A
	clrf	set_time_hrs2, A
	clrf	set_time_min1, A
	clrf	set_time_min2, A
	clrf	set_time_sec1, A
	clrf	set_time_sec2, A
	
	clrf	temporary_hrs, A
	clrf	temporary_min, A
	clrf	temporary_sec, A
	
	
Set_Time1:	
	call Input_Check	
	
	CPFSEQ	hex_C, A
	btfsc	skip_byte, 0, A
	bra	Cancel
	CPFSEQ	hex_D, A
	btfsc	skip_byte, 0, A
	bra	Delete
	CPFSEQ	hex_E, A
	btfsc	skip_byte, 0, A
	bra	Enter_Time
	
	movff	keypad_val, set_time_hrs1
	
	call	Write_keypad_val
	call	delay
Set_Time2:
	call	Input_Check	  

	CPFSEQ	hex_C, A
	btfsc	skip_byte, 0, A
	bra	Cancel
	CPFSEQ	hex_D, A
	btfsc	skip_byte, 0, A
	bra	Delete
	CPFSEQ	hex_E, A
	btfsc	skip_byte, 0, A
	bra	Enter_Time
	
	movff	keypad_val, set_time_hrs2
	
	call	Write_keypad_val
	call	Write_colon	    ;write ':' to LCD
	call	delay
Set_Time3:
	call	Input_Check	  
	
	CPFSEQ	hex_C, A
	btfsc	skip_byte, 0, A
	bra	Cancel
	CPFSEQ	hex_D, A
	btfsc	skip_byte, 0, A
	bra	Delete
	CPFSEQ	hex_E, A
	btfsc	skip_byte, 0, A
	bra	Enter_Time
	
	movff	keypad_val, set_time_min1
	
	call	Write_keypad_val
	call	delay
Set_Time4:
	call	Input_Check	  
	
	CPFSEQ	hex_C, A
	btfsc	skip_byte, 0, A
	bra	Cancel
	CPFSEQ	hex_D, A
	btfsc	skip_byte, 0, A
	bra	Delete
	CPFSEQ	hex_E, A
	btfsc	skip_byte, 0, A
	bra	Enter_Time
	
	movff	keypad_val, set_time_min2
	
	call	Write_keypad_val
	call	Write_colon	    ;write ':' to LCD
	call	delay
Set_Time5:
	call	Input_Check	  
	
	CPFSEQ	hex_C, A
	btfsc	skip_byte, 0, A
	bra	Cancel
	CPFSEQ	hex_D, A
	btfsc	skip_byte, 0, A
	bra	Delete
	CPFSEQ	hex_E, A
	btfsc	skip_byte, 0, A
	bra	Enter_Time
	
	movff	keypad_val, set_time_sec1
	
	call	Write_keypad_val
	call	delay
Set_Time6:
	call	Input_Check	  
	
	CPFSEQ	hex_C, A
	btfsc	skip_byte, 0, A
	bra	Cancel
	CPFSEQ	hex_D, A
	btfsc	skip_byte, 0, A
	bra	Delete
	CPFSEQ	hex_E, A
	btfsc	skip_byte, 0, A
	bra	Enter_Time
	
	movff	keypad_val, set_time_sec2
	
	call	Write_keypad_val
	call	delay

Check_Enter:
	call	Input_Check
	
	CPFSEQ	hex_C, A
	btfsc	skip_byte, 0, A
	bra	Cancel
	CPFSEQ	hex_D, A
	btfsc	skip_byte, 0, A
	bra	Delete
	CPFSEQ	hex_E, A
	btfsc	skip_byte, 0, A
	bra	Enter_Time
	bra	Check_Enter
	
Enter_Time:
	call	Input_Sort
	
	;call LCD_Clear
	
	call	LCD_cursor_off
	
	bcf	operation_check, 0, A
	bcf	alarm, 0, A
	
	call	LCD_Clear
	
	return
	
Cancel:
	
	call	LCD_cursor_off
	
	bcf	operation_check, 0, A
	bcf	alarm, 0, A
	
	call	LCD_Clear
	
	return
	
Delete:
	btfss	alarm, 0, A
	bra	Cancel
	bcf	alarm_on, 0, A
	bra	Cancel
  
Input_Check:
	call	Keypad
	movf	keypad_val, W, A
	CPFSEQ	hex_null, A
	bra	Keypad_Input_A
	bra	Input_Check
Keypad_Input_A:
	CPFSEQ	hex_A, A
	bra	Keypad_Input_B
	bra	Input_Check
Keypad_Input_B:
	CPFSEQ	hex_B, A
	bra	Keypad_Input_F;bra keypad_input_D
	bra	Input_Check
Keypad_Input_F:
	CPFSEQ	hex_F, A
	return
	bra	Input_Check
	
	
Display_Time_Setup:
    	call	LCD_Line1
	call	Write_Time	    ;write 'Time: ' to LCD
	call	Write_zeros
	call	LCD_Line2
	call	Write_Temp	    ;write 'Temp: ' to LCD
				    ;Here will write temperature to LCD
	return
	
Display_Set_Alarm:
	;call	LCD_Clear
    
    	call	LCD_Line1
	
	call	Write_Alarm	    ;write 'Alarm: ' to LCD
	
	;call	Write_zeros
	btfss	alarm_on,0, A
	call	Write_no_alarm
	btfss	skip_byte,0, A
	call	Display_Alarm_Time
	
	call	LCD_Line2
	
	call	Write_New
	
	;call	Write_Alarm	    ;write 'Time: ' to LCD
	call	Write_zeros
	;call	LCD_Line2
	;call	Write_Temp	    ;write 'Temp: ' to LCD
				    ;Here will write temperature to LCD
	return

Display_Alarm_Time:
	movf	alarm_hrs, W, A
	call Write_Decimal_to_LCD
	call	Write_colon
	movf	alarm_min, W, A
	call Write_Decimal_to_LCD
	call	Write_colon
	movf	alarm_sec, W, A
	call Write_Decimal_to_LCD
	return
	
Write_keypad_val:
	;movf	keypad_ascii, W
	;call	LCD_Write_Character
	movf	keypad_val, A
	call	LCD_Write_Low_Nibble
	return
    
Input_Sort:
	;movlw	0x3C		;setting hex values for decimal 24 and 60 for comparison
	;movwf	check_60, A
	;movlw	0x18
	;movwf	check_24, A
	
	movf	set_time_hrs1, W, A
	mullw	0x0A
	movf	PRODL, W, A
	addwf	set_time_hrs2, 0, 0
	CPFSGT	check_24, A
	bra	Output_Error
	movwf	temporary_hrs, A
	
	movf	set_time_min1, W, A
	mullw	0x0A
	movf	PRODL, W, A
	addwf	set_time_min2, 0, 0
	CPFSGT	check_60, A
	bra	Output_Error
	movwf	temporary_min, A
	
	movf	set_time_sec1, W, A
	mullw	0x0A
	movf	PRODL, W, A
	addwf	set_time_sec2, 0, 0
	CPFSGT	check_60, A
	bra	Output_Error
	movwf	temporary_sec, A
	
	btfss	alarm, 0, A
	bra	Input_into_Clock
	bra	Input_into_Alarm
	
Input_into_Clock:
	movff	temporary_hrs, clock_hrs
	movff	temporary_min, clock_min
	movff	temporary_sec, clock_sec
	;call	Rewrite_Clock		
	return

Input_into_Alarm:
	movff	temporary_hrs, alarm_hrs
	movff	temporary_min, alarm_min
	movff	temporary_sec, alarm_sec
	
	bsf	alarm_on, 0, A
	;call	Rewrite_Clock
	return
	
	
	
Output_Error:
	
	call    LCD_cursor_off ;turn off cursor and blinking

	call	LCD_Clear
	call	LCD_Line1	    ;set position in LCD to first line, first character
	call	Write_Error  
	bra	Cancel
    
	
    end; ?? are we supposed to have this or not?


