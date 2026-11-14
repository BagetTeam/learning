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

HEX_CODES:
.byte 0b00111111, 0b00000110, 0b01011011, 0b01001111 // 0, 1, 2, 3
.byte 0b01100110, 0b01101101, 0b01111101, 0b00000111 // 4, 5, 6, 7
.byte 0b01111111, 0b01101111, 0b01110111, 0b01111100 // 8, 9, A, b
.byte 0b00111001, 0b01011110, 0b01111001, 0b01110001 // C, d, E, F

NONE = 0x00

.global _start

_start:


end:
    b end

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
