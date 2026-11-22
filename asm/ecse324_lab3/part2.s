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

    // clear old interrupts
    mov A1, #0
    mov A2, #0
    bl ARM_TIM_config_ASM
    bl ARM_TIM_clear_INT_ASM

    mov A1, #0xF
    bl disable_PB_INT_ASM
    ldr A1, =EDGECAPTURE_REG
    mov A2, #0xF
    str A2, [A1]

    mov A2, #0
    ldr A1, =PB_int_flag
    str A2, [A1]
    ldr A1, =tim_int_flag
    str A2, [A1]

    BL CONFIG_GIC        // configure the ARM GIC

    mov A1, #0xF
    bl enable_PB_INT_ASM

    ldr A1, =TIMER_DEFAULT_LOAD
    mov A2, #0b111          // IRQ + auto-reload + enable
    bl ARM_TIM_config_ASM

    // setup done -> enable IRQs
    dsb SY
    MOV R0, #0b01010011 // IRQ unmasked, FIQ masked, MODE = SVC
    MSR CPSR_c, R0

IDLE:
    mov V1, #0          // shift count
    mov V2, #-1         // -1: left, 1: right
    mov V3, #2          // 0-4 -> 1, 1/2, 1/4, 1/8, 1/16 s
    mov V4, #0          // 0: running, 1: paused
    mov V5, #-1         // prev switches
    ldr V6, =COFFEE     // current msg

IDLE_loop:
    // IRQs off -> take flags, then clear
    // V7 -> timer, V8 -> PB
    cpsid I
    mov A2, #0
    ldr A1, =PB_int_flag
    ldr V8, [A1]
    str A2, [A1]
    ldr A1, =tim_int_flag
    ldr V7, [A1]
    str A2, [A1]
    cpsie I

    bl read_slider_switches_ASM
    cmp A1, #0x00
    ldreq V6, =COFFEE
    beq IDLE_valid_message
    cmp A1, #0x01
    ldreq V6, =CAFES
    beq IDLE_valid_message
    cmp A1, #0x02
    ldreq V6, =CABS
    beq IDLE_valid_message
    cmp A1, #0x04
    ldreq V6, =ACE
    beq IDLE_valid_message
    cmp A1, #0x08
    ldreq V6, =MSG_8
    beq IDLE_valid_message
    cmp A1, #0x10
    ldreq V6, =MSG_10
    beq IDLE_valid_message
    ldr V6, =MSG_BLANK
    b IDLE_message_ready

IDLE_valid_message:
    cmp A1, V5
    movne V1, #0 // new msg -> reset shift
    movne V7, #0
IDLE_message_ready:
    mov V5, A1

    // PB3 first -> pause/resume
    tst V8, #0x8
    bne IDLE_toggle_pause
    cmp V4, #0
    bne IDLE_display // paused -> skip PB0-2 + timer

    tst V8, #0x4
    rsbne V2, V2, #0 // PB2 -> reverse

    mov A4, V3
    and A1, V8, #0x3
    cmp A1, #0x1  // PB0 -> slower
    bne IDLE_check_faster
    cmp V3, #0
    subgt V3, V3, #1
IDLE_check_faster:
    cmp A1, #0x2  // PB1 -> faster
    bne IDLE_speed_ready
    cmp V3, #4
    addlt V3, V3, #1
IDLE_speed_ready:
    cmp V3, A4
    beq IDLE_check_timer
    bl IDLE_update_timer
    mov V7, #0

IDLE_check_timer:
    cmp V7, #0
    beq IDLE_display
    add V1, V1, V2
    ldrb A1, [V6]  // wrap at msg length
IDLE_wrap_left:
    cmp V1, #0
    addlt V1, V1, A1
    blt IDLE_wrap_left
IDLE_wrap_right:
    cmp V1, A1
    subge V1, V1, A1
    bge IDLE_wrap_right

IDLE_display:
    mov A1, V6
    mov A2, V1
    bl write_msg

    // speed -> 2 LEDs per level, paused -> off
    add A2, V3, #1
    lsl A2, A2, #1
    mov A1, #1
    lsl A1, A1, A2
    sub A1, A1, #1
    cmp V4, #0
    movne A1, #0
    bl write_LEDs_ASM
    b IDLE_loop

IDLE_toggle_pause:
    eor V4, V4, #1
    cpsid I
    ldr A3, =TIMER_control
    ldr A2, [A3]
    cmp V4, #0
    bicne A2, A2, #1  // pause -> keep remaining count
    orreq A2, A2, #1
    str A2, [A3]
    bl ARM_TIM_clear_INT_ASM
    ldr A1, =tim_int_flag
    mov A2, #0
    str A2, [A1]
    dsb SY
    cpsie I
    b IDLE_display

