// Quick Sort in ascending order (signed-bytes)
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
    push {V1, LR}
    mov V1, A2 // N
    sub A3, V1, #1 // high = N - 1
    mov A2, #0 // low = 0
    bl quick_sort
    mov A2, V1
    pop {V1, LR}
    bx LR

// pre-- A1: Address of array
// pre-- A2: low
// pre-- A3: high
quick_sort:
    push {V1, V2, LR}
    cmp A2, A3
    bge end_quick_sort

    mov V1, A2 // v1 = low
    bl partition 
    mov V2, A2 // v2 = i (index of pivot)
    
    add A2, V2, #1 // low = i+1, high = high
    bl quick_sort

    mov A2, V1 // low = low
    sub A3, V2, #1 // high = i-1
    bl quick_sort

end_quick_sort:
    pop {V1, V2, LR}
    bx LR


// pre-- A1: Address of array
// pre-- A2: low
// pre-- A3: high
// post- A2: i, where pivot is now at (all before pivot is smaller than pivot)
partition:
    push {V1, V2, V3, V4, V5}
    ldrsb V1, [A1, A3] // pivot = stuff[high]
    mov V2, A2 // i = low
    mov V3, A2 // j = low
swap_loop:
    ldrsb V5, [A1, V3] // num = stuff[j]
    cmp V5, V1
    bge ge_pivot

    // swap
    ldrsb V4, [A1, V2]
    strb V4, [A1, V3]
    strb V5, [A1, V2]
    add V2, V2, #1 // i++
ge_pivot:
    add V3, V3, #1 // j++
    cmp V3, A3
    blt swap_loop
swap_pivot:
    ldrsb V4, [A1, V2]
    strb V1, [A1, V2]
    strb V4, [A1, A3]
    mov A2, V2 // return (A2) i
    pop {V1, V2, V3, V4, V5}
    bx LR
