#include <xc.inc>
	
extrn	Write_Decimal_to_LCD  
extrn	keypad_val, keypad_ascii, operation_check
extrn	LCD_delay_x4us
extrn	temporary_hrs, temporary_min, temporary_sec
    
extrn	ADC_Setup, ADC_Read       
extrn	Temp
extrn	Keypad

extrn	Write_Snooze, Write_space, Write_colon, Write_ALARM, Write_Time, Write_Temp
extrn	LCD_Line2, LCD_Line1
    
global	clock_sec, clock_min, clock_hrs
global	Clock, Clock_Setup, Rewrite_Clock
global	hex_A, hex_B, hex_C, hex_D, hex_E, hex_F, hex_null  
global	alarm_hrs, alarm_min, alarm_sec, Display_Alarm_Time, alarm_on, skip_byte, check_24, check_60
    
psect	udata_acs
clock_hrs: ds 1
clock_min: ds 1
clock_sec: ds 1
    
alarm_sec:	ds  1
alarm_min:	ds  1
alarm_hrs:	ds  1
    
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

alarm_buzz: ds 1    


psect	Clock_timer_code, class=CODE

Clock_Setup: 
	movlw	0x00		;setting start time to 00:00:00
	movwf   clock_sec, A
	movwf   clock_min, A
	movwf   clock_hrs, A
	
	call	ADC_Setup
	
	movlw	0x00
	movwf	alarm_sec, A
	movwf	alarm_min, A
	movwf	alarm_hrs, A
	
	call	Rewrite_Clock
	
	movlw	0x3C		;setting hex values for decimal 24 and 60 for comparison
	movwf	check_60, A
	movlw	0x18
	movwf	check_24, A
	
	movlw	0x0A		;storing keypad character hex values
	movwf	hex_A, A
	movlw	0x0B
	movwf	hex_B, A
	movlw	0x0C
	movwf	hex_C, A
	movlw	0x0D
	movwf	hex_D, A
	movlw	0x0E
	movwf	hex_E, A
	movlw	0x0F
	movwf	hex_F, A
	movlw	0xff
	movwf	hex_null, A
	
	movlw	0x0B
	movwf	timer_start_value_1, A
	movlw	0xDB
	movwf	timer_start_value_2, A
	
	movlw	10000111B	; Set timer1 to 16-bit, Fosc/4/256
	movwf	T0CON, A	; = 62.5KHz clock rate, approx 1sec rollover
	bsf	TMR0IE		; Enable timer0 interrupt
	bsf	GIE		; Enable all interrupts
alarm_setup:
	bcf	alarm_on, 0, A
	bcf	buzz_bit, 0, A
	clrf	alarm_buzz, A
	
	return
    
Clock:	
	btfss	TMR0IF		; check that this is timer0 interrupt
	retfie	f		; if not then return
	call	Clock_Inc	; increment clock time
	movff	timer_start_value_1, TMR0H	;setting upper byte timer start value
	movff	timer_start_value_2, TMR0L		;setting lower byte timer start value
	bcf	TMR0IF		; clear interrupt flag
	btfss	operation_check, 0, A ;skip rewrite clock if = 1
	call	Rewrite_Clock	;write and display clock time as decimal on LCD 
	call	Check_Alarm
	retfie	f		; fast return from interrupt	
	
Check_Alarm:
	movlw	0x00
	cpfseq	alarm_buzz, A
	bra	Decrement_Alarm_Buzz
	bra	Compare_Alarm

Decrement_Alarm_Buzz:
	decf	alarm_buzz, A
	call	ALARM
	return
	
Compare_Alarm:  
	btfss	alarm_on, 0, A
	return
	movf	alarm_hrs, W, A
	CPFSEQ	clock_hrs, A
	return
	movf	alarm_min, W, A
	CPFSEQ	clock_min, A
	return
	movf	alarm_sec, W, A
	CPFSEQ	clock_sec, A
	return
	
	movlw	0x3C
	movwf	alarm_buzz, A
	
	call ALARM
	return
