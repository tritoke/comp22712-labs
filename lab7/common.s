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

	; save R0
	MOV	R3, R0
	; print the equals sign
	MOV	R0, #'='
	SVC	SVC_PrintC
	; restore R0
	MOV	R0, R3

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
; 	R0[11:8] = ROW_147
; 	R0[7: 4] = ROW_258
; 	R0[3: 0] = ROW_369
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

; resets the queue
reset_queue
	PUSH	{R0-R2}
	; first reset each element of the queue
	MOV	R0, #0
	MOV	R1, #0
	LDR	R2, =key_queue

reset_keyq_loop
	; store 0 to each queue item
	STR	R0, [R2, R1]

	; check loop condition
	ADD	R1, R1, #1
	CMP	R1, #KEY_QUEUE_CAPACITY
	BLO	reset_keyq_loop

	; reset head / tail / num_queued
	LDR	R1, =key_queue_head
	STR	R0, [R1]
	LDR	R1, =key_queue_tail
	STR	R0, [R1]
	LDR	R1, =key_queue_num_queued
	STR	R0, [R1]

	; return
	POP	{R0-R2}
	MOV	PC, LR

; adds a keypress from R0 to the key queue
enqueue_keypress
	PUSH	{R0-R2}

	; load in the base address of the queue
	LDR	R1, =key_queue

	; load in the head index of the queue
	LDR	R2, =key_queue_head
	LDR	R2, [R2]

	; write the character to the queue head
	STRB	R0, [R1, R2]

	; leaving R0, R1 as scratch registers

	; now that we have performed the store, increment pointers
	; always increment the head
	ADD	R2, R2, #1
	; and wrap it modulo queue size
	AND	R2, R2, #KEY_QUEUE_MASK
	; and store the head back to memory
	LDR	R0, =key_queue_head
	STR	R2, [R0]

	; test if the queue is full :: num_queued == KEY_QUEUE_CAPACITY
	LDR	R2, =key_queue_num_queued
	LDR	R2, [R2]
	CMP	R2, #KEY_QUEUE_CAPACITY

	; if it is not full then branch away
	BNE	queue_not_full

	; if it is full then advance the tail as well
	LDR	R1, =key_queue_tail
	LDR	R2, [R1]
	ADD	R2, R2, #1
	; wrap the tail
	AND	R2, R2, #KEY_QUEUE_MASK
	; store the tail back
	STR	R2, [R1]

	; and return
	B	enqueue_return

queue_not_full
	; load the number of elements queued
	LDR	R1, =key_queue_num_queued
	LDR	R2, [R1]
	; increment the number of elements queued
	ADD	R2, R2, #1
	; store the value back to memory
	STR	R2, [R1]

enqueue_return
	; restore registers and return
	POP	{R0-R2}
	MOV	PC, LR

; returns the next keypress in R0 or 0 if no keypresses are available
dequeue_keypress
	PUSH	{R1,R2}
	
	; first check whether there are actually any keypresses available
	LDR	R1, =key_queue_num_queued
	LDR	R2, [R1]
	; branch to special case if there are no keypresses
	CMP	R2, #0
	BLE	no_key_pressed

	; otherwise decrement the number queued
	SUB	R2, R2, #1

	; and store it back to memory
	STR	R2, [R1]

	; get the actual keypress from the queue
	LDR	R2, =key_queue_tail
	LDR	R2, [R2]
	LDR	R1, =key_queue
	LDRB	R0, [R1, R2]

	; finally update the head pointer
	ADD	R2, R2, #1
	AND	R2, R2, #KEY_QUEUE_MASK
	LDR	R1, =key_queue_tail

	; store it's value back to memory
	STR	R2, [R1]

	; and return
	B	dequeue_return

no_key_pressed
	MOV	R0, #0

dequeue_return
	POP	{R1,R2}
	MOV	PC, LR
