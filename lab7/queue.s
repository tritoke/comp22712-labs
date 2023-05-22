; ###########################################################
;                ___  _   _ _____ _   _ _____ 
;               / _ \| | | | ____| | | | ____|
;              | | | | | | |  _| | | | |  _|  
;              | |_| | |_| | |___| |_| | |___ 
;               \__\_\\___/|_____|\___/|_____|
; ###########################################################
                               

; adds a keypress from R0 to the key queue
enqueue_keypress
	PUSH	{R1-R3}

	; load in all the queue variables
	; R1 is a pointer to the key queue's base address
	LDR	R1, =key_queue
	; R2 is the index of the head of the queue
	LDR	R2, =key_queue_head
	LDR	R2, [R2]
	; R3 is the index of the tail of the queue
	LDR	R3, =key_queue_tail
	LDR	R2, [R3]



	; restore registers and return
	POP	{R1-R3}
	MOV	PC, LR
