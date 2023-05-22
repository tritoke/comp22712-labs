update_counter
	PUSH	{R0-R3,R12,LR}
	; read from the timer forever
	LDR	R12, =timer
	; register info:
	; R0 holds the just read value from the timer
	; R1 holds the previously read value from the timer
	; R2 holds the current number of ticks
	; R3 is a scratch register used in calculations
	; R12 holds the address of the timer peripheral

	; load the value of the spinning timer
	LDR	R0, [R12]
	SUB	R3, R1, R0
	; mask the value so it wraps around
	AND	R3, R3, #&FF
	ADD	R2, R2, R3
	; if the number of ticks is greater than 100
	; then subtract 100 and increment the memory location
	CMP	R2, #100
	SUB	R2, R2, #100
	POPLO	{R0-R3,R12,PC}
	; load timer value and store incremented
	LDR	R3, timer_counter
	ADD	R3, R3, #1
	STR	R3, timer_counter

	POP	{R0-R3,R12,PC}
