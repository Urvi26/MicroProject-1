#include <xc.inc>
	
extrn	Write_Decimal_LCD, LCD_Clear    
global	Clock, Clock_Setup
    
psect	udata_acs   
clock_sec:	ds  1
clock_min:	ds  1
clock_hrs:	ds  1
check_60:	ds  1
check_24:	ds  1
    
    psect	Clock_timer_code, class=CODE

clock_input_sec:	
	movwf	clock_sec
clock_input_min:
	movwf	clock_min
clock_input_hrs:
	movwf	clock_hrs
	
rewrite_clock: 
	call	LCD_Clear
	movf	clock_sec, W
	call	Write_Decimal_LCD
	movf	clock_min, W
	call	Write_Decimal_LCD
	movf	clock_hrs, W
	call	Write_Decimal_LCD

Clock_Setup: 
	movlw  0x00
	movwf   clock_sec
	movwf   clock_min
	movwf   clock_hrs
	movlw	0x3C
	movwf	check_60
	movlw	0x18
	movwf	check_24
    
	movlw	10000111B	; Set timer1 to 16-bit, Fosc/4/256
	movwf	T0CON, A	; = 62.5KHz clock rate, approx 1sec rollover
	movlw	0x0B
	movwf	TMR0H, A
	movlw	0xDB
	movwf	TMR0L, A
	bsf	TMR0IE		; Enable timer0 interrupt
	bsf	GIE		; Enable all interrupts
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

Clock:	
	btfss	TMR0IF		; check that this is timer0 interrupt
	retfie	f		; if not then return
	call	clock_inc	; increment PORTJ 
	call	rewrite_clock
	bcf	TMR0IF		; clear interrupt flag
	retfie	f		; fast return from interrupt
	
    end


