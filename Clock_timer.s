#include <xc.inc>
	
extrn	Write_Decimal_to_LCD
extrn	operation_check, alarm_on
extrn	LCD_Write_Character, LCD_Set_Position, LCD_Send_Byte_I, LCD_delay_ms, LCD_Clear, LCD_Send_Byte_D, LCD_Write_Hex
extrn	Keypad, keypad_val, keypad_ascii
extrn	write_alarm, write_time, alarm_on
global	Clock, Clock_setup, delay, check_60, check_24, alarm_sec, alarm_min, alarm_hrs, clock_sec, clock_min, clock_hrs, rewrite_clock
    
psect	udata_acs   
	
clock_sec:  ds  1
clock_min:  ds  1
clock_hrs:  ds  1
    
alarm_sec:  ds  1
alarm_min:  ds  1
alarm_hrs:  ds  1
    
check_60:   ds  1
check_24:   ds  1

    psect	Clock_timer_code, class=CODE
	
Clock_setup: 
	movlw  0x00
	movwf   clock_sec
	movwf   clock_min
	movwf   clock_hrs
	movwf	alarm_sec
	movwf	alarm_min
	movwf	alarm_hrs
	
	movlw	0x3C
	movwf	check_60
	movlw	0x18
	movwf	check_24
	call	rewrite_clock
	
	movlw	10000111B	; Set timer1 to 16-bit, Fosc/4/256
	movwf	T0CON, A	; = 62.5KHz clock rate, approx 1sec rollover
	movlw	0x0B
	movwf	TMR0H, A
	movlw	0xDB
	movwf	TMR0L, A
	bsf	TMR0IE		; Enable timer0 interrupt
	bsf	GIE		; Enable all interrupts
	
	clrf	alarm_on, 0
	
	return	

Clock:	
	btfss	TMR0IF		; check that this is timer0 interrupt
	retfie	f		; if not then return
	movlw	0x0B
	movwf	TMR0H, A
	movlw	0xDB
	movwf	TMR0L, A
	bcf	TMR0IF		; clear interrupt flag
	call	clock_inc	; increment PORTJ 
	call	compare_alarm
	btfss	operation_check, 0
	call	rewrite_clock
	retfie	f		; fast return from interrupt
	
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
	call buzzer ;WRITE THIS
	return
buzzer:
	call LCD_Clear
	call delay
	call delay
	call delay
	call write_alarm
	call delay
	call delay
	call	LCD_Clear
	return

rewrite_clock: 
	call write_time
	
	movlw	00001100B
	call LCD_Send_Byte_I
	
	call delay
	
	movlw	10000110B
	call LCD_Set_Position	    ;set position in LCD to first line, first character
	
	movf	clock_hrs, W
	call Write_Decimal_to_LCD	    ;write hours
	
	movlw	0x3A
	call	LCD_Write_Character ;write ':'
	
	movf	clock_min, W
	call Write_Decimal_to_LCD	    ;write minutes
	
	movlw	0x3A
	call	LCD_Write_Character ;write ':'
	    
	movf	clock_sec, W
	call Write_Decimal_to_LCD	    ;write seconds
	return
	
clock_inc:	
	incf	clock_sec   ;increment clock_sec
	movf	clock_sec, W	
	cpfseq	check_60    ;check if clock_sec is equal to 60
	return		    ;return if it isn't equal
	clrf	clock_sec   ;if it is equal, set to 0
	incf	clock_min   ;and increment clock_min
	movf	clock_min, W	
	cpfseq	check_60    ;check if clock_min is equal to 60
	return		    ;return if clock_min is not equal to 60
	clrf	clock_min   ;if it is equal to 60, set to 0
	incf	clock_hrs   ;and increment clock_hrs
	movf	clock_hrs, W	
	cpfseq	check_24    ;check if clock_hrs is equal to 24
	return		    ;return if it isn't
	clrf	clock_hrs   ;if it is equal, then set to 0
	return		    ; and return

delay: movlw	0x40
	call LCD_delay_ms
	return

    end
