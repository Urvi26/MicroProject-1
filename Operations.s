#include <xc.inc>
	
extrn	Write_Decimal_to_LCD
extrn	LCD_Clear, LCD_Write_Character, LCD_Write_Hex, operation_check
extrn	LCD_Set_Position, LCD_Write_Time, LCD_Write_Temp, LCD_Send_Byte_I, LCD_Send_Byte_D
extrn	LCD_Write_Low_Nibble, LCD_Write_High_Nibble, LCD_delay_x4us, LCD_delay_ms
extrn	Keypad, keypad_val, keypad_ascii
extrn	rewrite_clock
extrn	clock_sec, clock_min, clock_hrs  
extrn	hex_A, hex_B, hex_C, hex_D, hex_E, hex_F, hex_null
extrn	reset_clock
    
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
	bsf	operation_check, 0
	call	delay
check_keypad:
	call	Keypad
	movf	keypad_val, W
	CPFSEQ	hex_null	
	bra	check_alarm
	bra	check_keypad ;might get stuck
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
	bra	check_keypad
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
	
	movwf	temporary_hrs
	movwf	temporary_min
	movwf	temporary_sec
	
	call write_set_time
	
	movlw	10000000B	    ;set cursor to first line
	call	LCD_Set_Position
	
	call	LCD_Write_Time	    ;write 'Time: ' to LCD
	
	bcf	skip_byte,  0	    ;set skip byte to zero to be used to skip lines later
	
set_time1:	
	call input_check	
	
	CPFSEQ	hex_C
	btfsc	skip_byte, 0
	bra	cancel
	CPFSEQ	hex_E
	btfsc	skip_byte, 0
	bra	enter_time
	
	movff	keypad_val, set_time_hrs1
	
	call	set_time_write
	call delay
set_time2:
	call input_check	  

	CPFSEQ	hex_C
	btfsc	skip_byte, 0
	bra	cancel
	CPFSEQ	hex_E
	btfsc	skip_byte, 0
	bra	enter_time
	
	movff	keypad_val, set_time_hrs2
	
	call set_time_write
	movlw	0x3A		    ;write ':' to LCD
	call	LCD_Write_Character 
	call delay
set_time3:
	call input_check	  
	
	CPFSEQ	hex_C
	btfsc	skip_byte, 0
	bra	cancel
	CPFSEQ	hex_E
	btfsc	skip_byte, 0
	bra	enter_time
	
	movff	keypad_val, set_time_min1
	
	call set_time_write
	call delay
set_time4:
	call input_check	  
	
	CPFSEQ	hex_C
	btfsc	skip_byte, 0
	bra	cancel
	CPFSEQ	hex_E
	btfsc	skip_byte, 0
	bra	enter_time
	
	movff	keypad_val, set_time_min2
	
	call	set_time_write
	movlw	0x3A		    ;write ':' to LCD
	call	LCD_Write_Character 
	call delay
set_time5:
	call input_check	  
	
	CPFSEQ	hex_C
	btfsc	skip_byte, 0
	bra	cancel
	CPFSEQ	hex_E
	btfsc	skip_byte, 0
	bra	enter_time
	
	movff	keypad_val, set_time_sec1
	
	call set_time_write
	call delay
set_time6:
	call input_check	  
	
	CPFSEQ	hex_C
	btfsc	skip_byte, 0
	bra	cancel
	CPFSEQ	hex_E
	btfsc	skip_byte, 0
	bra	enter_time
	
	movff	keypad_val, set_time_sec2
	
	call set_time_write
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
	call input_into_clock
cancel:
	movlw	00001100B
	call    LCD_Send_Byte_I
	
	bcf	operation_check, 0
	
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
	;movf	keypad_ascii, W
	;call	LCD_Write_Character
	movf	keypad_val
	call	LCD_Write_Low_Nibble
	return
    
input_into_clock:
	movlw	0x3C		;setting hex values for decimal 24 and 60 for comparison
	movwf	check_60
	movlw	0x18
	movwf	check_24
	
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
	
	;call	reset_clock
	
	movff	temporary_hrs, clock_hrs
	movff	temporary_min, clock_min
	movff	temporary_sec, clock_sec
	
	;call	rewrite_clock		
	return
	
	
output_error:
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
    call	LCD_delay_ms;WRITE THIS SUBROUTINE FOR A 3SEC DELAY LATER
    movlw	0x64
    call	LCD_delay_ms
    movlw	0x64
    call	LCD_delay_ms
    movlw	0x64
    call	LCD_delay_ms
    
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


