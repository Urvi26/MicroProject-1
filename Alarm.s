#include <xc.inc>

extrn	clock_sec, clock_min, clock_hrs
extrn	LCD_Line2, Write_ALARM, Write_Snooze
extrn	Keypad, keypad_val
extrn	LCD_delay_x4us
extrn	hex_C, hex_A, skip_byte
global	alarm_sec, alarm_min, alarm_hrs, Check_Alarm, Alarm_Setup, alarm_on
    
psect	udata_acs

alarm_sec:	ds  1
alarm_min:	ds  1
alarm_hrs:	ds  1
    
alarm_on:   ds 1
buzz_bit: ds	1

buzzer_counter_1: ds 1
buzzer_counter_2: ds 1

alarm_buzz: ds 1    
    
psect	Alarm_code, class=CODE
    
Alarm_Setup:
	bcf	alarm_on, 0, A
	bcf	buzz_bit, 0, A
	clrf	alarm_buzz, A
	return
	
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
    


