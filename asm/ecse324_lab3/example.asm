.global _start

.equ SW_ADDR, 0xFF200040
.equ LED_ADDR, 0xFF200000

loop:
    bl read_slider_switches_ASM
    bl write_LEDs_ASM
    b loop

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