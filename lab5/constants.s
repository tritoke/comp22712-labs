; ###########################################################
;      ____ ___  _   _ ____ _____  _    _   _ _____ ____  
;     / ___/ _ \| \ | / ___|_   _|/ \  | \ | |_   _/ ___| 
;    | |  | | | |  \| \___ \ | | / _ \ |  \| | | | \___ \ 
;    | |__| |_| | |\  |___) || |/ ___ \| |\  | | |  ___) |
;     \____\___/|_| \_|____/ |_/_/   \_\_| \_| |_| |____/ 
; ###########################################################

; base address of the framebuffer

; timer constants
timer		EQU	&F1001010
; this was just what worked for me locally, change to something more appropriate for you if it is very off
TIMER_PRESCALER	EQU	300

; button constants
keypad_ABCD	EQU	&F1003000
KC_A		EQU	1
KC_B		EQU	2
KC_C		EQU	4
KC_D		EQU	8

; SVC constants
SVC_Max		EQU	(SVC_Last - SVC_Table) / 4
SVC_PrintC	EQU	&100
SVC_PrintStr	EQU	&101
SVC_SetPix	EQU	&102
SVC_GetTime	EQU	&103
SVC_BcdConv	EQU	&104
SVC_PrintHexC	EQU	&105
SVC_ButtPress	EQU	&106

; font / framebuffer constants
fbuf		EQU	&AC00_0000
FG_COLOUR	EQU	yellow
BG_COLOUR	EQU	black
FBUF_WIDTH	EQU	960
BYTES_PER_PIXEL	EQU	3
FONT_WIDTH	EQU	7
FONT_HEIGHT	EQU	8
ROWS		EQU	240
COLS		EQU	320
CURSOR_COLS	EQU	40
CURSOR_ROWS	EQU	30

; character constants
c_BS			EQU	8
c_HT			EQU	9
c_LF			EQU	10
c_VT			EQU	11
c_FF			EQU	12
c_CR			EQU	13

; general constants
True	EQU	1
False	EQU	0

; string lengths calculated from label differences
alphabet_len		EQU	alphabet_after - alphabet
timer_message_len	EQU	timer_message_after - timer_message
