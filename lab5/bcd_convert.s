; Convert unsigned binary value in R0 into BCD representation, returned in R0
; Any overflowing digits are generated, but not retained or returned in this
;  version.
; Corrupts registers R1-R6, inclusive; also R14
; Does not require a stack

bcd_convert	MOV	R6, lr			; Keep return address
						;  in case there is no stack
		LDR	R4, =dec_table		; Point at conversion table
		MOV	R5, #0			; Zero accumulator

bcd_loop	LDR	R1, [R4], #4		; Get next divisor, step pointer
		CMP	R1, #1			; Termination condition?
		BEQ	bcd_out			;  yes

		BL	divide			; R0 := R0/R1 (rem. R2)

		ADD	R5, R0, R5, lsl #4	; Accumulate result
		MOV	R0, R2			; Recycle remainder
		B	bcd_loop		;

bcd_out		ADD	R0, R0, R5, lsl #4	; Accumulate result to output

		MOV	pc, R6			; Return

dec_table	DCD	1000000000, 100000000, 10000000, 1000000
		DCD	100000, 10000, 1000, 100, 10, 1

;-------------------------------------------------------------------------------

; 32-bit unsigned integer division R0/R1
; Returns quotient in R0 and remainder in R2
; R3 is corrupted (will be zero)
; Returns quotient FFFFFFFF in case of division by zero
; Does not require a stack

divide		MOV	R2, #0			; AccH
		MOV	R3, #32			; Number of bits in division
		ADDS	R0, R0, R0		; Shift dividend

divide1		ADC	R2, R2, R2		; Shift AccH, carry into LSB
		CMP	R2, R1			; Will it go?
		SUBHS	R2, R2, R1		; If so, subtract
		ADCS	R0, R0, R0		; Shift dividend & Acc. result
		SUB	R3, R3, #1		; Loop count
		TST	R3, R3			; Leaves carry alone
		BNE	divide1			; Repeat as required

		MOV	pc, lr			; Return

;-------------------------------------------------------------------------------
