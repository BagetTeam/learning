// LED

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

HEX_CODES:
.byte 0b00111111, 0b00000110, 0b01011011, 0b01001111 // 0, 1, 2, 3
.byte 0b01100110, 0b01101101, 0b01111101, 0b00000111 // 4, 5, 6, 7
.byte 0b01111111, 0b01101111, 0b01110111, 0b01111100 // 8, 9, A, b
.byte 0b00111001, 0b01011110, 0b01111001, 0b01110001 // C, d, E, F

NONE = 0x00
FULL = 0x7F


// PB

PB0 = 0x00000001
PB1 = 0x00000002
PB2 = 0x00000004
PB3 = 0x00000008

.equ DATA_REG, 0xFF200050
.equ INTERRUPT_REG, 0xFF200058
.equ EDGECAPTURE_REG, 0xFF20005C


.global _start

_start:
    // setup
    mov A1, #0
    bl write_LEDs_ASM
    bl PB_clear_edgecp_ASM
    MOV A1, #0
    bl HEX_write_c0ffee

    bl compute

stop:
    b stop


compute:
    push {LR, V1, V2, V3, V4}
    mov V1, #0  // shift total count
    mov V2, #0  // right shifting count
    mov V3, #-1 // -1: left shiting, 1: right shifting
    mov V4, #0  // current slider
big_loop:
   // LED logic
    mov A1, V1
    bl write_LEDs_ASM
    
    // slider logic (count and messages)
    bl read_slider_switches_ASM
    cmp A1, V4 // change message -> clear count and rotation
    movne V1, #0 
    movne V2, #0
    mov V4, A1

    mov A1, V2
    cmp V4, #0x00
    bne check_cafe5
    bl HEX_write_c0ffee
    b check_rotation_pb
check_cafe5:
    cmp V4, #0x01
    bne check_cab5
    bl HEX_write_cafe5
    b check_rotation_pb
check_cab5:
    cmp V4, #0x02
    bne check_ace
    bl HEX_write_cab5
    b check_rotation_pb
check_ace:
    cmp V4, #0x04
    bne make_blank
    bl HEX_write_ace
    b check_rotation_pb
make_blank:
    bl HEX_write_blank // dont match any of the messages
    b rotation_logic_done

check_rotation_pb:
    // check PB edge cap
    mov A1, #PB2 // switch left -> right -> left
    bl PB_edgecp_is_pressed_ASM
    cmp A1, #1
    rsbeq V3, V3, #0 // reverse sign

    mov A1, #PB3 // shift 
    bl PB_edgecp_is_pressed_ASM
    cmp A1, #1
    addeq V1, V1, #1
    beq add_shift
done_add_shift:
    cmp V1, #1024
    subeq V1, V1, #1
rotation_logic_done:
    bl PB_clear_edgecp_ASM

    b big_loop
    pop {LR, V1, V2, V3, V4}
    bx LR

add_shift:
    add V2, V2, V3
    cmp V2, #6
    moveq V2, #0
    cmp V2, #-1
    moveq V2, #5
    b done_add_shift



// PB Logic

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
    
// LEDS logic
    
// pre-- A1: data to write to LED state
write_LEDs_ASM:
    LDR A2, =LED_ADDR // load the address of the LEDs' state
    STR A1, [A2] // update LED state with the contents of A1
    BX LR


// SLIDERS logic

// post- A1: slide switch state
read_slider_switches_ASM:
    LDR A2, =SW_ADDR // load the address of slider switch state
    LDR A1, [A2] // read slider switch state
    LDR A2, =0x3FF
    and A1, A1, A2
    BX LR


// HEX logic

HEX_write_blank:
    push {LR}
    mov A1, #(HEX0 | HEX1 | HEX2 | HEX3 | HEX4 | HEX5)
    bl HEX_clear_ASM
    pop {LR}
    bx LR

// pre-- A1: numbers of right shifting
HEX_write_c0ffee:
    push {LR, V1}
    mov V1, A1

    mov A1, #(HEX0 | HEX1)
    mov A2, V1
    bl HEX_index_shifting
    mov A2, #0xe
    bl HEX_write_ASM

    mov A1, #(HEX2 | HEX3)
    mov A2, V1
    bl HEX_index_shifting
    mov A2, #0xf
    bl HEX_write_ASM

    mov A1, #HEX4
    mov A2, V1
    bl HEX_index_shifting
    mov A2, #0x0
    bl HEX_write_ASM

    mov A1, #HEX5
    mov A2, V1
    bl HEX_index_shifting
    mov A2, #0xc
    bl HEX_write_ASM

    pop {LR, V1}
    bx LR

HEX_write_cafe5:
    push {LR, V1}
    mov V1, A1

    mov A1, #HEX0
    mov A2, V1
    bl HEX_index_shifting
    bl HEX_clear_ASM

    mov A1, #HEX1
    mov A2, V1
    bl HEX_index_shifting
    mov A2, #0x5
    bl HEX_write_ASM

    mov A1, #HEX2
    mov A2, V1
    bl HEX_index_shifting
    mov A2, #0xe
    bl HEX_write_ASM

    mov A1, #HEX3
    mov A2, V1
    bl HEX_index_shifting
    mov A2, #0xf
    bl HEX_write_ASM

    mov A1, #HEX4
    mov A2, V1
    bl HEX_index_shifting
    mov A2, #0xa
    bl HEX_write_ASM

    mov A1, #HEX5
    mov A2, V1
    bl HEX_index_shifting
    mov A2, #0xc
    bl HEX_write_ASM

    pop {LR, V1}
    bx LR

HEX_write_cab5:
    push {LR, V1}
    mov V1, A1

    mov A1, #(HEX0 | HEX1)
    mov A2, V1
    bl HEX_index_shifting
    bl HEX_clear_ASM

    mov A1, #HEX2
    mov A2, V1
    bl HEX_index_shifting
    mov A2, #0x5
    bl HEX_write_ASM

    mov A1, #HEX3
    mov A2, V1
    bl HEX_index_shifting
    mov A2, #0xb
    bl HEX_write_ASM

    mov A1, #HEX4
    mov A2, V1
    bl HEX_index_shifting
    mov A2, #0xa
    bl HEX_write_ASM

    mov A1, #HEX5
    mov A2, V1
    bl HEX_index_shifting
    mov A2, #0xc
    bl HEX_write_ASM

    pop {LR, V1}
    bx LR

HEX_write_ace:
    push {LR, V1}
    mov V1, A1
    mov A1, #(HEX0 | HEX1 | HEX2)
    mov A2, V1
    bl HEX_index_shifting
    bl HEX_clear_ASM

    mov A1, #HEX3
    mov A2, V1
    bl HEX_index_shifting
    mov A2, #0xe
    bl HEX_write_ASM
    
    mov A1, #HEX4
    mov A2, V1
    bl HEX_index_shifting
    mov A2, #0xc
    bl HEX_write_ASM
    
    mov A1, #HEX5
    mov A2, V1
    bl HEX_index_shifting
    mov A2, #0xa
    bl HEX_write_ASM
    
    pop {LR, V1}
    bx LR

// pre-- A1: index of HEX
// pre-- A2: right shifting number (0-5)
// post-- A1: index of HEX after shift
HEX_index_shifting:
    and A1, A1, #0x3F
    cmp A2, #0             // Check if shift amount is 0 (or negative)
    ble shift_done
index_shift:
    lsrs A1, A1, #1
    addcs A1, A1, #0x20
    subs A2, A2, #1
    bne index_shift
shift_done:
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
