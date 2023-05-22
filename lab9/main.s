; ###########################################################
;                 __  __    _    ___ _   _ 
;                |  \/  |  / \  |_ _| \ | |
;                | |\/| | / _ \  | ||  \| |
;                | |  | |/ ___ \ | || |\  |
;                |_|  |_/_/   \_\___|_| \_|
; ###########################################################

main	PUSH	{LR}
	; enable timer compare in the control register
	SVC	SVC_ReadCntrl
	ORR	R0, R0, #1
	SVC	SVC_StoreCntrl

	; setup timer compare
	LDR	R0, =INT_TIMER_COMPARE
	SVC	SVC_StoreInts

	MOV	R0, #DIRECTION_READ_ROW
	SVC	SVC_StoreKbDir

	; initialise the RNG
	BL	rng_init

	; initialise the highscore
	LDR	R1, =snake_highscore
	MOV	R0, #0
	STR	R0, [R1]

	; start of the game code
game_start
	; choose the difficulty
	LDR	R0, =difficulty_message
	LDR	R1, =difficulty_message_len
	SVC	SVC_PrintStr
	LDR	R1, =snake_min_frame_time
diff_choose_loop
	BL	dequeue_keypress

	; check if easy difficulty
	CMP	R0, #'1'
	MOVEQ	R0, #SNAKE_MIN_FRAME_TIME_EASY
	BEQ	show_instructions

	; check if medium difficulty
	CMP	R0, #'2'
	MOVEQ	R0, #SNAKE_MIN_FRAME_TIME_MEDIUM
	BEQ	show_instructions

	; check if hard difficulty
	CMP	R0, #'3'
	MOVEQ	R0, #SNAKE_MIN_FRAME_TIME_HARD
	BEQ	show_instructions

	; check if EXTREME difficulty
	CMP	R0, #'4'
	MOVEQ	R0, #SNAKE_MIN_FRAME_TIME_EXTREME
	BEQ	show_instructions

	B	diff_choose_loop

; display the instructions
show_instructions
	; set the minimum frame time
	STR	R0, [R1]

	; print the instructions message
	LDR	R0, =instructions_message
	LDR	R1, =instructions_message_len
	SVC	SVC_PrintStr
instructions_loop
	; wait until we dequeue a keypress, then start
	BL	dequeue_keypress
	CMP	R0, #0
	BEQ	instructions_loop

	; clear the screen
	MOV	R0, #c_FF
	SVC	SVC_PrintC
	
	; reset the board state
	BL	reset_board_state

	; reset the queues
	BL	clear_queue_keypress
	BL	clear_queue_snake_position
	BL	clear_queue_snake_direction

	; setup the snake's body in the queue
	MOV	R0, #((ASSET_COLS / 2) - 2)
	MOV	R1, #(ASSET_ROWS / 2)
	BL	enqueue_snake_position
	; draw the tail
	MOV	R2, #ASSET_snake_tail_right
	BL	draw_asset
	; set the board state for that position
	MOV	R2, #STATE_SNAKE
	BL	set_board_state

	ADD	R0, R0, #1
	BL	enqueue_snake_position
	; draw the body
	MOV	R2, #ASSET_snake_body
	BL	draw_asset
	; set the board state for that position
	MOV	R2, #STATE_SNAKE
	BL	set_board_state

	ADD	R0, R0, #1
	BL	enqueue_snake_position
	; draw the head
	MOV	R2, #ASSET_snake_head_right
	BL	draw_asset
	; set the board state for that position
	MOV	R2, #STATE_SNAKE
	BL	set_board_state

	; setup the snake's direction queue
	MOV	R0, #SNAKE_RIGHT
	BL	enqueue_snake_direction

	; generate the initial apple
	BL	generate_apple_coords
	MOV	R2, #ASSET_apple
	; and draw it
	BL	draw_asset
	; and set the board state
	MOV	R2, #STATE_APPLE
	BL	set_board_state

	LDR	R1, =snake_generate_new_apple
	MOV	R0, #False
	STR	R0, [R1]

	; setup the initial score
	LDR	R1, =snake_score
	MOV	R0, #0
	STR	R0, [R1]

