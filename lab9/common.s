; ###########################################################
;             ____ ___  __  __ __  __  ___  _   _ 
;            / ___/ _ \|  \/  |  \/  |/ _ \| \ | |
;           | |  | | | | |\/| | |\/| | | | |  \| |
;           | |__| |_| | |  | | |  | | |_| | |\  |
;            \____\___/|_|  |_|_|  |_|\___/|_| \_|
; ###########################################################

; include the BCD conversion function
INCLUDE bcd_convert.s

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

; prints out the total from R0
; returns the number of characters printed in R0
print_total
	PUSH	{R1-R3,LR}
	; first BCD convert the number
	BL	bcd_convert_safe
	; now that we have the number in BCD we can count the number of digits we need to print
	; by shifting it out four bits at a time until the value is zero

	; copy the value to R1, to count the digits
	MOV	R1, R0
	; store the number of digits in R2
	MOV	R2, #0

	; now count the digits and rotate the digits round to the back in R0
digit_count_loop
	; shift a nibble out, setting the z flag
	LSRS	R1, R1, #4
	; increment the counter
	ADD	R2, R2, #1
	; rotate the nibble to the back of R0
	ROR	R0, R0, #4
	; check the z flag
	BNE	digit_count_loop

	; the number of characters printed will be the number of digits + 1
	ADD	R3, R2, #1

	; now that we know the number of digits
	; we can go through and rotate in nibbles from the back of R0, and print them out
digit_print_loop
	ROR	R0, R0, #28
	BL	printhexc
	SUBS	R2, R2, #1
	BNE	digit_print_loop

	; move the result into R0
	MOV	R0, R3
	POP	{R1-R3,PC}

; read a row from the keyboard
; where R0, is one of the ROW_ constants
read_keyboard_row
	; set the row to read from
	SVC	SVC_StoreKbMtx
	; read out the row
	SVC	SVC_ReadKbMtx
	; limit the result to 4 bits so we only get the row information
	AND	R0, R0, #:1111
	; return
	MOV	PC, LR

; bit slices the keyboard into R0
; bits are as follows:
;	R0[11:8] = ROW_147
;	R0[7: 4] = ROW_258
;	R0[3: 0] = ROW_369
read_keyboard_state
	PUSH	{R1,LR}

	; read the "highest" row
	MOV	R0, #ROW_147
	BL	read_keyboard_row

	; store the result in R1
	MOV	R1, R0

	; read the next row
	MOV	R0, #ROW_258
	BL	read_keyboard_row

	; shift the previous result up, and OR in the next row
	ORR	R1, R0, R1, LSL #4

	; read the final keyboard row
	MOV	R0, #ROW_369
	BL	read_keyboard_row

	; shift the previous results up, and OR with the final row
	ORR	R0, R0, R1, LSL #4

	POP	{R1,PC}

; R0 is the value to be added to the key queue
enqueue_keypress
	PUSH	{R0-R7,LR}

	; load in the base address of the queue
	LDR	R2, =key_queue
	LDR	R3, =key_queue_head
	LDR	R4, =key_queue_tail
	LDR	R5, =key_queue_num_queued
	MOV	R6, #KEY_QUEUE_MASK
	MOV	R7, #KEY_QUEUE_CAPACITY

	; perform the enqueue
	BL	_enqueue

	POP	{R0-R7,PC}

; returns the next keypress in R0 or 0 if no keypresses are available
dequeue_keypress
	PUSH	{R1-R5,LR}

	LDR	R2, =key_queue
	LDR	R3, =key_queue_tail
	LDR	R4, =key_queue_num_queued
	MOV	R5, #KEY_QUEUE_MASK

	; perform the dequeue
	BL	_dequeue

	POP	{R1-R5,PC}

; clears the snake direction queue
clear_queue_keypress
	PUSH	{R0-R6,LR}

	LDR	R2, =key_queue
	LDR	R3, =key_queue_head
	LDR	R4, =key_queue_tail
	LDR	R5, =key_queue_num_queued
	LDR	R6, =KEY_QUEUE_CAPACITY

	; perform the clear
	BL	_clear_queue

	POP	{R0-R6,PC}

