; ###########################################################
;      ____ ___  _   _ ____ _____  _    _   _ _____ ____  
;     / ___/ _ \| \ | / ___|_   _|/ \  | \ | |_   _/ ___| 
;    | |  | | | |  \| \___ \ | | / _ \ |  \| | | | \___ \ 
;    | |__| |_| | |\  |___) || |/ ___ \| |\  | | |  ___) |
;     \____\___/|_| \_|____/ |_/_/   \_\_| \_| |_| |____/ 
; ###########################################################

; queue constants
KEY_QUEUE_CAPACITY	EQU	(1 << 4)
KEY_QUEUE_MASK		EQU	KEY_QUEUE_CAPACITY - 1

; keyboard constants
KEYBOARD_MATRIX_DIRECTION	EQU	&F100_2000
KEYBOARD_MATRIX			EQU	&F100_2004

; row constants
DIRECTION_READ_ROW	EQU	:0000_1111
ROW_369	                EQU	:0010_0000
ROW_258	                EQU	:0100_0000
ROW_147	                EQU	:1000_0000

; mode constants
MODE_USER_IRQ_DISABLED		EQU	&D0
MODE_USER_IRQ_ENABLED		EQU	&50
MODE_USER_FIQ_ENABLED		EQU	&90
MODE_USER_IRQ_AND_FIQ_ENABLED	EQU	&10
MODE_IRQ			EQU	&02
MODE_FIQ			EQU	&01

; interrupt constants
INT_ASSERT_REGISTER	EQU	&F200_0000
INT_MASK_REGISTER	EQU	&F200_0001
INT_LOWER_BUTTON	EQU	:1000_0000
INT_UPPER_BUTTON	EQU	:0100_0000
INT_TIMER_COMPARE	EQU	:0000_0001
INT_BUTTONS		EQU	:1100_0000
INT_BUTTONS_AND_TIMER	EQU	:1100_0001

; virtual IO port constants
IO_CONTROL_REGISTER	EQU	&F100_100C
IO_TIMER		EQU	&F100_1010
IO_TIMER_COMPARE	EQU	&F100_1014

; button constants
keypad_ABCD	EQU	&F1003000
KC_A		EQU	1
KC_B		EQU	2
KC_C		EQU	4
KC_D		EQU	8

; SVC constants
SVC_Max		EQU	(SVC_Last - SVC_Table) / 4
; these determine the correct offset for each SVC number based on label positions :))
SVC_BASE	EQU	&100
SVC_PrintC	EQU	SVC_BASE + (SVC_PRINTC_POS       - SVC_Table) / 4
SVC_PrintStr	EQU	SVC_BASE + (SVC_PRINTSTR_POS     - SVC_Table) / 4
SVC_SetPix	EQU	SVC_BASE + (SVC_SETPIX_POS       - SVC_Table) / 4
SVC_GetTime	EQU	SVC_BASE + (SVC_GETTIME_POS      - SVC_Table) / 4
SVC_PollButts	EQU	SVC_BASE + (SVC_POLLBUTTONS_POS  - SVC_Table) / 4
SVC_StoreInts	EQU	SVC_BASE + (SVC_STR_INTS_POS     - SVC_Table) / 4
SVC_ReadInts	EQU	SVC_BASE + (SVC_READ_INTS_POS    - SVC_Table) / 4
SVC_StoreCntrl	EQU	SVC_BASE + (SVC_STR_CNTRL_POS    - SVC_Table) / 4
SVC_ReadCntrl	EQU	SVC_BASE + (SVC_READ_CNTRL_POS   - SVC_Table) / 4
SVC_StoreTmCmp	EQU	SVC_BASE + (SVC_STR_TMCMP_POS    - SVC_Table) / 4
SVC_ReadTmCmp	EQU	SVC_BASE + (SVC_READ_TMCMP_POS   - SVC_Table) / 4
SVC_ReadKbMtx	EQU	SVC_BASE + (SVC_READ_KBMTX_POS   - SVC_Table) / 4
SVC_StoreKbMtx	EQU	SVC_BASE + (SVC_STR_KBMTX_POS    - SVC_Table) / 4
SVC_ReadKbDir	EQU	SVC_BASE + (SVC_READ_KBDIR_POS   - SVC_Table) / 4
SVC_StoreKbDir	EQU	SVC_BASE + (SVC_STR_KBDIR_POS    - SVC_Table) / 4

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
c_BS	EQU	8
c_HT	EQU	9
c_LF	EQU	10
c_VT	EQU	11
c_FF	EQU	12
c_CR	EQU	13

; general constants
True	EQU	1
False	EQU	0

; string lengths calculated from label differences
alphabet_len		EQU	alphabet_after - alphabet
