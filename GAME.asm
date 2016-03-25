#include    "msp430.h"

;------------------------------------------------------------------------------
;           Declare Macro
;------------------------------------------------------------------------------
delay       MACRO   COUNT
            mov.w   COUNT, TA0CCR0          ; Set Count limit
            bis.w   #GIE+LPM0, SR           ; enable interrupts and go to Low power mode
            nop
            ENDM

;------------------------------------------------------------------------------
            ORG     0C000h                  ; Program Start
;------------------------------------------------------------------------------
RESET       mov     #0280h, SP              ; Initialize Stackpointer
StopWDT     mov     #WDTPW+WDTHOLD, &WDTCTL ; Stop WDT

;------------------------------------------------------------------------------
;                   Configure Timer
;------------------------------------------------------------------------------
            bis.b   #LFXT1S_2,&BCSCTL3      ; ACLK = VLO (Very Low Clock 12KHz)
                                            ; setting bits 4 and 5 (LFXT1S) to 2
                                            ; in the Basic Clock
                                            ; System Control Register 3 (BCSCTL3)
            mov.w   #CCIE, &CCTL0           ; Enable counter interrupts
            mov.w   #TASSEL_1+MC_1, &TA0CTL ; Use ACLK, up-mode

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

            delay   #180                    ; Delay of 15ms
            mov.b   #030h, R14              ; Load command Wake
            call    #COMMANDLCD             ; Send command to Wake LCD #1
            delay   #60                     ; Delay of 5ms
            mov.b   #030h, R14              ; Load command Wake
            call    #COMMANDLCD             ; Send command to Wake LCD #2
            delay   #2                      ; Delay of ~160u
            mov.b   #030h, R14              ; Load command Wake
            call    #COMMANDLCD             ; Send command to Wake LCD #3
            delay   #2                      ; Delay of ~160u
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
            delay   #180                    ; Delay of 15ms
                                            ; Wait until LCD is stable

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
;                   Choose Difficulty Level State
;------------------------------------------------------------------------------
;                   R4 = Difficulty Level
;                   4 - Basic
;                   2 - Intermediate
;                   1 - Advanced
;------------------------------------------------------------------------------
            mov     #MSGDIFF, R13           ; Load Cstring of difficulty message
            call    #WRITEMSG               ; Write message
            delay   #24000                  ; Wait 2 seconds to show message

            mov.b   #01h, R14               ; Load command Clear Display
            call    #COMMANDLCD             ; Send command to Clear Display
            delay   #180                    ; Delay of 15ms
                                            ; Wait until LCD is stable
            mov.b   #0A8h, R14              ; Load command to move cursor 2nd LN
            call    #COMMANDLCD             ; Send command to move cursor 2nd LN
            mov     #MSGOPTION, R13         ; Load Cstring of option message
            call    #WRITESTR               ; Write string in 2nd line

LOOPAGAIN   mov.b   #04h, R4                ; Start assuming difficulty = 4
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
            delay   #6000                   ; delay of 0.5s for debouncing
            clrc                            ; clear carry bit
            rrc.b   R4                      ; Assume lower difficulty
            jnc     ASKNEXTDIFF             ; Ask for next difficulty
            jmp     LOOPAGAIN

DIFFCHOSEN  delay   #6000                   ; delay of 0.5s for debouncing
                                            ; Finished Decision Making
;------------------------------------------------------------------------------
;                   Set initial Level to 1
;------------------------------------------------------------------------------
;                   R5  = Level
;                   1   - TRANSISTOR
;                   2   - NAND
;                   4   - FLIP/FLOP
;                   8   - REGISTER
;                   16  - COUNTER
;                   32  - ALU
;                   64  - CPU
;                   128 - MCU
;------------------------------------------------------------------------------
            mov.b   #01h, R5                ; Set initial level to 1

;------------------------------------------------------------------------------
;****************** Start MainLoop ********************************************
;------------------------------------------------------------------------------
MAINLOOP    mov.b   #01h, R14               ; Load command Clear Display
            call    #COMMANDLCD             ; Send command to Clear Display
            delay   #180                    ; Delay of 15ms
                                            ; Wait until LCD is stable

