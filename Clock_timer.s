#include <xc.inc>
	
extrn	Write_Decimal_LCD, LCD_Clear, LCD_Write_Character, LCD_Write_Hex, operation_check
extrn	LCD_Set_Position, LCD_Write_Time, LCD_Write_Temp, Keypad, LCD_Send_Byte_I, LCD_Send_Byte_D, keypad_val, keypad_ascii
extrn	LCD_Write_Low_Nibble, LCD_Write_High_Nibble
global	Clock, Clock_Setup, operation
    
psect	udata_acs
clock_sec:	ds  1	;reserving byte to store second time in hex
clock_min:	ds  1	;reserving byte to store minute time in hex
clock_hrs:	ds  1	;reserving byte to store hour time in hex
check_60:	ds  1	;reserving byte to store decimal 60 in hex
check_24:	ds  1	;reserving byte to store decimal 24 in hex
    
LCD_cnt_l:	ds 1	; reserve 1 byte for variable LCD_cnt_l
LCD_cnt_h:	ds 1	; reserve 1 byte for variable LCD_cnt_h
LCD_cnt_ms:	ds 1	; reserve 1 byte for ms counter
    
clock_flag:	ds  1
hour_1:	ds 1
hour_2: ds 1
min_1: ds 1
min_2: ds 1
hex_A: ds 1
hex_B: ds 1
hex_C: ds 1
hex_D: ds 1
hex_E: ds 1
hex_F: ds 1
hex_null: ds 1
set_time_hrs1: ds 1
set_time_hrs2: ds 1  
set_time_hrsint: ds 1  
set_time_min1: ds 1
set_time_min2: ds 1
set_time_minint: ds 1  
set_time_sec1: ds 1
set_time_sec2: ds 1
set_time_secint: ds 1  
temporary_hrs: ds 1
temporary_min: ds 1
temporary_sec: ds 1
skip_byte: ds 1
timer_start_value_1: ds 1
timer_start_value_2: ds 1
    
	
    
psect	Clock_timer_code, class=CODE

Clock_Setup: 
	movlw	0x00		;setting start time to 00:00:00
	movwf   clock_sec
	movwf   clock_min
	movwf   clock_hrs
	call	rewrite_clock
	
	movlw	0x3C		;inputting hex values for decimal 24 and 60 for comparison
	movwf	check_60
	movlw	0x18
	movwf	check_24
	
	movlw	0x0A		;storing keypad character hex values
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
	
	movlw	0x0B
	movwf	timer_start_value_1
	movlw	0xDB
	movwf	timer_start_value_2
	
	clrf	skip_byte	;set skip byte to zero to be used to skip lines later
	
	movlw	10000111B	; Set timer1 to 16-bit, Fosc/4/256
	movwf	T0CON, A	; = 62.5KHz clock rate, approx 1sec rollover
	bsf	TMR0IE		; Enable timer0 interrupt
	bsf	GIE		; Enable all interrupts
	return
    
Clock:	
	btfss	TMR0IF		; check that this is timer0 interrupt
	retfie	f		; if not then return
	call	clock_inc	; increment clock time
	btfss	operation_check, 0 ;skip rewrite clock if = 1
	call	rewrite_clock	;write and display clock time as decimal on LCD  
	movff	timer_start_value_1, TMR0H	;setting upper byte timer start value
	movff	timer_start_value_2, TMR0L		;setting lower byte timer start value
	bcf	TMR0IF		; clear interrupt flag
	retfie	f		; fast return from interrupt	
	
rewrite_clock:
	movlw	10000000B	    ;set cursor to first line
	call	LCD_Set_Position
	call	LCD_Write_Time	    ;write 'Time: ' to LCD
	movf	clock_hrs, W	    ;write hours time to LCD as decimal
	call	Write_Decimal_LCD  
	movlw	0x3A		    ;write ':' to LCD
	call	LCD_Write_Character 
	movf	clock_min, W	    ;write minutes time to LCD as decimal
	call	Write_Decimal_LCD
	movlw	0x3A		    ;write ':' to LCD
	call	LCD_Write_Character
	movf	clock_sec, W	    ;write seconds time to LCD as decimal
	call	Write_Decimal_LCD
	movlw	11000000B	    ;set cursor to first line
	call	LCD_Set_Position
	call	LCD_Write_Temp	    ;write 'Temp: ' to LCD
				    ;Here will write temperature to LCD
	return

