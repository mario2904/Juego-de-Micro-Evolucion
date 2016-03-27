#include    "msp430.h"
;------------------------------------------------------------------------------
;           Declare DELAY Macro
;------------------------------------------------------------------------------
delay       MACRO   COUNT
            mov.w   COUNT, TA0CCR0          ; Set Count limit
            bis.w   #GIE+LPM0, SR           ; enable interrupts and go to
                                            ; Low power mode
            nop
            ENDM

;------------------------------------------------------------------------------
            ORG     0C000h                  ; Program Start
;------------------------------------------------------------------------------
RESET       mov     #0280h, SP              ; Initialize Stackpointer
StopWDT     mov     #WDTPW+WDTHOLD, &WDTCTL ; Stop WDT

;------------------------------------------------------------------------------
;                   Configure Timers
;------------------------------------------------------------------------------
            bis.b   #LFXT1S_2,&BCSCTL3      ; ACLK = VLO (Very Low Clock 12KHz)
                                            ; setting bits 4 and 5 (LFXT1S) to 2
                                            ; in the Basic Clock
                                            ; System Control Register 3 (BCSCTL3)
            mov.w   #CCIE, &CCTL0           ; Enable CCR0 interrupts
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
            mov.b   #0C0h, R14              ; Load command to move cursor 2nd LN
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
;                   0   - TRANSISTOR
;                   1   - NAND
;                   2   - FLIP/FLOP
;                   3   - REGISTER
;                   4  - COUNTER
;                   5  - ALU
;                   6  - CPU
;                   7 - MCU
;------------------------------------------------------------------------------
            mov.b   #00h, R5                ; Set initial level to 0

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
            mov.b   #0C0h, R14              ; Load command to move cursor 2nd LN
            call    #COMMANDLCD             ; Send command to move cursor 2nd LN
            rla.b   R5                      ; For indexing address (16-bit)
            mov     WHICHLVL(R5), R13       ; Load Cstring of current
                                            ; level message
            rra.b   R5                      ; Return to readable value
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

            mov.b   #0C0h, R15              ; Load address of PIVOT in R15

            mov.b   R15, R14                ; Load command to move cursor 2nd LN
            call    #COMMANDLCD             ; Send command to move cursor 2nd LN

            mov.b   PIVOT, R14              ; Load character to R14
            call    #WRITELCD               ; Write charater to LCD

;------------------------------------------------------------------------------
;                   Start Counter
;------------------------------------------------------------------------------
            bic.b   #04h, &P2SEL            ; Allow pin P2.2 to interrupt
            bis.b   #04h, &P2IE             ; Enable local interrupt
            bic.b   #0Ch, &P2IFG            ; Disable Interrupt Flag

TOGGLE      delay   WHICHDELAY(R4)          ; Delay depending on difficulty
            mov.b   R15, R14                ; Load command to move cursor (back)
            call    #COMMANDLCD             ; Send command to move cursor (back)
            mov.b   #020h, R14              ; Load Character " " to R14
            call    #WRITELCD               ; Write charater to LCD

            inc.b   R15                     ; Point to current cursor address

            cmp.b   #0D0h, R15              ; LCD Address out of bounds?
            jnz     TOGGLE1

            mov.b   #0C0h, R15              ; Load address of 1st character
                                            ; of second line in R15
            mov.b   R15, R14                ; Load command to move cursor (back)
            call    #COMMANDLCD             ; Send command to move cursor (back)
TOGGLE1     mov.b   PIVOT, R14              ; Load character to R14
            call    #WRITELCD               ; Write charater to LCD
            jmp     TOGGLE

CONTINUE    sub.b   #0C0h, R15              ; Calculate offset, now R15 = Value

            bis.b   #04h, &P2SEL            ; Don't Allow pin P2.2 to interrupt
            bic.b   #04h, &P2IE             ; Disable local interrupt
            bic.b   #0Ch, &P2IFG            ; Disable Interrupt Flag

            mov.b   #01h, R14               ; Load command Clear Display
            call    #COMMANDLCD             ; Send command to Clear Display
            delay   #180                    ; Delay of 15ms
