#include	<msp430.h>
;------------------------------------------------------------------------
			ORG	0C000h					; Program Start
;------------------------------------------------------------------------
RESET		mov	#0280h, SP				; Initialize Stackpointer
StopWDT		mov	#WDTPW+WDTHOLD, &WDTCTL	; Stop WDT



;------------------------------------------------------------------------
;					Interrupt Vectors
;------------------------------------------------------------------------
			ORG	0FFFEh					; MSP RESET Vector
			DW	RESET					; address of label RESET
			END
