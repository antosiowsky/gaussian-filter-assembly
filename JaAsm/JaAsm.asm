;RCX - OldPixels pointer
;R12 - NewPixels pointer
;R8 - Starting index
;R9 - End index
;R10 - width
;R11 - Negative width

.data
multiArray word 1, 2, 1, 2, 4, 2, 1, 2, 1
normalizationFactor dq 16.0 ; Normalization factor

.code
AsmProc proc
    sub rsp, 40 ; Allocate shadow space for fastcall

    movdqu xmm4, oword ptr[multiArray]      ;Load mask array
    movsd xmm5, qword ptr[normalizationFactor] ; Load normalization factor

    mov ebx, dword ptr[rbp + 48]          ;Image width
    mov r10, rbx                          ;Store width
    xor r11, r11                          ;Clear r11
    sub r11, r10                          ;Negative width

    mov r12, rdx                          ;New pixels pointer
    mov rdi, r8                           ;Starting index
    add rcx, r8                           ;Offset old pixels pointer
    add R12, r8                           ;Offset new pixels pointer

programLoop:
    cmp rdi, r9                           ;Loop condition
    je endLoop

    pxor xmm1, xmm1                       ;Clear registers
    pxor xmm2, xmm2
    pxor xmm3, xmm3

    pinsrb xmm1, byte ptr[RCX + R11], 1      ;Id.1. Locate mask values 1 in xmm1
    pinsrb xmm1, byte ptr[RCX + R11 + 3], 2    ;Id.2. Locate mask values 1 in xmm1
    pinsrb xmm1, byte ptr[RCX + 3], 4        ;Id.4. Locate mask values 1 in xmm1
    pinsrb xmm1, byte ptr[RCX + R10], 6      ;Id.6. Locate mask values 1 in xmm1
    pinsrb xmm1, byte ptr[RCX + R10 + 3], 7    ;Id.7. Locate mask values 1 in xmm1

    pinsrb xmm3, byte ptr[RCX + R11 - 3], 0    ;Id.0. Locate mask values -1 in xmm3
    pinsrb xmm3, byte ptr[RCX - 3], 1      ;Id.1. Locate mask values -1 in xmm3
    pinsrb xmm3, byte ptr[RCX + R10 - 3], 2    ;Id.2. Locate mask values -1 in xmm3

    psadbw xmm3, xmm2                     ;Sum pixel values with mask value -1

    pinsrb xmm3, byte ptr[RCX], 4          ;Id.4. Locate pixel with mask value -2 in xmm3

    pmullw xmm3, xmm4                     ;Multiply values in xmm3 with filter mask values stored in xmm4

    pxor xmm2, xmm2                       ;Clear xmm2
    psadbw xmm1, xmm2                     ;Sum pixel values with mask value 1

    paddsw xmm1, xmm3                     ;Sum signed values
    pshufd xmm3, xmm3, 00111001b            ;Shuffle for correct summation
    paddsw xmm1, xmm3                     ;Sum signed values

    ; Correct Normalization (using pextrw - most efficient):
    pextrw eax, xmm1, 0        ; Extract word at index 0 (lower word) to EAX
    movsx eax, ax              ; Sign-extend AX to EAX (important!)
    cvtsi2sd xmm0, eax        ; Convert to double
    divsd xmm0, xmm5          ; Divide by normalization factor

    ; Rounding and clamping:
    roundsd xmm0, xmm0, 0     ; Round to nearest integer
    cvtsd2si eax, xmm0        ; Convert back to signed integer

    cmp eax, 0
    jl zeroValue            ; Jump if negative

    cmp eax, 255
    jg maxVal                ; Jump if greater than 255

    mov byte ptr[R12], al    ; Store the normalized and clamped value
    jmp continueLoop

zeroValue:
    mov eax, 0
    mov byte ptr[R12], al
    jmp continueLoop

maxVal:
    mov eax, 255
    mov byte ptr[R12], al

continueLoop:
    inc rdi                 ;Increment loop counter
    inc rcx                 ;Increment original pixels index
    inc R12                 ;Increment new pixels index
    jmp programLoop

endLoop:
    add rsp, 40 ; Restore stack
    ret
AsmProc endp
end