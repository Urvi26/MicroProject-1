#include <xc.inc>

extrn	clock_sec, clock_min, clock_hrs
extrn	Write_ALARM, Write_Snooze
extrn	Keypad, keypad_val
extrn	LCD_delay_x4us, LCD_Set_to_Line_2
extrn	hex_C, hex_A, skip_byte
    
global	alarm_sec, alarm_min, alarm_hrs
global	Check_Alarm, Alarm_Setup
global	alarm_on
    
psect	udata_acs

alarm_sec:	ds  1
alarm_min:	ds  1
alarm_hrs:	ds  1
    
alarm_on:   ds 1
buzz_on_or_off: ds	1

buzzer_counter_1: ds 1
buzzer_counter_2: ds 1

alarm_countdown: ds 1    
    
psect	Alarm_code, class=CODE
    
Alarm_Setup:
	movlw	0x00	;;;;;
	movwf	alarm_sec, A
	movwf	alarm_min, A
	movwf	alarm_hrs, A
	
	bcf	alarm_on, 0, A
	bcf	buzz_on_or_off, 0, A
	
	clrf	alarm_countdown, A
	return
	
Check_Alarm:
	movlw	0x00
	cpfseq	alarm_countdown, A
	bra	Decrement_Alarm_Countdown
	bra	Compare_Alarm

Decrement_Alarm_Countdown:
	decf	alarm_countdown, A
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
	movwf	alarm_countdown, A
	
	call ALARM
	return
ALARM:
	call	Write_ALARM

	BTG	buzz_on_or_off,0
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
	btfss	buzz_on_or_off, 0, A
	bra	No_Buzz
	bra	Yes_Buzz
	
No_Buzz:
	call	Delay_Buzzer
	call	Delay_Buzzer
	return
	
Yes_Buzz:	
	bsf	LATB, 6, A	;Ouput high
	call	Delay_Buzzer
	bcf	LATB, 6, A	;Ouput low
	call	Delay_Buzzer
	return	
	
Delay_Buzzer:
	movlw   0x20
	call    LCD_delay_x4us
	return
	
Cancel_Alarm:
	clrf	alarm_countdown, A
	return
	
Snooze_Alarm:
	clrf	alarm_countdown, A
	call	Write_Snooze
	
	movlw	0x05
	addwf	alarm_min, A
	movlw	0x3B
	CPFSGT	alarm_min, A
	return
	movlw	0x3C
	subwf	alarm_min, 1, 0	;result stored back in f
	incf	alarm_hrs, A
	movlw	0x17
	CPFSGT	alarm_hrs, A
	return
	movlw	0x18
	subwf	alarm_hrs, 1, 0
	
	return

    


