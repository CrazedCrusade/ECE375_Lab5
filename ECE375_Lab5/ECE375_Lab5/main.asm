;***********************************************************
;*	ECE375_lab5.asm
;*
;*	 Author: Andrew Gondoputro
;*				and
;*			Harrison Gregory
;*	   Date: 2/13/2025
;*//////////////////////////////////////////////////////////
;*	Dscrpt: Utilizes code from BumpBot lab #1, but uses 
;*			interrupts to manage bumpbot behavior instead
;*			of polling.
;*//////////////////////////////////////////////////////////
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
**//////////////////////////////////////////////////////////
;*	Additions to lab 1:
;*			1) displays the number of hits to the
;*			 left and right sides. 
;*			2) Includes a clear button to reset number 
;*			of hits displayed on the screen 
;*//////////////////////////////////////////////////////////
;*  Pseudocode:
;*		https://docs.google.com/document/d/1c8lZ_wX4mUPv2ur406kXOY-pYR5Vd4SxY5e5zHvwLnE/edit?usp=sharing
;*
;*//////////////////////////////////////////////////////////
;*
;*	Sources: 
;*			1)
;*			 BasicBumpBot.asm	-	V3.0
;*	 Author: David Zier, Mohammed Sinky, and Dongjun Lee (modification August 10, 2022)
;*	   Date: August 10, 2022
;*	Company: TekBots(TM), Oregon State University - EECS
;*	Version: 3.0
;*
;*
;***********************************************************

.include "m32U4def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************

;*----------------------------------------------------------
; The following code cited from Source 1)-------------------

.def	mpr = r16				; Multi-Purpose Register
.def	waitcnt = r17				; Wait Loop Counter
.def	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter

.equ	WTime = 100				; Time to wait in wait loop

.equ	WskrR = 4				; Right Whisker Input Bit
.equ	WskrL = 5				; Left Whisker Input Bit
.equ	EngEnR = 5				; Right Engine Enable Bit
.equ	EngEnL = 6				; Left Engine Enable Bit
.equ	EngDirR = 4				; Right Engine Direction Bit
.equ	EngDirL = 7				; Left Engine Direction Bit

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////
.equ	MovFwd = (1<<EngDirR|1<<EngDirL)	; Move Forward Command
.equ	MovBck = $00				; Move Backward Command
.equ	TurnR = (1<<EngDirL)			; Turn Right Command
.equ	TurnL = (1<<EngDirR)			; Turn Left Command
.equ	Halt = (1<<EngEnR|1<<EngEnL)		; Halt Command

;============================================================
; NOTE: Let me explain what the macros above are doing.
; Every macro is executing in the pre-compiler stage before
; the rest of the code is compiled.  The macros used are
; left shift bits (<<) and logical or (|).  Here is how it
; works:
;	Step 1.  .equ	MovFwd = (1<<EngDirR|1<<EngDirL)
;	Step 2.		substitute constants
;			 .equ	MovFwd = (1<<4|1<<7)
;	Step 3.		calculate shifts
;			 .equ	MovFwd = (b00010000|b10000000)
;	Step 4.		calculate logical or
;			 .equ	MovFwd = b10010000
; Thus MovFwd has a constant value of b10010000 or $90 and any
; instance of MovFwd within the code will be replaced with $90
; before the code is compiled.  So why did I do it this way
; instead of explicitly specifying MovFwd = $90?  Because, if
; I wanted to put the Left and Right Direction Bits on different
; pin allocations, all I have to do is change thier individual
; constants, instead of recalculating the new command and
; everything else just falls in place.
;==============================================================

;End of Citation.---------------------------------------------
;-------------------------------------------------------------

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

		; Initialize TekBot Forward Movement
		ldi		mpr, MovFwd		; Load Move Forward Command
		out		PORTB, mpr		; Send command to motors


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
		;Move Forward:


		;Enable interrupts here:


		//If any interrupt flags were set:
		;IF (0 < bumpIntFlags) 
			;rcall IF_ANY_PRESS

		;END IF

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
; Func: IF_ANY_PRESS
; Desc: Determines what to do if any of the whiskers or the 
;		clear button were pressed. Prioritizes whisker bump
;		commands over display clearing so that once the 
;		normal bumpbot behavior resumes, the LCD's values
;		will be reset. 
;-----------------------------------------------------------
IF_ANY_PRESS:							; Begin a function with a label

		; Save variable by pushing them to the stack


		; Execute the function here:

		; Disable Interrupts:  We only want interrupts while the bot moves forward

		; Mask last two bits of bumbInterFlags as bumpWhiskFlags

		; Call BOTH_PRESS for the case that at least the right whisker was hit:
		; IF ((bumpWhiskFlags == 3) || (bumpWhiskFlags == 1)
			;rcall BOTH_PRESS

		; Call LEFT_PRESS for the case that only the left whisker was hit:
		; IF (bumpWhiskFlags==2)
			;rcall LEFT_PRESS
		

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

