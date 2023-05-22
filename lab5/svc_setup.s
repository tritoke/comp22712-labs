; ###########################################################
;      ______     ______   ____  _____ _____ _   _ ____
;     / ___\ \   / / ___| / ___|| ____|_   _| | | |  _ \
;     \___ \\ \ / / |     \___ \|  _|   | | | | | | |_) |
;      ___) |\ V /| |___   ___) | |___  | | | |_| |  __/
;     |____/  \_/  \____| |____/|_____| |_|  \___/|_|
; ###########################################################

SVC_Entry
	PUSH	{R11, R12, LR}		; push link register for use later
	LDR	R12, [LR, #-4] 		; read SVC number
	BIC	R12, R12, #&FFFF_FF00	; mask off opcode and everything about 0x100
	CMP	R12, #SVC_Max
	BHS	SVC_Invalid		; check if a valid SVC
	LDR	R11, =SVC_Table		; calculate the address of the handler to jump to
	LDR	LR, =SVC_CleanUp	; set up LR for jump
	LDR	PC, [R11, R12, LSL #2]	; get the address and jump to it
SVC_CleanUp
	POP	{R11, R12, PC}^		; return

; jump table for my SVC implementation
SVC_Table	DEFW	printc
		DEFW	printstr
		DEFW	setpix
		DEFW	gettime
		DEFW	bcd_convert_safe
		DEFW	printhexc
		DEFW	button_pressed
SVC_Last

; for any invalid SVC simply hang
SVC_Invalid	B	.
