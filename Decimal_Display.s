#include <xc.inc>

extrn	LCD_Setup, LCD_Clear, LCD_Set_Position, LCD_Write_High_Nibble ; external LCD subroutines
global	Write_Decimal_to_LCD
    
psect	udata_acs   ; reserve data space in access ram
bigl:	ds 1	;8x16, 16 bit number low byte input
bigh:	ds 1	;8x16, 16 bit number high byte input
small:	ds 1	;8x16, 8 bit number input

seoutl:	ds 1	;16x8, low byte output
seoutm:	ds 1	;16x8, middle byte output
seouth:	ds 1	;16x8, high byte output
seouti:	ds 1	;16x8, intermediate used while multiplying

teoutll:ds 1	;24x8, low byte output
teoutl:	ds 1	;24x8, second lowest byte output
teouth:	ds 1	;24x8, second highest byte output
teouthh:ds 1	;24x8, high byte output
teouti:	ds 1	;24x8, intermediate used while multiplying

tinl:	ds 1	;24x8, 24 bit number low byte input
tinm:	ds 1	;24x8, 24 bit number middle byte input
tinh:	ds 1	;24x8, 24 bit number high byte input
ein:	ds 1	;24x8, 8 bit number input

psect	Hextodec_code,class=CODE

    ;convert hex to decimal;
Write_Decimal_to_LCD:
	    ;first multiplication;
	movwf	small, A		;preparing inputs for multiplication
		
	movlw	0xf6
	movwf	bigl, A
	movlw	0x28
	movwf	bigh, A
	
	call  multiply16x8   ;first multiplication of conversion
		
	    ;second multiplication;
	movlw	0x0A	;preparing inputs for multiplication
	movwf	ein, A    
	
	movlw	0x0f
	andwf	seouth, 0, 1	;preparing inputs for multiplication
	movwf	tinh		
	movff	seoutm, tinm
	movff	seoutl, tinl
	
	call	multiply24x8	;second multiplication for conversion
	
	movf	teouth, W
	call	LCD_Write_High_Nibble	;display high nibble of most sig byte of answer
	
	    ;third multiplication;
	movlw	0x0f
	andwf   teouth, 0, 1	    ;preparing inputs for multiplication
	movwf	tinh		
	movff	teoutl, tinm
	movff	teoutll, tinl
	
	call	multiply24x8  ;third multiplication for conversion
	
	movf	teouth, W
	call	LCD_Write_High_Nibble	;display high nibble of most sig byte of answer
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
	
	end
