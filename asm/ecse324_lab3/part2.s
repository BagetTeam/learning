.section .vectors, "ax"
B _start // reset vector
B SERVICE_UND // undefined instruction vector
B SERVICE_SVC // software interrupt vector
B SERVICE_ABT_INST // aborted prefetch vector
B SERVICE_ABT_DATA // aborted data vector
.word 0 // unused vector
B SERVICE_IRQ // IRQ interrupt vector
B SERVICE_FIQ // FIQ interrupt vector

.data
.align 2
PB_int_flag:
    .word 0
tim_int_flag:
    .word 0

.section .rodata
.equ TIMER_load, 0xFFFEC600
.equ TIMER_counter, 0xFFFEC604
.equ TIMER_control, 0xFFFEC608
.equ TIMER_interr, 0xFFFEC60C
.equ TIMER_DEFAULT_LOAD, 50000000 // 200 MHz * 0.25 s
.equ INTERRUPT_REG, 0xFF200058
.equ EDGECAPTURE_REG, 0xFF20005C
.equ SW_ADDR, 0xFF200040
.equ LED_ADDR, 0xFF200000

// HEX
.equ HEX_ADDR_0_3, 0xFF200020
.equ HEX_ADDR_4_5, 0xFF200030

HEX0 = 0x00000001
HEX1 = 0x00000002
HEX2 = 0x00000004
HEX3 = 0x00000008
HEX4 = 0x00000010
HEX5 = 0x00000020

BLANK = 0x10
NONE = 0x00

HEX_CODES:
.byte 0b00111111, 0b00000110, 0b01011011, 0b01001111 // 0, 1, 2, 3
.byte 0b01100110, 0b01101101, 0b01111101, 0b00000111 // 4, 5, 6, 7
.byte 0b01111111, 0b01101111, 0b01110111, 0b01111100 // 8, 9, A, b
.byte 0b00111001, 0b01011110, 0b01111001, 0b01110001 // C, d, E, F
.byte 0x00 // Blank
.align 2

// first byte is length of msg, all other is chars of msg (len is important for write_msg)
COFFEE:
    .byte 6, 0xC, 0, 0xF, 0xF, 0xE, 0xE

CAFES:
    .byte 6, 0xC, 0xA, 0xF, 0xE, 5, BLANK

CABS:
    .byte 6, 0xC, 0xA, 0xB, 5, BLANK, BLANK

ACE:
    .byte 6, 0xA, 0xC, 0xE, BLANK, BLANK, BLANK

MSG_8:
    .byte 10, 7, 0, 0xA, 0xD, 5, 7, 0, 0, 1, 5

MSG_10:
    .byte 16, 0xC, 0xA, 0xF, 0xE, BLANK, 0xB, 0xE, 0xE, 0xF, BLANK, 0xC, 0, 0xF, 0xF, 0xE, 0xE

MSG_BLANK:
    .byte 6, BLANK, BLANK, BLANK, BLANK, BLANK, BLANK

.align 2




// Task:

/*  LED -> Light up speed (2 lights per increase (1, 1/2, 1/4, 1/8, 1/16) for all 10 LEDs)
        - Pause = all off

    PB: 0 = Make slower (no effect at min speed)
        1 = Make faster (no effect at max speed)
        2 = reverse shifting
        3 = pause and resume shifting
        - when paused, 0-1-2 no effect
    
    Switches: same as part 1

*/ 


.text
.global _start
_start:
    /* Set up stack pointers for IRQ and SVC processor modes */
    MOV R1, #0b11010010 // interrupts masked, MODE = IRQ
    MSR CPSR_c, R1 // change to IRQ mode
    LDR SP, =0xFFFFFFFF - 3 // set IRQ stack to A9 on-chip memory
    /* Change to SVC (supervisor) mode with interrupts disabled */
    MOV R1, #0b11010011 // interrupts masked, MODE = SVC
    MSR CPSR, R1 // change to supervisor mode
    LDR SP, =0x3FFFFFFF - 3 // set SVC stack to top of DDR3 memory

    // Stop the timer and clear stale events while CPU IRQs are masked.
    MOV A1, #0
    MOV A2, #0
    BL ARM_TIM_config_ASM
    BL ARM_TIM_clear_INT_ASM

    MOV A1, #0xF
    BL disable_PB_INT_ASM
    LDR A1, =EDGECAPTURE_REG
    MOV A2, #0xF
    STR A2, [A1]          // clear all stale pushbutton edges

    MOV A2, #0
    LDR A1, =PB_int_flag
    STR A2, [A1]
    LDR A1, =tim_int_flag
    STR A2, [A1]

    BL CONFIG_GIC        // enable interrupt IDs 29 and 73

    MOV A1, #0xF
    BL enable_PB_INT_ASM

    // Reload A1 explicitly: the calls above overwrite argument registers.
    LDR A1, =TIMER_DEFAULT_LOAD
    MOV A2, #0b111          // Prescaler=0, IRQ=1, auto-reload=1, enable=1
    BL ARM_TIM_config_ASM

    // Unmask CPU IRQs only after all initialization writes have completed.
    DSB SY
    MOV R0, #0b01010011 // IRQ unmasked, FIQ masked, MODE = SVC
    MSR CPSR_c, R0

