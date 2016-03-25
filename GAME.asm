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
            call    #DELAY15M               ; Wait until LCD is stable

;------------------------------------------------------------------------------
;                   Show First Message
;------------------------------------------------------------------------------
            mov     #MSGSTART, R13          ; Load Cstring of first message
            call    #WRITEMSG               ; Write message
POLL1       bit.b   #04h, &P2IN             ; Poll Button B1 until pressed
            jnz     POLL1                   ; This line will change depending
                                            ; on the button used
                                            ; Active high or Active low

;------------------------------------------------------------------------------
;                   Choose Difficulty Level
;------------------------------------------------------------------------------
;                   R4 = Difficulty Level
;                   4 - Basic
;                   2 - Intermediate
;                   0 - Advanced
;------------------------------------------------------------------------------
            mov     #MSGDIFF, R13           ; Load Cstring of difficulty message
            call    #WRITEMSG               ; Write message
            call    #DELAY500M              ; Wait ~2 seconds to show message
            call    #DELAY500M              ;
            call    #DELAY500M              ;
            call    #DELAY500M              ;
            mov.b   #01h, R14               ; Load command Clear Display
            call    #COMMANDLCD             ; Send command to Clear Display
            call    #DELAY15M               ; Wait until LCD is stable
            mov.b   #0A8h, R14              ; Load command to move cursor 2nd LN
            call    #COMMANDLCD             ; Send command to move cursor 2nd LN
            mov     #MSGOPTION, R13         ; Load Cstring of option message
            call    #WRITESTR               ; Write string in 2nd line

LOOPAGAIN   mov.b   #04h, R4                ; Start assuming difficulty = 2
ASKNEXTDIFF mov     WHICHDIFF(R4), R13      ; Load Cstring of currently
                                            ; assumed difficulty message
            mov.b   #080h, R14              ; Load command to move cursor 1st LN
            call    #COMMANDLCD             ; Send command to move cursor 1st LN
            call    #WRITESTR               ; Write string in 1st line
POLL2       bit.b   #04h, &P2IN             ; Poll Button 1
            jz      DIFFCHOSEN              ; This line will change depending
                                            ; on the button used
                                            ; Active high or Active low
            bit.b   #08h, &P2IN             ; Poll Button 2
            jnz     POLL2                   ; This line will change depending
                                            ; on the button used
                                            ; Active high or Active low
            call    #DELAY500M              ; For debouncing
            clrc                            ; clear carry bit
            rrc.b   R4                      ; Assume lower difficulty
            jnc     ASKNEXTDIFF             ; Ask for next difficulty
            jmp     LOOPAGAIN

DIFFCHOSEN                                  ; Finished Decision Making

HERE        jmp     HERE

;------------------------------------------------------------------------------
;                   LCD - Write 1 line string Message in the second line
;------------------------------------------------------------------------------
;                   R13 = Pointer to message Cstring
;                   R14 = COMMAND/CHARACTER
;------------------------------------------------------------------------------
WRITESTR    mov.b   @R13+, R14              ; Load character to R14
            call    #WRITELCD               ; Write charater to LCD
            cmp.b   #00h, 0(R13)            ; Is this the null character?
            jnz     WRITESTR                ; If it's not, continue loop
            ret

;------------------------------------------------------------------------------
;                   LCD - Write 2 line Message
;------------------------------------------------------------------------------
;                   R13 = Pointer to message Cstring
;                   R14 = COMMAND/CHARACTER
;------------------------------------------------------------------------------
WRITEMSG    mov.b   #01h, R14               ; Load command Clear Display
            call    #COMMANDLCD             ; Send command to Clear Display
            call    #DELAY15M               ; Wait until LCD is stable
            call    #WRITESTR               ; Write first line
            mov.b   #0A8h, R14              ; Load command to move cursor
            call    #COMMANDLCD             ; Send command to move cursor
            inc     R13                     ; Fetch next Cstring
            call    #WRITESTR               ; Write second line
            ret

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
;                   Dummy Delay - Wait for LCD to stabilize
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
;                   Dummy Delay - Wait for LCD to stabilize
;------------------------------------------------------------------------------
            nop                             ; Small Delay
            nop                             ; Small Delay
            nop                             ; Small Delay
            nop                             ; Small Delay
;------------------------------------------------------------------------------
            ret

;------------------------------------------------------------------------------
;                   SUBROUTINE DELAY500ms |~500.01ms|OVERALL cycles = 550,010
;------------------------------------------------------------------------------
DELAY500M   mov     #50000, R15             ; Load number of iterations
DELAY500MA  dec     R15                     ; Decrement number of iterations
            nop                             ; Small Delay
            nop                             ; Small Delay
            nop                             ; Small Delay
            nop                             ; Small Delay
            nop                             ; Small Delay
            nop                             ; Small Delay
            nop                             ; Small Delay
            nop                             ; Small Delay
            jnz     DELAY500MA              ; If Z != 0 continue looping
            ret

;------------------------------------------------------------------------------
;                   SUBROUTINE DELAY15m |~15.001ms|OVERALL cycles = 16,501
;------------------------------------------------------------------------------
DELAY15M    mov     #5497, R15              ; Load number of iterations
DELAY15MA   dec     R15                     ; Decrement number of iterations
            jnz     DELAY15MA               ; If Z != 0 continue looping
            ret

;------------------------------------------------------------------------------
;                   SUBROUTINE DELAY5m |5.00ms|OVERALL cycles = 5,500
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
;                   Switch Statements
;------------------------------------------------------------------------------
WHICHDIFF   DW      MSGADVAN, MSGINTER, MSGBASIC

;------------------------------------------------------------------------------
;                   Static Messages - Cstring
;------------------------------------------------------------------------------
MSGSTART    DB      "Presiona el",  "Boton Principal"
MSGDIFF     DB      "Escoja Modo de", "Operacion"
MSGOPTION   DB      "Si=B1      No=B2"
MSGBASIC    DB      "     Basico     "
MSGINTER    DB      "   Intermedio   "
MSGADVAN    DB      "    Avanzado    "
MSGUP       DB      "Avanza al", "Proximo Nivel"
MSGDOWN     DB      "Baja de Nivel", " "
MSGWON      DB      "Felicidades! :)", "Usted ha Ganado"
MSGLOST     DB      "Lo sentimos :(", "Usted ha Perdido"

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
