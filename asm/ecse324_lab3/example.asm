.global _start

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


_start:
    MOV A1, #(HEX0 | HEX1 | HEX3 | HEX5)
    bl HEX_clear_ASM

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


// pre-- A1: index of HEX
HEX_clear_ASM:
    push {V1, V2, V3}
    LDR V1, =HEX_ADDR_0_3
    mov V2, #0 // hex0
loop:
    ands V3, A1, #1
    bne clear
finish_clear:
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

clear:
    mov V3, #0xFF
    lsl V3, V3, V2

    LDR A2, [V1]
    bic A2, A2, V3
    str A2, [V1]
    b finish_clear

switch:
    // switch from 0-3 to 4-5
    mov V2, #0
    LDR V1, =HEX_ADDR_4_5
    b finish_switch

HEX_flood_ASM:


HEX_write_ASM: