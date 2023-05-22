; ###########################################################
;             ____ ___  __  __ __  __  ___  _   _ 
;            / ___/ _ \|  \/  |  \/  |/ _ \| \ | |
;           | |  | | | | |\/| | |\/| | | | |  \| |
;           | |__| |_| | |  | | |  | | |_| | |\  |
;            \____\___/|_|  |_|_|  |_|\___/|_| \_|
; ###########################################################

; include the BCD conversion function
INCLUDE	bcd_convert.s

; bcd convert but it saves and restores registers
bcd_convert_safe
	PUSH	{R1-R6,LR}
	BL	bcd_convert
	POP	{R1-R6,PC}

; prints a hex character representing the lowest nibble in R0
printhexc
	PUSH	{R0,LR}
	AND	R0, R0, #&F		; mask off everything except the lower 4 bits
	CMP	R0, #10			; compare to 10
	ADDLO	R0, R0, #'0'		; if it is unsigned lower then add the character value of 0
	ADDHS	R0, R0, #'a' - 10	; else add the char value of 'A' - 10
	BL	printc
	POP	{R0,PC}

; get the address of the font glyph for character in R0 - returns result in R0
getchad	PUSH	{R1}
	SUB	R0, R0, #&20 ; get offset of char from space
	; multiply by seven
	; R0 = (R0 << 3) - R0 -> R0 * (8 - 1) -> 7 * R0
	RSB	R0, R0, R0, LSL #3
	LDR	R1, =font
	ADD	R0, R0, R1   ; add the offset to the base address
	POP	{R1}
	MOV	PC, LR
