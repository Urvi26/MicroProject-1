  #include<xc.inc>

global	Keypad
psect	udata_acs   ; named variables in access ram
col_input:	ds 1	; reserve 1 byte for variable Col_input
row_input:  ds 1
keypad_input: ds 1
delay_val: ds 1
keypad_char: ds 1 
 
psect	keypad_code,class=CODE	

Keypad:
	call Keypad_Setup
	
	    ;trigger and read column input;
	movlw	0x0f
	movwf	TRISE	;set E0-E3 as input and E4-E7 as output
	call delay
	movff	PORTE, col_input    ;store column input in col_input
	
	    ;trigger and read row input;
	movlw	0xf0
	movwf	TRISE	;set E4-7 as input, E0-E3 as output
	call	delay
	movff	PORTE, row_input    ;store row input in row_input
	
	    ;add row and column input;
	movf	row_input, W, A
	addwf	col_input, 0, 0  ; add row and column bytes and store result in 0x24
	movwf	keypad_input	; check if added value is correct by reading onto PORTH
	    
	    ;check input to get character ascii code (stored in 0x26);
	call check
	return 	
	
Keypad_Setup: 
	movlw	0x10	; delay value
	movwf   delay_val	; moving delay value into delay file registers
		
	banksel	PADCFG1	; selecting bank register
	bsf REPU	; setting PORTE pull-ups on
	movlb	0x00	;setting bank register back to 0
	call delay
	
	clrf	LATE	;clear LATE
	call delay
	return
	
check:	movlw	0x00 ;ascii for null
	movwf	keypad_char, A
	movlw	11111111B
	CPFSLT	keypad_input
	return

	movlw	0x31	;ascii for 1
	movwf	keypad_char, A
	movlw	11101110B   ;check value into W
    	CPFSLT	keypad_input
	return
	
	movlw	0x32	;ascii for 2
	movwf	keypad_char, A
	movlw	11101101B
	CPFSLT	keypad_input
	return
	
	movlw	0x33	;aascii for 3
	movwf	keypad_char, A
	movlw	11101011B   ;check value into W
    	CPFSLT	keypad_input
	return
 
	movlw	0x46	;ascii for F
	movwf	keypad_char, A
	movlw	11100111B
	CPFSLT	keypad_input
	return
	
	movlw	0x34	;ascii for 4
	movwf	keypad_char, A
	movlw	11011110B   ;check value into W
    	CPFSLT	keypad_input
	return
 
	movlw	0x35	;ascii for 5
	movwf	keypad_char, A
	movlw	11011101B
	CPFSLT	keypad_input
	return
	
	movlw	0x36	;ascii for 6
	movwf	keypad_char, A
	movlw	11011011B   ;check value into W
    	CPFSLT	keypad_input
	return
 
	movlw	0x45	;ascii for E
	movwf	keypad_char, A
	movlw	11010111B
	CPFSLT	keypad_input
	return
	
	movlw	0x37	;ascii for 7
	movwf	keypad_char, A
	movlw	10111110B   ;check value into W
	CPFSLT	keypad_input
	return
 
	movlw	0x38	;ascii for 8
	movwf	keypad_char, A
	movlw	10111101B
	CPFSLT	keypad_input
	return
	
	movlw	0x39 ;ascii for 9   
	movwf	keypad_char, A
	movlw	10111011B   ;check value into W
    	CPFSLT	keypad_input
	return
	
	movlw	0x44	;ascii for D
	movwf	keypad_char, A
	movlw	10110111B   ;check value into W
    	CPFSLT	keypad_input
	return
 
	movlw	0x41	;ascii for A
	movwf	keypad_char, A
	movlw	01111110B
	CPFSLT	keypad_input
	return
	
	movlw	0x30	;ascii for 0
	movwf	keypad_char, A
	movlw	01111101B   ;check value into W
	CPFSLT	keypad_input
	return
 
	movlw	0x42	;ascii for B
	movwf	keypad_char, A
	movlw	01111011B
	CPFSLT	keypad_input
	return
	
	movlw	0x43	;ascii for C
	movwf	keypad_char, A
	movlw	01110111B   ;check value into W
    	CPFSLT	keypad_input
	return
	movlw	0x00
	movwf	keypad_char
	return

delay:	decfsz	delay_val
	bra delay
	return

	end 


