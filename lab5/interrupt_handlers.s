; ###########################################################
;  ___ _   _ _____ _____ ____  ____  _   _ ____ _____ ____  
; |_ _| \ | |_   _| ____|  _ \|  _ \| | | |  _ \_   _/ ___| 
;  | ||  \| | | | |  _| | |_) | |_) | | | | |_) || | \___ \ 
;  | || |\  | | | | |___|  _ <|  _ <| |_| |  __/ | |  ___) |
; |___|_| \_| |_| |_____|_| \_\_| \_\\___/|_|    |_| |____/ 
; ###########################################################

; these are just some temporary interrupt handlers which
; calculate the interrupted address and pause execution
InterruptHandler
	SUB	R12, R14, #4
	B	.

FastInterruptHandler
	SUB	R12, R14, #4
	B	.
