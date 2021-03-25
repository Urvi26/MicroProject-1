#include <xc.inc>

extrn	LCD_Setup, LCD_Clear, LCD_Set_Position, LCD_Write_High_Nibble ; external LCD subroutines
global	Write_Decimal_to_LCD, multiply16x8, multiply24x8
    
psect	udata_acs   ; reserve data space in access ram
in_16x8_16l:	ds 1	;8x16, 16 bit number low byte input
in_16x8_16h:	ds 1	;8x16, 16 bit number high byte input
in_16x8_8:	ds 1	;8x16, 8 bit number input

out_16x8_l:	ds 1	;16x8, low byte output
out_16x8_m:	ds 1	;16x8, middle byte output
out_16x8_h:	ds 1	;16x8, high byte output
intermediate_16x8:	ds 1	;16x8, intermediate used while multiplying

out_24x8_ll:ds 1	;24x8, low byte output
out_24x8_ul:	ds 1	;24x8, second lowest byte output
out_24x8_lu:	ds 1	;24x8, second highest byte output
out_24x8_uu:ds 1	;24x8, high byte output
intermediate_24x8:	ds 1	;24x8, intermediate used while multiplying

in_24x8_24l:	ds 1	;24x8, 24 bit number low byte input
in_24x8_24m:	ds 1	;24x8, 24 bit number middle byte input
in_24x8_24h:	ds 1	;24x8, 24 bit number high byte input
in_24x8_8:	ds 1	;24x8, 8 bit number input

psect	Hextodec_code,class=CODE

    ;convert hex to decimal;
Write_Decimal_to_LCD:
	    ;first multiplication;
	movwf	in_16x8_8		;preparing inputs for multiplication
		
	movlw	0xf6
	movwf	in_16x8_16l
	movlw	0x28
	movwf	in_16x8_16h
	
	call  multiply16x8   ;first multiplication of conversion
		
	    ;second multiplication;
	movlw	0x0A	;preparing inputs for multiplication
	movwf	in_24x8_8    
	
	movlw	0x0f
	andwf	out_16x8_h, 0, 1	;preparing inputs for multiplication
	movwf	in_24x8_24h		
	movff	out_16x8_m, in_24x8_24m
	movff	out_16x8_l, in_24x8_24l
	
	call	multiply24x8	;second multiplication for conversion
	
	movf	out_24x8_lu, W
	call	LCD_Write_High_Nibble	;display high nibble of most sig byte of answer
	
	    ;third multiplication;
	movlw	0x0f
	andwf   out_24x8_lu, 0, 1	    ;preparing inputs for multiplication
	movwf	in_24x8_24h		
	movff	out_24x8_ul, in_24x8_24m
	movff	out_24x8_ll, in_24x8_24l
	
	call	multiply24x8  ;third multiplication for conversion
	
	movf	out_24x8_lu, W
	call	LCD_Write_High_Nibble	;display high nibble of most sig byte of answer
	return
	
multiply24x8:	
    
	movf    in_24x8_24l, W
	mulwf   in_24x8_8
	movff   PRODL, out_24x8_ll
	movff   PRODH, out_24x8_ul

	movff   in_24x8_8, in_16x8_8
	movff   in_24x8_24m, in_16x8_16l
	movff   in_24x8_24h, in_16x8_16h
	call    multiply16x8
	movff   out_16x8_l, intermediate_24x8
	movff   out_16x8_m, out_24x8_lu
	movff   out_16x8_h, out_24x8_uu

	movf    intermediate_24x8, W
	addwf   out_24x8_ul, 1, 0

	movlw   0x00
	addwfc  out_24x8_lu, 1,0

	movlw   0x00
	addwfc  out_24x8_uu,   1,0
	return

multiply16x8:	
    
	    ;multiplying 8bit number with least sig byte of 16bit number
	movf	in_16x8_8, W
	mulwf	in_16x8_16l	    ;multiply W with 0x21
	movff	PRODL, out_16x8_l ;store product in file registers
	movff	PRODH, out_16x8_m
	
	    ;multiplying 8 bit number with most sig byte of 16 bit number
	movf	in_16x8_8, W
	mulwf	in_16x8_16h	;multiply W with 0x22
	movff	PRODL, intermediate_16x8
	movff	PRODH, out_16x8_h
	
	    ;adding products together to get final product;
	movf	intermediate_16x8, W
	addwf	out_16x8_m, 1, 0  ; add most sig of first product with least sig of second product and store in 0x21
	
	movlw	0x00
	addwfc	out_16x8_h, 1, 0  ;add carry bit to most sig bit of second product and store in 0x23
	return
	
	end	
