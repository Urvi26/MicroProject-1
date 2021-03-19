#include <xc.inc>
	
extrn	Write_Decimal_LCD, LCD_Clear, LCD_Write_Character, LCD_Write_Hex, operation_check
extrn	LCD_Set_Position, LCD_Write_Time, LCD_Write_Temp, Keypad, LCD_Send_Byte_I, LCD_Send_Byte_D, keypad_val, keypad_ascii
extrn	LCD_Write_Low_Nibble, LCD_Write_High_Nibble, LCD_delay_x4us
global	operation,  write_alarm
extrn	alarm_sec, alarm_min, alarm_hrs, alarm
extrn	LCD_delay_ms, rewrite_clock
extrn	clock_sec, clock_min, clock_hrs    
   
psect	udata_acs

check_60:	ds  1	;reserving byte to store decimal 60 in hex
check_24:	ds  1	;reserving byte to store decimal 24 in hex

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
    
skip_byte: ds 1


psect	Set_code, class=CODE
    

	
operation:
	call	delay
read_keypad:
	call	Keypad
	movf	keypad_val, W
	CPFSEQ hex_null	
	bra	check_alarm
	bra	operation ;might get stuck
check_alarm:	
	CPFSEQ	hex_A
	bra check_set_time
	;bra set_alarm
check_set_time:
	CPFSEQ	hex_B
	bra check_cancel
	bra set_time
check_cancel:
	CPFSEQ	hex_C
	bra read_keypad
	return
	
set_alarm:
	movlw	00001111B
	call    LCD_Send_Byte_I
	
	movlw	11000000B
	call    LCD_Set_Position
	call	write_alarm
	
	clrf	alarm
	call	write_alarm_time
	movlw	11000110B
	call    LCD_Set_Position
	bra set_time1
    
	movlw	00001111B
	call    LCD_Send_Byte_I
    
	movlw	10000000B	    ;set cursor to first line
	call	LCD_Set_Position
	call	write_alarm
	
	call write_set_time
	
	movlw	10000000B	    ;set cursor to first line
	call	LCD_Set_Position
	
	clrf	skip_byte
	
	call	LCD_Write_Time	    ;write 'Time: ' to LCD
	
write_alarm_time:
	movf	alarm_hrs, W
	call Write_Decimal_LCD
	movlw	0x3A
	call LCD_Write_Character
	movf	alarm_min, W
	call Write_Decimal_LCD
	movlw	0x3A
	call LCD_Write_Character
	movf	alarm_sec, W
	call Write_Decimal_LCD
	return
	
	
set_time: 
	movlw	00001111B
	call    LCD_Send_Byte_I
    
	movlw	10000000B	    ;set cursor to first line
	call	LCD_Set_Position
	
	movlw	0x0
	movwf	set_time_hrs1
	movwf	set_time_hrs2
	movwf	set_time_min1
	movwf	set_time_min2
	movwf	set_time_sec1
	movwf	set_time_sec2
	
	call	write_set_time
	
	movlw	10000000B	    ;set cursor to first line
	call	LCD_Set_Position
	
	clrf	skip_byte
	
	call	LCD_Write_Time	    ;write 'Time: ' to LCD
set_time1:
    
	call input_check	  
	
	CPFSEQ	hex_C
	btfsc	skip_byte, 0
	bra	cancel
	CPFSEQ	hex_E
	btfsc	skip_byte, 0
	bra	enter_time
	
	call	set_time_write
	movff	keypad_val, set_time_hrs1
	call delay
set_time2:
	call input_check	  
	
	CPFSEQ	hex_C
	btfsc	skip_byte, 0
	bra	cancel
	CPFSEQ	hex_E
	btfsc	skip_byte, 0
	bra	enter_time
	
	call set_time_write
	movlw	0x3A		    ;write ':' to LCD
	call	LCD_Write_Character 
	
	movff	keypad_val, set_time_hrs2
	call delay
set_time3:
	call input_check	  
	
	CPFSEQ	hex_C
	btfsc	skip_byte, 0
	bra	cancel
	CPFSEQ	hex_E
	btfsc	skip_byte, 0
	bra	enter_time
	
	call set_time_write
	movff	keypad_val, set_time_min1
	call delay
set_time4:
	call input_check	  
	
	CPFSEQ	hex_C
	btfsc	skip_byte, 0
	bra	cancel
	CPFSEQ	hex_E
	btfsc	skip_byte, 0
	bra	enter_time
	
	call	set_time_write
	movlw	0x3A		    ;write ':' to LCD
	call	LCD_Write_Character 
	
	movff	keypad_val, set_time_min2
	call delay
set_time5:
	call input_check	  
	
	CPFSEQ	hex_C
	btfsc	skip_byte, 0
	bra	cancel
	CPFSEQ	hex_E
	btfsc	skip_byte, 0
	bra	enter_time
	
	call set_time_write
	movff	keypad_val, set_time_sec1
	call delay
set_time6:
	call input_check	  
	
	CPFSEQ	hex_C
	btfsc	skip_byte, 0
	bra	cancel
	CPFSEQ	hex_E
	btfsc	skip_byte, 0
	bra	enter_time
	
	call set_time_write
	movff	keypad_val, set_time_sec2
	call delay

check_enter:
	call input_check
	CPFSEQ	hex_C
	btfsc	skip_byte, 0
	bra	cancel
	CPFSEQ	hex_E
	btfsc	skip_byte, 0
	bra	enter_time
	bra	check_enter
	
enter_time:
	call input_prepare
	btfsc	alarm, 0
	call input_into_clock
	call input_into_alarm
	movlw	00001100B
	call    LCD_Send_Byte_I
	return
	
cancel:
	movlw	00001100B
	call    LCD_Send_Byte_I
	
	return
	
input_prepare:
	movlw	0x3C		;inputting hex values for decimal 24 and 60 for comparison
	movwf	check_60
	movlw	0x18
	movwf	check_24
    
	movf	set_time_hrs1, W
	mullw	0x0A
	movf	PRODL, W
	addwf	set_time_hrs2, 0
	movwf	0x20
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
	;call	rewrite_clock
	return	
	
	
	
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
	bra keypad_input_D
	bra input_check
keypad_input_D:
	CPFSEQ	hex_D
	bra keypad_input_F
	bra input_check
keypad_input_F:
	CPFSEQ	hex_F
	return
	bra input_check	
	
	
write_set_time:
    	movlw	10000000B	    ;set cursor to first line
	call	LCD_Set_Position
	call	LCD_Write_Time	    ;write 'Time: ' to LCD
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
	movlw	11000000B	    ;set cursor to first line
	call	LCD_Set_Position
	call	LCD_Write_Temp	    ;write 'Temp: ' to LCD
				    ;Here will write temperature to LCD
	return
	
set_time_write:
	movf	keypad_ascii, W
	call	LCD_Write_Character
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
	movlw	0xff
	call	LCD_delay_ms
	movlw	0xff
	call	LCD_delay_ms
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

delay:
	movlw	0x64
	call	LCD_delay_ms
	movlw	0x64
	call	LCD_delay_ms
	movlw	0x64
	call	LCD_delay_ms
	return