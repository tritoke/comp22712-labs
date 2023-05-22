; ###########################################################
;                    ____    _  _____  _    
;                   |  _ \  / \|_   _|/ \   
;                   | | | |/ _ \ | | / _ \  
;                   | |_| / ___ \| |/ ___ \ 
;                   |____/_/   \_\_/_/   \_\
; ###########################################################

LTORG

; implement a basic cursor, 4 bytes for each
curcol	DEFW	0
currow	DEFW	0

; key debounce data
key_debounce_counters	DEFS	12
key_curr_pressed	DEFW	0

; printable characters string
alphabet	DEFB	"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!\"#$%&'()*+,-./:;<=>?@[\]^_`{|}"
alphabet_after

; game over message string
game_over_message	DEFB	"GAME OVER ## score = "
game_over_message_after

; highscore message string
highscore_message	DEFB	"\r\n\r\nHIGHSCORE = "
highscore_message_after

; new highscore message string
new_highscore_message	DEFB	"\r\n\r\n!!! NEW HIGHSCORE !!!"
new_highscore_message_after

restart_message		DEFB	"\r\n\r\nPRESS * to restart"
restart_message_after

instructions_message
	DEFB	c_VT, c_VT, c_VT, c_VT, c_CR
	DEFB	"How to play:                \r\n"
	DEFB	"                            \r\n"
	DEFB	"Go Left:  4\r\n"
	DEFB	"Go Right: 6\r\n"
	DEFB	"Go Up:    2\r\n"
	DEFB	"Go Down:  8\r\n"
	DEFB	"\n"
	DEFB	"Press any key to start."
instructions_message_after

difficulty_message
	DEFB	"Choose your difficulty:\r\n"
	DEFB	"Easy:    1\r\n"
	DEFB	"Medium:  2\r\n"
	DEFB	"Hard:    3\r\n"
	DEFB	"EXTREME: 4"
difficulty_message_after

; lookup table for the keyboard
key_table	DEFB	"369#2580147*"

; sometimes u just need a zero u know
zero	DEFB	0x00

; colours
purple	DEFB	0x80, 0x00, 0x80
yellow	DEFB	0xFF, 0xF4, 0x30
white	DEFB	0xFF, 0xFF, 0xFF
black	DEFB	0x00, 0x00, 0x00

; starts at first ascii character - ' ' 0x20
font
INCLUDE font.s

; include the data / constants for the assets
INCLUDE assets.s

; RNG state
ALIGN
xorshift_rng_state	DEFW	0

; snake variables
snake_frame_start		DEFW	0
snake_min_frame_time		DEFW	0
snake_score			DEFW	0
snake_highscore			DEFW	0
snake_generate_new_apple	DEFW	False

; add a global counter for time
timer_counter	DEFW	0

; allows O(1) lookup for whether the snake is going to eat itself / whether the apple generated is valid
LTORG
board_state	DEFS	(ASSET_ROWS * ASSET_COLS)
