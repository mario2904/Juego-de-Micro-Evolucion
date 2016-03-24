#include    "msp430.h"
;------------------------------------------------------------------------------
            ORG     0C000h                  ; Program Start
;------------------------------------------------------------------------------
RESET       mov     #0280h, SP              ; Initialize Stackpointer
StopWDT     mov     #WDTPW+WDTHOLD, &WDTCTL ; Stop WDT

;------------------------------------------------------------------------------
;                   Configure Ports
;------------------------------------------------------------------------------
            bis.b   #0FFh, &P1DIR           ; Set all ports of P1 as output
                                            ; For use with the LCD 16X2
                                            ; In 8-bit mode
            bis.b   #03h, &P2DIR            ; Set P2.0 and P2.1 as output
                                            ; For use as ENABLE and
                                            ; REGISTER SELECT of the LCD 16X2
            bic.b   #0Ch, &P2DIR            ; Set P2.2 and P2.3 as input
                                            ; For use with the two buttons
            bis.b   #0Ch, &P2REN            ; Select internal resistor of P2.2
                                            ; and P2.3
            bis.b   #0Ch, &P2OUT            ; Make it pull-up both internal
                                            ; resistors

;------------------------------------------------------------------------------
;                   Initialize LCD
;------------------------------------------------------------------------------
            bic.b   #01h, &P1OUT            ; Turn off ENABLE
            call    #DELAY15M               ; Wait for 15ms
            mov.b   #030h, R14              ; Load command Wake
            call    #COMMANDLCD             ; Send command to Wake LCD #1
            call    #DELAY5M                ; Wait for 5ms
            mov.b   #030h, R14              ; Load command Wake
            call    #COMMANDLCD             ; Send command to Wake LCD #2
            call    #DELAY160U              ; Wait for 160us
            mov.b   #030h, R14              ; Load command Wake
            call    #COMMANDLCD             ; Send command to Wake LCD #3
            call    #DELAY160U              ; Wait for 160us
            mov.b   #038h, R14              ; Load command set 8-bit/2-line
            call    #COMMANDLCD             ; Send command to set 8-bit/2-line
            mov.b   #010h, R14              ; Load command set cursor
            call    #COMMANDLCD             ; Send command to set cursor
            mov.b   #0Ch, R14               ; Load command Turn on the
                                            ; Display and Cursor
            call    #COMMANDLCD             ; Send command to Turn on the
                                            ; Display and Cursor
            mov.b   #06h, R14               ; Load command Entry mode set
            call    #COMMANDLCD             ; Send command Entry mode set
            mov.b   #01h, R14               ; Load command Clear Display
            call    #COMMANDLCD             ; Send command to Clear Display

            call    #DELAY15M
HERE        jmp     HERE

;------------------------------------------------------------------------------
;                   LCD - Command Subroutine
;------------------------------------------------------------------------------
;                   P2.0 = ENABLE
;                   P2.1 = RESGISTER SELECT
;                   R14  = COMMAND
;------------------------------------------------------------------------------
COMMANDLCD  mov.b   R14, &P1OUT             ; Load COMMAND in Port 1
            bic.b   #02h, &P2OUT            ; Turn off REGISTER SELECT
            bis.b   #01h, &P2OUT            ; Turn on ENABLE
;------------------------------------------------------------------------------
;                   Delay >= 300ns          Really small!
            nop                             ; Small Delay
;------------------------------------------------------------------------------
            bic.b   #01h, &P2OUT            ; Turn off ENABLE
;------------------------------------------------------------------------------
;                   Dummy Delay
;------------------------------------------------------------------------------
            nop                             ; Small Delay
            nop                             ; Small Delay
            nop                             ; Small Delay
            nop                             ; Small Delay
;------------------------------------------------------------------------------
            ret

;------------------------------------------------------------------------------
;                   LCD - Write Subroutine
;------------------------------------------------------------------------------
;                   P2.0 = ENABLE
;                   P2.1 = RESGISTER SELECT
;                   R14  = SYMBOL (LETTER/NUMBER)
;------------------------------------------------------------------------------
WRITELCD    mov.b   R14, &P1OUT             ; Load SYMBOL in Port 1
            bis.b   #02h, &P2OUT            ; Turn on REGISTER SELECT
            bis.b   #01h, &P2OUT            ; Turn on ENABLE
;------------------------------------------------------------------------------
;                   Delay >= 300ns          Really small!
            nop                             ; Small Delay
;------------------------------------------------------------------------------
            bic.b   #01h, &P2OUT            ; Turn off ENABLE
;------------------------------------------------------------------------------
;                   Dummy Delay
;------------------------------------------------------------------------------
            nop                             ; Small Delay
            nop                             ; Small Delay
            nop                             ; Small Delay
            nop                             ; Small Delay
;------------------------------------------------------------------------------
            ret

;------------------------------------------------------------------------------
;                   SUBROUTINE DELAY15m |~15.001ms|OVERALL cycles = 16501
;------------------------------------------------------------------------------
DELAY15M    mov     #5497, R15              ; Load number of iterations
DELAY15MA   dec     R15                     ; Decrement number of iterations
            jnz     DELAY15MA               ; If Z != 0 continue looping
            ret

;------------------------------------------------------------------------------
;                   SUBROUTINE DELAY5m |5.00ms|OVERALL cycles = 5500
;------------------------------------------------------------------------------
DELAY5M     mov     #1830, R15              ; Load number of iterations
DELAY5MA    dec     R15                     ; Decrement number of iterations
            jnz     DELAY5MA                ; If Z != 0 continue looping
            ret

;------------------------------------------------------------------------------
;                   SUBROUTINE DELAY160U |~161.81us|OVERALL cycles = 178
;------------------------------------------------------------------------------
DELAY160U   mov     #56, R15                ; Load number of iterations
DELAY160UA  dec     R15                     ; Decrement number of iterations
            jnz     DELAY160UA              ; If Z != 0 continue looping
            ret

;------------------------------------------------------------------------------
;                   Lookup Tables - Index=Level
;------------------------------------------------------------------------------
CONDITION   DB      4, 4, 3, 3, 3, 2, 0
FAILNEXT    DB      0, 0, 1, 2, 3, 3, 4

;------------------------------------------------------------------------------
;                       Interrupt Vectors
;------------------------------------------------------------------------------
            ORG     0FFFEh                  ; MSP RESET Vector
            DW      RESET                   ; Address of label RESET
            END
