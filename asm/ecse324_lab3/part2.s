.equ TIMER_load, 0xFFFEC600
.equ TIMER_counter, 0xFFFEC604
.equ TIMER_control, 0xFFFEC608
.equ TIMER_interr, 0xFFFEC60C



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

