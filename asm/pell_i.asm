.global _start
N: .word 10 // input parameter n
P: .space 4 // Pell number result
_start:
    ldr A1, N // get the input parameter
    bl pell // go!
    str A1, P // save the result
stop:
    b stop

// Pell number calculation
// pre-- A1: Pell number index i to calculate, n >= 0
// post- A1: Pell number P = pell(n)
pell:
    push {V1, V2, V3, V4}
    cmp A1, #0
    beq pell_done
    cmp A1, #1
    beq pell_done

    mov V1, #0 // prev
    mov V2, #1 // cur
    mov V3, #1 // i = 1
pell_loop:
    mov V4, V2
    add V2, V1, V2, LSL #1
    mov V1, V4

    add V3, V3, #1
    cmp V3, A1
    blt pell_loop

    mov A1, V2
pell_done:
    pop {V1, V2, V3, V4}
    bx LR
