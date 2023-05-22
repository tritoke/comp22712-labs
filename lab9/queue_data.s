; ###########################################################
;      ___  _   _ _____ _   _ _____ ____    _  _____  _
;     / _ \| | | | ____| | | | ____|  _ \  / \|_   _|/ \
;    | | | | | | |  _| | | | |  _| | | | |/ _ \ | | / _ \
;    | |_| | |_| | |___| |_| | |___| |_| / ___ \| |/ ___ \
;     \__\_\\___/|_____|\___/|_____|____/_/   \_\_/_/   \_\
; ###########################################################

LTORG

; key queue data
key_queue		DEFS	KEY_QUEUE_CAPACITY
key_queue_head		DEFW	0
key_queue_tail		DEFW	0
key_queue_num_queued	DEFW	0

; snake row queue
snake_row_queue			DEFS	SNAKE_QUEUE_CAPACITY
snake_row_queue_head		DEFW	0
snake_row_queue_tail		DEFW	0
snake_row_queue_num_queued	DEFW	0

; snake column queue
snake_col_queue			DEFS	SNAKE_QUEUE_CAPACITY
snake_col_queue_head		DEFW	0
snake_col_queue_tail		DEFW	0
snake_col_queue_num_queued	DEFW	0

; snake direction queue
snake_direction_queue			DEFS	SNAKE_QUEUE_CAPACITY
snake_direction_queue_head		DEFW	0
snake_direction_queue_tail		DEFW	0
snake_direction_queue_num_queued	DEFW	0