;------------------------------------------------------------------------------
;                   Show Current Level
;------------------------------------------------------------------------------
            mov     #MSGLVL, R13            ; Load Cstring of level message
            call    #WRITESTR               ; Write string in 1st line
            mov.b   #0A8h, R14              ; Load command to move cursor 2nd LN
            call    #COMMANDLCD             ; Send command to move cursor 2nd LN
            mov     WHICHLVL(R5), R13       ; Load Cstring of current
                                            ; level message
            call    #WRITESTR               ; Write string in 2nd line

            delay   #24000                  ; Wait 2 seconds to show message

;------------------------------------------------------------------------------
;                   Start Counter and Select Number State
;------------------------------------------------------------------------------
            mov.b   #01h, R14               ; Load command Clear Display
            call    #COMMANDLCD             ; Send command to Clear Display
            delay   #180                    ; Delay of 15ms
                                            ; Wait until LCD is stable

            mov     #MSGINSTR, R13          ; Load Cstring of instruct message
            call    #WRITEMSG               ; Write message
            delay   #24000                  ; Wait 2 seconds to show message

            mov.b   #01h, R14               ; Load command Clear Display
            call    #COMMANDLCD             ; Send command to Clear Display
            delay   #180                    ; Delay of 15ms
                                            ; Wait until LCD is stable

            mov     #MSGNUMBS, R13          ; Load Cstring of numbers message
            call    #WRITESTR               ; Write string in 1st line
            mov.b   #0A8h, R14              ; Load command to move cursor 2nd LN
            call    #COMMANDLCD             ; Send command to move cursor 2nd LN

            mov     PIVOT, R14              ; Load character to R14
            call    #WRITELCD               ; Write charater to LCD


HERE        jmp     HERE

;------------------------------------------------------------------------------
;                   LCD - Write 1 line string Message
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
            delay   #180                    ; Delay of 15ms
                                            ; Wait until LCD is stable
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
;                   Switch Statements
;------------------------------------------------------------------------------
WHICHDIFF   DW      MSGADVAN, MSGINTER, MSGBASIC
WHICHLVL    DW      MSGLV0, MSGLV1, MSGLV2, MSGLV3, MSGLV4, MSGLV5, MSGLV6
            DW      MSGLV7
;WHICHDELAY  DW      DELAY100M, DELAY200M, DELAY400M

;------------------------------------------------------------------------------
;                   Static Messages - Cstring
;------------------------------------------------------------------------------
MSGSTART    DB      "Presiona el",  "Boton Principal"
MSGDIFF     DB      "Escoja Modo de", "Operacion"
MSGOPTION   DB      "Si=B1      No=B2"
MSGBASIC    DB      "     Basico     "
MSGINTER    DB      "   Intermedio   "
MSGADVAN    DB      "    Avanzado    "
MSGINSTR    DB      "Presiona B1", "Para Detener"
MSGNUMBS    DB      "0123456789ABCDEF"
MSGLVL      DB      "Esta en Nivel"
MSGLV0      DB      "0 - TRANSISTOR"
MSGLV1      DB      "1 - NAND"
MSGLV2      DB      "2 - FLIP/FLOP"
MSGLV3      DB      "3 - REGISTER"
MSGLV4      DB      "4 - COUNTER"
MSGLV5      DB      "5 - ALU"
MSGLV6      DB      "6 - CPU"
MSGLV7      DB      "7 - MCU"
MSGUP       DB      "Avanza al", "Proximo Nivel"
MSGDOWN     DB      "Baja de Nivel", " "
MSGWON      DB      "Felicidades! :)", "Usted ha Ganado"
MSGLOST     DB      "Lo sentimos :(", "Usted ha Perdido"
PIVOT       DB      "^"

;------------------------------------------------------------------------------
;                   Lookup Tables - Index=Level
;------------------------------------------------------------------------------
CONDITION   DB      4, 4, 3, 3, 3, 2, 0
FAILNEXT    DB      0, 0, 1, 2, 3, 3, 4

;------------------------------------------------------------------------------
;                   ISR of TA0 - Delay
;------------------------------------------------------------------------------
TACCR0_ISR  mov.w   #0, TA0CCR0             ; Stop Timer
            bic.w   #GIE+LPM0, 0(SP)        ; Disable interrupts and
                                            ; Get out of Low power mode
            reti

;------------------------------------------------------------------------------
;                       Interrupt Vectors
;------------------------------------------------------------------------------
            ORG     0FFFEh                  ; MSP RESET Vector
            DW      RESET                   ; Address of label RESET
            ORG     0FFF2h                  ; interrupt vector (TACCR0)
            DW      TACCR0_ISR              ; Timer interrupt subrutine
            END
            END
