#include    "msp430.h"
; *****************************************************************************
; Connections:
;
;                -----------                   ----------
;               |msp430g2553|                 |   LCD    |
;               |           |                 |          |
;               |       P1.0|---------------->|D0        |
;               |       P1.1|---------------->|D1        |
;               |       P1.2|---------------->|D2        |
;               |       P1.3|---------------->|D3        |
;               |       P1.4|---------------->|D4        |
;               |       P1.5|---------------->|D5        |
;               |       P1.6|---------------->|D6        |
;               |       P1.7|---------------->|D7        |
;               |           |                 |          |
;               |       P2.0|---------------->|E         |
;               |           |         GND --->|RW        |
;               |       P2.1|---------------->|RS        |
;               |           |                 |          |
;               |       P2.2|----------        ----------
;               |       P2.3|-----     |
;                -----------      |    |
;                                 |    |
;                                ---  ---
;                            B2 | x || x | B1
;                                ---  ---
;                                 |    |
;                                   GND
;
;Description: This is a simple game called: El Juego de la Micro-Evolucion
;
;
; *****************************************************************************
;------------------------------------------------------------------------------
;                   Declare DELAY Macro
;                   COUNT = Value to count up to
;------------------------------------------------------------------------------
delay       MACRO   COUNT
            mov.w   COUNT, TA0CCR0          ; Set Count limit
            bis.w   #GIE+LPM0, SR           ; enable interrupts and go to
                                            ; Low power mode
            nop
            ENDM

;------------------------------------------------------------------------------
;                   Declare WRITE Macro
;                   CHAR = ASCII value of character to write in LCD
;                   R14  = (CHARACTER) DATUM to pass to the LCD
;------------------------------------------------------------------------------
lcdwrt      MACRO   CHAR
            bis.b   #02h, &P2OUT            ; Turn on REGISTER SELECT
            mov.b   CHAR, R14               ; Load character CHAR
            call    #WRT_CMD_LCD            ; Write charater CHAR to LCD
            ENDM

;------------------------------------------------------------------------------
;                   Declare COMMAND Macro
;                   CMD = COMMAND to send the LCD
;                   R14 = (COMMAND) DATUM to pass to the LCD
;------------------------------------------------------------------------------
lcdcmd      MACRO   CMD
            bic.b   #02h, &P2OUT            ; Turn on REGISTER SELECT
            mov.b   CMD, R14                ; Load command CMD
            call    #WRT_CMD_LCD            ; Send command CMD to LCD
            ENDM

;------------------------------------------------------------------------------
;                   Declare ABS Macro
;                   NUM = NUMBER to calculate absolute value
;------------------------------------------------------------------------------
abs         MACRO   NUM
            LOCAL   CONTINUE1, CONTINUE2
            sub.b   #07, NUM                ; Subtract from 7
            jn      CONTINUE1
            jmp     CONTINUE2

CONTINUE1   inv.b   NUM                     ; neg the value by 2's complement
            inc.b   NUM                     ;

CONTINUE2
            ENDM

;------------------------------------------------------------------------------
            ORG     0C000h                  ; Program Start
;------------------------------------------------------------------------------
RESET       mov.w   #0280h, SP              ; Initialize Stackpointer
StopWDT     mov.w   #WDTPW+WDTHOLD, &WDTCTL ; Stop WDT

;------------------------------------------------------------------------------
;                   Configure Timer
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
            bis.b   #0FFh, &P1DIR           ; Set all pins of port P1 as output
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
            lcdcmd  #030h                   ; Send command to Wake LCD #1
            delay   #60                     ; Delay of 5ms
            lcdcmd  #030h                   ; Send command to Wake LCD #2
            delay   #2                      ; Delay of ~160u
            lcdcmd  #030h                   ; Send command to Wake LCD #3
            delay   #2                      ; Delay of ~160u
            lcdcmd  #038h                   ; Send command to set 8-bit/2-line
            lcdcmd  #010h                   ; Send command to set cursor
            lcdcmd  #0Ch                    ; Send command to Turn on the
                                            ; Display and do not show Cursor
            lcdcmd  #06h                    ; Send command Entry mode set
            lcdcmd  #01h                    ; Send command to Clear Display
            delay   #180                    ; Delay of 15ms
                                            ; Wait until LCD is stable

;------------------------------------------------------------------------------
;                   Show First Message
;------------------------------------------------------------------------------
            mov.w   #MSGSTART, R13          ; Load Cstring of first message
            call    #WRITEMSG               ; Write message
POLL1       bit.b   #04h, &P2IN             ; Poll Button B1 until pressed
            jnz     POLL1                   ; Jump to keep polling

