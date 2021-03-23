#include <xc.inc>


psect	Alarm_code, class=CODE
check_alarm:
;	movlw	0x00
;	cpfseq	Alarm_buzz		;check if alarm_buzz has reached 0
;	bra	decrement_alarm_buzz	;keep decrementing and buzzing if it hasn't
	;bra	compare_alarm		;go to compare alarm and return to normal cycles if it has reached 0

;decrement_alarm_buzz:
	;decf	Alarm_buzz		;subroutine to keep decrementing alarm_buzz
	;call	ALARM			;and buzzing
	;return
	
;try instead of line 120-129?
	decfsz Alarm_buzz
	BNN	ALARM
	BRA	compare_alarm
	
compare_alarm:				;compare alarm
	btfss	alarm_on, 0		;check if alarm is on
	return				;return if it isnt on
	movf	alarm_hrs, W		;otherwise compare clock time to alarm time
	CPFSEQ	clock_hrs
	return
	movf	alarm_min, W
	CPFSEQ	clock_min
	return
	movf	alarm_sec, W
	CPFSEQ	clock_sec
	return			    ;return if not the same
	
	movlw	0x3C
	movwf	Alarm_buzz	    ;set alarm_buzz to 60 to be able to buzz for 60 seconds
	    
	call ALARM		    ;call alarm if it is the same
	return
ALARM:
	movlw	11000000B	    ;set cursor to first line
	call	LCD_Set_Position
	call	Display_ALARM	    ;display alarm while alarm is ringing
	
	;call	check_buzz_bit	    ;check the buzz_bit to set it if it was clear and to clear it if it was set
	BTG	buzz_bit, 0
	
	call	buzzer		    ;call buzzer which buzzes when the buzz_bit is set

	return	
		
;check_buzz_bit:
;	btfsc	buzz_bit, 0		;check if buzz bit is set
;	bra	clear_buzz_bit		;branch to set it if it isnt set
;	bra	set_buzz_bit		;branch to clear it if it is set
;clear_buzz_bit:	
;	bcf	buzz_bit, 0		;clear buzz_bit 
;	return
;set_buzz_bit:
;	bsf	buzz_bit, 0		;set buzz_bit
;	return
	
buzzer:	
	;Initialize
	bcf	TRISB, 6		;set RB6 to output
	
	movlw	0x64
	movwf	buzzer_counter_1	;values for buzzer counter that counts down a second and buzzes at every count
	movlw	0x1E
	movwf	buzzer_counter_2	;	"

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
	
	call	buzz_loop_2		;call second loop at every count, nested loops
	movlw	0x1E
	movwf	buzzer_counter_2	;reset count down value for second loop
	
	decfsz	buzzer_counter_1	;decrease till 0 and skip when 0
	bra	buzz_loop_1
	return		
buzz_loop_2:
	call	buzz_sequence		;buzz at every count
	decfsz	buzzer_counter_2
	bra	buzz_loop_2
	return

buzz_sequence:	
check_if_buzz:
	btfss	buzz_bit, 0
	bra no_buzz
	bra yes_buzz
	
no_buzz: 
	call delay_buzzer
	call delay_buzzer
	return
yes_buzz:	
	bsf	LATB, 6	;Ouput high
	call	delay_buzzer
	bcf	LATB, 6	;Ouput low
	call	delay_buzzer
	return	
    
delay_buzzer:
    movlw   0x20	    ;half the time period long delay
    call    LCD_delay_x4us
    return

    
cancel_alarm:
	clrf	Alarm_buzz
	return
	
snooze_alarm:
	clrf    Alarm_buzz
	call	Display_snooze
	movlw	0x05
	addwf	alarm_min
	movlw	0x3B
	CPFSGT	alarm_min
	return
	movlw	0x3C
	subwf	alarm_min, 1
	incf	alarm_hrs
	movlw	0x17
	CPFSGT	alarm_hrs
	return
	movlw	0x18
	subwf	alarm_hrs, 1
	return

end


