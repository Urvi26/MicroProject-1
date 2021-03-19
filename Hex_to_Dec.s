#include <xc.inc>

extrn	LCD_Setup, LCD_Clear, LCD_Set_Position, LCD_Write_High_Nibble ; external LCD subroutines
global	Write_Decimal_LCD
    
psect	udata_acs   ; reserve data space in access ram
counter:    ds 1    ; reserve one byte for a counter variable
delay_count:ds 1    ; reserve one byte for counter in the delay routine

bigl: ds 1	;8x16, 16 bit number low byte input
bigh: ds 1	;8x16, 16 bit number high byte input
small: ds 1	;8x16, 8 bit number input

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

psect	hextodecimal_code,class=CODE
    
    ;convert hex to decimal;
Write_Decimal_LCD:
	
	;first multiplication;
	;preparing inputs for multiplication
	movwf	small	    ;move hex time to small
		
	movlw	0xf6	    ;move conversion factor 0x28f6 to big 
	movwf	bigl
	movlw	0x28
	movwf	bigh
	
	call  multiply16x8   ;multiply hex time by hex to dec conversion factor
		
	;second multiplication;
	;preparing inputs for multiplication
	movlw	0x0A	    ;move dec 10 to ein (eight bit input)
	movwf	ein    
	
	movlw	0x0f  ;move remaining result of time x 0x28f6  multiplication into inputs
	andwf	seouth, 0, 1	    ;setting first digit of seouth to 0
	movwf	tinh	    ;and move to input
	movff	seoutm, tinm
	movff	seoutl, tinl
	
	call	multiply24x8	;multiplication of remaining r§ digits of first multiplication by 0x0A
	
	movf	teouth, W
	call	LCD_Write_High_Nibble	;display most significant digit of multiplication on LCD
	
	;third multiplication;
	;preparing inputs for multiplication
	movlw	0x0f	    
	andwf   teouth, 0, 1		;setting first digit of second multiplication to 0
	movwf	tinh		
	movff	teoutl, tinm
	movff	teoutll, tinl
	
	call	multiply24x8	;multiplication of remainder of second multiplication with 0x0A
	
	movf	teouth, W
	call	LCD_Write_High_Nibble	;display most significant digit of multiplication to LCD
	return
	
multiply24x8:		;multiplication of 24 bit number by 8 bit number
	
	movf    tinl, W	    ;multiplying 8 bit no. by lowest byte of 24 bit
	mulwf   ein
	movff   PRODL, teoutll
	movff   PRODH, teoutl

	movff   ein, small  
	movff   tinm, bigl
	movff   tinh, bigh
	call    multiply16x8	;multiplying 8 bit no. by highest two byte of 24 bit
	movff   seoutl, teouti
	movff   seoutm, teouth
	movff   seouth, teouthh

	movf    teouti, W	;adding two multiplications together
	addwf   teoutl, 1, 0

	movlw   0x00
	addwfc  teouth, 1,0

	movlw   0x00
	addwfc  teouthh,   1,0
	return

multiply16x8:	
    
	    ;multiplying 8bit number with least sig byte of 16bit number
	movf	small, W
	mulwf	bigl	    ;multiply W with bigl
	movff	PRODL, seoutl ;store product in file registers
	movff	PRODH, seoutm
	
	    ;multiplying 8 bit number with most sig byte of 16 bit number
	movf	small, W
	mulwf	bigh	;multiply W with bigh
	movff	PRODL, seouti
	movff	PRODH, seouth
	
	    ;adding products together to get final product;
	movf	seouti, W
	addwf	seoutm, 1, 0  ; add most sig of first product with least sig of second product and store in 0x21
	
	movlw	0x00
	addwfc	seouth, 1, 0  ;add carry bit to most sig bit of second product and store in 0x23
	return

	; a delay subroutine if you need one, times around loop in delay_count
delay:	decfsz	delay_count, A	; decrement until zero
	bra	delay
	return
	
	end


