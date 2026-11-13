// 
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
    MOV A1, #(HEX0 | HEX1 | HEX3 | HEX5)
    bl HEX_write_c0ffee

stop:
    b stop



HEX_write_c0ffee:
    push {LR}
    mov A1, #(HEX0 | HEX1)
    mov A2, #0xe
    bl HEX_write_ASM
    mov A1, #(HEX2 | HEX3)
    mov A2, #0xf
    bl HEX_write_ASM
    mov A1, #HEX4
    mov A2, #0x0
    bl HEX_write_ASM
    mov A1, #HEX5
    mov A2, #0xc
    bl HEX_write_ASM
    pop {LR}
    bx LR

HEX_write_cafe5:
    push {LR}
    mov A1, #HEX0
    mov A2, #NONE
    bl HEX_apply_pattern
    mov A1, #HEX1
    mov A2, #0x5
    bl HEX_write_ASM
    mov A1, #HEX2
    mov A2, #0xe
    bl HEX_write_ASM
    mov A1, #HEX3
    mov A2, #0xf
    bl HEX_write_ASM
    mov A1, #HEX4
    mov A2, #0xa
    bl HEX_write_ASM
    mov A1, #HEX5
    mov A2, #0xc
    bl HEX_write_ASM
    pop {LR}
    bx LR

HEX_write_cab5:
    push {LR}
    mov A1, #(HEX0 | HEX1)
    mov A2, #NONE
    bl HEX_apply_pattern
    mov A1, #HEX2
    mov A2, #0x5
    bl HEX_write_ASM
    mov A1, #HEX3
    mov A2, #0xb
    bl HEX_write_ASM
    mov A1, #HEX4
    mov A2, #0xa
    bl HEX_write_ASM
    mov A1, #HEX5
    mov A2, #0xc
    bl HEX_write_ASM
    pop {LR}
    bx LR

HEX_write_ace:
    push {LR}
    mov A1, #(HEX0 | HEX1 | HEX2)
    mov A2, #NONE
    bl HEX_apply_pattern
    mov A1, #HEX3
    mov A2, #0xe
    bl HEX_write_ASM
    mov A1, #HEX4
    mov A2, #0xc
    bl HEX_write_ASM
    mov A1, #HEX5
    mov A2, #0xa
    bl HEX_write_ASM
    pop {LR}
    bx LR




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