IDLE:
    // Persistent state (the drivers and IRQ handlers preserve these registers).
    MOV V1, #0            // rotation: positive = right, negative = left
    MOV V2, #-1           // direction: initially left
    MOV V3, #2            // speed index 0..4: 1, 1/2, 1/4, 1/8, 1/16 s
    MOV V4, #0            // paused: 0 = running, 1 = paused
    MOV V5, #-1           // previous switches; force initial message selection
    LDR V6, =COFFEE       // current length-prefixed message

IDLE_loop:
    // Atomically take and clear both flags so an IRQ cannot be lost between
    // reading a flag and clearing it. V7 = timer event, V8 = button mask.
    CPSID I
    MOV A2, #0
    LDR A1, =PB_int_flag
    LDR V8, [A1]
    STR A2, [A1]
    LDR A1, =tim_int_flag
    LDR V7, [A1]
    STR A2, [A1]
    CPSIE I

    BL read_slider_switches_ASM
    CMP A1, #0x00
    LDREQ V6, =COFFEE
    BEQ IDLE_valid_message
    CMP A1, #0x01
    LDREQ V6, =CAFES
    BEQ IDLE_valid_message
    CMP A1, #0x02
    LDREQ V6, =CABS
    BEQ IDLE_valid_message
    CMP A1, #0x04
    LDREQ V6, =ACE
    BEQ IDLE_valid_message
    CMP A1, #0x08
    LDREQ V6, =MSG_8
    BEQ IDLE_valid_message
    CMP A1, #0x10
    LDREQ V6, =MSG_10
    BEQ IDLE_valid_message
    LDR V6, =MSG_BLANK     // invalid switches only blank the HEX display
    B IDLE_message_ready

IDLE_valid_message:
    CMP A1, V5
    MOVNE V1, #0          // a newly selected message starts left-justified
    MOVNE V7, #0          // do not immediately shift it with an old timer event
IDLE_message_ready:
    MOV V5, A1

    // PB3 takes priority if several buttons arrive together. Discard any
    // simultaneous timer tick when pausing/resuming; do not jump on resume.
    TST V8, #0x8
    BNE IDLE_toggle_pause
    CMP V4, #0
    BNE IDLE_display      // while paused, ignore PB0-2 and timer events

    TST V8, #0x4
    RSBNE V2, V2, #0      // PB2 reverses direction

    MOV A4, V3            // remember the old speed
    AND A1, V8, #0x3
    CMP A1, #0x1          // PB0 alone: slower, down to index 0
    BNE IDLE_check_faster
    CMP V3, #0
    SUBGT V3, V3, #1
IDLE_check_faster:
    CMP A1, #0x2          // PB1 alone: faster, up to index 4
    BNE IDLE_speed_ready
    CMP V3, #4
    ADDLT V3, V3, #1
IDLE_speed_ready:
    CMP V3, A4
    BEQ IDLE_check_timer
    BL IDLE_update_timer
    MOV V7, #0            // the new speed starts with a fresh timer interval

IDLE_check_timer:
    CMP V7, #0
    BEQ IDLE_display
    ADD V1, V1, V2        // move exactly one position per timer event
    LDRB A1, [V6]         // wrap over the entire message, including blanks
IDLE_wrap_left:
    CMP V1, #0
    ADDLT V1, V1, A1
    BLT IDLE_wrap_left
IDLE_wrap_right:
    CMP V1, A1
    SUBGE V1, V1, A1
    BGE IDLE_wrap_right

IDLE_display:
    MOV A1, V6
    MOV A2, V1
    BL write_msg

    // Speed index n lights the lowest 2*(n+1) LEDs; pause turns them off.
    ADD A2, V3, #1
    LSL A2, A2, #1
    MOV A1, #1
    LSL A1, A1, A2
    SUB A1, A1, #1
    CMP V4, #0
    MOVNE A1, #0
    BL write_LEDs_ASM
    B IDLE_loop

