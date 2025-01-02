.data
gaussian_kernel db 1, 2, 1, 2, 4, 2, 1, 2, 1  ; J�dro Gaussa 3x3
kernel_sum dd 16                           ; Suma wag j�dra

image_width dd 320                         ; Szeroko�� obrazu (w pikselach)
image_height dd 240                        ; Wysoko�� obrazu (w pikselach)

.code
; Funkcja Gaussa: gauss_filter
; Argumenty:
; rsi - wska�nik do tablicy wej�ciowej (inputData)
; rdi - wska�nik do tablicy wyj�ciowej (outputData)
; rcx - szeroko�� obrazu
; rdx - wysoko�� obrazu
AsmProc PROC
    push rbx
    push rbp
    push rsi
    push rdi

    ; Parametry: obraz RGB, 3x3 j�dro Gaussa
    ; rcx = szeroko�� obrazu (image_width)
    ; rdx = wysoko�� obrazu (image_height)

    mov r8, rcx                ; szeroko�� obrazu
    mov r9, rdx                ; wysoko�� obrazu
    lea rsi, [rsi]             ; wska�nik do tablicy wej�ciowej
    lea rdi, [rdi]             ; wska�nik do tablicy wyj�ciowej

    ; G��wna p�tla iteracji po pikselach
    mov r10d, 1                ; zaczynamy od pierwszego piksela
pixel_loop:
    cmp r10d, r9               ; Czy przekroczyli�my wysoko�� obrazu?
    jge end_loop               ; Je�li tak, ko�czymy

    mov r11d, 1                ; Rozpoczynamy iteracj� przez szeroko��
column_loop:
    cmp r11d, r8               ; Czy przekroczyli�my szeroko�� obrazu?
    jge next_row               ; Je�li tak, przejd� do nast�pnego wiersza

    ; Oblicz indeks piksela (wyci�gamy x, y, i wiersz, i kolumn� w pami�ci)
    mov eax, r10d              ; Wiersz obrazu
    imul eax, r8               ; Wiersz * szeroko�� obrazu
    add eax, r11d              ; Dodaj kolumn� (piksel)
    imul eax, 3                ; Mno�enie przez 3 (RGB)
    lea rsi, [rsi + rax]       ; Oblicz przesuni�cie do aktualnego piksela (RGB)

    ; Inicjalizuj sumy kolor�w (R, G, B) w xmm0
    pxor xmm0, xmm0            ; Zerujemy sumy R
    pxor xmm1, xmm1            ; Zerujemy sumy G
    pxor xmm2, xmm2            ; Zerujemy sumy B

    ; Iteracja przez j�dro 3x3
    mov r12d, -1               ; Start wierszy w j�drze: -1
row_loop:
    cmp r12d, 1                ; Iterujemy przez 3 wiersze
    jg pixel_store

    mov r13d, -1               ; Start kolumny w j�drze: -1
col_loop:
    cmp r13d, 1                ; Iterujemy przez 3 kolumny
    jg next_row

    ; Oblicz przesuni�cie do s�siaduj�cego piksela
    mov eax, r12d
    imul eax, r8               ; Wiersz * szeroko�� obrazu w pikselach
    add eax, r13d              ; Dodanie kolumny
    imul eax, 3                ; Mno�enie przez 3 (RGB)
    lea rsi2, [rsi + rax]      ; Przesuni�cie do s�siedniego piksela

    ; Za�aduj warto�ci piksela s�siedniego do xmm3
    movdqu xmm3, oword ptr [rsi2]

    ; Mno�enie przez wag� j�dra
    movzx r14d, byte ptr [gaussian_kernel + (r12d + 1) * 3 + r13d + 1]
    pmuludq xmm3, r14d         ; Mno�enie przez wag� (R, G, B)

    ; Dodaj wyniki do sum
    paddd xmm0, xmm3

    inc r13d                   ; Kolejna kolumna w j�drze
    jmp col_loop

next_row:
    inc r12d                   ; Kolejny wiersz w j�drze
    jmp row_loop

pixel_store:
    ; Normalizacja przez kernel_sum
    mov eax, kernel_sum
    movd xmm5, eax             ; Za�aduj kernel_sum do xmm5
    cvtdq2ps xmm0, xmm0        ; Konwertuj R na zmiennoprzecinkowe
    cvtdq2ps xmm1, xmm1        ; Konwertuj G na zmiennoprzecinkowe
    cvtdq2ps xmm2, xmm2        ; Konwertuj B na zmiennoprzecinkowe
    divps xmm0, xmm5           ; Podziel R przez kernel_sum
    divps xmm1, xmm5           ; Podziel G przez kernel_sum
    divps xmm2, xmm5           ; Podziel B przez kernel_sum
    cvttps2dq xmm0, xmm0       ; Konwertuj R na liczby ca�kowite
    cvttps2dq xmm1, xmm1       ; Konwertuj G na liczby ca�kowite
    cvttps2dq xmm2, xmm2       ; Konwertuj B na liczby ca�kowite

    ; Zapisz wynik do tablicy wyj�ciowej
    movdqu oword ptr [rdi + rax], xmm0

    inc r11d                   ; Nast�pny piksel w kolumnie
    jmp column_loop

next_row:
    inc r10d                   ; Przejd� do nast�pnego wiersza
    jmp pixel_loop

end_loop:
    pop rdi
    pop rsi
    pop rbp
    pop rbx
    ret
AsmProc ENDP
end