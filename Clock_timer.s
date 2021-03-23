#include <xc.inc>
	
extrn	LCD_Write_Time, LCD_Write_Temp, LCD_Write_Alarm
extrn	LCD_Set_Position, LCD_Write_Character, LCD_Write_Hex
extrn	Write_Decimal_to_LCD  
extrn	keypad_val, keypad_ascii, operation_check
extrn	LCD_delay_ms, LCD_delay_x4us
extrn	temporary_hrs, temporary_min, temporary_sec
    
extrn	ADC_Setup, ADC_Read       
extrn	Temp
extrn	Keypad

    
global	clock_sec, clock_min, clock_hrs
global	Clock, Clock_Setup, rewrite_clock
global	hex_A, hex_B, hex_C, hex_D, hex_E, hex_F, hex_null  
global	alarm_hrs, alarm_min, alarm_sec, Display_Alarm_Time, alarm, alarm_on
    
psect	udata_acs
clock_hrs: ds 1
clock_min: ds 1
clock_sec: ds 1
    
alarm_sec:	ds  1
alarm_min:	ds  1
alarm_hrs:	ds  1
    
alarm:	ds 1
alarm_on:   ds 1
buzz_bit: ds	1
    
buzzer_counter_1: ds 1
buzzer_counter_2: ds 1

check_60:	ds  1	;reserving byte to store decimal 60 in hex
check_24:	ds  1	;reserving byte to store decimal 24 in hex

timer_start_value_1:	ds 1
timer_start_value_2:	ds 1

hex_A:	ds 1
hex_B:	ds 1
hex_C:	ds 1
hex_D:	ds 1
hex_E:	ds 1
hex_F:	ds 1
hex_null:   	ds  1

Alarm_buzz: ds 1    
    
skip_byte: ds 1

psect	Clock_timer_code, class=CODE

Clock_Setup: 
	movlw	0x00		;setting start time to 00:00:00
	movwf   clock_sec
	movwf   clock_min
	movwf   clock_hrs
	
	;Temp Port A setup
	;bcf	TRISA, 3
	
	call	ADC_Setup
	
	movlw	0x01	;;;;;
	movwf	alarm_sec
	movwf	alarm_min
	movwf	alarm_hrs
	
	bcf	alarm, 0
	bcf	alarm_on, 0
	bcf	buzz_bit, 0
	
	clrf	Alarm_buzz
	
	bsf	skip_byte, 0
	
	call	rewrite_clock
	
	movlw	0x3C		;setting hex values for decimal 24 and 60 for comparison
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
	
	movlw	10000111B	; Set timer1 to 16-bit, Fosc/4/256
	movwf	T0CON, A	; = 62.5KHz clock rate, approx 1sec rollover
	bsf	TMR0IE		; Enable timer0 interrupt
	bsf	GIE		; Enable all interrupts
	return
    
Clock:	
	btfss	TMR0IF		; check that this is timer0 interrupt
	retfie	f		; if not then return
	call	clock_inc	; increment clock time
	movff	timer_start_value_1, TMR0H	;setting upper byte timer start value
	movff	timer_start_value_2, TMR0L		;setting lower byte timer start value
	bcf	TMR0IF		; clear interrupt flag
	btfss	operation_check, 0 ;skip rewrite clock if = 1
	call	rewrite_clock	;write and display clock time as decimal on LCD 
	call	check_alarm
	retfie	f		; fast return from interrupt	
	
check_alarm:
	movlw	0x00
	cpfseq	Alarm_buzz
	bra	decrement_alarm_buzz
	bra	compare_alarm

decrement_alarm_buzz:
	decf	Alarm_buzz
	call	ALARM
	return
	
compare_alarm:  
	btfss	alarm_on, 0
	return
	movf	alarm_hrs, W
	CPFSEQ	clock_hrs
	return
	movf	alarm_min, W
	CPFSEQ	clock_min
	return
	movf	alarm_sec, W
	CPFSEQ	clock_sec
	return
	
	movlw	0x3C
	movwf	Alarm_buzz
	
	call ALARM
	return
ALARM:
	movlw	11000000B	    ;set cursor to first line
	call	LCD_Set_Position
	call	Display_ALARM

	call	check_buzz_bit
	call	buzzer

	return	
		
check_buzz_bit:
	btfsc	buzz_bit, 0
	bra	clear_buzz_bit
	bra	set_buzz_bit
clear_buzz_bit:	
	bcf	buzz_bit, 0
	return
