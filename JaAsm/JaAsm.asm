; Autor: Jakub Antonowicz, Data: 8.01.2024, Rok/Semestr: 3/5
; Temat: Filtracja obrazu przy u�yciu filtru gaussa
; Opis: Program implementuje filtracj� obrazu za pomoc� filtra gaussa. Wynik jest zapisywany do nowego obszaru pami�ci.
; Wersja: 1.0
; Historia zmian: 
; - Wersja 1.0: Implementacja podstawowej procedury przetwarzania obrazu.

.data
multiArray word 1, 2, 1, 2, 4, 2, 1, 2, 1      ; Macierz filtru 3x3
normalizationFactor dq 9.0                     ; Wsp�czynnik normalizacji

.code
; ---------------------------------------------------
; AsmProc - Procedura filtrowania obrazu
; Parametry wej�ciowe:
; RCX - Wska�nik do tablicy starych pikseli
; R12 - Wska�nik do tablicy nowych pikseli
; R8  - Indeks pocz�tkowy do przetwarzania
; R9  - Indeks ko�cowy do przetwarzania
; R10 - Szeroko�� obrazu
; Wyj�cie:
; Tablica nowych pikseli w pami�ci wskazywanej przez R12
; Rejestry i flagi zmieniane:
; RAX, RBX, R11, XMM0-XMM5
; ---------------------------------------------------
AsmProc proc
    sub rsp, 40                      ; Przygotowanie przestrzeni dla shadow space
    movdqu xmm4, oword ptr[multiArray] ; Wektorowe za�adowanie macierzy filtra do rejestru
    movsd xmm5, qword ptr[normalizationFactor] ; Wektorowe za�adowanie wsp�czynnika normalizacji

    mov ebx, dword ptr[rbp + 48]     ; Szeroko�� obrazu
    mov r10, rbx                     ; Przypisanie szeroko�ci do R10
    xor r11, r11                     ; Wyzerowanie R11
    sub r11, r10                     ; R11 = -width, aby przesun�� wska�nik do pikseli wstecz

    mov r12, rdx                     ; Przepisz wska�nik do tablicy nowych pikseli
    mov rdi, r8                      ; Przenies indeks pocz�tkowy do licznika petli
    add rcx, r8                      ; Przesuni�cie wska�nika do starych pikseli o index pocz
    add R12, r8                      ; Przesuni�cie wska�nika do nowych pikseli o index pocz

mainLoop:                            ; G��wna p�tla przetwarzania
    cmp rdi, r9                      ; Sprawdzenie warunku zako�czenia p�tli
    je exitLoop                      ; Wyj�cie z p�tli, je�li indeks osi�gnie ko�cowy

    pxor xmm1, xmm1                  ; Wektorowe wyczyszczenie rejestr�w
    pxor xmm2, xmm2                  ; XOR z samym soba to 0
    pxor xmm3, xmm3

    ; �adowanie pikseli
    pinsrb xmm1, byte ptr[RCX + R11], 1
    pinsrb xmm1, byte ptr[RCX + R11 + 3], 2
    pinsrb xmm1, byte ptr[RCX + 3], 4
    pinsrb xmm1, byte ptr[RCX + R10], 6
    pinsrb xmm1, byte ptr[RCX + R10 + 3], 7

    ; �adowanie pikseli 
    pinsrb xmm3, byte ptr[RCX + R11 - 3], 0
    pinsrb xmm3, byte ptr[RCX - 3], 1
    pinsrb xmm3, byte ptr[RCX + R10 - 3], 2

    psadbw xmm3, xmm2                ; Wektorowe sumowanie pikseli z wagami -1
    pinsrb xmm3, byte ptr[RCX], 4    ; Piksel z wag� -2
    pmullw xmm3, xmm4                ; Mno�enie pikseli przez wagi

    pxor xmm2, xmm2                  ; Wyczyszczenie xmm2
    psadbw xmm1, xmm2                ; Sumowanie pikseli z wagami 1
    paddsw xmm1, xmm3                ; Dodanie warto�ci z wagami -1 i -2
    pshufd xmm3, xmm3, 00111001b     ; Przemieszczenie dla poprawnego sumowania
    paddsw xmm1, xmm3                ; Dodanie warto�ci

    ; Normalizacja i zaokr�glenie
    pextrw eax, xmm1, 0              ; Ekstrakcja warto�ci
    movsx eax, ax                    ; Rozszerzenie znaku
    cvtsi2sd xmm0, eax               ; Konwersja na double
    divsd xmm0, xmm5                 ; Dzielenie przez wsp�czynnik normalizacji
    roundsd xmm0, xmm0, 0            ; Zaokr�glenie do najbli�szej liczby ca�kowitej
    cvtsd2si eax, xmm0               ; Konwersja na liczb� ca�kowit�

    ; Sprawdzanie zakresu
    cmp eax, 0
    jl zeroValue
    cmp eax, 255
    jg maxValue
    mov byte ptr[R12], al
    jmp nextPixel

zeroValue:
    mov eax, 0
    mov byte ptr[R12], al
    jmp nextPixel

maxValue:
    mov eax, 255
    mov byte ptr[R12], al

nextPixel:
    inc rdi                          ; Zwi�kszenie indeksu p�tli
    inc rcx                          ; Przesuni�cie wska�nika starych pikseli
    inc R12                          ; Przesuni�cie wska�nika nowych pikseli
    jmp mainLoop                     ; Powr�t do pocz�tku p�tli

exitLoop:
    add rsp, 40                      ; Przywr�cenie stosu
    ret
AsmProc endp
end