;------------------------------------------------------------------------------
;                   Choose Difficulty Level State
;------------------------------------------------------------------------------
;                   R4 = Difficulty Level
;                   2 - Basic
;                   1 - Intermediate
;                   0 - Advanced
;------------------------------------------------------------------------------
            mov     #MSGDIFF, R13           ; Load Cstring of difficulty message
            call    #WRITEMSG               ; Write message
            delay   #24000                  ; Wait 2 seconds to show message

            lcdcmd  #01h                    ; Send command to Clear Display
            delay   #180                    ; Delay of 15ms
                                            ; Wait until LCD is stable
            lcdcmd  #0C0h                   ; Send command to move cursor 2nd LN
            mov     #MSGOPTION, R13         ; Load Cstring of option message
            call    #WRITESTR               ; Write string in 2nd line

LOOPAGAIN   mov.b   #02h, R4                ; Start assuming difficulty = 2
ASKNEXTDIFF rla.b   R4                      ; For indexing address (16-bit)
            mov     WHICHDIFF(R4), R13      ; Load Cstring of currently
                                            ; assumed difficulty message
            rra.b   R4                      ; Return to readable value

            lcdcmd  #080h                   ; Send command to move cursor 1st LN
            call    #WRITESTR               ; Write string in 1st line

POLL2       bit.b   #04h, &P2IN             ; Poll Button 1
            jz      DIFFCHOSEN              ; B1 Pressed, Exit loop
            bit.b   #08h, &P2IN             ; B1 not Pressed, Poll Button 2
            jnz     POLL2                   ; Nothing Pressed, keep polling

            delay   #6000                   ; B2=NO Pressed
                                            ; Delay of 0.5s for debouncing
            dec.b   R4                      ; Assume lower difficulty
            jn      LOOPAGAIN               ; Start looping again
            jmp     ASKNEXTDIFF             ; Ask for next difficulty

DIFFCHOSEN  delay   #6000                   ; Delay of 0.5s for debouncing
                                            ; Finished Decision Making

;------------------------------------------------------------------------------
;                   Set initial Level to 1
;------------------------------------------------------------------------------
;                   R5  =  Level
;                   0   -  TRANSISTOR
;                   1   -  NAND
;                   2   -  FLIP/FLOP
;                   3   -  REGISTER
;                   4   -  COUNTER
;                   5   -  ALU
;                   6   -  CPU
;                   7   -  MCU
;------------------------------------------------------------------------------
            mov.b   #00h, R5                ; Set initial level to 0

;------------------------------------------------------------------------------
;****************** Start MainLoop ********************************************
;------------------------------------------------------------------------------
MAINLOOP    lcdcmd  #01                     ; Send command to Clear Display
            delay   #180                    ; Delay of 15ms
                                            ; Wait until LCD is stable

;------------------------------------------------------------------------------
;                   Show Current Level
;------------------------------------------------------------------------------
            mov.w   #MSGLVL, R13            ; Load Cstring of level message
            call    #WRITESTR               ; Write string in 1st line
            lcdcmd  #0C0h                   ; Send command to move cursor 2nd LN
            rla.b   R5                      ; For indexing address (16-bit)
            mov.w   WHICHLVL(R5), R13       ; Load Cstring of current
                                            ; level message
            rra.b   R5                      ; Return to readable value
            call    #WRITESTR               ; Write string in 2nd line
            delay   #24000                  ; Wait 2 seconds to show message

;------------------------------------------------------------------------------
;                   Show Instruction Message and Initialize Roulette
;------------------------------------------------------------------------------
            lcdcmd  #01h                    ; Send command to Clear Display
            delay   #180                    ; Delay of 15ms
                                            ; Wait until LCD is stable

            mov.w   #MSGINSTR, R13          ; Load Cstring of instruct message
            call    #WRITEMSG               ; Write message
            delay   #24000                  ; Wait 2 seconds to show message

            lcdcmd  #01h                    ; Send command to Clear Display
            delay   #180                    ; Delay of 15ms
                                            ; Wait until LCD is stable

            mov.w   #MSGNUMBS, R13          ; Load Cstring of numbers message
            call    #WRITESTR               ; Write string in 1st line

            mov.b   #0C0h, R6               ; Load DDRAM address of PIVOT in R6
            lcdcmd  R6                      ; Send command to move cursor 2nd LN

            lcdwrt  PIVOT                   ; Write character PIVOT to LCD

;------------------------------------------------------------------------------
;                   Start Counter and Select Number State
;------------------------------------------------------------------------------
            bic.b   #04h, &P2SEL            ; Allow pin P2.2 to interrupt
            bis.b   #04h, &P2IE             ; Enable local interrupt
            bic.b   #0Ch, &P2IFG            ; Disable Interrupt Flag

