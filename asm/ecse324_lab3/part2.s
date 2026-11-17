.section .vectors, "ax"
B _start // reset vector
B SERVICE_UND // undefined instruction vector
B SERVICE_SVC // software interrupt vector
B SERVICE_ABT_INST // aborted prefetch vector
B SERVICE_ABT_DATA // aborted data vector
.word 0 // unused vector
B SERVICE_IRQ // IRQ interrupt vector
B SERVICE_FIQ // FIQ interrupt vector

.equ TIMER_load, 0xFFFEC600
.equ TIMER_counter, 0xFFFEC604
.equ TIMER_control, 0xFFFEC608
.equ TIMER_interr, 0xFFFEC60C

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
    BL CONFIG_GIC // configure the ARM GIC
    // NOTE: write to the pushbutton KEY interrupt mask register
    // Or, you can call enable_PB_INT_ASM subroutine from previous task
    // to enable interrupt for ARM A9 private timer,
    // use ARM_TIM_config_ASM subroutine
    LDR R0, =0xFF200050 // pushbutton KEY base address
    MOV R1, #0xF // set interrupt mask bits
    STR R1, [R0, #0x8] // interrupt mask register (base + 8)
    // enable IRQ interrupts in the processor
    MOV R0, #0b01010011 // IRQ unmasked, MODE = SVC
    MSR CPSR_c, R0

    // clear any prev timeouts
    MOV A1, #0
    MOV A2, #0
    BL ARM_TIM_config_ASM
    BL ARM_TIM_clear_INT_ASM

    // enable pb interrupts
    mov A1, #0b1111
    bl enable_PB_INT_ASM

    // set timer config
    MOV A2, #0b111          // Prescaler=0, IRQ=1, auto-reload=1, enable=1
    bl ARM_TIM_config_ASM

IDLE:
    B IDLE // This is where you write your main program task(s

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
    /* NOTE: Check which interrupt has occurred (check interrupt IDs)
     * Then call the corresponding ISR
     * If the ID is not recognized, branch to UNEXPECTED
     * See the assembly example provided in the DE1-SoC Computer Manual
     * on page 46 */
Pushbutton_check:
    CMP R5, #73
UNEXPECTED:
    BNE UNEXPECTED          // if not recognized, stop here
    BL KEY_ISR
EXIT_IRQ:
    /* Write to the End of Interrupt Register (ICCEOIR) */
    STR R5, [R4, #0x10]     // write to ICCEOIR
    POP {R0-R7, LR}
    SUBS PC, LR, #4

/*--- FIQ ---------------------------------------------------------*/
SERVICE_FIQ:
    B SERVICE_FIQ


/*--- KEY interrupt service routine -------------------------------*/
KEY_ISR:
    LDR R0, =0xFF200050     // base address of pushbutton KEY port
    LDR R1, [R0, #0xC]      // read edge capture register
    MOV R2, #0xF
    STR R2, [R0, #0xC]      // clear the interrupt
    LDR R0, =0xFF200020     // base address of HEX display
CHECK_KEY0:
    MOV R3, #0x1
    ANDS R3, R3, R1         // check for KEY0
    BEQ CHECK_KEY1
    MOV R2, #0b00111111
    STR R2, [R0]            // display "0"
    B END_KEY_ISR
CHECK_KEY1:
    MOV R3, #0x2
    ANDS R3, R3, R1         // check for KEY1
    BEQ CHECK_KEY2
    MOV R2, #0b00000110
    STR R2, [R0]            // display "1"
    B END_KEY_ISR
CHECK_KEY2:
    MOV R3, #0x4
    ANDS R3, R3, R1         // check for KEY2
    BEQ IS_KEY3
    MOV R2, #0b01011011
    STR R2, [R0]            // display "2"
    B END_KEY_ISR
IS_KEY3:
    MOV R2, #0b01001111
    STR R2, [R0]            // display "3"
END_KEY_ISR:
    BX LR
