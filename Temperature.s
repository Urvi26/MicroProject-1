#include <xc.inc>
    
    
;extrn	UART_Setup, UART_Transmit_Message  ; external uart subroutines
extrn	LCD_Setup, LCD_Clear, LCD_Set_Position, LCD_Send_Byte_D
extrn	LCD_Write_Hex, LCD_Write_Character, LCD_Write_Low_Nibble ; external LCD subroutines
extrn	ADC_Setup, ADC_Read		   ; external ADC subroutines
    
global	Temp
	
psect	udata_acs   ; reserve data space in access ram
counter:    ds 1    ; reserve one byte for a counter variable
delay_count:ds 1    ; reserve one byte for counter in the delay routine
kh: ds 1	;k high byte, an input for 16x16
kl: ds 1	;k low byte, an input for 16x16
bigl: ds 1	;8x16, 16 bit number low byte input
bigh: ds 1	;8x16, 16 bit number high byte input
small: ds 1	;8x16, 8 bit number input
ssoutll:ds 1	;16x16, low byte output
ssoutl:	ds 1	;16x16, second lowest byte output
ssouth:	ds 1	;16x16, second highest byte output
ssouthh:ds 1	;16x16, high byte output
ssoutil:ds 1	;16x16, intermediate used while multiplying
ssoutih: ds 1	;16x16, intermediate used while multiplying
seoutl:	ds 1	;16x8, low byte output
seoutm:	ds 1	;16x8, middle byte output
seouth:	ds 1	;16x8, high byte output
seouti:	ds 1	;16x8, intermediate used while multiplying
teoutll:ds 1	;24x8, low byte output
teoutl:	ds 1	;24x8, second lowest byte output
teouth:	ds 1	;24x8, second highest byte output
teouthh:ds 1	;24x8, high byte output
teouti:ds 1	;24x8, intermediate used while multiplying
tinl:ds 1	;24x8, 24 bit number low byte input
tinm:ds 1	;24x8, 24 bit number middle byte input
tinh:ds 1	;24x8, 24 bit number high byte input
ein:ds 1	;24x8, 8 bit number input
    
divisor: ds 1
dividend: ds 1
quotient: ds 1
remainder: ds 1
    
psect	temp_code, class=CODE
	;convert and display binary voltage as decimal on LCD;
Temp:
	;call	LCD_Clear
	;movlw	11000000B
	;call	LCD_Set_Position	; sets position on LCD
	call	ADC_Read	; reads voltage value and stores in ADRESH:ADRESL
	
	call	Conversion	;converst from hex to decimal
	
	movlw	10110010B
	call	LCD_Write_Character
	movlw	0x43
	call	LCD_Write_Character
	
	return
	;goto	measure_loop		; repeat loop so that voltage is displayed continuously as knob is turned
	
	;convert hex to decimal;
Conversion:
	movlw	0x8A	;preparing inputs for multiplication
	movwf	kl
	movlw	0x41	;most sig byte of first number
	movwf	kh
	call  multiply16x16_ADRES   ;first step of conversion
	;movf	ssouthh, W
	;call	LCD_Write_Low_Nibble	;display low nibble of most sig byte of answer
	
	
	
	movlw	0x0A	;preparing inputs for multiplication
	movwf	ein
	
	movff	ssouth, tinh	;preparing inputs for multiplication
	movff	ssoutl, tinm
	movff	ssoutll, tinl
	call	multiply24x8	;second multiplication for conversion
	movf	teouthh, W
	call	LCD_Write_Low_Nibble	;display low nibble of most sig byte of answer
	
	
	
	movff	teouth, tinh	;preparing inputs for multiplication
	movff	teoutl, tinm
	movff	teoutll, tinl
	call	multiply24x8  ;third multiplication for conversion
	movf	teouthh, W
	call	LCD_Write_Low_Nibble	;display low nibble of most sig byte of answer
	
	movlw	0x2E
	call	LCD_Write_Character ;writing decimal point
	
	movff	teouth, tinh	;preparing inputs for multiplication
	movff	teoutl, tinm
	movff	teoutll, tinl
	call	multiply24x8  ;fourth multiplication for conversion
	movf	teouthh, W
	call	LCD_Write_Low_Nibble	;display low nibble of most sig byte of answer
	
	return
	
multiply24x8:	
    
	movf    tinl, W
	mulwf   ein
	movff   PRODL, teoutll
	movff   PRODH, teoutl

	movff   ein, small
	movff   tinm, bigl
	movff   tinh, bigh
	call    multiply16x8
	movff   seoutl, teouti
	movff   seoutm, teouth
	movff   seouth, teouthh

	movf    teouti, W
	addwf   teoutl, 1, 0

	movlw   0x00
	addwfc  teouth, 1,0

	movlw   0x00
	addwfc  teouthh,   1,0
	return

    
multiply16x16_ADRES:
	   ;multiplying least sig byte of first number with second number;
	   
	movff	ADRESL, bigl  ;least sig byte of second number
	movff	ADRESH, bigh  ;most sig byte of second number  
	
	movff	kl, small		;least sig byte of first number into W
	call	multiply16x8	;multiply 
	movff	seoutl, ssoutll	;store product in file registers
	movff	seoutm, ssoutl
	movff	seouth, ssouth
	
	    ;multiplying most sig byte of first number with second number;
	    
	movff	kh, small		;most sig byte of first number
	call	multiply16x8	;multiply
	movff	seoutl, ssoutil	;store product in file registers
	movff	seoutm, ssoutih
	movff	seouth, ssouthh
	
	    ;adding the two products to get final product;
	    
	movf	ssoutil, W	     
	addwfc	ssoutl, 1, 0	;adding second most sig byte of first product with least sig byte of second prod

	movf	ssoutih, W
	addwfc	ssouth, 1, 0  ;adding most sig byte of first product with second least sig byte of second prod, with carry
	
	movlw	0x00
	addwfc	ssouthh, 1, 0  ;add carry to most sig byte of second prod
	return
	
multiply16x8:	
    
	    ;multiplying 8bit number with least sig byte of 16bit number
	movf	small, W
	mulwf	bigl	    ;multiply W with 0x21
	movff	PRODL, seoutl ;store product in file registers
	movff	PRODH, seoutm
	
	    ;multiplying 8 bit number with most sig byte of 16 bit number
	movf	small, W
	mulwf	bigh	;multiply W with 0x22
	movff	PRODL, seouti
	movff	PRODH, seouth
	
	    ;adding products together to get final product;
	movf	seouti, W
	addwf	seoutm, 1, 0  ; add most sig of first product with least sig of second product and store in 0x21
	
	movlw	0x00
	addwfc	seouth, 1, 0  ;add carry bit to most sig bit of second product and store in 0x23
	return

division:
    clrf    quotient
    movff   dividend, remainder
    movf    divisor, W
    CPFSGT  dividend    
    return
    subwf   dividend, 1, 0
    incf    quotient	;clear this somewhere?
    bra	    division
	
	; a delay subroutine if you need one, times around loop in delay_count
delay:
	decfsz	delay_count, A	; decrement until zero
	bra	delay
	return
delaya:
	call delayb
	decfsz	0x1A, A	; decrement until zero
	bra	delaya
	return
delayb:
	decfsz	0x1B, A	; decrement until zero
	bra	delayb
	return
	