game_loop
	; store when we started the frame
	LDR	R0, =timer_counter
	LDR	R0, [R0]
	LDR	R1, =snake_frame_start
	STR	R0, [R1]

	; dequeue a keypress
	BL	dequeue_keypress
	CMP	R0, #0

	; if we dequeued a zeroed then load the last direction
	; and jump straight to moving the snake
	BLEQ	peak_head_snake_direction
	BEQ	move_snake

	; now check it is a valid direction
	CMP	R0, #SNAKE_UP
	CMPNE	R0, #SNAKE_RIGHT
	CMPNE	R0, #SNAKE_LEFT
	CMPNE	R0, #SNAKE_DOWN

	; if not then load the previous direction
	BLNE	peak_head_snake_direction

move_snake
	; moving the snake consists of the following steps:
	;   0. checking if the new coordinates are off the board
	;   1. checking whether the snake is going to eat itself
	;   2. checking whether the snake is eating an apple
	;   3. enqueue-ing the new head position and direction
	;   4. drawing over the head with an ASSET_snake_body
	;   5. drawing the new head in the right direction
	;   6. setting the board state of the new head to SNAKE
	;   7. dequeue-ing the tail position and direction
	;   8. overwriting the old tail with ASSET_empty
	;   9. setting the board state of the old tail to EMPTY
	;   10. drawing the tail in the right direction
	;   11. conditionally generate a new apple

	; move the snake direction into R2
	MOV	R2, R0
	; load the current head position
	BL	peak_head_snake_position

	; make a copy of the position in the high registers
	MOV	R7, R0
	MOV	R8, R1

	; register mappings
	; R0 -> head column
	; R1 -> head row
	; R2 -> direction

	; calculate the new head
	CMP	R2, #SNAKE_UP
	; going up means row -= 1
	SUBEQ	R1, R1, #1

	CMP	R2, #SNAKE_RIGHT
	; going right means col += 1
	ADDEQ	R0, R0, #1

	CMP	R2, #SNAKE_LEFT
	; going left means col -= 1
	SUBEQ	R0, R0, #1

	CMP	R2, #SNAKE_DOWN
	; going down means row += 1
	ADDEQ	R1, R1, #1

	; 0. check collision with the walls
	;    col == -1
	; || col == ASSET_COLS
	; || row == -1
	; || row == ASSET_ROWS 
	CMP	R0, #-1
	CMPNE	R0, #ASSET_COLS
	CMPNE	R1, #-1
	CMPNE	R1, #ASSET_ROWS
	BEQ	game_over

	; 1. check if the snake is going to eat itself
	; save the column otherwise it will be overwritten
	MOV	R4, R0
	BL	get_board_state
	; save the board state to R3
	MOV	R3, R0
	; restore the column
	MOV	R0, R4

	; now we can check the state to see if it is snake
	CMP	R3, #STATE_SNAKE
	; if it is snake then jump to the end
	BEQ	game_over

	; 2. check if the snake is eating an apple
	; if it is not an apple then go to drawing stage
	CMP	R3, #STATE_APPLE
	BNE	draw_stage

	; if it is an apple then increment the score counter
	; and set a flag to generate an apple later
	LDR	R5, =snake_score
	LDR	R4, [R5]
	ADD	R4, R4, #1
	STR	R4, [R5]

	; set the flags
	LDR	R5, =snake_generate_new_apple
	MOV	R4, #True
	STR	R4, [R5]