; R0 is the column to be added
; R1 is the row to be added
enqueue_snake_position
	PUSH	{R0-R7,LR}
	PUSH	{R1}

	; enqueue the column
	LDR	R2, =snake_col_queue
	LDR	R3, =snake_col_queue_head
	LDR	R4, =snake_col_queue_tail
	LDR	R5, =snake_col_queue_num_queued
	LDR	R6, =SNAKE_QUEUE_MASK
	LDR	R7, =SNAKE_QUEUE_CAPACITY
	BL	_enqueue

	; now enqueue the saved row
	POP	{R0}
	LDR	R2, =snake_row_queue
	LDR	R3, =snake_row_queue_head
	LDR	R4, =snake_row_queue_tail
	LDR	R5, =snake_row_queue_num_queued
	BL	_enqueue

	POP	{R0-R7,PC}

; returns the position as:
; R0 -> Column
; R1 -> Row
dequeue_snake_position
	PUSH	{R2-R5,LR}

	; dequeue the row
	LDR	R2, =snake_row_queue
	LDR	R3, =snake_row_queue_tail
	LDR	R4, =snake_row_queue_num_queued
	LDR	R5, =SNAKE_QUEUE_MASK
	BL	_dequeue

	; save it to the stack for later
	PUSH	{R0}

	; dequeue the column
	LDR	R2, =snake_col_queue
	LDR	R3, =snake_col_queue_tail
	LDR	R4, =snake_col_queue_num_queued
	BL	_dequeue

	; pop the saved column into R1
	POP	{R1}

	; return
	POP	{R2-R5,PC}

; clears the two snake position queues
clear_queue_snake_position
	PUSH	{R0-R6,LR}

	; clear the column queue
	LDR	R2, =snake_col_queue
	LDR	R3, =snake_col_queue_head
	LDR	R4, =snake_col_queue_tail
	LDR	R5, =snake_col_queue_num_queued
	LDR	R6, =SNAKE_QUEUE_CAPACITY

	; perform the clear
	BL	_clear_queue

	; clear the row queue
	LDR	R2, =snake_row_queue
	LDR	R3, =snake_row_queue_head
	LDR	R4, =snake_row_queue_tail
	LDR	R5, =snake_row_queue_num_queued
	LDR	R6, =SNAKE_QUEUE_CAPACITY

	; perform the clear
	BL	_clear_queue

	POP	{R0-R6,PC}

; returns the column in R0, and the row in R1
peak_tail_snake_position
	PUSH	{R2-R4,LR}

	LDR	R2, =snake_row_queue
	LDR	R3, =snake_row_queue_tail
	LDR	R4, =snake_row_queue_num_queued

	; peak the row tail
	BL	_peak_tail

	; save the row
	PUSH	{R0}

	LDR	R2, =snake_col_queue
	LDR	R3, =snake_col_queue_tail
	LDR	R4, =snake_col_queue_num_queued

	; peak the tail
	BL	_peak_tail

	; restore the row to R1
	POP	{R1}

	POP	{R2-R4,PC}

; returns the column in R0, and the row in R1
peak_head_snake_position
	PUSH	{R2-R5,LR}

	LDR	R2, =snake_row_queue
	LDR	R3, =snake_row_queue_head
	LDR	R4, =snake_row_queue_num_queued
	LDR	R5, =SNAKE_QUEUE_MASK

	; peak the row head
	BL	_peak_head

	; save the row
	PUSH	{R0}

	LDR	R2, =snake_col_queue
	LDR	R3, =snake_col_queue_head
	LDR	R4, =snake_col_queue_num_queued

	; peak the col head
	BL	_peak_head

	; restore the row to R1
	POP	{R1}

	POP	{R2-R5,PC}

; queues the direction in R0
enqueue_snake_direction
	PUSH	{R0-R7,LR}

	LDR	R2, =snake_direction_queue
	LDR	R3, =snake_direction_queue_head
	LDR	R4, =snake_direction_queue_tail
	LDR	R5, =snake_direction_queue_num_queued
	LDR	R6, =SNAKE_QUEUE_MASK
	LDR	R7, =SNAKE_QUEUE_CAPACITY

	; perform the enqueue
	BL	_enqueue

	POP	{R0-R7,PC}

