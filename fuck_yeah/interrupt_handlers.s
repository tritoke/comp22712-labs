; ###########################################################
;  ___ _   _ _____ _____ ____  ____  _   _ ____ _____ ____  
; |_ _| \ | |_   _| ____|  _ \|  _ \| | | |  _ \_   _/ ___| 
;  | ||  \| | | | |  _| | |_) | |_) | | | | |_) || | \___ \ 
;  | || |\  | | | | |___|  _ <|  _ <| |_| |  __/ | |  ___) |
; |___|_| \_| |_| |_____|_| \_\_| \_\\___/|_|    |_| |____/ 
; ###########################################################

InterruptHandler
	SUB	LR, LR, #4
	PUSH	{R0-R6, LR}

	; now determine the type of interrupt - button vs timer compare

	; read the interrupt bits
	BL	read_interrupt_bits

	; test if timer compare is high
	; 	high -> timer compare
	;	low -> button
	TST	R0, #INT_TIMER_COMPARE

	; handle the timer compare
	BNE	int_handle_timer_compare

	; handle the buttons
int_handle_button
	; I don't handle the buttons at the moment because they aren't enabled
	B	.

int_handle_timer_compare
	; increment the global counter
	LDR	R1, =timer_counter
	LDR	R0, [R1]
	ADD	R0, R0, #1
	STR	R0, [R1]

	; first read the keyboard state
	BL	read_keyboard_state

	; load which keys are currently pressed
	; now loop through each key and increment the debounce counter for it
	MOV	R1, #0
	LDR	R2, =key_debounce_counters
bit_slice_loop
	; shift bits out of the keyboard state
	; the lower bit is now the CC or carry clear flag
	LSRS	R0, R0, #1

	; load the load the current debounce counter
	LDRB	R3, [R2, R1]
	; shift the bits up
	LSL	R3, R3, #1
	; set the last bit of the counter if we shifted
	; the current bit out of the keyboard state
	ORRCS	R3, R3, #1
	STRB	R3, [R2, R1]

	; increment counter
	ADD	R1, R1, #1
	; check loop condition
	CMP	R1, #12
	BLO	bit_slice_loop

	; now that we're outside of the loop, go through the debounce'd counters
	; and queue a key press for each new keypress we see
	; building the key-pressed state as we go

	; subtract one from the key_debounce_counters pointer, so we can index backwards, ending at 1
	SUB	R2, R2, #1
	LDR	R5, =key_curr_pressed
	LDR	R4, [R5]

	; use R6 to help calculate the new key_curr_pressed
	MOV	R6, #:1000_0000_0000
debouncing_loop
	; load the debounce counter for this character
	LDRB	R3, [R2, R1]

	; if the debounce counter is zero then clear the current bit of key_curr_pressed
	CMP	R3, #0
	BICEQ	R4, R4, R6

	; and skip all the other checks
	BEQ	debouncing_loop_end
	
	; if the current bit of the key_curr_pressed
	; variable is set, then skip all remaining checks
	TST	R4, R6
	BNE	debouncing_loop_end

	; test if the debounce counter is all 1's
	CMP	R3, #:1111_1111

	; if it isn't then just continue the loop
	BNE	debouncing_loop_end
	
	; otherwise set the current bit of key_curr_pressed
	ORR	R4, R4, R6

	; and emit a key press
	; by first decoding the current key pressed
	LDR	R0, =key_table

	; subtract one to account for the +1 offset in the loop variable
	SUB	R0, R0, #1
	LDRB	R0, [R0, R1]

	; then adding it to the queue
	BL	enqueue_keypress

debouncing_loop_end
	; shift the current bit position down by one
	LSR	R6, R6, #1

	; decrement counter and check loop condition
	SUBS	R1, R1, #1
	BNE	debouncing_loop

	; once we've broken out of the loop
	; store to key_curr_pressed
	STR	R4, [R5]

	; finally update the value in timer compare so that we get another interrupt in 1ms
	BL	gettime
	ADD	R0, R0, #1
	AND	R0, R0, #:1111_1111
	BL	store_timer_compare
int_return
	; return from interrupt mode
	POP	{R0-R6, PC}^

; this is just a temporary interrupt handler which
; calculates the interrupted address and pauses execution
FastInterruptHandler
	SUB	R12, R14, #4
	B	.
