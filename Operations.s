#include <xc.inc>
	
extrn	Write_Decimal_to_LCD
extrn	LCD_Clear, operation_check
extrn	LCD_Write_Low_Nibble, LCD_delay_x4us, LCD_delay_ms
    
extrn	Keypad, keypad_val

extrn	rewrite_clock
extrn	clock_sec, clock_min, clock_hrs  
extrn	hex_A, hex_B, hex_C, hex_D, hex_E, hex_F, hex_null
extrn	Write_Error, Write_no_alarm, Write_zeros, Write_Time, Write_Temp, Write_Alarm, Write_New
extrn	Write_colon, Write_space, LCD_cursor_on, LCD_cursor_off, LCD_Line1, LCD_Line2
    
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
	call	LCD_cursor_on
	
	call	LCD_Line2
	
	call	Display_Set_Alarm
	
	call	LCD_Line2
	
	call	Write_New
	
	;call	Write_Alarm	    ;write 'Time: ' to LCD
	
	bsf	alarm, 0, A
	
	bra set_time_clear	
	
set_time: 
	call	LCD_cursor_on
    
	call	LCD_Line1
	
	call	Display_Set_Time
	
	call	LCD_Line1
	
	call	Write_Time	    ;write 'Time: ' to LCD
	
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
	call	Write_colon	    ;write ':' to LCD
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
	call	Write_colon	    ;write ':' to LCD
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
	
	call LCD_cursor_off
	
	bcf	operation_check, 0, A
	bcf	alarm, 0, A
	
	call	LCD_Clear
	
	return
	
cancel:
	
	call	LCD_cursor_off
	
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
	
	call    LCD_cursor_off ;turn off cursor and blinking

	call	LCD_Clear
	call	LCD_Line1	    ;set position in LCD to first line, first character
	call	Write_Error  
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


