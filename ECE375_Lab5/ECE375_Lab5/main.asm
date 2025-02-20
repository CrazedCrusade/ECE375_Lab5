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
.def	i = r25

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit


.equ	buttonLeft = 4				; Input bit for PD4
.equ	buttonRight = 5				; Input bit for PD5



.def	waitcnt = r17				; Wait Loop Counter
.def	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter



.def	leftCount = r22			; Left Counter
.def	rightCount = r23		; Right Counter



.equ	WTime = 50				; Time to wait in wait loop
.equ	BTime = 50				; Time to backup?

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

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt
.org $0002
		rcall HitRight
		reti
.org $0004
		rcall HitLeft
		reti
.org $0008
		rcall ClearCount
		reti
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

		rcall LCDInit
		rcall FLSH_STR_TO_SRAM
		rcall LCDWrite




		; Initialize external interrupts
			; Set the Interrupt Sense Control to falling edge
		ldi mpr, 0b1000_1010
		sts EICRA, mpr

		; Configure the External Interrupt Mask
		ldi mpr, 0b0000_1011
		out EIMSK, mpr		; set the mask
		; Turn on interrupts
		sei ; set interrupt

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


;-----------------------------------------------------------
; Func: Function To Display on both Counters
; Desc: 

;-----------------------------------------------------------
DisplayOnLCD:
		rcall LCDCLR
		rcall FLSH_STR_TO_SRAM
		mov mpr, r22		;move Left counter to mpr
		ldi XL, low(Line2Pt1)
		ldi XH, High(Line2Pt1)
		rcall Bin2ASCII

		mov mpr, r23		;move Left counter to mpr
		ldi XL, low(Line2Pt2)
		ldi XH, High(Line2Pt2)
		rcall Bin2ASCII
		rcall LCDWrite

		ret


;-----------------------------------------------------------
; Func: FLSH_STR_TO_SRAM
; Desc: This function stores string in flash to the correct
;		locations in SRAM for the LCDDriver by first pushing
;		a character from the string onto the stack, then 
;		utilizing a helper function to store that character
;		from the stack to the correct SRAM location. Then 
;		this function loops until all characters from the 
;		string are in SRAM in order. 
; limits: 
;		1) Assumes a 32 character string, 16 characters per
;			line is stored between STRING_BEG and STRING_END
;		2) Assumes that characters are in the correct order
;			in the flash memory (as typed after .db).
;-----------------------------------------------------------						
FLSH_STR_TO_SRAM:
    ; Initialize Z register to point to STRING_BEG
    ldi     ZL, low(STRING_BEG << 1)      ; Load low byte of address into ZL
    ldi     ZH, high(STRING_BEG << 1)     ; Load high byte of address into ZH
    ldi		XH, $01		; Inital Value of X
	ldi		XL, $00		; inital Value of X

	ldi		i, 32		; Starting i for a loop counter

FLSH_LOOP:
    ; Load the character from flash into the register
    lpm     r15, Z+                   ; Load byte from address in Z to a GPR (FLASH-->GPR). Then increment Z to next Flash address
	st		X+, r15						; Load GPR value to SRAM location (GPR-->SRAM). Then increment X to the next SRAM location
	dec		i							; Decrement the loop counter
	brne	FLSH_LOOP					; Continue the loop so long as i is positive
	ret ; End of function, String successfully stored to SRAM








;----------------------------------------------------------------
; Sub:	HitRight
; Desc:	Handles functionality of the TekBot when the right whisker
;		is triggered.
;----------------------------------------------------------------
HitRight:
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;

		; Move Backwards for a second
		ldi		mpr, MovBck	; Load Move Backward command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, BTime	; Wait for 2 second
		rcall	Wait			; Call wait function

		; Turn left for a second
		ldi		mpr, TurnL	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Move Forward again
		ldi		mpr, MovFwd	; Load Move Forward command
		out		PORTB, mpr	; Send command to port

		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr
		inc		RightCount;

		rcall	DisplayONLCD
		ldi		mpr, 0b0000_1011
		out		EIFR, mpr
		ret				; Return from subroutine



;----------------------------------------------------------------
; Sub:	HitLeft
; Desc:	Handles functionality of the TekBot when the left whisker
;		is triggered.
;----------------------------------------------------------------
HitLeft:
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;

		; Move Backwards for a second
		ldi		mpr, MovBck	; Load Move Backward command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, BTime	; Wait for 2 second
		rcall	Wait			; Call wait function

		; Turn right for a second
		ldi		mpr, TurnR	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Move Forward again
		ldi		mpr, MovFwd	; Load Move Forward command
		out		PORTB, mpr	; Send command to port
		inc		leftCount;


		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr

		rcall	DisplayONLCD
		ldi		mpr, 0b0000_1011
		out		EIFR, mpr
		ret				; Return from subroutine


;----------------------------------------------------------------
; Sub:	Wait
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly
;		waitcnt*10ms.  Just initialize wait for the specific amount
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			(((((3*ilcnt)-1+4)*olcnt)-1+4)*waitcnt)-1+16
;----------------------------------------------------------------
Wait:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt		; Decrement wait
		brne	Loop			; Continue Wait loop

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		waitcnt		; Restore wait register
		ret				; Return from subroutine



ClearCount:

	ret


;***********************************************************
;*	Stored Program Data
;***********************************************************
; Enter any stored data you might need here
STRING_BEG:; Address Name for Beginning of string location in flash
; Each char stored as an Ascii equivalent Int
.DB		"Left   |Right   "  ;Upper line	16 char
STRING_COUNTER_VALS:
.DB		"0      |0       "  ;Lower line	16 char
STRING_END: ; Address Name for end of string location in flash

.dseg 
.org $0100
Line1:
	.byte 16

Line2Pt1: 
	.byte 8
Line2Pt2: 
	.byte 8



;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver

;Blank line here to account for Microchip Studio Bug 

