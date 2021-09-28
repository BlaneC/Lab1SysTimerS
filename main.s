
;16s counter 
;main.s
;Author : zhou zhou
;Date: 05/09/2017
;Runs on TM4C1294 
;PJ0 as a set button
;PJ1 as a reset button
;PN0 LED indicates nQ
;PN1 LED indicates Q


GPIO_PORTN_DATA_R	EQU 0x400643FC
GPIO_PORTN_DIR_R	EQU 0x40064400
GPIO_PORTN_DEN_R	EQU 0x4006451C
GPIO_PORTN_AFSEL_R	EQU	0x40064420
	
GPIO_PORTF_DATA_R	EQU 0x4005D3FC
GPIO_PORTF_DIR_R	EQU 0x4005D400
GPIO_PORTF_DEN_R	EQU 0x4005D51C
GPIO_PORTF_AFSEL_R	EQU	0x4005D420
	
NVIC_ST_CTRL_R		EQU 0xE000E010
NVIC_ST_RELOAD_R	EQU 0xE000E014
NVIC_ST_CURRENT_R	EQU 0xE000E018

SYSCTL_RCGCGPIO_R	EQU 0x400FE608
	
	AREA    |.text|, CODE, READONLY, ALIGN=2
	THUMB
	EXPORT  __main
			
GPIO_Init
	;enable clcok for both port
	LDR R1, =SYSCTL_RCGCGPIO_R
    LDR R0, [R1]                    ; R0 = [R1]
    ORR R0, R0, #0x1120 ; 			;Enable Port N F J
    STR R0, [R1]                    ; [R1] = R0
    NOP
	NOP
	NOP
    NOP                             ; allow time to finish activating
	;direction registers
	LDR R1, =GPIO_PORTN_DIR_R       ; R1 = &GPIO_PORTN_DIR_R
    LDR R0, [R1]                    ; R0 = [R1]
    ORR R0, R0, #0x03              ; R0 = R0|0x03 (make PN0,PN1 output)
    STR R0, [R1] 
	
	LDR R1, =GPIO_PORTF_DIR_R       ; R1 = &GPIO_PORTF_DIR_R
    LDR R0, [R1]                    ; R0 = [R1]
    ORR R0, R0, #0x11              ; R0 = R0|0x11 (make PF0,PF4 output)
    STR R0, [R1] 
	
	;digital enable
	LDR R1, =GPIO_PORTN_DEN_R       ; R1 = &GPIO_PORTN_DEN_R
    LDR R0, [R1]                    ; R0 = [R1]
    ORR R0, R0, #0x03               ; R0 = R0|0x03 (enable digital I/O on PN0,PN1)
    STR R0, [R1]  

	LDR R1, =GPIO_PORTF_DEN_R       ; R1 = &GPIO_PORTF_DEN_R
    LDR R0, [R1]                    ; R0 = [R1]
    ORR R0, R0, #0x11               ; R0 = R0|0x03 (enable digital I/O on PF0,PF4)
    STR R0, [R1]  

    BX  LR

SysTick_Init

	LDR R1, =NVIC_ST_CTRL_R			;	Load the memory address for the SysTick Control register
	LDR R2, =NVIC_ST_RELOAD_R		; 	Load the memory address for the 
	LDR R3, =NVIC_ST_CURRENT_R		; 	Load the memory address for the 

	MOV R0, #0						;	Prepare 0 to reset the SysTick Control register
	MOV R4, #0xFFFFFF				; 	Prepare 0xFFFFFF (Max value for Load register) Into General register 4

	STR R0, [R1]					; 	Store 0x0 into the SysTick Control register
	STR R4, [R2]					; 	Store 0xFFFFFF into the SysTick Load register
	STR	R0, [R3]					; 	Store 0 into the SysTick Current register
	
	MOV	R2, #5						;	Prepare 1, to Enable the SysTick Timer
	STR	R2, [R1]					;	Store 1 into the SysTick Control register, enabling it

	BX	LR
	
	
	
WAIT1S
	LDR	R6, =NVIC_ST_RELOAD_R		;	Load the reload register address
	LDR	R7, =NVIC_ST_CURRENT_R		;	Load the reload register address
	MOV R4, #0xF424					; 	Prepare 16 million to be stored into the load register (needs to be shifted)
	LSL	R4, #8						;	Shift the loaded value in R0 left by 2 bytes to make it equivalent to 16 million
	MOV	R5, #0						;	Prepare 0 to be loaded into the current register
	STR	R4, [R6]					; 	Store 16 million in the SysTick load register
	STR	R5, [R7]					;	Set the SysTick Current register to 0
	;STR	R5, [R6]					; 	Write 0 to the RELOAD REGISTER to prevent reloading
W_LOOP1
	LDR R1,=NVIC_ST_CTRL_R
	LDR R0,[R1]
	AND R0,#0x00010000
	CMP R0,#0x00
	BEQ W_LOOP1
	BX	LR


DELAY1					; delay 3ms
	MOV	R0, #65000
LOOP_DELAY1	
	SUBS R0, #1
	NOP
	NOP
	BNE	 LOOP_DELAY1
	
	BX	LR	
		
	
__main
	BL  	GPIO_Init
	BL		SysTick_Init
LOOP1
	MOV		R2, #0 					; Set the initial value for counter
LOOP2	
	MOV 	R0,R2					; load current value 
	MOV 	R3,R2
	AND 	R0,#0x01				; isolate current value's first bit
	AND 	R3,#0x02				; isolate current value's second bit
	LSL		R3,#3					; shift left 3 bits, LEDs are portN_0 and PORTN_4
	ORR 	R0,R0,R3				; add two value together and store 
	
	LDR 	R1,=GPIO_PORTF_DATA_R	; into data register
	STR 	R0,[R1]
	
	MOV 	R0,R2					;load current value
	MOV 	R3,R2
	AND 	R0,#0x04				; isolate current value's third bit
	LSR		R0,#2					; shift to right 2 since it corresponds to PORTN_0
	AND 	R3,#0x08				; isolate forth bit
	LSR		R3,#2					; shift to right 2 since it corresponds to PORTN_1
	ORR 	R0,R0,R3				
	LDR 	R1,=GPIO_PORTN_DATA_R
	STR 	R0,[R1]
	
	BL		WAIT1S
	;BL		DELAY1
	;BL		DELAY1
	;BL		DELAY1
	
	ADD R2,	#1						; increment current value
	CMP R2,	#0x10					; check if it over 16
	BNE 	LOOP2
	
	B 		LOOP1
	
	ALIGN
	END
		