draw_stage
	; 3. enqueue-ing the new head position and direction
	BL	enqueue_snake_position
	; save the position to R3, R4
	MOV	R3, R0
	MOV	R4, R1
	; move the direction into R0 for queueing
	MOV	R0, R2
	BL	enqueue_snake_direction

	; 4. drawing over the head with an ASSET_snake_body
	; restore the old head position to R0,R1
	MOV	R0, R7
	MOV	R1, R8
	; save the direction to R6
	MOV	R6, R2
	; draw the new body
	MOV	R2, #ASSET_snake_body
	BL	draw_asset

	; 5. drawing the new head in the right direction
	; restore the new head
	MOV	R0, R3
	MOV	R1, R4
	; select the right asset
	CMP	R6, #SNAKE_RIGHT
	MOVEQ	R2, #ASSET_snake_head_right
	CMP	R6, #SNAKE_LEFT
	MOVEQ	R2, #ASSET_snake_head_left
	CMP	R6, #SNAKE_UP
	MOVEQ	R2, #ASSET_snake_head_up
	CMP	R6, #SNAKE_DOWN
	MOVEQ	R2, #ASSET_snake_head_down

	; draw the new head
	BL	draw_asset

	; 6. set the board state of the new head to snake
	MOV	R2, #STATE_SNAKE
	BL	set_board_state

	; if we've eaten an apple, don't perform any tail logic
	LDR	R4, =snake_generate_new_apple
	LDR	R3, [R4]
	CMP	R3, #True
	BEQ	gen_new_apple

	; 7. dequeue-ing the tail position and direction
	; dequeue direction first then save it to R6
	BL	dequeue_snake_direction
	MOV	R6, R0
	BL	dequeue_snake_position

	; 8. overwriting the old tail with ASSET_empty
	MOV	R2, #ASSET_empty
	BL	draw_asset

	; 9. set the board state of the old tail to EMPTY
	MOV	R2, #STATE_EMPTY
	BL	set_board_state

	; 10. drawing the tail in the right direction
	; look where the tail of the queue is
	BL	peak_tail_snake_position

	; load in the right asset
	CMP	R6, #SNAKE_RIGHT
	MOVEQ	R2, #ASSET_snake_tail_right
	CMP	R6, #SNAKE_LEFT
	MOVEQ	R2, #ASSET_snake_tail_left
	CMP	R6, #SNAKE_UP
	MOVEQ	R2, #ASSET_snake_tail_up
	CMP	R6, #SNAKE_DOWN
	MOVEQ	R2, #ASSET_snake_tail_down

	; draw it to the screen
	BL	draw_asset

	; 11. conditionally generate a new apple
	LDR	R4, =snake_generate_new_apple
	LDR	R3, [R4]
	CMP	R3, #True

	; if the flag is not set then jump to the wait stage
	BNE	wait_stage

gen_new_apple
	; the flag is set so set it to false and generate an apple
	MOV	R3, #False
	STR	R3, [R4]

	; generate the new coordinates
	BL	generate_apple_coords

	; draw in the new apple
	MOV	R2, #ASSET_apple
	BL	draw_asset

	; set the state
	MOV	R2, #STATE_APPLE
	BL	set_board_state

; game is so fast on my PC that I have to slow it down :sunglasses:
; sadly a busy wait loop is the best I could come up with :/
wait_stage
	LDR	R1, =snake_frame_start
	LDR	R1, [R1]
	LDR	R2, =snake_min_frame_time
	LDR	R2, [R2]
	LDR	R3, =timer_counter
wait_loop
	; always step the RNG state to add some useful delay
	BL	rng_step_state
	; load the current value of the timer
	LDR	R0, [R3]
	; get the difference between the starting time and the current time
	SUB	R0, R0, R1
	CMP	R0, R2
	BLO	wait_loop

	; and repeat :)
	B	game_loop

game_over
	; print the game over message
	LDR	R0, =game_over_message
	LDR	R1, =game_over_message_len
	SVC	SVC_PrintStr

	; print the score
	LDR	R0, =snake_score
	; save the score for later
	LDR	R3, [R0]
	MOV	R0, R3
	BL	print_total

	; check to see if we have beaten the highscore
	LDR	R2, =snake_highscore
	LDR	R4, [R2]
	CMP	R3, R4

	BHI	new_highscore
	
	; print the highscore message
	LDR	R0, =highscore_message
	LDR	R1, =highscore_message_len
	SVC	SVC_PrintStr

	; restore the highscore and print it
	MOV	R0, R4
	BL	print_total

	B	print_restart

new_highscore
	; otherwise, save it and print the new highscore message
	STR	R0, [R2]
	LDR	R0, =new_highscore_message
	LDR	R1, =new_highscore_message_len
	SVC	SVC_PrintStr

print_restart
	; print the restart message
	LDR	R0, =restart_message
	LDR	R1, =restart_message_len
	SVC	SVC_PrintStr

restart_loop
	; check if * was pressed
	BL	dequeue_keypress
	CMP	R0, #'*'
	BNE	restart_loop

	; clear the screen before we restart
	MOV	R0, #c_FF
	SVC	SVC_PrintC
	B	game_start

main_end
	POP	{PC}
