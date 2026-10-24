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
    // PUSH
    push {V1, V2, LR}
    mov V1, A1 // n

    cmp V1, #1
    beq pell_stop
    cmp V1, #0
    beq pell_stop

    // 2 * pell(n-1)
    sub A1, V1, #1
    bl pell
    mov V2, A1, LSL #1

    // pell(n-2)
    sub A1, V1, #2
    bl pell
    add A1, V2, A1
pell_stop:
    // POP   
    pop {V1, V2, LR}
    bx LR
