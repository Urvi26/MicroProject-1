#include <xc.inc>
	
extrn	Write_Decimal_to_LCD  
extrn	operation_check
      
extrn	Temp
extrn	Check_Alarm
extrn	Write_colon, Write_Time, Write_Temp
extrn	LCD_Set_to_Line_2, LCD_Set_to_Line_1
    
global	clock_sec, clock_min, clock_hrs
global	Clock, Clock_Setup, Rewrite_Clock
global	skip_byte, check_24, check_60
    
psect	udata_acs
clock_hrs: ds 1
clock_min: ds 1
clock_sec: ds 1

timer_start_value_1:	ds 1
timer_start_value_2:	ds 1
    
check_60:	ds  1	;reserving byte to store decimal 60 in hex
check_24:	ds  1	;reserving byte to store decimal 24 in hex

psect	Clock_code, class=CODE

Clock_Setup: 
	movlw	0x00		;setting start time to 00:00:00
	movwf   clock_sec, A
	movwf   clock_min, A
	movwf   clock_hrs, A
	
	call	Rewrite_Clock
	
	movlw	0x3C		;setting hex values for decimal 24 and 60 for comparison
	movwf	check_60, A
	movlw	0x18
	movwf	check_24, A
	
	movlw	0x0B
	movwf	timer_start_value_1, A
	movlw	0xDB
	movwf	timer_start_value_2, A
	
	movlw	10000111B	; Set timer1 to 16-bit, Fosc/4/256
	movwf	T0CON, A	; = 62.5KHz clock rate, approx 1sec rollover
	bsf	TMR0IE		; Enable timer0 interrupt
	bsf	GIE		; Enable all interrupts

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

Rewrite_Clock:
	call	LCD_Set_to_Line_1
	call	Write_Time	    ;write 'Time: ' to LCD
	
	movf	clock_hrs, W, A	    ;write hours time to LCD as decimal
	call	Write_Decimal_to_LCD  
	call	Write_colon	    ;write ':' to LCD
	
	movf	clock_min, W, A	    ;write minutes time to LCD as decimal
	call	Write_Decimal_to_LCD
	call	Write_colon	    ;write ':' to LCD
	
	movf	clock_sec, W, A	    ;write seconds time to LCD as decimal
	call	Write_Decimal_to_LCD
	call	LCD_Set_to_Line_2
	
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
	    