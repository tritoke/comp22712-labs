; ###########################################################
;        __     _______ ____ _____ ___  ____  ____  
;        \ \   / / ____/ ___|_   _/ _ \|  _ \/ ___| 
;         \ \ / /|  _|| |     | || | | | |_) \___ \ 
;          \ V / | |__| |___  | || |_| |  _ < ___) |
;           \_/  |_____\____| |_| \___/|_| \_\____/ 
; ###########################################################
                                           
ORG 0
	B	_start			; reset
	B	UndefinedInstruct	; undef instr
	B	SVC_Entry		; supervisor
	B	PrefetchAbort		; prefetch abort
	B	DataAbort		; data abort
	B	.			; - - 
	B	InterruptHandler	; IRQ
	B	FastInterruptHandler	; FRQ