; returns the direction in R0
dequeue_snake_direction
	PUSH	{R1-R5,LR}

	LDR	R2, =snake_direction_queue
	LDR	R3, =snake_direction_queue_tail
	LDR	R4, =snake_direction_queue_num_queued
	LDR	R5, =SNAKE_QUEUE_MASK

	; perform the dequeue
	BL	_dequeue

	POP	{R1-R5,PC}

; clears the snake direction queue
clear_queue_snake_direction
	PUSH	{R0-R6,LR}

	LDR	R2, =snake_direction_queue
	LDR	R3, =snake_direction_queue_head
	LDR	R4, =snake_direction_queue_tail
	LDR	R5, =snake_direction_queue_num_queued
	LDR	R6, =SNAKE_QUEUE_CAPACITY

	; perform the clear
	BL	_clear_queue

	POP	{R0-R6,PC}

; returns the direction in R0
peak_tail_snake_direction
	PUSH	{R1-R4,LR}

	LDR	R2, =snake_direction_queue
	LDR	R3, =snake_direction_queue_tail
	LDR	R4, =snake_direction_queue_num_queued

	; peak the tail
	BL	_peak_tail

	POP	{R1-R4,PC}

; returns the direction in R0
peak_head_snake_direction
	PUSH	{R1-R5,LR}

	LDR	R2, =snake_direction_queue
	LDR	R3, =snake_direction_queue_head
	LDR	R4, =snake_direction_queue_num_queued
	LDR	R5, =SNAKE_QUEUE_MASK

	; peak the head
	BL	_peak_head

	POP	{R1-R5,PC}

