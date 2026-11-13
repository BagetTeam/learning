.equ SW_ADDR, 0xFF200040
.equ LED_ADDR, 0xFF200000
.equ HEX_ADDR_0_3, 0xFF200020
.equ HEX_ADDR_4_5, 0xFF200030

// for selecting which hex to perform action to (011010 = hex 1, 3, 4) 
HEX0 = 0x00000001
HEX1 = 0x00000002
HEX2 = 0x00000004
HEX3 = 0x00000008
HEX4 = 0x00000010
HEX5 = 0x00000020

// writing numbers
ZERO  = 0x3F    // 0111111
ONE   = 0x06    // 0000110
TWO   = 0x5B    // 1011011
THREE = 0x4F    // 1001111
FOUR  = 0x66    // 1100110
FIVE  = 0x6D    // 1101101
SIX   = 0x7D    // 1111101
SEVEN = 0x07    // 0000111
EIGHT = 0x7F    // 1111111
NINE  = 0x6F    // 1101111
AA = 0x77         // 1110111
BB = 0x7C         // 1111100
CC = 0x39         // 0111001
DD = 0x5E         // 1011110
EE = 0x79         // 1111001
FF = 0x71         // 1110001

NONE = 0x00
FULL = 0x7F

.data
HEX_patterns:
    .byte ZERO, ONE, TWO, THREE
    .byte FOUR, FIVE, SIX, SEVEN
    .byte EIGHT, NINE, AA, BB
    .byte CC, DD, EE, FF
.text

.global _start

_start:
    MOV A1, #(HEX0 | HEX1 | HEX3 | HEX5)
    bl HEX_flood_ASM

stop:
    b stop

// Slider Switches Driver
// returns the state of slider switches in A1
// post- A1: slide switch state
read_slider_switches_ASM:
    LDR A2, =SW_ADDR // load the address of slider switch state
    LDR A1, [A2] // read slider switch state
    BX LR
    
// LEDs Driver
// writes the state of LEDs (On/Off) in A1 to the LEDs' control register
// pre-- A1: data to write to LED state
write_LEDs_ASM:
    LDR A2, =LED_ADDR // load the address of the LEDs' state
    STR A1, [A2] // update LED state with the contents of A1
    BX LR


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
    ldr A3, =HEX_patterns
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
