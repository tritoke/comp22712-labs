; ###########################################################
;                    ____    _  _____  _    
;                   |  _ \  / \|_   _|/ \   
;                   | | | |/ _ \ | | / _ \  
;                   | |_| / ___ \| |/ ___ \ 
;                   |____/_/   \_\_/_/   \_\
; ###########################################################
                        
; implement a basic cursor, 4 bytes for each
curcol	DEFW	0
currow	DEFW	0

; key debounce data
key_debounce_counters	DEFS	12
key_curr_pressed	DEFW	0

; key queue data
key_queue		DEFS	KEY_QUEUE_CAPACITY
key_queue_head		DEFW	0
key_queue_tail		DEFW	0
key_queue_num_queued	DEFW	0

; printable characters string
alphabet	DEFB	"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!\"#$%&'()*+,-./:;<=>?@[\]^_`{|}"
alphabet_after

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

ALIGN