clock_inc:	
	incf	clock_sec	    ;increase seconds time by one
	movf	clock_sec, W	   
	cpfseq	check_60	    ;check clock seconds is equal than 60
	return			    ;return if not equal to 60
	clrf	clock_sec	    ;set second time to 0 if was equal to 60
	incf	clock_min	    ;increase minute time by one
	movf	clock_min, W
	cpfseq	check_60	    ;check if minute time equal to 60
	return
	clrf	clock_min	    ;set minute time to 0 if = 60
	incf	clock_hrs	    ;increase hour time by one
	movf	clock_hrs, W	
	cpfseq	check_24	    ;check if hour time equal to 24
	return	
	clrf	clock_hrs	    ;set hour time to 0 if = 24
	return

	
	
	
operation:
	call	delay
	call	Keypad
	movf	keypad_val, W
	CPFSEQ hex_null	
	bra	check_alarm
	bra  operation ;might get stuck
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
	bra operation
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
	call write_set_time
	
	movlw	10000000B	    ;set cursor to first line
	call	LCD_Set_Position
	
	
	call	LCD_Write_Time	    ;write 'Time: ' to LCD
set_time1:	
    
	call input_check	  
	
	CPFSEQ	hex_C
	btfsc	skip_byte, 0
	return
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
	return
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
	return
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
	return
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
	return
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
	return
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
	return
	CPFSEQ	hex_E
	btfsc	skip_byte, 0
	bra	enter_time
	bra	check_enter
	
enter_time:
	call input_into_clock
	
	
cancel:
	movlw	00001100B
	call    LCD_Send_Byte_I
	
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
    
input_into_clock:
	
	clrf	PRODL
	clrf	PRODH
	
	movlw	0x01
	movwf	set_time_hrs1
	movlw	0x02
	movwf	set_time_hrs2
    
	;movlw	0x03
	;movwf	set_time_hrs1
	movlw	0x0A
	mulwf	set_time_hrs1
	movff	PRODL, temporary_hrs
	movf	set_time_hrs2
	;movf	set_time_hrs2, W
	addwf	temporary_hrs, W
	movwf	temporary_hrs, W
	
	
	;movff	PRODL, set_time_hrsint
	;movlw	set_time_hrsint
	;addwf	set_time_hrs2, W
	;movwf	temporary_hrs
	CPFSLT	check_24
	;call	output_error
	
	movlw	0x0A
	mulwf	set_time_min1
	movff	PRODL, set_time_minint
	movlw	set_time_minint
	;addwf	set_time_min2, W
	movwf	temporary_min
	CPFSLT	check_60
	;call	output_error
	
	movlw	0x0A
	mulwf	set_time_sec1
	movff	PRODL, set_time_secint
	movlw	set_time_secint
	;addwf	set_time_sec2, W
	movwf	temporary_sec
	CPFSLT	check_60
	;call	output_error
	
	movff	temporary_hrs, clock_hrs
	movff	temporary_min, clock_min
	movff	temporary_sec, clock_sec
	
	;movlw	0x01
	;movwf	keypad_val, A	
	;movf	keypad_val, A
	;movwf	clock_hrs
	;movwf	clock_min
	;movwf	clock_sec
	return
	
output_error:
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
    movlw	0x0A
    call	LCD_delay_x4us    ;WRITE THIS SUBROUTINE FOR A 3SEC DELAY LATER
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
	return		
	
; ** a few delay routines below here as LCD timing can be quite critical ****
LCD_delay_ms:		    ; delay given in ms in W
	movwf	LCD_cnt_ms, A
lcdlp2:	movlw	250	    ; 1 ms delay
	call	LCD_delay_x4us	
	decfsz	LCD_cnt_ms, A
	bra	lcdlp2
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