// V3 -> speed, restart timer
IDLE_update_timer:
    push {LR}
    cpsid I
    ldr A3, =TIMER_control
    mov A2, #0
    str A2, [A3]
    ldr A1, =200000000
    lsr A1, A1, V3
    mov A2, #0b110  // configure while stopped
    bl ARM_TIM_config_ASM
    bl ARM_TIM_clear_INT_ASM
    ldr A1, =tim_int_flag
    mov A2, #0
    str A2, [A1]
    ldr A3, =TIMER_control
    mov A2, #0b111
    str A2, [A3]
    dsb SY
    cpsie I
    pop {LR}
    bx LR



// returns the state of slider switches in A1
// post- A1: slide switch state
read_slider_switches_ASM:
    LDR A2, =SW_ADDR // load the address of slider switch state
    LDR A1, [A2] // read slider switch state
    ldr A2, =0x3FF
    and A1, A1, A2
    BX LR

// LEDs Driver
// writes the state of LEDs (On/Off) in A1 to the LEDs' control register
// pre-- A1: data to write to LED state
write_LEDs_ASM:
    LDR A2, =LED_ADDR // load the address of the LEDs' state
    STR A1, [A2] // update LED state with the contents of A1
    BX LR

// pre-- A1: load, 
// pre-- A2: config
ARM_TIM_config_ASM:
    ldr A3, =TIMER_load
    str A1, [A3]

    ldr A3, =TIMER_control
    str A2, [A3]
    bx LR


// post-- A1: F bit (0x00000001 or 0x000000000)
ARM_TIM_read_INT_ASM:
    ldr A1, =TIMER_interr
    ldr A1, [A1]
    and A1, A1, #1
    bx LR

// clear F
ARM_TIM_clear_INT_ASM:
    ldr A1, =TIMER_interr
    mov A2, #1
    str A2, [A1]
    bx LR







// pre-- A1: msg to write 
// pre-- A2: number of right shifts (negative = left)
write_msg:
    push {V1-V5, LR}

    ldrb A3, [A1], #1
    mov V1, A1
    mov V2, A3
    cmp V2, #6
    movlt V2, #6  // width -> max(length, 6)
    sub V3, V2, A3

write_msg_shift_negative:
    cmp A2, #0
    addlt A2, A2, V2
    blt write_msg_shift_negative

write_msg_shift_reduce:
    cmp A2, V2
    subge A2, A2, V2
    bge write_msg_shift_reduce // shift -> 0..width-1

    rsb V4, A2, V2
    cmp V4, V2
    moveq V4, #0
    mov V5, #HEX5 // HEX5 -> HEX0

write_msg_digit:
    mov A2, #BLANK
    cmp V4, V3
    blt write_msg_display
    sub A3, V4, V3
    ldrb A2, [V1, A3]

write_msg_display:
    mov A1, V5
    bl HEX_write_ASM

    add V4, V4, #1
    cmp V4, V2
    moveq V4, #0
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
    ldr V1, =HEX_ADDR_0_3
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
    ldr V1, =HEX_ADDR_4_5
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

    mov R0, #29             // timer -> ID 29
    mov R1, #1
    bl CONFIG_INTERRUPT

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
    ubfx R0, R5, #0, #10    // R0 -> ID, R5 -> full token
    cmp R0, #29
    beq Timer_check
Pushbutton_check:
    cmp R0, #73
    beq Handle_pushbutton
    ldr R1, =1023           // spurious -> return
    cmp R0, R1
    beq RETURN_IRQ
UNEXPECTED:
    b UNEXPECTED           // unknown ID -> stop
Handle_pushbutton:
    BL KEY_ISR
    b EXIT_IRQ
Timer_check:
    bl ARM_TIM_ISR
EXIT_IRQ:
    /* Write to the End of Interrupt Register (ICCEOIR) */
    dsb SY                 // clear peripheral -> EOI
    STR R5, [R4, #0x10]     // write to ICCEOIR
RETURN_IRQ:
    POP {R0-R7, LR}
    SUBS PC, LR, #4

/*--- FIQ ---------------------------------------------------------*/
SERVICE_FIQ:
    B SERVICE_FIQ


/*--- KEY interrupt service routine -------------------------------*/
KEY_ISR:
    ldr R0, =EDGECAPTURE_REG
    ldr R1, [R0]
    and R1, R1, #0xF
    ldr R2, =PB_int_flag
    str R1, [R2]  // PB mask -> flag
    str R1, [R0]
    bx LR

/*--- ARM A9 private timer interrupt service routine ---------------*/
ARM_TIM_ISR:
    ldr R0, =tim_int_flag
    mov R1, #1
    str R1, [R0]  // timer -> flag
    b ARM_TIM_clear_INT_ASM
