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

	;LDR	R0, =alphabet
	;LDR	R1, alphabet_len
	;SVC	SVC_PrintStr

	; reset state
	MOV	R0, #False
	STR	R0, timer_running
	STR	R0, pause_pressed
	; False == 0
	STR	R0, kc_b_pressed_start
	STR	R0, start_timer_state
	STR	R0, prev_time_elapsed
	STR	R0, prev_timer_read
	STR	R0, curr_tick_count

	; reset the counter to 0
	BL	reset_counter

	; button A - KC_A - is the start button
	; button B - KC_B - is the pause/reset button
timer_loop
	; always update the timer
	BL	update_counter
	
	; get the current value of the timer counter
	BL	get_timer_counter
	; store it in R1
	MOV	R1, R0

	; check to see whether the timer is running
	; if it is then jump to checking pause / reset
	LDR	R0, timer_running
	CMP	R0, #True
	BEQ	check_pause_reset

	; the timer is not running so check whether button A is being pressed
	MOV	R0, #KC_A
	SVC	SVC_ButtPress
	CMP	R0, #True

	; if the button is not being pressed then jump to checking for pause / reset
	BNE	check_pause_reset

	; if we get here we know the button is being pressed
	; so store True into timer_running
	MOV	R0, #True
	STR	R0, timer_running
	; and set the current timer start
	STR	R1, start_timer_state

check_pause_reset
	; check whether the B key is being pressed
	MOV	R0, #KC_B
	SVC	SVC_ButtPress

	; R0 now holds whether the B button was pressed
	CMP	R0, #True

	; if its not presed jump to that code
	BNE	kc_b_not_pressed
	; if the button is being pressed
	;	and the state is not paused we need to pause it, record the current timer value and restart the loop
	LDR	R0, pause_pressed
	CMP	R0, #True
	BEQ	paused_time_check
	; if we are here we know we need to pause it and record the value in the timer
	; store True to pause pressed
	STR	R0, pause_pressed
	; pause the timer
	MOV	R0, #False
	STR	R0, timer_running
	; store the value just read from the counter into kc_b_pressed_start
	STR	R1, kc_b_pressed_start
	; take the difference between now and start_timer_state
	; and store it prev_time_elapsed
	LDR	R2, start_timer_state
	LDR	R0, prev_time_elapsed
	; prev_timer_state = pte - sts + now
	SUB	R0, R0, R2
	ADD	R0, R0, R1
	; store the value back into memory
	STR	R0, prev_time_elapsed

	; finished pause logic, jump to start of loop
	B	timer_loop

paused_time_check
	; if the button is being pressed
	; 	and the state is currently paused we need to check whether 1 second has passed
	;	and if it has then we need to reset the state and print it out once before continuing the loop
	
	; R1 holds the current timer value
	; check whether current_time - start_time >= 10
	; if it is then one second has passed so we reset the timer
	LDR	R0, kc_b_pressed_start
	SUB	R0, R0, R1
	CMP	R0, #10
	; if it is lower than 10, then continue back to the top of the loop
	BLO	timer_loop
	; else reset the timer state
	BL	reset_counter
	; and branch back to the start
	B	timer_loop

kc_b_not_pressed
	; if b is not pressed, check whether we are paused, and if we are then go back to the top
	LDR	R0, pause_pressed
	CMP	R0, #True
	BEQ	timer_loop

	; if we are not paused see whether the timer is running and jump back to the top if it is
	LDR	R0, timer_running
	CMP	R0, #True
	BNE	timer_loop

	; print the timer
	BL	print_timer
	; continue the loop
	B	timer_loop

	; return from main (WE SHOULD NEVER GET HERE)
	POP	{PC}

timer_running		DEFW	False
pause_pressed		DEFW	False
kc_b_pressed_start	DEFW	0
start_timer_state	DEFW	0
prev_time_elapsed	DEFW	0
prev_timer_read		DEFW	0
curr_tick_count		DEFW	0

; resets timer state
reset_counter
	PUSH	{R0,LR}
	; get the value of the timer
	SVC	SVC_GetTime
	; store that value into prev_timer_read
	STR	R0, prev_timer_read
	; store 0 in curr_tick_count, prev_time_elapsed and intimer_counter
	MOV	R0, #0
	STR	R0, curr_tick_count
	STR	R0, prev_time_elapsed
	STR	R0, timer_counter
	; store -1 in prev_counter_value
	MOV	R0, #-1
	STR	R0, prev_counter_value
	; prints out the reset state
	BL	print_timer
	; restore registers and return
	POP	{R0, PC}

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

; previous counter value
prev_counter_value	DEFW	0

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
	; subtract off the starting time
	LDR	R1, start_timer_state
	SUB	R0, R0, R1
	; Add to the time we have previously run for
	LDR	R1, prev_time_elapsed
	ADD	R0, R0, R1

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