IDLE_toggle_pause:
    EOR V4, V4, #1
    CPSID I
    LDR A3, =TIMER_control
    LDR A2, [A3]
    CMP V4, #0
    BICNE A2, A2, #1      // pause the counter without reloading its value
    ORREQ A2, A2, #1      // resume with the remaining count and same speed
    STR A2, [A3]
    BL ARM_TIM_clear_INT_ASM
    LDR A1, =tim_int_flag
    MOV A2, #0
    STR A2, [A1]
    DSB SY
    CPSIE I
    B IDLE_display

// Internal helper: restart the timer at the running speed in V3.
// Preserves V1-V8; clobbers A1-A3. Called only from IDLE with IRQs enabled.
IDLE_update_timer:
    PUSH {LR}
    CPSID I
    LDR A3, =TIMER_control
    MOV A2, #0
    STR A2, [A3]          // stop before changing the load
    LDR A1, =200000000    // one second at 200 MHz
    LSR A1, A1, V3
    MOV A2, #0b110        // IRQ and auto-reload enabled, counter stopped
    BL ARM_TIM_config_ASM
    BL ARM_TIM_clear_INT_ASM
    LDR A1, =tim_int_flag
    MOV A2, #0
    STR A2, [A1]
    LDR A3, =TIMER_control
    MOV A2, #0b111
    STR A2, [A3]
    DSB SY
    CPSIE I
    POP {LR}
    BX LR

read_slider_switches_ASM:
    LDR A2, =SW_ADDR
    LDR A1, [A2]
    LDR A2, =0x3FF
    AND A1, A1, A2
    BX LR

// pre-- A1: LED bit mask
write_LEDs_ASM:
    LDR A2, =LED_ADDR
    STR A1, [A2]
    BX LR

// pre-- A1: load value (initial value)
// pre-- A2: configuration bit 
ARM_TIM_config_ASM:
    ldr A3, =TIMER_load
    str A1, [A3]

    ldr A3, =TIMER_control
    str A2, [A3]
    bx lR


// read 'F' value
// post-- A1: 0x00000000 or 0x00000001
ARM_TIM_read_INT_ASM:
    ldr A1, =TIMER_interr
    ldr A1, [A1]
    and A1, A1, #1
    bx LR

// clear 'F' value
ARM_TIM_clear_INT_ASM:
    ldr A1, =TIMER_interr
    mov A2, #1
    str A2, [A1]
    bx LR


















// pre-- A1: address of a length-prefixed message (digits 0-15 or BLANK)
// pre-- A2: signed number of right shifts (negative shifts rotate left)
// Short messages are padded on the left to six positions.
// Longer messages rotate across their full length; only six positions show.
// Preserves V1-V5; clobbers A1-A3 and flags.
write_msg:
    push {V1-V5, LR}

    ldrb A3, [A1], #1       // Length; A1 now points to the first digit
    mov V1, A1             // Message data pointer
    mov V2, A3
    cmp V2, #6
    movlt V2, #6           // Circular width = max(length, 6)
    sub V3, V2, A3         // Number of leading blank positions

write_msg_shift_negative:
    cmp A2, #0
    addlt A2, A2, V2
    blt write_msg_shift_negative

write_msg_shift_reduce:
    cmp A2, V2
    subge A2, A2, V2
    bge write_msg_shift_reduce // Normalize shift into 0 .. width-1

    rsb V4, A2, V2         // First source = (width - shift) % width
    cmp V4, V2
    moveq V4, #0
    mov V5, #HEX5          // Write from leftmost HEX5 to rightmost HEX0

write_msg_digit:
    mov A2, #BLANK
    cmp V4, V3
    blt write_msg_display  // Source is within the leading padding
    sub A3, V4, V3
    ldrb A2, [V1, A3]      // Message digit (including explicit blanks)

write_msg_display:
    mov A1, V5
    bl HEX_write_ASM

    add V4, V4, #1
    cmp V4, V2
    moveq V4, #0           // Wrap source at the full circular width
    lsrs V5, V5, #1
    bne write_msg_digit

    pop {V1-V5, LR}
    bx LR

// pre-- A1: indices of HEX
HEX_clear_ASM:
    mov A2, #NONE
    b HEX_apply_pattern

// pre-- A1: indices of HEX
HEX_flood_ASM:
    mov A2, #FULL
    b HEX_apply_pattern

