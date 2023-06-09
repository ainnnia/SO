global inverse_permutation

INT_MAX_PLUS_ONE equ 2147483648
INT_SIZE equ 4

%define n           	r9          ; ilość liczb
%define array 	        rsi         ; tablica
%define i 	            r8          ; licznik pętli
%define id               r8d         ; mały indeks pomocniczy
%define j 	            r10         ; indeks pomocniczy
%define jd              r10d        ; mały indeks pomocniczy
%define result 	        rax         ; wynik
%define m               r11         ; indeks pomocniczy
%define md              r11d        ; mały indeks pomocniczy

%macro validate_n 0 ; check if the size is valid
    cmp n, 1 ; check if n is not less than 1
    jl  return_false
    mov rcx, INT_MAX_PLUS_ONE 
    cmp n, rcx ; check if n is not greater than INT_MAX_PLUS_ONE
    jg return_false
%endmacro

%macro validate_array 0 ; check if the array is valid
    mov i, 0
validate_array_loop:
    movsxd rcx, dword[array + i * INT_SIZE] ; rcx now holds array[i] as a 64 bit integer
    cmp rcx, 0 ; check if array[i] is positive
    jl return_false
    cmp rcx, n ; check if array[i] is less than n
    jge return_false
    inc i
    cmp i, n
    jl validate_array_loop
    xor i, i
%endmacro

%macro check_permutation 0 ; check if the array is a correct permutation
    mov i, 0
check_permutation_loop:
    mov ecx, dword[array + i * INT_SIZE] ; ecx now holds array[i] as a 32 bit integer
    and ecx, 0x7fffffff ; clear the sing bit
    movsxd j, ecx; j now holds array[i] without a sign as a 64 bit integer
    mov eax, dword[array + j * INT_SIZE] ; eax now holds array[j] = array[array[i]]
    test eax, 0x80000000 ; check if array[j] is marked
    jnz return_false_and_revert ; if it is, the array is not a permutation
    or eax, 0x80000000 ; mark array[j]
    mov dword[array + j * INT_SIZE], eax ; store the marked array[j]
    inc i
    cmp i, n
    jl check_permutation_loop
    xor i, i
%endmacro

; Inverts the array in place. The array must be a permutation.
; Based on Algorithm I by Bing-Chao Huang, with the following modifications:
; Instead of setting the element of the array to negative values, only the sign bit is marked.
; This allows to use the algorithm on arrays with permutations starting from 0, not 1
; The array is reverted at the end of the algorithm.
%macro inverse_in_place 0 
    xor i, i
    xor j, j
    xor m, m
    ; setting up the variables
    mov rax, n
    dec rax
    mov md, eax 
    mov jd, 1 ; jd now holds 1
    or jd, 0x80000000 ; mark jd
    
.next_element: ; I2
    mov id, dword[array + m * INT_SIZE] ; id now holds array[m]
    test id, 0x80000000 ; check if array[m] is marked
    jnz .final_loop_part ; if it is, invert the element
.invert_one: ; I3
    mov dword[array + m * INT_SIZE], jd ; store the marked array[m]
    mov jd, md
    test jd, 0x80000000
    jnz .unmark_jd ; if it is, unmark the element
    .mark_jd:
    or jd, 0x80000000 ; mark the element
    jmp .leave_marked_jd
    .unmark_jd:
    and jd, 0x7fffffff ; clear the sign bit
    .leave_marked_jd:
    mov md, id
    mov id, dword[array + m * INT_SIZE] ; id now holds array[m]
.end_of_cycle: ; I4
    test id, 0x80000000 ; check if array[m] is marked
    jz .invert_one ; if it is not, invert the element
.store_final_value: ; I5
    mov id, jd
.final_loop_part:
    mov eax, id
    test eax, 0x80000000
    jnz .unmark_eax ; if it is, unmark the element
    .mark_eax:
    or eax, 0x80000000 ; mark the element
    jmp .leave_marked_eax
    .unmark_eax:
    and eax, 0x7fffffff ; clear the sign bit
    .leave_marked_eax:
    mov dword[array + m * INT_SIZE], eax ; store the marked array[m]
    dec m
    cmp m, 0
    jge .next_element

%endmacro

inverse_permutation:

    ; Input:

    mov n, rdi ; get the size of the array
    mov array, rsi ; get the array

    ; Validation:
    
    validate_n ; check if the size is valid
    validate_array ; check if the array is valid
    check_permutation ; check if the array is a permutation

    ; Revert the array:

    mov i, 0
.revert_loop:
    and dword[array + i * INT_SIZE], 0x7fffffff ; clear the sign bit
    inc i
    cmp i, n
    jl .revert_loop
    xor i, i

    ; Algorithm:

    inverse_in_place

    ; End:

return_true:
    mov result, 1
    ret

return_false:
    mov result, 0
    ret

return_false_and_revert:
    mov result, 0

return_and_revert:
    mov i, 0
.revert_array_loop:
    and dword[array + i * INT_SIZE], 0x7fffffff ; clear the sign bit
    inc i
    cmp i, n
    jl .revert_array_loop
    xor i, i
    ret