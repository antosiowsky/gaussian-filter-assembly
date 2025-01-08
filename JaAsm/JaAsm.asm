; Autor: Jakub Antonowicz, Data: 8.01.2024, Rok/Semestr: 3/5
; Temat: Filtracja obrazu przy u¿yciu filtru gaussa
; Opis: Program implementuje filtracjê obrazu za pomoc¹ filtra gaussa. Wynik jest zapisywany do nowego obszaru pamiêci.
; Wersja: 1.0
; Historia zmian: 
; - Wersja 1.0: Implementacja podstawowej procedury przetwarzania obrazu.

.data
multiArray word 1, 2, 1, 2, 4, 2, 1, 2, 1      ; Macierz filtru konwolucyjnego 3x3
normalizationFactor dq 9.0                     ; Wspó³czynnik normalizacji (sumaryczna waga filtra)

.code
; ---------------------------------------------------
; AsmProc - Procedura filtrowania obrazu
; Parametry wejœciowe:
; RCX - WskaŸnik do tablicy starych pikseli
; R12 - WskaŸnik do tablicy nowych pikseli
; R8  - Indeks pocz¹tkowy do przetwarzania
; R9  - Indeks koñcowy do przetwarzania
; R10 - Szerokoœæ obrazu
; Wyjœcie:
; Tablica nowych pikseli w pamiêci wskazywanej przez R12
; Rejestry i flagi zmieniane:
; RAX, RBX, R11, XMM0-XMM5
; ---------------------------------------------------
AsmProc proc
    sub rsp, 40                      ; Przygotowanie przestrzeni dla shadow space
    movdqu xmm4, oword ptr[multiArray] ; Za³adowanie macierzy filtra do rejestru
    movsd xmm5, qword ptr[normalizationFactor] ; Za³adowanie wspó³czynnika normalizacji

    mov ebx, dword ptr[rbp + 48]     ; Szerokoœæ obrazu
    mov r10, rbx                     ; Przypisanie szerokoœci do R10
    xor r11, r11                     ; Wyzerowanie R11
    sub r11, r10                     ; R11 = -width

    mov r12, rdx                     ; WskaŸnik do nowych pikseli
    mov rdi, r8                      ; Indeks pocz¹tkowy
    add rcx, r8                      ; Przesuniêcie wskaŸnika do starych pikseli
    add R12, r8                      ; Przesuniêcie wskaŸnika do nowych pikseli

programLoop:
    cmp rdi, r9                      ; Sprawdzenie warunku zakoñczenia pêtli
    je endLoop

    pxor xmm1, xmm1                  ; Wyczyszczenie rejestrów
    pxor xmm2, xmm2
    pxor xmm3, xmm3

    ; £adowanie pikseli z wagami 1
    pinsrb xmm1, byte ptr[RCX + R11], 1
    pinsrb xmm1, byte ptr[RCX + R11 + 3], 2
    pinsrb xmm1, byte ptr[RCX + 3], 4
    pinsrb xmm1, byte ptr[RCX + R10], 6
    pinsrb xmm1, byte ptr[RCX + R10 + 3], 7

    ; £adowanie pikseli z wagami -1
    pinsrb xmm3, byte ptr[RCX + R11 - 3], 0
    pinsrb xmm3, byte ptr[RCX - 3], 1
    pinsrb xmm3, byte ptr[RCX + R10 - 3], 2

    psadbw xmm3, xmm2                ; Sumowanie pikseli z wagami -1
    pinsrb xmm3, byte ptr[RCX], 4    ; Piksel z wag¹ -2
    pmullw xmm3, xmm4                ; Mno¿enie pikseli przez wagi

    pxor xmm2, xmm2                  ; Wyczyszczenie xmm2
    psadbw xmm1, xmm2                ; Sumowanie pikseli z wagami 1
    paddsw xmm1, xmm3                ; Dodanie wartoœci z wagami -1 i -2
    pshufd xmm3, xmm3, 00111001b     ; Przemieszczenie dla poprawnego sumowania
    paddsw xmm1, xmm3                ; Dodanie wartoœci

    ; Normalizacja i zaokr¹glenie
    pextrw eax, xmm1, 0              ; Ekstrakcja wartoœci
    movsx eax, ax                    ; Rozszerzenie znaku
    cvtsi2sd xmm0, eax               ; Konwersja na double
    divsd xmm0, xmm5                 ; Dzielenie przez wspó³czynnik normalizacji
    roundsd xmm0, xmm0, 0            ; Zaokr¹glenie do najbli¿szej liczby ca³kowitej
    cvtsd2si eax, xmm0               ; Konwersja na liczbê ca³kowit¹

    ; Sprawdzanie zakresu
    cmp eax, 0
    jl zeroValue
    cmp eax, 255
    jg maxVal
    mov byte ptr[R12], al
    jmp continueLoop

zeroValue:
    mov eax, 0
    mov byte ptr[R12], al
    jmp continueLoop

maxVal:
    mov eax, 255
    mov byte ptr[R12], al

continueLoop:
    inc rdi                          ; Zwiêkszenie indeksu pêtli
    inc rcx                          ; Przesuniêcie wskaŸnika starych pikseli
    inc R12                          ; Przesuniêcie wskaŸnika nowych pikseli
    jmp programLoop

endLoop:
    add rsp, 40                      ; Przywrócenie stosu
    ret
AsmProc endp
end