;------------------------------------------------------------------------------
;                   Calculate Absolute Value
;------------------------------------------------------------------------------
            sub.b   #07, R15                ; Subtract from 7
            jn      CONTINUE1
            jmp     CONTINUE2

CONTINUE1   inv.b   R15                     ; neg the value by 2's complement
            inc.b   R15                     ;

;------------------------------------------------------------------------------
;                   Check Condition
;------------------------------------------------------------------------------
CONTINUE2   cmp.b   CONDITION(R5), R15      ; R15 < CONDITION ?
            jl      YES1                    ; YES
NO          cmp.b   #0h, R5                 ; No, Are you in level 0?
            jz      YOULOST                 ; YES, Then you lost the game
            mov.b   FAILNEXT(R5), R5        ; Level down
            mov     #MSGDOWN, R13           ; Load Cstring of level down message
            call    #WRITEMSG               ; Write message
            jmp     MAINLOOP                ; Continue playing

YES         inc.b   R5                      ; Level up
            cmp.b   #07h, R5                ; Are you now in Last level 7?
            jz      YOUWON                  ; Yes, You won the game!
            mov     #MSGUP, R13             ; Load Cstring of level up message
            call    #WRITEMSG               ; Write message
            jmp     MAINLOOP                ; Continue playing

;------------------------------------------------------------------------------
;                   YOU WON STATE
;------------------------------------------------------------------------------
YOUWON      mov     #MSGWON, R13            ; Load Cstring of You Won! message
            call    #WRITEMSG               ; Write message
HERE1       jmp     HERE1                   ; END!

;------------------------------------------------------------------------------
;                   YOU LOST STATE
;------------------------------------------------------------------------------
YOULOST     mov     #MSGLOST, R13           ; Load Cstring of You Lost! message
            call    #WRITEMSG               ; Write message
HERE2       jmp     HERE2                   ; END!

;------------------------------------------------------------------------------
;                   SUBROUTINES
;------------------------------------------------------------------------------

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
            mov.b   #0C0h, R14              ; Load command to move cursor
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
            nop                             ; Small Delay
            nop                             ; Small Delay
            nop                             ; Small Delay
            nop                             ; Small Delay
;------------------------------------------------------------------------------
            ret

;------------------------------------------------------------------------------
;                   ISR of TA0 - Delay
;------------------------------------------------------------------------------
TA0CCR0_ISR mov.w   #0, TA0CCR0             ; Stop Timer
            bic.w   #GIE+LPM0, 0(SP)        ; Disable interrupts and
                                            ; Get out of Low power mode
            reti

;------------------------------------------------------------------------------
;                   ISR of Push Button B1 - Pin P2.2
;------------------------------------------------------------------------------
PB_ISR      bic.b   #0Ch, &P2IFG            ; Disable Interrupt Flag
            mov.w   #0, TA0CCR0             ; Stop Timer
            bic.w   #GIE+LPM0, 0(SP)        ; Disable interrupts and
                                            ; Get out of Low power mode
            mov.w   #CONTINUE, 2(SP)        ; After reti, go to Address CONTINUE
            reti

;------------------------------------------------------------------------------
;                   Switch Statements
;------------------------------------------------------------------------------
WHICHDIFF   DW      MSGADVAN, MSGINTER, MSGBASIC
WHICHLVL    DW      MSGLV0, MSGLV1, MSGLV2, MSGLV3, MSGLV4, MSGLV5, MSGLV6
            DW      MSGLV7
WHICHDELAY  DW      1200, 2400, 4800        ; For delays .1s, .2s, .4s
                                            ; respectively

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
CONDITION   DB      4, 4, 3, 3, 3, 2, 1
FAILNEXT    DB      0, 0, 1, 2, 3, 3, 4

;------------------------------------------------------------------------------
;                       Interrupt Vectors
;------------------------------------------------------------------------------
            ORG     0FFFEh                  ; MSP RESET Vector
            DW      RESET                   ; Address of label RESET
            ORG     0FFF2h                  ; Interrupt vector (TA0CCR0 CCIFG)
            DW      TA0CCR0_ISR             ; Timer TA0 interrupt subrutine
            ORG     0FFE6h                  ; Interrupt vector of P2
            DW      PB_ISR                  ; Address of label PB_ISR
            END