// pre-- A1: indices of HEX
// pre-- A2: pattern to match (0-9 or a-f)
HEX_write_ASM:
    ldr A3, =HEX_CODES
    ldrb A2, [A3, A2]
    b HEX_apply_pattern


// pre-- A1: indices of HEX
// pre-- A2: pattern to apply
HEX_apply_pattern:
    push {V1, V2, V3}
    LDR V1, =HEX_ADDR_0_3
    mov V2, #0 // hex0
loop:
    ands V3, A1, #1
    bne write
finish_write:
    add V2, V2, #8
    cmp V2, #32
    beq switch
finish_switch:
    lsr A1, #1
    cmp A1, #0
    bne loop
end_loop:
    pop {V1, V2, V3}
    bx LR

write:
    mov V3, #0xFF
    lsl V3, V3, V2
    // clear
    LDR A3, [V1]
    bic A3, A3, V3
    // write
    lsl V3, A2, V2
    orr A3, A3, V3
    // save
    str A3, [V1]
    b finish_write

switch:
    // switch from 0-3 to 4-5
    mov V2, #0
    LDR V1, =HEX_ADDR_4_5
    b finish_switch















































// PB
// reads the data register
// post-- A1: indices of pressed buttons
read_PB_data_ASM:
    ldr A1, =DATA_REG
    ldr A1, [A1]
    and A1, A1, #0xF
    bx LR 


// tells us if a button is pressed or not
// pre-- A1: index of button to look at
// post-- A1: 0x00000001 if button is pressed else 0
PB_data_is_pressed_ASM:
    push {V1, LR}
    mov V1, A1
    bl read_PB_data_ASM
    tst V1, A1

    moveq A1, #0x00000000
    movne A1, #0x00000001
    
    pop {V1, LR}
    bx LR


// post-- A1: indices of buttons pressed and released
read_PB_edgecp_ASM:
    ldr A1, =EDGECAPTURE_REG
    ldr A1, [A1]
    and A1, A1, #0xF
    bx LR 


// pre-- A1: index of button
// post-- A1: 0x00000001 if button is pressed and release else 0
PB_edgecp_is_pressed_ASM:
    push {V1, LR}
    mov V1, A1
    bl read_PB_edgecp_ASM
    tst V1, A1

    moveq A1, #0x00000000
    movne A1, #0x00000001
    
    pop {V1, LR}
    bx LR

// clears edgecapture register by writing what we read to it
PB_clear_edgecp_ASM:
    push {V1, V2}
    ldr V1, =EDGECAPTURE_REG
    ldr V2, [V1]
    str V2, [V1]
    pop {V1, V2}
    bx LR 
    
// set interupt mask bit to indices of PB
// pre-- A1: indices of PB
enable_PB_INT_ASM:
    ldr A2, =INTERRUPT_REG
    ldr A3, [A2]
    orr A3, A3, A1
    str A3, [A2]
    bx LR

// unset interupt mask bit to indices of PB
// pre-- A1: indices of PB
disable_PB_INT_ASM:
    ldr A2, =INTERRUPT_REG
    ldr A3, [A2]
    bic A3, A3, A1
    str A3, [A2]
    bx LR






















