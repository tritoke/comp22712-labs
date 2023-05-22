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
	AND	R12, R12, #&FF		; mask off opcode and everything about 0x100
	CMP	R12, #SVC_Max
	BHS	SVC_Invalid		; check if a valid SVC
	LDR	R11, =SVC_Table		; calculate the address of the handler to jump to
	LDR	LR, =SVC_CleanUp	; set up LR for jump
	LDR	PC, [R11, R12, LSL #2]	; get the address and jump to it
SVC_CleanUp
	POP	{R11, R12, PC}^		; return

; jump table for my SVC implementation
SVC_Table
SVC_PRINTC_POS		DEFW	printc
SVC_PRINTSTR_POS	DEFW	printstr
SVC_SETPIX_POS		DEFW	setpix
SVC_GETTIME_POS		DEFW	gettime
SVC_POLLBUTTONS_POS	DEFW	poll_buttons
SVC_STR_INTS_POS	DEFW	store_interrupt_bits
SVC_READ_INTS_POS	DEFW	read_interrupt_bits
SVC_STR_CNTRL_POS	DEFW	store_control_register
SVC_READ_CNTRL_POS	DEFW	read_control_register
SVC_STR_TMCMP_POS	DEFW	store_timer_compare
SVC_READ_TMCMP_POS	DEFW	read_timer_compare
SVC_READ_KBMTX_POS	DEFW	read_keyboard_matrix
SVC_STR_KBMTX_POS	DEFW	store_keyboard_matrix
SVC_READ_KBDIR_POS	DEFW	read_keyboard_matrix_direction
SVC_STR_KBDIR_POS	DEFW	store_keyboard_matrix_direction
SVC_Last

; for any invalid SVC simply hang
SVC_Invalid	B	.
