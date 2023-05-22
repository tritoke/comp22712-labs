; ########################################################################
;  ______     ______   _____ _   _ _   _  ____ _____ ___ ___  _   _ ____  
; / ___\ \   / / ___| |  ___| | | | \ | |/ ___|_   _|_ _/ _ \| \ | / ___| 
; \___ \\ \ / / |     | |_  | | | |  \| | |     | |  | | | | |  \| \___ \ 
;  ___) |\ V /| |___  |  _| | |_| | |\  | |___  | |  | | |_| | |\  |___) |
; |____/  \_/  \____| |_|    \___/|_| \_|\____| |_| |___\___/|_| \_|____/ 
; ########################################################################
                                                                        
; get the col and row from the cursor
; col in R0, row in R1
getcur	LDR	R0, curcol
	LDR	R1, currow
	MOV	PC, LR

; set the col and row from the cursor
; col in R0, row in R1
; clobbers R0 and R1 - setting them to the wrapped cursor position
setcur	PUSH	{R2}
	; handle wrapping
	; cos backspace we need to handle wrapping backwards
	; if col < 0; col = 0; row -= 1
	CMP	R0, #0
	MOVLT	R0, #0
	SUBLT	R1, R1, #1
	BLT	wcur
	; if col > 40; col = 0; row += 1
	CMP	R0, #CURSOR_COLS
	MOVGE	R0, #0
	ADDGE	R1, R1, #1
wcur	LDR	R2, =curcol
	STR	R0, [R2]
	LDR	R2, =currow
	STR	R1, [R2]
	POP	{R2}
	MOV	PC, LR

; calculate the row and column from the cursor position
; screen is 320x240 which is 40 columns and 30 rows of 8x8 cells
; returns x in R0, y in R1
getpos	LDR	R0, curcol ; get column value
	LDR	R1, currow ; get row value
	LSL	R0, R0, #3 ; col *= 8	
	LSL	R1, R1, #3 ; row *= 8	
	MOV	PC, LR

; set the cursor position from x, y
; takes x in R0, y in R1
setpos	PUSH	{R0-R2,LR}
	LSR	R0, R0, #3 ; col /= 8	
	LSR	R1, R1, #3 ; row /= 8	
	BL	setcur
	POP	{R0-R2,PC}

; writes a string out to the terminal
; takes pointer to string in R0, length of string in R1
printstr
	PUSH	{R0,R1,LR}
	; move arguments to new registers
	MOV	R2, R0
	MOV	R3, R1
mloop	LDRB	R0, [R2], #1
	BL	printc	; we don't need to use the supervisor call here as we are already in supervisor mode
	SUBS	R3, R3, #1
	BNE	mloop
	POP	{R0,R1,PC}

; write character to row, col
; and update the cursor
; takes the character in R0
printc	PUSH	{R0-R3,LR}
	; handle special case characters

	; handle backspace
	CMP	R0, #c_BS
	BLEQ	getcur
	SUBEQ	R0, R0, #1 ; col -= 1
	BEQ	update_cursor

	; handle horizontal tabulate
	CMP	R0, #c_HT
	BLEQ	getcur
	ADDEQ	R0, R0, #1 ; col += 1
	BEQ	update_cursor

	; handle line feed
	CMP	R0, #c_LF
	BLEQ	getcur
	ADDEQ	R1, R1, #1 ; row += 1
	BEQ	update_cursor

	; handle vertial tabulate
	CMP	R0, #c_VT
	BLEQ	getcur
	SUBEQ	R1, R1, #1 ; row -= 1
	BEQ	update_cursor

	; handle form feed
	CMP	R0, #c_FF
	LDREQ	R2, =BG_COLOUR
	BEQ	clear_screen

	; handle carriage return
	CMP	R0, #c_CR

	; final special case so if its false just jump to where we write the character
	BNE	write_character
	BL	getcur
	MOV	R0, #0 ; col = 0

