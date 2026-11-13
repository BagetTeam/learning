PB0 = 0x00000001
PB1 = 0x00000002
PB2 = 0x00000004
PB3 = 0x00000008

.equ DATA_REG, 0xFF200050
.equ INTERRUPT_REG, 0xFF200058
.equ EDGECAPTURE_REG, 0xFF20005C


.global _start

_start:
    mov A1, #PB1
    bl PB_data_is_pressed_ASM

stop:
    b stop

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