set_buzz_bit:
	bsf	buzz_bit, 0
	return
	
	
rewrite_clock:
	movlw	10000000B	    ;set cursor to first line
	call	LCD_Set_Position
	call	LCD_Write_Time	    ;write 'Time: ' to LCD
	movf	clock_hrs, W	    ;write hours time to LCD as decimal
	call	Write_Decimal_to_LCD  
	movlw	0x3A		    ;write ':' to LCD
	call	LCD_Write_Character 
	movf	clock_min, W	    ;write minutes time to LCD as decimal
	call	Write_Decimal_to_LCD
	movlw	0x3A		    ;write ':' to LCD
	call	LCD_Write_Character
	movf	clock_sec, W	    ;write seconds time to LCD as decimal
	call	Write_Decimal_to_LCD
	movlw	11000000B	    ;set cursor to first line
	call	LCD_Set_Position
	call	LCD_Write_Temp	    ;write 'Temp: ' to LCD
	call	Temp		    ;Here will write temperature to LCD
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
	
	
Display_Alarm_Time:
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
	
Display_ALARM:				    ;write the words 'time:' before displaying the time
	;call delay
	movlw	11000000B
	call	LCD_Set_Position	    ;set position in LCD to first line, first character
	movlw	0x41
	call	LCD_Write_Character	;write 'A'
	movlw	0x4C
	call	LCD_Write_Character	;write 'L'
	movlw	0x41
	call	LCD_Write_Character	;write 'A'
	movlw	0x52
	call	LCD_Write_Character	;write 'R'
	movlw   0x4D
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
	
Write_space:
	movlw   0x20
	call    LCD_Write_Character	;write 'M'
	return
    
buzzer:	
	;Initialize
	bcf	TRISB, 6
	
	movlw	0x64
	movwf	buzzer_counter_1
	movlw	0x1E
	movwf	buzzer_counter_2

buzz_loop_1:
    
check_cancel_snooze:
	call	Keypad
	movf	keypad_val, W
	CPFSEQ	hex_C
	btfss	skip_byte, 0
	bra	cancel_alarm
	CPFSEQ	hex_A
	btfss	skip_byte, 0
	bra	snooze_alarm	    
   

	call	buzz_loop_2
	movlw	0x1E
	movwf	buzzer_counter_2
	
	decfsz	buzzer_counter_1
	bra	buzz_loop_1
	return
    
buzz_loop_2:
	call	buzz_sequence
    
	decfsz	buzzer_counter_2
	bra	buzz_loop_2	
	return
	
	
	
buzz_sequence:	
    
check_if_buzz:
	btfss	buzz_bit, 0
	bra	no_buzz
	bra	yes_buzz
	
no_buzz:
	call	delay_buzzer
	call	delay_buzzer
	return
	
yes_buzz:	
	bsf	LATB, 6	;Ouput high
	call	delay_buzzer
	bcf	LATB, 6	;Ouput low
	call	delay_buzzer
	return	
	
	
	
cancel_alarm:
	clrf	Alarm_buzz
	return
	
snooze_alarm:
	clrf	Alarm_buzz
	call	Display_Snooze
	
	movlw	0x05
	addwf	alarm_min
	movlw	0x3B
	cpfsgt	alarm_min
	return
	movlw	0x3C
	subwf	alarm_min, 1
	incf	alarm_hrs
	movlw	0x17
	cpfsgt	alarm_hrs
	return
	movlw	0x18
	subwf	alarm_hrs, 1
	
	return
	
Display_Snooze:				    ;write the words 'time:' before displaying the time
	movlw	11000000B
	call	LCD_Set_Position	    ;set position in LCD to first line, first character
	movlw	0x53
	call	LCD_Write_Character	;write 'S'
	movlw	0x6E
	call	LCD_Write_Character	;write 'n'
	movlw	0x6F
	call	LCD_Write_Character	;write 'o'
	movlw	0x6F
	call	LCD_Write_Character	;write 'o'
	movlw   0x7A
	call    LCD_Write_Character	;write 'z'
	movlw   0x65
	call    LCD_Write_Character	;write 'e'
	
	call	Write_space
	call	Write_space
	call	Write_space
	call	Write_space
	call	Write_space
	
	movlw	0x64
	call	LCD_delay_ms
	movlw	0x64
	call	LCD_delay_ms
	movlw	0x64
	call	LCD_delay_ms
	
	
	return	
	
delay_buzzer:
	movlw   0x20
	call    LCD_delay_x4us
	return
    