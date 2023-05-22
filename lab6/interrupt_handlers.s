; ###########################################################
;  ___ _   _ _____ _____ ____  ____  _   _ ____ _____ ____  
; |_ _| \ | |_   _| ____|  _ \|  _ \| | | |  _ \_   _/ ___| 
;  | ||  \| | | | |  _| | |_) | |_) | | | | |_) || | \___ \ 
;  | || |\  | | | | |___|  _ <|  _ <| |_| |  __/ | |  ___) |
; |___|_| \_| |_| |_____|_| \_\_| \_\\___/|_|    |_| |____/ 
; ###########################################################

InterruptHandler
	SUB	LR, LR, #4
	PUSH	{R0,R1,LR}
	; determine the type of interrupt - button vs timer compare

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
	; idrk what to do with these yet
	B	.

int_handle_timer_compare
	; read the current timer value
	BL	gettime
	; add user defined constant to the timer counter
	LDR	R1, =timer_compare_increment
	LDR	R1, [R1]
	ADD	R0, R0, R1
	; wrap it to an 8 bit value
	AND	R0, R0, #:1111_1111
	; store it to the register so we get another interrupt in ~100ms
	; this wraps because it effectively does an AND with 0xFF, which turns 0x100 (256) -> 0x00
	LDR	R1, =IO_TIMER_COMPARE
	STR	R0, [R1]
	; increment the timer counter
	LDR	R1, =timer_counter
	LDR	R0, [R1]
	ADD	R0, R0, #1
	STR	R0, [R1]
int_return
	; return from the ISR
	POP	{R0,R1,PC}^ 

; this is just a temporary interrupt handler which
; calculates the interrupted address and pauses execution
FastInterruptHandler
	SUB	R12, R14, #4
	B	.