TOGGLE      delay   WHICHDELAY(R4)          ; Delay depending on difficulty
            lcdcmd  R6                      ; Send command to move cursor (back)
            lcdwrt  #020h                   ; Write character " " to LCD

            inc.b   R6                      ; Point to current cursor address

            cmp.b   #0D0h, R6               ; LCD Address out of bounds?
            jnz     TOGGLE1                 ; No, Continue

            mov.b   #0C0h, R6               ; Yes, Load address of 1st character
                                            ; of second line in R6
            lcdcmd  R6                      ; Send command to move cursor
TOGGLE1     lcdwrt  PIVOT                   ; Write charater PIVOT to LCD
            jmp     TOGGLE

CONTINUE    sub.b   #0C0h, R6               ; Calculate offset, now R6  = Value

            bis.b   #04h, &P2SEL            ; Don't Allow pin P2.2 to interrupt
            bic.b   #04h, &P2IE             ; Disable local interrupt
            bic.b   #0Ch, &P2IFG            ; Disable Interrupt Flag

            delay   #12000                  ; Wait 1 second to show number
            lcdcmd  #01h                    ; Send command to Clear Display
            delay   #180                    ; Delay of 15ms
;------------------------------------------------------------------------------
;                   Calculate Absolute Value
;------------------------------------------------------------------------------
            abs     R6                      ; Calculate absolute value

;------------------------------------------------------------------------------
;                   Check Condition
;------------------------------------------------------------------------------
            cmp.b   CONDITION(R5), R6       ; R6  < CONDITION ?
            jl      YES                     ; YES
NO          mov.b   FAILNEXT(R5), R5        ; NO, Level down
            cmp.b   #0h, R5                 ; Are you in level 0?
            jz      YOULOST                 ; YES, Then you lost the game
            mov.w   #MSGDOWN, R13           ; Load Cstring of level down message
            jmp     NOTYET                  ; Show level and keep playing

YES         inc.b   R5                      ; Level up
            cmp.b   #07h, R5                ; Are you now in Last level 7?
            jz      YOUWON                  ; Yes, You won the game!
            mov.w   #MSGUP, R13             ; Load Cstring of level up message

NOTYET      call    #WRITEMSG               ; Write message
            delay   #24000                  ; Wait 2 seconds to show message
            jmp     MAINLOOP                ; Continue playing

;------------------------------------------------------------------------------
;                   YOU WON STATE
;------------------------------------------------------------------------------
YOUWON      mov.w   #MSGWON, R13            ; Load Cstring of You Won! message
            call    #WRITEMSG               ; Write message
            jmp     $                       ; END! (endless loop)

;------------------------------------------------------------------------------
;                   YOU LOST STATE
;------------------------------------------------------------------------------
YOULOST     mov.w   #MSGLOST, R13           ; Load Cstring of You Lost! message
            call    #WRITEMSG               ; Write message
            jmp     $                       ; END! (endless loop)

;------------------------------------------------------------------------------
;                   SUBROUTINES
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;                   LCD - Write 1 line string Message
;------------------------------------------------------------------------------
;                   R13 = Pointer to message Cstring
;------------------------------------------------------------------------------
WRITESTR    lcdwrt  @R13+                   ; Write charater to LCD
            cmp.b   #00h, 0(R13)            ; Is this the null character?
            jnz     WRITESTR                ; If it's not, continue loop
            ret

;------------------------------------------------------------------------------
;                   LCD - Write 2 line Message
;------------------------------------------------------------------------------
;                   R13 = Pointer to message Cstring
;------------------------------------------------------------------------------
WRITEMSG    lcdcmd  #01h                    ; Send command to Clear Display
            delay   #180                    ; Delay of 15ms
                                            ; Wait until LCD is stable
            call    #WRITESTR               ; Write first line
            lcdcmd  #0C0h                   ; Send command to move cursor 2nd LN
            inc     R13                     ; Fetch next Cstring
            call    #WRITESTR               ; Write second line
            ret

;------------------------------------------------------------------------------
;                   LCD - WRITE_OR_COMMAND Subroutine
;------------------------------------------------------------------------------
;                   P2.0 = ENABLE
;                   P2.1 = RESGISTER SELECT
;                   R14  = (DATUM) COMMAND/CHARACTER
;------------------------------------------------------------------------------
WRT_CMD_LCD mov.b   R14, &P1OUT             ; Load COMMAND/CHARACTER in Port 1

            bis.b   #01h, &P2OUT            ; Turn on ENABLE
            nop                             ; Small Delay
            bic.b   #01h, &P2OUT            ; Turn off ENABLE

            mov.w   0(R4), 0(R4)            ; Delay - 6 cycles, 3 words
            mov.w   0(R4), 0(R4)            ; Delay - 6 cycles, 3 words
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
PB_ISR      bic.b   #04h, &P2IFG            ; Disable Interrupt Flag of P2.2
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
WHICHDELAY  DW      1200, 2400, 4800        ; For Delays .1s, .2s, .4s
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
