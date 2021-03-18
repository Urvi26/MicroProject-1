#include <xc.inc>
	
extrn	Write_Decimal_LCD, LCD_Clear, LCD_Write_Character, LCD_Write_Hex
extrn	LCD_Set_Position, LCD_Write_Time, LCD_Write_Temp
global	Clock, Clock_Setup
    
psect	udata_acs
clock_sec:	ds  1	;reserving byte to store second time in hex
clock_min:	ds  1	;reserving byte to store minute time in hex
clock_hrs:	ds  1	;reserving byte to store hour time in hex
check_60:	ds  1	;reserving byte to store decimal 60 in hex
check_24:	ds  1	;reserving byte to store decimal 24 in hex
    
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
set_time_min1: ds 1
set_time_min2: ds 1
set_time_sec1: ds 1
set_time_sec2: ds 1
temporary_hrs: ds 1
temporary_min: ds 1
temporary_sec: ds 1
skip_byte: ds 1
   
	
    
psect	Clock_timer_code, class=CODE


Clock:	
	btfss	TMR0IF		; check that this is timer0 interrupt
	retfie	f		; if not then return
	call	clock_inc	; increment clock time
	call	rewrite_clock	;write and display clock time as decimal on LCD  
	movlw	0x0B		;setting upper byte timer start value
	movwf	TMR0H, A	
	movlw	0xDB		;setting lower byte timer start value
	movwf	TMR0L, A
	bcf	TMR0IF		; clear interrupt flag
	retfie	f		; fast return from interrupt
	    
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
	
	movlw	0x0A		
	movwf	hex_A
	movlw	0x0B
	movwf	hex_B
	movlw	0x0E
	movwf	hex_E
	movlw	0xff
	movwf	hex_null	
	
	clrf	skip_byte
	
	movlw	10000111B	; Set timer1 to 16-bit, Fosc/4/256
	movwf	T0CON, A	; = 62.5KHz clock rate, approx 1sec rollover
	bsf	TMR0IE		; Enable timer0 interrupt
	bsf	GIE		; Enable all interrupts
	return	
	
rewrite_clock:
	movlw	10000000B	    ;set cursor to first line
	call	LCD_Set_Position
	call	LCD_Write_Time
	movf	clock_hrs, W
	call	Write_Decimal_LCD
	movlw	0x3A
	call	LCD_Write_Character
	movf	clock_min, W
	call	Write_Decimal_LCD
	movlw	0x3A
	call	LCD_Write_Character
	movf	clock_sec, W
	call	Write_Decimal_LCD
	movlw	11000000B	    ;set cursor to first line
	call	LCD_Set_Position
	call	LCD_Write_Temp
	;movlw	0x35
	;call	LCD_Write_Character
	return

clock_inc:	
	incf	clock_sec
	movf	clock_sec, W
	cpfseq	check_60
	return
	clrf	clock_sec
	incf	clock_min
	movf	clock_min, W
	cpfseq	check_60
	return
	clrf	clock_min
	incf	clock_hrs
	movf	clock_hrs, W
	cpfseq	check_24
	return
	clrf	clock_hrs
	return
	
keypad_int: 
	btfss	TMR0IF		; check that this is timer0 interrupt
	retfie	f		; if not then return
	call	delay
	call	operation   ;OUTPUT MESSAGE THAT SAYS INPUT A FOR ALARM, B FOR TIME AND C FOR CANCEL??? OR JUST STICK 'SET ALARM' ETC ON BUTTONS PHYSICALLY
	
leave_interrupt:
	bcf	TMR0IF		; clear interrupt flag
	retfie	f		; fast return from interrupt	
	
	
	
operation:
	call	Keypad
	movf	keypad_val, W
	CPFSEQ hex_null	
	bra	check_alarm
	bra  operation ;might get stuck
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
	bra operation
	return

	
	
set_time: 
	call LCD_Clear
	movlw	00001111B
	call    LCD_Send_Byte_I
	clrf	set_time_hrs1
	clrf	set_time_hrs2
	clrf	set_time_min1
	clrf	set_time_min2
	clrf	set_time_sec1
	clrf	set_time_sec2
set_time1:	
	call input_check	  
	
	CPFSEQ	hex_C
	btfsc	skip_byte
	return
	CPFSEQ	hex_E
	btfsc	skip_byte
	bra	enter_time
	
	call set_time_write
	movff	keypad_val, set_time_hrs1
	call delay
set_time2:
	call input_check	  
	
	CPFSEQ	hex_C
	btfsc	skip_byte
	return
	CPFSEQ	hex_E
	btfsc	skip_byte
	bra	enter_time
	
	call set_time_write
	movff	keypad_val, set_time_hrs2
	call delay
set_time3:
	call input_check	  
	
	CPFSEQ	hex_C
	btfsc	skip_byte
	return
	CPFSEQ	hex_E
	btfsc	skip_byte
	bra	enter_time
	
	call set_time_write
	movff	keypad_val, set_time_min1
	call delay
set_time4:
	call input_check	  
	
	CPFSEQ	hex_C
	btfsc	skip_byte
	return
	CPFSEQ	hex_E
	btfsc	skip_byte
	bra	enter_time
	
	call set_time_write
	movff	keypad_val, set_time_min2
	call delay
set_time5:
	call input_check	  
	
	CPFSEQ	hex_C
	btfsc	skip_byte
	return
	CPFSEQ	hex_E
	btfsc	skip_byte
	bra	enter_time
	
	call set_time_write
	movff	keypad_val, set_time_sec1
	call delay
set_time6:
	call input_check	  
	
	CPFSEQ	hex_C
	btfsc	skip_byte
	return
	CPFSEQ	hex_E
	btfsc	skip_byte
	bra	enter_time
	
	call set_time_write
	movff	keypad_val, set_time_sec2
	call delay

enter_time:
	call input_into_clock
	
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
	
	
set_time_write:
	movf	keypad_char, W
	call	LCD_Write_Character
	return
    
input_into_clock:
	movf	set_time_hrs1, W
	mullw	0x0A
	movf	set_time_hrs2, W
	addwf	PRODL, 0, 1
	CPFSLT	check_24
	goto	output_error
	movwf	temporary_hrs	
	
	movf	set_time_min1, W
	mullw	0x0A
	movf	set_time_min2, W
	addwf	PRODL, 0, 1
	CPFSLT	check_60
	goto	output_error
	movwf	temporary_min
	
	movf	set_time_min1, W
	mullw	0x0A
	movf	set_time_min2, W
	addwf	PRODL, 0, 1
	CPFSLT	check_60
	goto	output_error
	movwf	temporary_sec
	
	movff	temporary_hrs, clock_hrs
	movff	temporary_min, clock_min
	movff	temporary_sec, clock_sec
	return
	
output_error:
    call clear_LCD
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
    call	delay_3s    ;WRITE THIS SUBROUTINE FOR A 3SEC DELAY LATER
    goto	leave_interrupt
    
    
    end

