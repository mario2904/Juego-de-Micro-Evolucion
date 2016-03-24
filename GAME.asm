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
            call    #STATICMSG              ; Call subroutine to show message
BTNPRESS1_1 bit.b   #04h, &P2IN             ; Poll Button B1 until pressed
            jnz     BTNPRESS1_1             ; This line will change depending
                                            ; on the button used
                                            ; Active high or Active low

;------------------------------------------------------------------------------
;                   Choose Difficulty Level
;                   R4 = Difficulty Level
;                   1 - Basic
;                   2 - Intermediate
;                   3 - Advanced
;------------------------------------------------------------------------------
            mov     #MSGDIFF, R13           ; Load Cstring of difficulty message
            call    #STATICMSG              ; Call subroutine to show message
            call    #DELAY500M              ; Wait ~2 seconds to show message
            call    #DELAY500M              ;
            call    #DELAY500M              ;
            call    #DELAY500M              ;
LOOPAGAIN   call    #DELAY500M              ; For debouncing
            mov.b   #01h, R4                ; Start assuming difficulty = 1
            mov     #MSGBASIC, R13          ; Load Cstring of basic message
            call    #STATICMSG              ; Call subroutine to show message
LOOPBASIC   bit.b   #04h, &P2IN             ; Poll Button 1
            jz      DIFFCHOSEN              ; This line will change depending
                                            ; on the button used
                                            ; Active high or Active low
            bit.b   #08h, &P2IN             ; Poll Button 2
            jnz     LOOPBASIC               ; This line will change depending
                                            ; on the button used
                                            ; Active high or Active low
            call    #DELAY500M              ; For debouncing
            inc     R4                      ; Continue assuming difficulty = 2
            mov     #MSGINTER, R13          ; Load Cstring of intermediate message
            call    #STATICMSG              ; Call subroutine to show message
LOOPINTER   bit.b   #04h, &P2IN             ; Poll Button 1
            jz      DIFFCHOSEN              ; This line will change depending
                                            ; on the button used
                                            ; Active high or Active low
            bit.b   #08h, &P2IN             ; Poll Button 2
            jnz     LOOPINTER               ; This line will change depending
                                            ; on the button used
                                            ; Active high or Active low
            call    #DELAY500M              ; For debouncing
            inc     R4                      ; Continue assuming difficulty = 3
            mov     #MSGADVAN, R13          ; Load Cstring of advanced message
            call    #STATICMSG              ; Call subroutine to show message
LOOPADVAN   bit.b   #04h, &P2IN             ; Poll Button 1
            jz      DIFFCHOSEN              ; This line will change depending
                                            ; on the button used
                                            ; Active high or Active low
            bit.b   #08h, &P2IN             ; Poll Button 2
            jnz     LOOPADVAN               ; This line will change depending
                                            ; on the button used
                                            ; Active high or Active low
            jmp     LOOPAGAIN               ; Loop again through all options

DIFFCHOSEN                                  ; Finished Decision Making

HERE        jmp     HERE

;------------------------------------------------------------------------------
;                   LCD - Show static Message
;------------------------------------------------------------------------------
;                   R13 = Pointer to message Cstring
;                   R14 = COMMAND/CHARACTER
;------------------------------------------------------------------------------
STATICMSG   mov.b   #01h, R14               ; Load command Clear Display
            call    #COMMANDLCD             ; Send command to Clear Display
            call    #DELAY15M               ; Wait until LCD is stable
STATICMSGA1 mov.b   @R13+, R14              ; Load character to R14
            call    #WRITELCD               ; Write charater to LCD
            cmp.b   #00h, 0(R13)            ; Is this the null character?
            jnz     STATICMSGA1             ; If it's not, continue loop
            mov.b   #0A8h, R14              ; Load command to move cursor
            call    #COMMANDLCD             ; Send command to move cursor
            inc     R13                     ; Fetch next Cstring
STATICMSGA2 mov.b   @R13+, R14              ; Load character to R14
            call    #WRITELCD               ; Write charater to LCD
            cmp.b   #00h, 0(R13)            ; Is this the null character?
            jnz     STATICMSGA2             ; If it's not, continue loop
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
;                   Static Messages - Cstring
;------------------------------------------------------------------------------
MSGSTART    DB      "Presiona el",  "Boton Principal"
MSGDIFF     DB      "Escoja Modo de", "Operacion"
MSGBASIC    DB      "     Basico     ", "Si=B1      No=B2"
MSGINTER    DB      "   Intermedio   ", "Si=B1      No=B2"
MSGADVAN    DB      "    Avanzado    ", "Si=B1      No=B2"
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
