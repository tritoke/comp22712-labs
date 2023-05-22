; ###########################################################
;                ____  _____ _____ _   _ ____  
;               / ___|| ____|_   _| | | |  _ \ 
;               \___ \|  _|   | | | | | | |_) |
;                ___) | |___  | | | |_| |  __/ 
;               |____/|_____| |_|  \___/|_|    
; ###########################################################

; kernel setup function
_start	; first setup kernel stack
	LDR	SP, =_kernel_stack
	; set interrupts
	Bl	_init_interrupts
	; clear the screen.
	BL	clrscr
	; setup return to user mode
	LDR	R14, =MODE_USER_IRQ_ENABLED
	MSR	SPSR_c, R14
	LDR	R14, =_init_main
	MOVS	PC, R14 ; "return" to user code

; initialise the interrupt stacks
_init_interrupts
	; move into interrupt mode
	MRS	R0, CPSR		; load the CPSR register
	MOV	R1, R0			; save the CPSR state for later
	BIC	R0, R0, #:1111		; clear out the mode bits
	ORR	R0, R0, #MODE_IRQ	; set IRQ mode
	MSR	CPSR_c, R0		; store the calculated CPSR value
	NOP	; we are now in interrupt mode

	; so we can setup the interrupt stack
	LDR	SP, =_interrupt_stack

	; move into fast interrupt mode
	BIC	R0, R0, #:1111		; clear out the mode bits again
	ORR	R0, R0, #MODE_FIQ	; set FIQ mode
	MSR	CPSR_c, R0		; store the calculated CPSR value
	NOP	; we are now in interrupt mode

	; so we can setup the fast interrupt stack
	LDR	SP, =_fast_interrupt_stack

	; return to supervisor mode
	MSR	CPSR_c, R1
	NOP

	; return
	MOV	PC, LR

; user setup function
_init_main
	; setup user stack
	LDR	SP, =_stack

	; jump to main
	BL	main
	B	.	; hang after returning from main
