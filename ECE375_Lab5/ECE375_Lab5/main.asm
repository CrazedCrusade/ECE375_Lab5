;***********************************************************
;*	ECE375_lab5.asm
;*
;*	 Author: Andrew Gondoputro
;*				and
;*			Harrison Gregory
;*	   Date: 2/13/2025
;*
;*	Dscrpt: Utilizes code from BumpBot lab #1, but uses 
;*			interrupts to manage bumpbot behavior instead
;*			of polling.
;*
/**	Behavior:
			If only left whisker hit:
				backup, increment leftWhiskCount, turn right.
			If Both or right whisker hit:
				backup, increment rightWhiskCount, turn left.
				If leftWhisker also hit:
					also increment leftWhiskCount.
			If Cleared:
				set both counters on to zero.
			Update the Screen to show current counts.
			Continue forward when nothing else is happening.
**/
;*	Additions to lab 1:
;*			1) displays the number of hits to the
;*			 left and right sides. 
;*			2) Includes a clear button to reset number 
;*			of hits displayed on the screen 
;*  Pseudocode:
;*		https://docs.google.com/document/d/1c8lZ_wX4mUPv2ur406kXOY-pYR5Vd4SxY5e5zHvwLnE/edit?usp=sharing
;***********************************************************

.include "m32U4def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

		; Set up interrupt vectors for any interrupts being used

		; This is just an example:
;.org	$002E					; Analog Comparator IV
;		rcall	HandleAC		; Call function to handle interrupt
;		reti					; Return from interrupt

.org	$0056					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine
		; Initialize Stack Pointer
		ldi		mpr, low(RAMEND)  ; Load low byte of RAMEND into 'mpr'
		out		SPL, mpr  ; Store low byte of RAMEND into SPL (stack pointer low byte)
		ldi		mpr, high(RAMEND)  ; Load high byte of RAMEND into 'mpr'
		out		SPH, mpr  ; Store high byte of RAMEND into SPH (stack pointer high byte)

		; Initialize Port B for output
		ldi		mpr, $FF		; Set Port B Data Direction Register
		out		DDRB, mpr		; for output
		ldi		mpr, $00		; Initialize Port B Data Register
		out		PORTB, mpr		; so all Port B outputs are low

		; Initialize Port D for input
		ldi		mpr, $00		; Set Port D Data Direction Register
		out		DDRD, mpr		; for input
		ldi		mpr, $FF		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State

		; Initialize external interrupts
			; Set the Interrupt Sense Control to falling edge

		; Configure the External Interrupt Mask

		; Turn on interrupts
			
			; NOTE: This must be the last thing to do in the INIT function

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program

		; TODO

		rjmp	MAIN			; Create an infinite while loop to signify the
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
;	You will probably want several functions, one to handle the
;	left whisker interrupt, one to handle the right whisker
;	interrupt, and maybe a wait function
;------------------------------------------------------------

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the
;		beginning of your functions
;-----------------------------------------------------------
FUNC:							; Begin a function with a label

		; Save variable by pushing them to the stack

		; Execute the function here

		; Restore variable by popping them from the stack in reverse order

		ret						; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************
; Enter any stored data you might need here
STRING_BEG:; Address Name for Beginning of string location in flash
; Each char stored as an Ascii equivalent Int
.DB		"Right       Left"  ;Upper line	16 char
STRING_COUNTER_VALS:
.DB		"000          000"  ;Lower line	16 char
STRING_END: ; Address Name for end of string location in flash

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver

;Blank line here to account for Microchip Studio Bug 