ALARM:
	call	LCD_Line2
	call	Write_ALARM

	BTG	buzz_bit,0
	call	Buzzer

	return	
			
Rewrite_Clock:
	call	LCD_Line1
	call	Write_Time	    ;write 'Time: ' to LCD
	movf	clock_hrs, W, A	    ;write hours time to LCD as decimal
	call	Write_Decimal_to_LCD  
	call	Write_colon	    ;write ':' to LCD
	movf	clock_min, W, A	    ;write minutes time to LCD as decimal
	call	Write_Decimal_to_LCD
	call	Write_colon	    ;write ':' to LCD
	movf	clock_sec, W, A	    ;write seconds time to LCD as decimal
	call	Write_Decimal_to_LCD
	call	LCD_Line2
	call	Write_Temp	    ;write 'Temp: ' to LCD
	call	Temp		    ;Here will write temperature to LCD
	return
	

Clock_Inc:	
	incf	clock_sec, A	    ;increase seconds time by one
	movf	clock_sec, W, A	   
	cpfseq	check_60, A	    ;check clock seconds is equal than 60
	return			    ;return if not equal to 60
	clrf	clock_sec, A	    ;set second time to 0 if was equal to 60
	incf	clock_min, A	    ;increase minute time by one
	movf	clock_min, W, A
	cpfseq	check_60, A	    ;check if minute time equal to 60
	return
	clrf	clock_min, A	    ;set minute time to 0 if = 60
	incf	clock_hrs, A	    ;increase hour time by one
	movf	clock_hrs, W, A	
	cpfseq	check_24, A	    ;check if hour time equal to 24
	return	
	clrf	clock_hrs, A	    ;set hour time to 0 if = 24
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
	  
Buzzer:	
	;Initialize
	bcf	TRISB, 6, A
	
	movlw	0x64
	movwf	buzzer_counter_1, A
	movlw	0x1E
	movwf	buzzer_counter_2, A

Buzz_Loop_1:
    
Check_Cancel_Snooze:
	call	Keypad
	movf	keypad_val, W, A
	CPFSEQ	hex_C, A
	btfsc	skip_byte, 0, A
	bra	Cancel_Alarm
	CPFSEQ	hex_A, A
	btfsc	skip_byte, 0, A
	bra	Snooze_Alarm	    
   

	call	Buzz_Loop_2
	movlw	0x1E
	movwf	buzzer_counter_2, A
	
	decfsz	buzzer_counter_1, A
	bra	Buzz_Loop_1
	return
    
Buzz_Loop_2:
	call	Buzz_Sequence
    
	decfsz	buzzer_counter_2, A
	bra	Buzz_Loop_2	
	return
	
	
	
Buzz_Sequence:	
    
Check_if_Buzz:
	btfss	buzz_bit, 0, A
	bra	No_Buzz
	bra	Yes_Buzz
	
No_Buzz:
	call	delay_buzzer
	call	delay_buzzer
	return
	
Yes_Buzz:	
	bsf	LATB, 6, A	;Ouput high
	call	delay_buzzer
	bcf	LATB, 6, A	;Ouput low
	call	delay_buzzer
	return	
	
	
	
Cancel_Alarm:
	clrf	alarm_buzz, A
	return
	
Snooze_Alarm:
	clrf	alarm_buzz, A
	call	Write_Snooze
	
	movlw	0x05
	addwf	alarm_min, A
	movlw	0x3B
	cpfsgt	alarm_min, A
	return
	movlw	0x3C
	subwf	alarm_min, 1, 0	;result stored back in f
	incf	alarm_hrs, A
	movlw	0x17
	cpfsgt	alarm_hrs, A
	return
	movlw	0x18
	subwf	alarm_hrs, 1, 0
	
	return

	
delay_buzzer:
	movlw   0x20
	call    LCD_delay_x4us
	return
    