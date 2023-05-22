; ###########################################################
;                 ___  _   _ _____ _   _ _____
;                / _ \| | | | ____| | | | ____|
;               | | | | | | |  _| | | | |  _|
;               | |_| | |_| | |___| |_| | |___
;                \__\_\\___/|_____|\___/|_____|
; ###########################################################

; adds an item to the queue
; R0 -> Item to store
; R2 -> queue address
; R3 -> head of the queue
; R4 -> tail of the queue
; R5 -> number of items in the queue
; R6 -> the queue mask
; R7 -> the queue capacity
_enqueue
	; write the character to the queue head
	LDR	R1, [R3]
	STRB	R0, [R2, R1]

	; now that we have performed the store, increment pointers
	; always increment the head
	ADD	R1, R1, #1
	; and wrap it modulo queue size
	AND	R1, R1, R6
	; and store the head back to memory
	STR	R1, [R3]

	; test if the queue is full :: num_queued == CAPACITY
	LDR	R1, [R5]
	CMP	R1, R7

	; if it is not full then branch away
	BNE	queue_not_full

	; if it is full then advance the tail as well
	LDR	R1, [R4]
	ADD	R1, R1, #1
	; wrap the tail
	AND	R1, R1, R6
	; store the tail back
	STR	R1, [R4]
	B	enqueue_return
queue_not_full
	; increment the number of elements queued
	ADD	R1, R1, #1
	; store the value back to memory
	STR	R1, [R5]

enqueue_return
	; return
	MOV	PC, LR

_dequeue
	; first check whether there are any items available
	LDR	R1, [R4]

	; branch to special case if there are no items

	CMP	R1, #0
	BLE	no_item

	; otherwise decrement the number queued
	SUB	R1, R1, #1

	; and store it back to memory
	STR	R1, [R4]

	; get the actual item from the queue
	LDR	R1, [R3]
	LDRB	R0, [R2, R1]

	; finally update the head pointer
	ADD	R1, R1, #1
	; wrap it back round
	AND	R1, R1, R5

	; store it's value back to memory
	STR	R1, [R3]

	; and return
	B	dequeue_return

no_item
	MOV	R0, #0

dequeue_return
	MOV	PC, LR

_peak_tail
	; first check whether there are any items available
	LDR	R1, [R4]

	; branch to special case if there are no items
	CMP	R1, #0
	BLE	peak_no_item

	; get the actual item from the queue
	LDR	R1, [R3]
	LDRB	R0, [R2, R1]

	; and return
	B	peak_tail_return

_peak_head
	; first check whether there are any items available
	LDR	R1, [R4]

	; branch to special case if there are no items
	CMP	R1, #0
	BLE	peak_no_item

	; get the actual item from the queue
	LDR	R1, [R3]
	; head points to the next element after the end so subtract one and wrap
	SUB	R1, R1, #1
	AND	R1, R1, R5
	LDRB	R0, [R2, R1]

	; and return
	B	peak_tail_return

peak_no_item
	MOV	R0, #0

peak_tail_return
	MOV	PC, LR

; resets the state of the queue
_clear_queue
	; first reset each element of the queue
	MOV	R0, #0
	MOV	R1, #0

_clear_loop
	; store 0 to each queue item
	STR	R0, [R2, R1]

	; check loop condition
	ADD	R1, R1, #1
	CMP	R1, R6
	BLO	_clear_loop

	; reset head / tail / num_queued
	STR	R0, [R3]
	STR	R0, [R4]
	STR	R0, [R5]

	; return
	MOV	PC, LR
