.global _start
// int a[4] = {1, 2, 3, 4};
matrixA: .word 1, 2, 3, 4
lengthA: .word 4
// int b[8] = {2, 3, 5, 7, 11, 13, 17, 19};
matrixB: .word 2, 3, 5, 7, 11, 13, 17, 19
lengthB: .word 8
// we’ll save our results here
results: .space 8

// Summation
// Sum the integers in the given array
// pre-- A1: address of array
// pre-- A2: length of array
// post- A1: sum of elements
sum:
    PUSH {V1, V2, V3} // **you** push any registers used below onto the stack
    // int answer = 0;
    // for (int index=0; index<length; index++)
    MOV V1, #0 // **you** answer=0
    MOV V2, #0 // **you** index=0
sumIter:
    CMP V2, A2 // **you** index<length?
    BGE sumDone // **you** if not, branch to sumDone
    // answer += array[index];
    LDR V3, [A1], #4 // **you** read the element at index in the array
    ADD V1, V1, V3 // **you** accumulate the answer
    ADD V2, V2, #1 // **you** index++
    B sumIter // repeat until done!
sumDone:
    MOV A1, V1 // **you** move the final answer into A1
    POP {V1, V2, V3} // **you** pop any registers pushed above
    BX LR // return!
_start:
    // int a_s = sum((int *) a, 4); // 10
    LDR A1, =matrixA // put the address of A in A1
    LDR A2, lengthA // put the length of A in A2
    BL sum // call the function
    LDR V1, =results // put the address of Results in V1
    STR A1, [V1] // save the answer (in A1) in result+0
    // int b_s = sum((int *) b, 8); // 77
    LDR A1, =matrixB // **you** put the address of B in A1
    LDR A2, lengthB // **you** put the length of B in A2
    BL sum // **you** call the function
    STR A1, [V1, #4] // **you** save the answer (in A1) in result+4
inf:
    B inf // infinite loop!