update_cursor
	BL	setcur
	B	printc_ret

clear_screen
	BL	clrscr
	B	printc_ret

write_character
	; get the address of the character
	BL	getchad
	; copy the font address into R2
	MOV	R2, R0
	; get the coordinates to write to
	BL	getpos
	; write the 7 columns from the font 
	MOV	R3, #7
wfclp	BL	wfcol
	; increment the font column and the actual column
	ADD	R0, R0, #1
	ADD	R2, R2, #1
	SUBS	R3, R3, #1
	BNE	wfclp

	; blank column
	; get a pointer to 0x00
	LDR	R2, =zero
	BL	wfcol
	ADD	R0, R0, #1

	; set the new cursor position
	BL	setpos
printc_ret
	POP	{R0-R3,PC}

; write a font column starting at the given row, col
; row in R0, col in R1, font column address in R2
wfcol	PUSH	{R1-R4,LR}
	LDR	R3, [R2]
	MOV	R4, #8     ; go through all 8 bits
cloop	TST	R3, #1     ; test last bit of font
	LDREQ	R2, =BG_COLOUR
	LDRNE	R2, =FG_COLOUR
loaded	BL	setpix
	ADD	R1, R1, #1 ; increment the column
	SUBS	R4, R4, #1 ; subtract one from the counter
	LSR	R3, R3, #1 ; shift the font one bit right
	BNE	cloop
	POP	{R1-R4,PC}

; clears the entire screen
clrscr	PUSH 	{R0,R1,LR}
	; reset the cursor to the start of the screen
	MOV	R0, #0
	MOV	R1, #0
	BL	setcur

	MOV	R0, #CURSOR_ROWS
	MOV	R1, #CURSOR_COLS
	MUL	R1, R0, R1
	; print a space for each cell
	MOV	R0, #&20
print_blank
	BL	printc
	SUBS	R1, R1, #1
	BNE	print_blank

	; reset the cursor to the start of the screen
	MOV	R0, #0
	MOV	R1, #0
	BL	setcur

	POP 	{R0,R1,PC}

; set pixel at x: R0, y: R1 to the pixel value at R2
setpix	PUSH	{R0-R3}
	MOV	R3, #BYTES_PER_PIXEL
	MUL	R0, R0, R3
	MOV	R3, #FBUF_WIDTH
	MUL	R1, R1, R3
	ADD	R0, R0, R1
	; R0 = 960 * y + 3 * x
	LDR	R3, =fbuf
	ADD	R0, R0, R3
	; Address of R0 is the pixel component to write to
	; load and write R value
	LDRB	R3, [R2], #1
	STRB	R3, [R0], #1
	; load and write G value
	LDRB	R3, [R2], #1
	STRB	R3, [R0], #1
	; load and write B value
	LDRB	R3, [R2]
	STRB	R3, [R0]
	POP	{R0-R3}
	MOV	PC, LR

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

; loads the value of the timer peripheral into R0
gettime
	PUSH	{R1}
	LDR	R1, =timer
	LDR	R0, [R1]
	BIC	R0, R0, #&FFFF_FF00
	POP	{R1}
	MOV	PC, LR

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
	BIC	R0, R0, #&FFFF_FFF0	; mask off everything except the lower 4 bits
	CMP	R0, #10			; compare to 10
	ADDLO	R0, R0, #'0'		; if it is unsigned lower then add the character value of 0
	ADDHS	R0, R0, #'a' - 10	; else add the char value of 'A' - 10
	BL	printc
	POP	{R0,PC}

; returns whether the button represented by the constant in R0 is pressed
; returns (result in R0) True if the button is pressed, otherwise False
button_pressed
	PUSH	{R1}
	LDR	R1, =keypad_ABCD
	LDR	R1, [R1]
	TST	R1, R0
	MOVNE	R0, #True
	MOVEQ	R0, #False
	POP	{R1}
	MOV	PC, LR
