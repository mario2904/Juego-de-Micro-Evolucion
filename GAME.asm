#include    <msp430.h>
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
            bis.b   #02h, &P2DIR            ; Set P2.0 and P2.1 as output
                                            ; For use as ENABLE and
                                            ; REGISTER SELECT of the LCD 16X2
            bic.b   #0Ch, &P2DIR            ; Set P2.2 and P2.3 as input
                                            ; For use with the two buttons

;------------------------------------------------------------------------------
;                   Initialize LCD
;------------------------------------------------------------------------------
            bic.b   #01h, &P1OUT            ; Turn off ENABLE
            call    #DELAY15M               ; Wait for 15ms
            mov.b   #030h, R14              ; Load command Wake
            call    #COMMAND                ; Send command to Wake LCD #1
            call    #DELAY5M                ; Wait for 5ms
            mov.b   #030h, R14              ; Load command Wake
            call    #COMMAND                ; Send command to Wake LCD #2
            call    #DELAY160U              ; Wait for 160us
            mov.b   #030h, R14              ; Load command Wake
            call    #COMMAND                ; Send command to Wake LCD #3
            call    #DELAY160U              ; Wait for 160us
            mov.b   #038h, R14              ; Load command set 8-bit/2-line
            call    #COMMAND                ; Send command to set 8-bit/2-line
            mov.b   #010h, R14              ; Load command set cursor
            call    #COMMAND                ; Send command to set cursor
            mov.b   #0Ch, R14               ; Load command Turn on the
                                            ; Display and Cursor
            call    #COMMAND                ; Send command to Turn on the
                                            ; Display and Cursor
            mov.b   #06h, R14               ; Load command Entry mode set
            call    #COMMAND                ; Send command Entry mode set




;------------------------------------------------------------------------------
;                   LCD - Command Subroutine
;------------------------------------------------------------------------------
;                   P2.0 = ENABLE
;                   P2.1 = RESGISTER SELECT
;                   R14  = COMMAND
;------------------------------------------------------------------------------
COMMAND     mov.b   R14, &P1OUT             ; Load COMMAND in Port 1
            bic.b   #02h, &P2OUT            ; Turn off REGISTER SELECT
            bis.b   #01h, &P2OUT            ; Turn on ENABLE
;------------------------------------------------------------------------------
;                   Delay >= 300ns          Really small!
            dec     R15
;------------------------------------------------------------------------------
            bic.b   #01h, &P2OUT            ; Turn off ENABLE
            ret

;------------------------------------------------------------------------------
;                   LCD - Write Subroutine
;------------------------------------------------------------------------------
;                   P2.0 = ENABLE
;                   P2.1 = RESGISTER SELECT
;                   R14  = SYMBOL (LETTER/NUMBER)
;------------------------------------------------------------------------------
WRITE       mov.b   R14, &P1OUT             ; Load SYMBOL in Port 1
            bis.b   #02h, &P2OUT            ; Turn on REGISTER SELECT
            bis.b   #01h, &P2OUT            ; Turn on ENABLE
;------------------------------------------------------------------------------
;                   Delay >= 300ns          Really small!
            dec     R15
;------------------------------------------------------------------------------
            bic.b   #01h, &P2OUT            ; Turn off ENABLE
            ret

;------------------------------------------------------------------------------
;              SUBROUTINE DELAY15m (15.001ms)(OVERALL cycles = 14,993 + 8 = 15,001)
;------------------------------------------------------------------------------
DELAY15M    mov     #4997, R15
DELAY15MA   dec     R15
            jnz     DELAY15MA
            ret

;------------------------------------------------------------------------------
;              SUBROUTINE DELAY5m (5.002ms)(OVERALL cycles = 4,994 + 8 = 5,002)
;------------------------------------------------------------------------------
DELAY5M     mov     #1664, R15
DELAY5MA    dec     R15
            jnz     DELAY5MA
            ret

;------------------------------------------------------------------------------
;              SUBROUTINE DELAY160U (160us)(OVERALL cycles = 152 + 8 = 160)
;------------------------------------------------------------------------------
DELAY160U   mov     #50, R15
DELAY160UA  dec     R15
            jnz     DELAY160UA
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
            DW      RESET                   ; address of label RESET
            END
