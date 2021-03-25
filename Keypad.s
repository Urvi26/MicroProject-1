
    #include<xc.inc>

global	Keypad, keypad_val, keypad_ascii

extrn	LCD_delay_x4us
    
psect	udata_acs   ; named variables in access ram
col_input:	ds 1	; reserve 1 byte for variable Col_input
row_input:  ds 1
keypad_input: ds 1
delay_val: ds 1
keypad_ascii: ds 1
keypad_val: ds 1
 
psect	keypad_code,class=CODE	

Keypad:
	call Keypad_Setup
	
	    ;trigger and read column input;
	movlw	0x0f
	movwf	TRISE, A	;set E0-E3 as input and E4-E7 as output
	call delay_keypad
	movff	PORTE, col_input    ;store column input in col_input
	
	    ;trigger and read row input;
	movlw	0xf0
	movwf	TRISE, A	;set E4-7 as input, E0-E3 as output
	call	delay_keypad
	movff	PORTE, row_input    ;store row input in row_input
	
	    ;add row and column input;
	movf	row_input, W, A
	addwf	col_input, 0, 0  ; add row and column bytes and store result in 0x24
	movwf	keypad_input, A	; check if added value is correct by reading onto PORTH
	    
	    ;check input to get character ascii code (stored in 0x26);
	call check
	return 	
	
Keypad_Setup: 
	movlw	0x10	; delay value
	movwf   delay_val, A	; moving delay value into delay file registers
		
	banksel	PADCFG1	; selecting bank register
	bsf REPU	; setting PORTE pull-ups on
	movlb	0x00	;setting bank register back to 0
	call delay_keypad
	
	clrf	LATE, A	;clear LATE
	call delay_keypad
	return
	
check:	
check_null: 
	movlw	11111111B
	CPFSEQ	keypad_input, A
	bra check1
	movlw	0xff
	movwf	keypad_val, A	
	movlw	0x00	;ascii for null
	movwf	keypad_ascii, A
	return
	
check1:	movlw	11101110B	;move keypad value expected from 1 button into W
    	CPFSEQ	keypad_input, A	;check if keypad output equal to 1 expected output
	bra check2		;branch to next check if not equal
	movlw	0x01		;if equal set keypad_val to 0x01
	movwf	keypad_val, A	
	movlw	0x31		;ascii	code for 1
	movwf	keypad_ascii, A	;set keypad_ascii to 1 ascii code
	return
	
check2:	movlw	11101101B
	CPFSEQ	keypad_input, A
	bra	check3
	movlw	0x02	
	movwf	keypad_val, A
	movlw	0x32		;ascii for 2
	movwf	keypad_ascii, A
	return
	
check3:	movlw	11101011B  
    	CPFSEQ	keypad_input, A
	bra checkF
	movlw	0x03
	movwf	keypad_val, A
	movlw	0x33		;aascii for 3
	movwf	keypad_ascii, A
	return
 
checkF:	movlw	11100111B
	CPFSEQ	keypad_input, A
	bra check4
	movlw	0x0F
	movwf	keypad_val, A
	movlw	0x46		;ascii for F
	movwf	keypad_ascii, A
	return
	
check4:	movlw	11011110B   
    	CPFSEQ	keypad_input, A
	bra check5
	movlw	0x04	
	movwf	keypad_val, A
	movlw	0x34		;ascii for 4
	movwf	keypad_ascii, A
	return
 
check5:	movlw	11011101B
	CPFSEQ	keypad_input, A
	bra check6
	movlw	0x05	
	movwf	keypad_val, A
	movlw	0x35		;ascii for 5
	movwf	keypad_ascii, A
	return
	
check6:	movlw	11011011B  
    	CPFSEQ	keypad_input, A
	bra checkE
	movlw	0x06	
	movwf	keypad_val, A
	movlw	0x36		;ascii for 6
	movwf	keypad_ascii, A
	return
 
checkE:	movlw	11010111B
	CPFSEQ	keypad_input, A
	bra check7
	movlw	0x0E	
	movwf	keypad_val, A
	movlw	0x45		;ascii for E
	movwf	keypad_ascii, A
	return
	
check7:	movlw	10111110B 
	CPFSEQ	keypad_input, A
	bra check8	
	movlw	0x07	
	movwf	keypad_val, A
	movlw	0x37		;ascii for 7
	movwf	keypad_ascii, A
	return
 
check8:	movlw	10111101B
	CPFSEQ	keypad_input, A
	bra check9
	movlw	0x08	
	movwf	keypad_val, A
	movlw	0x38		;ascii for 8
	movwf	keypad_ascii, A
	return
	
check9:	movlw	10111011B   
    	CPFSEQ	keypad_input, A
	bra checkD
	movlw	0x09   
	movwf	keypad_val, A
	movlw	0x39		;ascii for 9 
	movwf	keypad_ascii, A
	return
	
checkD:	movlw	10110111B  
    	CPFSEQ	keypad_input, A
	bra checkA
	movlw	0x0D	
	movwf	keypad_val, A
	movlw	0x44		;ascii for D
	movwf	keypad_ascii, A
	return
 
checkA:	movlw	01111110B
	CPFSEQ	keypad_input, A
	bra check0
	movlw	0x0A	
	movwf	keypad_val, A
	movlw	0x41		;ascii for A
	movwf	keypad_ascii, A
	return
	
check0:	movlw	01111101B  
	CPFSEQ	keypad_input, A
	bra checkB
	movlw	0x00	
	movwf	keypad_val, A
	movlw	0x30		;ascii for 0
	movwf	keypad_ascii, A
	return
 
checkB: movlw	01111011B
	CPFSEQ	keypad_input, A
	bra checkC
	movlw	0x0B	
	movwf	keypad_val, A
	movlw	0x42		;ascii for B
	movwf	keypad_ascii, A
	return
	
checkC:	movlw	01110111B   
    	CPFSEQ	keypad_input, A
	bra null
	movlw	0x0C	
	movwf	keypad_val, A
	movlw	0x43		;ascii for C
	movwf	keypad_ascii, A
	return
	
null:	movlw	0x00
	movwf	keypad_ascii, A
	movlw	0xff
	movwf	keypad_val, A
	return
	
	
delay_keypad:	
	movlw	0x10
	call	LCD_delay_x4us
	;decfsz	delay_val
	;bra delay_keypad
	return

	end 


