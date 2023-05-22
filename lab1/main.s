        B       main

leds    DEFW    &AC03_8400
states  DEFB    &44, &64, &14, &24 ; the colours to store to the LED for each state
        DEFB    &44, &46, &41, &42
        ALIGN

main    MOV     R2, #0           ; state = 0
mloop   AND     R2, R2, #&7      ; state %= 8
        ADR     R4, states
        LDR     R0, [R4, R2] ; get state colours
        BL      set_led

        MOV     R0, #&80000
        BL      delay

        ADD     R2, R2, #1 ; move to next state

        B       mloop
        ; end the program?? lol
        SVC     2


; store the value in R0 to the LED
; clobbers R1
set_led LDR     R1, leds
        STRB    R0, [R1]
        MOV     PC, LR

; loop for R0 cycles
delay   SUBS    R0, R0, #1
        BNE     delay
        MOV     PC, LR

