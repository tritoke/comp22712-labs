; ###########################################################
;                 __  __    _    ___ _   _ 
;                |  \/  |  / \  |_ _| \ | |
;                | |\/| | / _ \  | ||  \| |
;                | |  | |/ ___ \ | || |\  |
;                |_|  |_/_/   \_\___|_| \_|
; ###########################################################
main	PUSH	{LR}
	; enable timer compare in the control register
	SVC	SVC_ReadCntrl
	ORR	R0, R0, #1
	SVC	SVC_StoreCntrl

	; setup timer compare
	LDR	R0, =INT_TIMER_COMPARE
	SVC	SVC_StoreInts

	MOV	R0, #DIRECTION_READ_ROW
	SVC	SVC_StoreKbDir

	; reset the keypress queue
	BL	reset_queue

	MOV	R6, #False
	MOV	R3, #0
keyboard_loop
	; dequeue a keypress
	BL	dequeue_keypress
	CMP	R0, #0

	; if we dequeued a zeroed then just continue
	BEQ	keyboard_loop

	; first we need to decode the number
	SUB	R1, R0, #'0'
	CMP	R1, #10

	; if it is not a number then rejoin the top of the loop
	BHS	keyboard_loop

	; otherwise save the character for later
	MOV	R2, R0

	; if we haven't printed any numbers don't print a plus
	CMP	R6, #True

	; conditionally print out a plus
	MOVEQ	R0, #'+'
	SVCEQ	SVC_PrintC

	; store true to R6 so we print plusses after this
	MOVNE	R6, #True

	; print the number
	MOV	R0, R2
	SVC	SVC_PrintC

	; add it to the total
	ADD	R3, R3, R1

	; now display the total
	MOV	R0, R3
	BL	print_total

	; use backspace to put the cursor back to where we want to print the next +
	MOV	R1, R0
	MOV	R0, #c_BS
backspace_loop
	; print the backspace character
	SVC	SVC_PrintC
	SUBS	R1, R1, #1
	BNE	backspace_loop

	; and repeat :)
	B	keyboard_loop

main_end
	POP	{PC}