/*--- GIC configuration -------------------------------------------*/
CONFIG_GIC:
    PUSH {LR}
    /* To configure the FPGA KEYS interrupt (ID 73):
     * 1. set the target to cpu0 in the ICDIPTRn register
     * 2. enable the interrupt in the ICDISERn register */
    /* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
    /* NOTE: you can configure different interrupts
     * by passing their IDs to R0 and repeating the next 3 lines */
    MOV R0, #73             // KEY port (Interrupt ID = 73)
    MOV R1, #1              // this field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT

    MOV R0, #29             // ARM A9 private timer (banked for this CPU)
    MOV R1, #1
    BL CONFIG_INTERRUPT

    /* configure the GIC CPU Interface */
    LDR R0, =0xFFFEC100     // base address of CPU Interface
    /* Set Interrupt Priority Mask Register (ICCPMR) */
    LDR R1, =0xFFFF         // enable interrupts of all priorities levels
    STR R1, [R0, #0x04]
    /* Set the enable bit in the CPU Interface Control Register (ICCICR).
     * This allows interrupts to be forwarded to the CPU(s) */
    MOV R1, #1
    STR R1, [R0]
    /* Set the enable bit in the Distributor Control Register (ICDDCR).
     * This enables forwarding of interrupts to the CPU Interface(s) */
    LDR R0, =0xFFFED000
    STR R1, [R0]
    POP {PC}

/*
 * Configure registers in the GIC for an individual Interrupt ID
 * We configure only the Interrupt Set Enable Registers (ICDISERn) and
 * Interrupt Processor Target Registers (ICDIPTRn). The default (reset)
 * values are used for other registers in the GIC
 * Arguments: R0 = Interrupt ID, N
 *            R1 = CPU target
 */
CONFIG_INTERRUPT:
    PUSH {R4-R5, LR}
    /* Configure Interrupt Set-Enable Registers (ICDISERn).
     * reg_offset = integer_div(N / 32) * 4
     * value = 1 << (N mod 32) */
    LSR R4, R0, #3          // calculate reg_offset
    BIC R4, R4, #3          // R4 = reg_offset
    LDR R2, =0xFFFED100
    ADD R4, R2, R4          // R4 = address of ICDISER
    AND R2, R0, #0x1F       // N mod 32
    MOV R5, #1              // enable
    LSL R2, R5, R2          // R2 = value
    /* Using the register address in R4 and the value in R2 set the
     * correct bit in the GIC register */
    LDR R3, [R4]            // read current register value
    ORR R3, R3, R2          // set the enable bit
    STR R3, [R4]            // store the new register value
    /* Configure Interrupt Processor Targets Register (ICDIPTRn)
     * reg_offset = integer_div(N / 4) * 4
     * index = N mod 4 */
    BIC R4, R0, #3          // R4 = reg_offset
    LDR R2, =0xFFFED800
    ADD R4, R2, R4          // R4 = word address of ICDIPTR
    AND R2, R0, #0x3        // N mod 4
    ADD R4, R2, R4          // R4 = byte address in ICDIPTR
    /* Using register address in R4 and the value in R2 write to
     * (only) the appropriate byte */
    STRB R1, [R4]
    POP {R4-R5, PC}


/*--- Undefined instructions --------------------------------------*/
SERVICE_UND:
    B SERVICE_UND

/*--- Software interrupts -----------------------------------------*/
SERVICE_SVC:
    B SERVICE_SVC

/*--- Aborted data reads ------------------------------------------*/
SERVICE_ABT_DATA:
    B SERVICE_ABT_DATA

/*--- Aborted instruction fetch -----------------------------------*/
SERVICE_ABT_INST:
    B SERVICE_ABT_INST

/*--- IRQ ---------------------------------------------------------*/
SERVICE_IRQ:
    PUSH {R0-R7, LR}
    /* Read the ICCIAR from the CPU Interface */
    LDR R4, =0xFFFEC100
    LDR R5, [R4, #0x0C]     // read from ICCIAR
    UBFX R0, R5, #0, #10    // interrupt ID; retain full ICCIAR token in R5
    CMP R0, #29
    BEQ Timer_check
Pushbutton_check:
    CMP R0, #73
    BEQ Handle_pushbutton
    LDR R1, =1023           // spurious IRQ: no interrupt to acknowledge
    CMP R0, R1
    BEQ RETURN_IRQ
UNEXPECTED:
    B UNEXPECTED           // unknown interrupt ID: stop here for debugging
Handle_pushbutton:
    BL KEY_ISR
    B EXIT_IRQ
Timer_check:
    BL ARM_TIM_ISR
EXIT_IRQ:
    /* Write to the End of Interrupt Register (ICCEOIR) */
    DSB SY                 // finish clearing the peripheral before EOI
    STR R5, [R4, #0x10]     // write to ICCEOIR
RETURN_IRQ:
    POP {R0-R7, LR}
    SUBS PC, LR, #4

/*--- FIQ ---------------------------------------------------------*/
SERVICE_FIQ:
    B SERVICE_FIQ


/*--- KEY interrupt service routine -------------------------------*/
KEY_ISR:
    LDR R0, =EDGECAPTURE_REG
    LDR R1, [R0]           // one bit per pressed-and-released pushbutton
    AND R1, R1, #0xF
    LDR R2, =PB_int_flag
    STR R1, [R2]           // IDLE will interpret the captured button mask
    STR R1, [R0]           // write captured bits back to clear the interrupt
    BX LR

/*--- ARM A9 private timer interrupt service routine ---------------*/
ARM_TIM_ISR:
    LDR R0, =tim_int_flag
    MOV R1, #1
    STR R1, [R0]           // IDLE will consume this pending timer event
    B ARM_TIM_clear_INT_ASM // clear F and return using the caller's LR
