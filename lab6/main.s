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

	; print out our timer message :)
	LDR	R0, =timer_message
	LDR	R1, =timer_message_len
	SVC	SVC_PrintStr

	; initialise memory locations
	; curr_tick_count = 0
reset_state
	MOV	R0, #0
	STR	R0, paused_timer_val
	STR	R0, paused_running_start

	; 0 is the unstarted state
	STR	R0, fsm_state

	; reset the timer counter
	LDR	R1, =timer_counter
	STR	R0, [R1]

	; store -1 to prev_counter_value
	MOV	R0, #-1
	STR	R0, prev_counter_value

	; print the timer just show it shows on screen
	BL	print_timer

fsm_loop
	; move the status of Button A and B into R6 and R7 respectively
	; button A - KC_A - is the start button
	MOV	R0, #KC_A
	BL	is_button_pressed
	MOV	R6, R0

	; button B - KC_B - is the pause/reset button
	MOV	R0, #KC_B
	BL	is_button_pressed
	MOV	R7, R0

	; jump to the right FSM state
	LDR	R0, =Jump_Table
	LDR	R1, fsm_state
	LDR	PC, [R0, R1, LSL #2]

unstarted	
	; if we are unstarted then we need to check if button A is being pressed
	CMP	R6, #True

	; if it isn't then just branch back to the top of the loop
	BNE	fsm_loop

	; otherwise we need to reset the time in the counter
	MOV	R0, #0
	LDR	R1, =timer_counter
	STR	R0, [R1]

	; and transition the state to running
	MOV	R0, #STATE_RUNNING
	STR	R0, fsm_state

	B	fsm_loop
running
	; if we're running then print the timer
	BL	print_timer

	; we now need to check if button B is pressed
	CMP	R7, #True
	
	; if it isn't then we just jump to the top of the loop again
	BNE	fsm_loop

	; if it is pressed then we need to store the current value of
	; the timer into paused_timer_val, and paused_running_start
	BL	get_timer_counter
	STR	R0, paused_timer_val
	STR	R0, paused_running_start

	; and transition the state to the paused-counting state
	MOV	R0, #STATE_PAUSED_COUNTING
	STR	R0, fsm_state

	B	fsm_loop
paused_counting
	; if we are in paused counting we need to check if button A is being pressed
	; to see if we should transition to running
	CMP	R6, #True
	BEQ	pc_a_pressed

	; if button A is not pressed we then check button B
	CMP	R7, #False

	; if it is not pressed we should transition to paused
	BEQ	pc_b_not_pressed

	; otherwise we know it is pressed and need to check if 1 second has passed
	; by comparing the current value of the timer with the time when we started pressing B
	BL	get_timer_counter
	LDR	R1, paused_running_start
	SUB	R0, R0, R1

	; timer increments every 100ms so 10 of them is one second
	CMP	R0, #10

	; if not enough time has passed just return to the top of the loop
	BLT	fsm_loop

	; if enough time has passed then we need to reset the timer state
	; and transition to the "unstarted" state
	; this can be done by jumping to reset_state which just resets the entire program state
	B	reset_state

pc_a_pressed
	; if button A has been pressed then we need to resume the timer
	; this means restoring the paused time back into the counter
	LDR	R0, paused_timer_val
	LDR	R1, =timer_counter
	STR	R0, [R1]

	; and changing the state to running
	MOV	R0, #STATE_RUNNING
	STR	R0, fsm_state

	B	fsm_loop

pc_b_not_pressed
	; change the state to paused
	MOV	R0, #STATE_PAUSED
	STR	R0, fsm_state

	B	fsm_loop

paused	; if we are paused then we need to check whether button A is pressed
	; to see if we should transition to running
	CMP	R6, #True
	BEQ	pc_a_pressed

	; if button A is not pressed we then check button B
	CMP	R7, #True

	; if it isn't pressed simply go to the top of the loop
	BNE	fsm_loop

	; if it is pressed we should store the current timer value to
	; paused_running_start
	BL	get_timer_counter
	STR	R0, paused_running_start

	; and then transition to paused-counting
	MOV	R0, #STATE_PAUSED_COUNTING
	STR	R0, fsm_state

	B	fsm_loop

; define the FSM states
STATE_UNSTARTED		EQU	0
STATE_RUNNING		EQU	1
STATE_PAUSED		EQU	2
STATE_PAUSED_COUNTING	EQU	3

; define the state jump table
Jump_Table
	DEFW	unstarted
	DEFW	running
	DEFW	paused
	DEFW	paused_counting

paused_timer_val	DEFW	0			; the value of the timer when we paused
paused_running_start	DEFW	0			; the value of the timer when we B started being pressed
prev_counter_value	DEFW	0			; the previous value of the counter
fsm_state		DEFW	STATE_UNSTARTED		; the state of our FSM

print_timer
	PUSH	{R0, R1, LR}
	; read the value from the counter
	BL	get_timer_counter
	; read the previous counter value
	LDR	R1, prev_counter_value

	CMP	R0, R1
	; if it hasn't changed then return
	BEQ	print_timer_end

	; it's changed so update the "previous" value
	STR	R0, prev_counter_value

	; BCD encode the timer value
	BL	bcd_convert_safe

	; rotate the "last" digit to be printed into the lowest nibble
	ROR	R0, R0, #12
	; print it as a hex character - prints as decimal for BCD
	BL	printhexc
	; return the nibbles one by one
	ROR	R0, R0, #32 - 4
	BL	printhexc
	ROR	R0, R0, #32 - 4
	BL	printhexc
	; print a colon before the last digit
	MOV	R1, R0
	MOV	R0, #':'
	SVC	SVC_PrintC
	; print the final digit
	MOV	R0, R1
	ROR	R0, R0, #32 - 4
	BL	printhexc

	; print 5 backspaces
	MOV	R0, #c_BS
	SVC	SVC_PrintC
	SVC	SVC_PrintC
	SVC	SVC_PrintC
	SVC	SVC_PrintC
	SVC	SVC_PrintC

	; restore registers and return
print_timer_end
	POP	{R0, R1, PC}

; gets the value from the timer counter and places it in R0
get_timer_counter
	LDR	R0, =timer_counter
	LDR	R0, [R0]
	MOV	PC, LR

; returns True if the button in R0 is currently pressed
is_button_pressed
	PUSH	{R1}
	MOV	R1, R0
	SVC	SVC_PollButts
	TST	R1, R0
	MOVNE	R0, #True
	MOVEQ	R0, #False
	POP	{R1}
	MOV	PC, LR
