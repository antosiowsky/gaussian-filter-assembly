//Autor: Jakub Antonowicz, Data : 8.01.2024, Rok / Semestr : 3 / 5
//Temat: Filtracja obrazu przy użyciu filtru gaussa.
//Opis: Program implementuje filtrację obrazu za pomocą filtra gaussa. Wynik jest zapisywany do nowego obszaru pamięci.
//Wersja: 1.0
//Historia zmian :
//-Wersja 1.0: Implementacja podstawowej procedury przetwarzania obrazu.
#include "pch.h"
#include <algorithm>
#include <vector>
using namespace std;

// Funkcja inicjalizująca maskę Gaussa (3x3).
// Maska Gaussa to tablica o rozmiarze 3x3, która służy do wygładzania obrazu.
// Zawiera wstępnie zdefiniowane wagi, które zostaną użyte do obliczeń.
long* InitializeGaussianMask()
{
    static long mask[9] = { 1, 2, 1, 2, 4, 2, 1, 2, 1 }; // Wagi maski Gaussa
    return mask; // Zwraca wskaźnik do maski
}

// Funkcja obliczająca nową wartość piksela na podstawie maski Gaussa.
// Przyjmuje fragment obrazu (3x3) oraz maskę, a następnie oblicza nową wartość
// na podstawie ich iloczynu i normalizuje wynik.
unsigned char ComputeNewPixelValueGaussian(const unsigned char* fragment, const long* mask)
{
    int value = 0; // Akumulator wartości
    const int weightSum = 16; // Suma wag w masce Gaussa (dla normalizacji)
    const int pixelCount = 9; // Liczba pikseli w masce (3x3)

    for (int i = 0; i < pixelCount; ++i) // Iteracja po pikselach fragmentu
    {
        value += fragment[i] * mask[i]; // Obliczanie sumy ważonej
    }

    value /= weightSum; // Normalizacja wartości
    value = clamp(value, 0, 255); // Ograniczenie wartości do zakresu 0-255

    return static_cast<unsigned char>(value); // Zwraca nową wartość jako unsigned char
}

// Główna funkcja aplikująca filtr Gaussa na obraz.
// Funkcja przetwarza fragment obrazu określony przez `startIndex` i `endIndex`.
// Przyjmuje wskaźniki do tablic wejściowej (input) i wyjściowej (output),
// szerokość oraz wysokość obrazu.
extern "C" __declspec(dllexport) void __stdcall CppProc(
    unsigned char* input,
    unsigned char* output,
    int startIndex,
    int endIndex,
    int bitmapWidth,
    int bitmapHeight)
{
    int numberOfIndicesToFilter = endIndex - startIndex;
    const long* mask = InitializeGaussianMask();
    const int colorChannels = 3;
    const int imageWidth = bitmapWidth * colorChannels;

    for (int i = startIndex; i < startIndex + numberOfIndicesToFilter; i += colorChannels)
    {
        int x = (i / colorChannels) % bitmapWidth;
        int y = (i / colorChannels) / bitmapWidth;

        if (x == 0 || x == bitmapWidth - 1 || y == 0 || y == bitmapHeight - 1)
        {
            output[i] = input[i];
            output[i + 1] = input[i + 1];
            output[i + 2] = input[i + 2];
            continue;
        }

        unsigned char fragmentR[9] = { 0 }, fragmentG[9] = { 0 }, fragmentB[9] = { 0 };

        for (int dy = -1; dy <= 1; ++dy)
        {
            for (int dx = -1; dx <= 1; ++dx)
            {
                int nx = x + dx;
                int ny = y + dy;

                if (nx < 0 || nx >= bitmapWidth || ny < 0 || ny >= bitmapHeight)
                    continue;

                int offset = ny * imageWidth + nx * colorChannels;
                int index = (dy + 1) * 3 + (dx + 1);

                fragmentR[index] = input[offset];
                fragmentG[index] = input[offset + 1];
                fragmentB[index] = input[offset + 2];
            }
        }

        output[i] = ComputeNewPixelValueGaussian(fragmentR, mask);
        output[i + 1] = ComputeNewPixelValueGaussian(fragmentG, mask);
        output[i + 2] = ComputeNewPixelValueGaussian(fragmentB, mask);
    }
}