; draws an asset at the given coordinate on the screen
; R0 - Column to draw asset to
; R1 - Row to draw asset to
; R2 - Asset number
draw_asset
	PUSH	{R0-R8}
	; first check the data is all in range
	CMP	R0, #ASSET_COLS
	BHS	invalid_asset

	CMP	R1, #ASSET_ROWS
	BHS	invalid_asset

	CMP	R2, #ASSET_MAX
	BHS	invalid_asset

	; now load the addresses of important variables
	LDR	R8, =AssetAddressTable

	; load the address of the asset to draw
	LDR	R4, [R8, R2, LSL #2]

	; now load the palette
	LDR	R8, =Palette

	; adjust the row and column so that they refer to pixels, not assets
	MOV	R2, #10
	MUL	R0, R0, R2
	MUL	R1, R1, R2
	
	; R5 is the number of pixels extracted from the current byte
	MOV	R5, #pixels_per_byte

	; R6 is the number of pixels written in the current row
	MOV	R6, #0

	; R7 is the number of rows written
	MOV	R7, #0
	
asset_loop
	; if we there are still pixels left in the current byte
	CMP	R5, #pixels_per_byte

	; then go and load a pixel
	BLO	load_pixel

	; otherwise reset R5
	MOV	R5, #0
	; and load a new byte
	LDRB	R3, [R4], #1

load_pixel
	; take the low bits of the byte
	AND	R2, R3, #((1 << bits_per_colour) - 1)
	; load the address of the colour from the palette
	ADD	R2, R8, R2, LSL #2
	; set the pixel on the screen
	SVC	SVC_SetPix
	; shift in the next colour
	LSR	R3, R3, #bits_per_colour
	; and update the number of pixels written
	ADD	R6, R6, #1
	; and update the column
	ADD	R0, R0, #1
	; and update the number of pixels extracted from the current byte
	ADD	R5, R5, #1

	; now check if we have finished the row
	CMP	R6, #10
	; if we haven't then just jump back up
	BLO	asset_loop

	; we've finished the row so update the state
	MOV	R6, #0
	ADD	R7, R7, #1
	ADD	R1, R1, #1
	SUB	R0, R0, #10

	; now check if we have written all the rows
	CMP	R7, #10
	BLO	asset_loop

	; otherwise return
	POP	{R0-R8}
	MOV	PC, LR

; just hang if we get an invalid asset
invalid_asset	B	.

; resets the state of the board
reset_board_state
	PUSH	{R0-R2}
	MOV	R0, #0
	LDR	R1, =board_state
	MOV	R2, #STATE_EMPTY
reset_inner_loop
	STR	R2, [R1, R0]
	ADD	R0, R0, #1

	CMP	R0, #(ASSET_COLS * ASSET_ROWS)
	BLO	reset_inner_loop
	
	; return
	POP	{R0-R2}
	MOV	PC, LR

; set the state of the board at row, column
; R0 -> column
; R1 -> row
; R2 -> state
set_board_state
	PUSH	{R0,R1,R3}

	; calculate the index of the position in the array
	; index = (row * ASSET_COLS) + col
	MOV	R3, #ASSET_COLS
	MUL	R1, R1, R3
	ADD	R0, R0, R1

	; set the address to the new state value
	LDR	R1, =board_state
	STRB	R2, [R1, R0]

	; return
	POP	{R0,R1,R3}
	MOV	PC, LR

; get the state of the board at row, column
; R0 -> column
; R1 -> row
get_board_state
	PUSH	{R1,R2}

	; calculate the index of the position in the array
	; index = (row * ASSET_COLS) + col
	MOV	R2, #ASSET_COLS
	MUL	R1, R1, R2
	ADD	R0, R0, R1

	; load the address of the board state
	LDR	R1, =board_state
	LDRB	R0, [R1, R0]

	; return
	POP	{R1,R2}
	MOV	PC, LR

; seed the RNG from the value in R0
rng_seed
	PUSH	{R1}

	; set the state
	LDR	R1, =xorshift_rng_state
	STR	R0, [R1]
	
	POP	{R1}
	MOV	PC, LR

; initialse the RNG from the value in the free running timer
rng_init
	PUSH	{R0, LR}

	; set the state
	SVC	SVC_GetTime
	; the state cannot be zero so always set the top bit
	ORR	R0, R0, #(1 << 31)
	BL	rng_seed

	POP	{R0, PC}

; generates a 32 bit psuedo-random value in R0
rng_step_state
	PUSH	{R0,R1}

	; https://en.wikipedia.org/wiki/Xorshift
	; algorithm "xor" from p. 4 of Marsaglia, "Xorshift RNGs"

	; load in the RNG state
	LDR	R1, =xorshift_rng_state
	LDR	R0, [R1]
	
	; use R1 as a temp
	; x ^= x << 13
	LSL	R1, R0, #13
	EOR	R0, R0, R1

	; x ^= x >> 17
	LSR	R1, R0, #17
	EOR	R0, R0, R1

	; x ^= x << 5
	LSL	R1, R0, #5
	EOR	R0, R0, R1

	; store the new state back to memory
	LDR	R1, =xorshift_rng_state
	STR	R0, [R1]

	; return
	POP	{R0,R1}
	MOV	PC, LR

rng_generate
	PUSH	{LR}

	; step the internal state of the RNG
	BL	rng_step_state
	
	; the next random value is just the new state
	LDR	R0, =xorshift_rng_state
	LDR	R0, [R0]

	POP	{PC}

; generates a new set of coordinates for the apple
; and stores them to memory
generate_apple_coords
	PUSH	{R2,LR}
	
generate_top
	; generate a random number
	BL	rng_generate

	; mix bits into the lower 16 bits so we can use smaller values
	LSR	R1, R0, #16
	EOR	R0, R0, R1
	LDR	R1, =0xFFFF
	AND	R0, R0, R1

	; now split it into a lower and upper 8 bits
	LSR	R1, R0, #8
	AND	R1, R1, #0xFF
	AND	R0, R0, #0xFF

	; R0 -> lower 8 bits
	; R1 -> upper 8 bits

	; now calculate R0 % ASSET_COLS to get the column
col_mod_loop
	CMP	R0, #ASSET_COLS
	SUBHS	R0, R0, #ASSET_COLS
	BHS	col_mod_loop

	; now calculate R1 % ASSET_ROWS to get the row
row_mod_loop
	CMP	R1, #ASSET_ROWS
	SUBHS	R1, R1, #ASSET_ROWS
	BHS	row_mod_loop

	; check that we haven't generated on a tile which is a snake
	PUSH	{R0}
	BL	get_board_state
	MOV	R2, R0
	POP	{R0}

	; check that we haven't generated it on top of the snake
	CMP	R2, #STATE_SNAKE
	BEQ	generate_top

	POP	{R2,PC}
