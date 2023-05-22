; ###########################################################
;                    ____    _  _____  _    
;                   |  _ \  / \|_   _|/ \   
;                   | | | |/ _ \ | | / _ \  
;                   | |_| / ___ \| |/ ___ \ 
;                   |____/_/   \_\_/_/   \_\
; ###########################################################
                        
ALIGN

; implement a basic cursor, 4 bytes for each
curcol	DEFW	0
currow	DEFW	0

; timer data
timer_ticks		DEFW	0
timer_counter		DEFW	0
timer_compare_increment	DEFW	130

; memory for the Interrupt based keyboard inputs
last_button_pressed	DEFW	0
button_pressed		DEFW	False

; printable characters string
alphabet	DEFB	"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ!\"#$%&'()*+,-./:;<=>?@[\]^_`{|}"
alphabet_after

; timer message string
timer_message	DEFB	"\t\t\t\t\t\t"
		DEFB	"Hi, welcome to my stopwatch\r\n"
		DEFB	"\t\t\t\t\t\t\t\t\t\t\t\t"
		DEFB	"Press A to GO!!!\r\n"
		DEFB	"\t\t\t\t\t\t\t\t\t\t"
		DEFB	"Press B to pause :)\r\n"
		DEFB	"Hold it for a second to reset the timer.\r\n"
		DEFB	"\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t"
timer_message_after


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
