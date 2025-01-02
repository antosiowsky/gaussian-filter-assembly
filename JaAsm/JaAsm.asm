.data
gaussian_kernel db 1, 2, 1, 2, 4, 2, 1, 2, 1  ; J¹dro Gaussa 3x3
kernel_sum dd 16                           ; Suma wag j¹dra

image_width dd 320                         ; Szerokoœæ obrazu (w pikselach)
image_height dd 240                        ; Wysokoœæ obrazu (w pikselach)

.code
; Funkcja Gaussa: gauss_filter
; Argumenty:
; rsi - wskaŸnik do tablicy wejœciowej (inputData)
; rdi - wskaŸnik do tablicy wyjœciowej (outputData)
; rcx - szerokoœæ obrazu
; rdx - wysokoœæ obrazu
AsmProc PROC
    push rbx
    push rbp
    push rsi
    push rdi

    ; Parametry: obraz RGB, 3x3 j¹dro Gaussa
    ; rcx = szerokoœæ obrazu (image_width)
    ; rdx = wysokoœæ obrazu (image_height)

    mov r8, rcx                ; szerokoœæ obrazu
    mov r9, rdx                ; wysokoœæ obrazu
    lea rsi, [rsi]             ; wskaŸnik do tablicy wejœciowej
    lea rdi, [rdi]             ; wskaŸnik do tablicy wyjœciowej

    ; G³ówna pêtla iteracji po pikselach
    mov r10d, 1                ; zaczynamy od pierwszego piksela
pixel_loop:
    cmp r10d, r9               ; Czy przekroczyliœmy wysokoœæ obrazu?
    jge end_loop               ; Jeœli tak, koñczymy

    mov r11d, 1                ; Rozpoczynamy iteracjê przez szerokoœæ
column_loop:
    cmp r11d, r8               ; Czy przekroczyliœmy szerokoœæ obrazu?
    jge next_row               ; Jeœli tak, przejdŸ do nastêpnego wiersza

    ; Oblicz indeks piksela (wyci¹gamy x, y, i wiersz, i kolumnê w pamiêci)
    mov eax, r10d              ; Wiersz obrazu
    imul eax, r8               ; Wiersz * szerokoœæ obrazu
    add eax, r11d              ; Dodaj kolumnê (piksel)
    imul eax, 3                ; Mno¿enie przez 3 (RGB)
    lea rsi, [rsi + rax]       ; Oblicz przesuniêcie do aktualnego piksela (RGB)

    ; Inicjalizuj sumy kolorów (R, G, B) w xmm0
    pxor xmm0, xmm0            ; Zerujemy sumy R
    pxor xmm1, xmm1            ; Zerujemy sumy G
    pxor xmm2, xmm2            ; Zerujemy sumy B

    ; Iteracja przez j¹dro 3x3
    mov r12d, -1               ; Start wierszy w j¹drze: -1
row_loop:
    cmp r12d, 1                ; Iterujemy przez 3 wiersze
    jg pixel_store

    mov r13d, -1               ; Start kolumny w j¹drze: -1
col_loop:
    cmp r13d, 1                ; Iterujemy przez 3 kolumny
    jg next_row

    ; Oblicz przesuniêcie do s¹siaduj¹cego piksela
    mov eax, r12d
    imul eax, r8               ; Wiersz * szerokoœæ obrazu w pikselach
    add eax, r13d              ; Dodanie kolumny
    imul eax, 3                ; Mno¿enie przez 3 (RGB)
    lea rsi2, [rsi + rax]      ; Przesuniêcie do s¹siedniego piksela

    ; Za³aduj wartoœci piksela s¹siedniego do xmm3
    movdqu xmm3, oword ptr [rsi2]

    ; Mno¿enie przez wagê j¹dra
    movzx r14d, byte ptr [gaussian_kernel + (r12d + 1) * 3 + r13d + 1]
    pmuludq xmm3, r14d         ; Mno¿enie przez wagê (R, G, B)

    ; Dodaj wyniki do sum
    paddd xmm0, xmm3

    inc r13d                   ; Kolejna kolumna w j¹drze
    jmp col_loop

next_row:
    inc r12d                   ; Kolejny wiersz w j¹drze
    jmp row_loop

pixel_store:
    ; Normalizacja przez kernel_sum
    mov eax, kernel_sum
    movd xmm5, eax             ; Za³aduj kernel_sum do xmm5
    cvtdq2ps xmm0, xmm0        ; Konwertuj R na zmiennoprzecinkowe
    cvtdq2ps xmm1, xmm1        ; Konwertuj G na zmiennoprzecinkowe
    cvtdq2ps xmm2, xmm2        ; Konwertuj B na zmiennoprzecinkowe
    divps xmm0, xmm5           ; Podziel R przez kernel_sum
    divps xmm1, xmm5           ; Podziel G przez kernel_sum
    divps xmm2, xmm5           ; Podziel B przez kernel_sum
    cvttps2dq xmm0, xmm0       ; Konwertuj R na liczby ca³kowite
    cvttps2dq xmm1, xmm1       ; Konwertuj G na liczby ca³kowite
    cvttps2dq xmm2, xmm2       ; Konwertuj B na liczby ca³kowite

    ; Zapisz wynik do tablicy wyjœciowej
    movdqu oword ptr [rdi + rax], xmm0

    inc r11d                   ; Nastêpny piksel w kolumnie
    jmp column_loop

next_row:
    inc r10d                   ; PrzejdŸ do nastêpnego wiersza
    jmp pixel_loop

end_loop:
    pop rdi
    pop rsi
    pop rbp
    pop rbx
    ret
AsmProc ENDP
end