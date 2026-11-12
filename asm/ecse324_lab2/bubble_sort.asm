// Bubble Sort in ascending order (signed-bytes)
// In place modification, return input array address in A1
.global _start

Stuff:  .byte 0,3,2,5,5,4,1 // input array
        .space 1 // to align next word

N: .word 7 // number of elements in Stuff
Sorted: .space 7 // (optional) sorted output
        .space 1 // to align next word

_start:
    ldr A1, =Stuff // get the address of Stuff
    ldr A2, N // get the number of things in Stuff
    bl sort // go!
stop:
    b stop
    // Sorting algorithm
    // pre-- A1: Address of array of signed bytes to be sorted
    // pre-- A2: Number of elements in array
    // post- A1: Address of sorted array

sort:
    push {V1, V2, V3, V4, V5}
    cmp A2, #2
    blt end_sort
    mov V1, A2 // i = N
swap:
    mov V3, #1 // j = 1
loop_swap:
    sub V2, V3, #1
    ldrsb V4, [A1, V2]
    ldrsb V5, [A1, V3]
    cmp V4, V5
    ble V4_le
V4_gt:
    strb V4, [A1, V3]
    strb V5, [A1, V2]
V4_le:
    add V3, V3, #1
    cmp V3, V1
    blt loop_swap // while j < i
end_loop_swap:
    sub V1, V1, #1
    cmp V1, #1
    bgt swap // while i > 1
end_sort:
    pop {V1, V2, V3, V4, V5}
    bx LR

