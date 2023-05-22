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
	MOV	R14, #&D0
	MSR	SPSR_c, R14
	LDR	R14, =_init_main
	MOVS	PC, R14 ; "return" to user code

; user setup function
_init_main
	; setup user stack
	LDR	SP, =_stack

	; zero out all the registers
	MOV	R0,  #0
	MOV	R1,  #0
	MOV	R2,  #0
	MOV	R3,  #0
	MOV	R4,  #0
	MOV	R5,  #0
	MOV	R6,  #0
	MOV	R7,  #0
	MOV	R8,  #0
	MOV	R9,  #0
	MOV	R10, #0
	MOV	R11, #0
	MOV	R12, #0

	; jump to main
	BL	main
	B	.	; hang after returning from main
