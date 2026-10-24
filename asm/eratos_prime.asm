.global _start
N: .word 12
Numbers: .short 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
Primes: .space 24
_start:
// your code starts here
    LDR A1, =Numbers
    LDR A2, N
    LDR V1, =Primes
    MOV V2, #0 // num = 0
    MOV V3, #0 // some value 0
    MOV V4, #1 // prime = 1
search:
    SUB V2, V4, #1 // num = prime - 1

// while (num < n && numbers[num] == 0) num++
find_next_prime:
    CMP V2, A2
    BGE searchDone // if (num >= n) -> return
    MOV V6, V2, LSL #1
    LDRH V6, [A1, V6]
    CMP V6, #0
    BNE found_next_prime
    ADD V2, #1
    B find_next_prime
found_next_prime:
    MOV V4, V6 
    STRH V4, [V1], #2 // Primes[pri++] = numbers[num]

set_zero:
    MOV V6, V2, LSL #1
    STRH V3, [A1, V6] // numbers[num] = 0
    ADD V2, V2, V4
    CMP V2, A2
    BLT set_zero
all_zero_set:
    B search
searchDone:
    B searchDone