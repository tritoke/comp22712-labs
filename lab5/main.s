; ###########################################################
;                 __  __    _    ___ _   _ 
;                |  \/  |  / \  |_ _| \ | |
;                | |\/| | / _ \  | ||  \| |
;                | |  | |/ ___ \ | || |\  |
;                |_|  |_/_/   \_\___|_| \_|
; ###########################################################
main	PUSH	{LR}
	; print the FF character - clear the screen
	LDR	R0, =c_FF
	SVC	SVC_PrintC

	; print out our timer message :)
	LDR	R0, =timer_message
	LDR	R1, =timer_message_len
	SVC	SVC_PrintStr

	; initialise memory locations
	; curr_tick_count = 0
reset_state
	MOV	R0, #0
	STR	R0, curr_tick_count
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
	; read the time from the peripheral and store it to prev_timer_read
	SVC	SVC_GetTime
	STR	R0, prev_timer_read

	; print the timer just show it shows on screen
	BL	print_timer

timer_loop
	; always update the timer
	BL	update_counter

	; move the status of Button A and B into R6 and R7 respectively
	; button A - KC_A - is the start button
	MOV	R0, #KC_A
	SVC	SVC_ButtPress
	MOV	R6, R0
	; button B - KC_B - is the pause/reset button
	MOV	R0, #KC_B
	SVC	SVC_ButtPress
	MOV	R7, R0

	; jump to the right FSM state
	LDR	R0, =Jump_Table
	LDR	R1, fsm_state
	LDR	PC, [R0, R1, LSL #2]
	
unstarted	
	; if we are unstarted then we need to check if button A is being pressed
	CMP	R6, #True
	; if it isn't then just branch back to the top of the loop
	BNE	timer_loop

	; otherwise we need to reset the time in the counter
	MOV	R0, #0
	LDR	R1, =timer_counter
	STR	R0, [R1]

	; and transition the state to running
	MOV	R0, #STATE_RUNNING
	STR	R0, fsm_state

	B	timer_loop
running
	; if we're running then print the timer
	BL	print_timer

	; we now need to check if button B is pressed
	CMP	R7, #True
	
	; if it isn't then we just jump to the top of the loop again
	BNE	timer_loop

	; if it is pressed then we need to store the current value of
	; the timer into paused_timer_val, and paused_running_start
	BL	get_timer_counter
	STR	R0, paused_timer_val
	STR	R0, paused_running_start

	; and transition the state to the paused-counting state
	MOV	R0, #STATE_PAUSED_COUNTING
	STR	R0, fsm_state

	B	timer_loop
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
	BLT	timer_loop
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

	B	timer_loop

pc_b_not_pressed
	; change the state to paused
	MOV	R0, #STATE_PAUSED
	STR	R0, fsm_state

	B	timer_loop

paused	; if we are paused then we need to check whether button A is pressed
	; to see if we should transition to running
	CMP	R6, #True
	BEQ	pc_a_pressed

	; if button A is not pressed we then check button B
	CMP	R7, #True

	; if it isn't pressed simply go to the top of the loop
	BNE	timer_loop

	; if it is pressed we should store the current timer value to
	; paused_running_start
	BL	get_timer_counter
	STR	R0, paused_running_start

	; and then transition to paused-counting
	MOV	R0, #STATE_PAUSED_COUNTING
	STR	R0, fsm_state

	B	timer_loop

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

prev_timer_read		DEFW	0			; the last value read from the timer
curr_tick_count		DEFW	0			; the current tick count
paused_timer_val	DEFW	0			; the value of the timer when we paused
paused_running_start	DEFW	0			; the value of the timer when we B started being pressed
prev_counter_value	DEFW	0			; the previous value of the counter
fsm_state		DEFW	STATE_UNSTARTED		; the state of our FSM

; Updates the value of the timer counter in memory
update_counter
	PUSH	{R0-R3,LR}
	; register info:
	; R0 holds the just read value from the timer
	; R1 holds the previously read value from the timer
	; R2 holds the current number of ticks
	; R3 is a scratch register used in calculations

	; load the value of the spinning timer
	SVC	SVC_GetTime
	; load the previous value of the timer
	LDR	R1, prev_timer_read
	; if it is the same as the value we just return
	CMP	R0, R1
	POPEQ	{R0-R3,PC}
	; if it is different then store the just-read value back to prev_timer_read
	STR	R0, prev_timer_read
	; get the difference between the current and previous timer values
	SUB	R3, R0, R1
	; if R3 > 0 then good value, else wrap it 
	CMP	R3, #0
	; R3 = 0 - R3
	ADDLT	R3, R3, #256
	; load the current tick count
	LDR	R2, curr_tick_count
	ADD	R2, R2, R3
	CMP	R2, #TIMER_PRESCALER
	; if the number of ticks is greater than TIMER_PRESCALER
	BLT	update_counter_store_ticks
	; then subtract 100 and increment the memory location
	SUB	R2, R2, #TIMER_PRESCALER
	; load timer value and store incremented
	LDR	R3, timer_counter
	ADD	R3, R3, #1
	STR	R3, timer_counter

	; update the current tick count in memory
update_counter_store_ticks
	STR	R2, curr_tick_count
	POP	{R0-R3,PC}

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
	SVC	SVC_BcdConv

	; rotate the "last" digit to be printed into the lowest nibble
	ROR	R0, R0, #12
	; print it as a hex character - prints as decimal for BCD
	SVC	SVC_PrintHexC
	; return the nibbles one by one
	ROR	R0, R0, #32 - 4
	SVC	SVC_PrintHexC
	ROR	R0, R0, #32 - 4
	SVC	SVC_PrintHexC
	; print a colon before the last digit
	MOV	R1, R0
	MOV	R0, #':'
	SVC	SVC_PrintC
	; print the final digit
	MOV	R0, R1
	ROR	R0, R0, #32 - 4
	SVC	SVC_PrintHexC

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
