#include <xc.inc>

extrn	LCD_Setup, LCD_Clear, LCD_Set_Position, LCD_Write_High_Nibble ; external LCD subroutines
global	Write_Decimal_to_LCD
    
psect	udata_acs   ; reserve data space in access ram

conversion_l: ds 1	;8x16, 16 bit number low byte input
conversion_u: ds 1	;8x16, 16 bit number high byte input
hex_input: ds 1	;8x16, 8 bit number input

input_16_l: ds 1	;8x16, 16 bit number low byte input
input_16_u: ds 1	;8x16, 16 bit number high byte input
input_8_f16: ds 1	;8x16, 8 bit number input

output_16x8_l:	ds 1	;16x8, low byte output
output_16x8_m:	ds 1	;16x8, middle byte output
output_16x8_u:	ds 1	;16x8, high byte output
output_16x8_i:	ds 1	;16x8, intermediate used while multiplying

input_24_l:ds 1	;24x8, 24 bit number low byte input
input_24_m:ds 1	;24x8, 24 bit number middle byte input
input_24_u:ds 1	;24x8, 24 bit number high byte input
input_8_f24:ds 1	;24x8, 8 bit number input

output_24x8_l:ds 1	;24x8, low byte output
output_24x8_ul:	ds 1	;24x8, second lowest byte output
output_24x8_lu:	ds 1	;24x8, second highest byte output
output_24x8_u:ds 1	;24x8, high byte output
output_24x8_i:ds 1	;24x8, intermediate used while multiplying

psect	Decimal_Display_code,class=CODE
    
    ;write hex to LCD in decimal format;
Write_Decimal_to_LCD:
	movwf	hex_input    ;move hex time to hex_input
		
	movlw	0xf6	    ;move conversion factor 0x28f6 to conversion 
	movwf	conversion_l
	movlw	0x28
	movwf	conversion_u
	
	;first multiplication;
	;preparing inputs for multiplication
	movff	hex_input, input_8_f16     ;set hex_input as 8x16 multiplication 8-bit input
	movff	conversion_l, input_16_l
	movff	conversion_u, input_16_u
  
	call  Multiplication_16x8   ;multiply hex time by hex to dec conversion factor
		
	;second multiplication;
	;preparing inputs for multiplication
	movlw	0x0A	    ;move dec 10 to 24x8 multiplication 8-bit input
	movwf	input_8_f24   
	
	movf	output_16x8_u, W   ;move remaining result of time x 0x28f6  multiplication into inputs
	andlw	0x0f	    ;setting first digit of seouth to 0
	movwf	input_24_u	    ;and move to input
	movff	output_16x8_m, input_24_m
	movff	output_16x8_l, input_24_l
	
	call	Multiplication_24x8	;multiplication of remaining r§ digits of first multiplication by 0x0A
	
	movf	output_24x8_lu, W
	call	LCD_Write_High_Nibble	;display most significant digit of multiplication on LCD
	
	;third multiplication;
	;preparing inputs for multiplication
	movf	output_24x8_lu, W	    
	andlw	0x0f		;setting first digit of second multiplication to 0
	movwf	input_24_u	
	movff	output_24x8_l, input_24_m
	movff	output_24x8_ul, input_24_l
	
	call	Multiplication_24x8	;multiplication of remainder of second multiplication with 0x0A
	
	movf	output_24x8_lu, W
	call	LCD_Write_High_Nibble	;display most significant digit of multiplication to LCD
	return
	
Multiplication_24x8:		;multiplication of 24 bit number by 8 bit number
	
	movf    input_24_l, W	    ;multiplying 8 bit no. by lowest byte of 24 bit
	mulwf   input_8_f24
	movff   PRODL, output_24x8_l
	movff   PRODH, output_24x8_ul

	movff   input_8_f24, input_8_f16 
	movff   input_24_m, input_16_l
	movff   input_24_u, input_16_u
	call    Multiplication_16x8	;multiplying 8 bit no. by highest two byte of 24 bit
	movff   output_16x8_l, output_24x8_i
	movff   output_16x8_m, output_24x8_lu
	movff   output_16x8_u, output_24x8_u

	movf    output_24x8_i, W	;adding two multiplications together
	addwf   output_24x8_ul, 1, 0

	movlw   0x00
	addwfc  output_24x8_lu, 1,0

	movlw   0x00
	addwfc  output_24x8_u,   1,0
	return

Multiplication_16x8:	
    
	    ;multiplying 8bit number with least sig byte of 16bit number
	movf	input_8_f16 , W
	mulwf	input_16_l	    ;multiply W with bigl
	movff	PRODL, output_16x8_l ;store product in file registers
	movff	PRODH, output_16x8_m
	
	    ;multiplying 8 bit number with most sig byte of 16 bit number
	movf	input_8_f16, W
	mulwf	input_16_u	;multiply W with bigh
	movff	PRODL, output_16x8_i
	movff	PRODH, output_16x8_u
	
	    ;adding products together to get final product;
	movf	output_16x8_i, W
	addwf	output_16x8_m, 1, 0  ; add most sig of first product with least sig of second product and store in 0x21
	
	movlw	0x00
	addwfc	output_16x8_u, 1, 0  ;add carry bit to most sig bit of second product and store in 0x23
	return


	
	end