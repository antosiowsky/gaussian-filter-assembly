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
    unsigned char* input, // Tablica wejściowa reprezentująca obraz
    unsigned char* output, // Tablica wyjściowa, w której zapisane zostaną wyniki
    int startIndex, // Indeks początkowy fragmentu do przetwarzania
    int endIndex, // Indeks końcowy fragmentu do przetwarzania
    int bitmapWidth, // Szerokość obrazu (w pikselach)
    int bitmapHeight) // Wysokość obrazu (w pikselach)
{
    int numberOfIndicesToFilter = endIndex - startIndex; // Liczba pikseli do przetworzenia

    const long* mask = InitializeGaussianMask(); // Inicjalizacja maski Gaussa

    const int colorChannels = 3; // Liczba kanałów kolorów (RGB)
    const int imageWidth = bitmapWidth * colorChannels; // Szerokość obrazu w bajtach (dla wszystkich kanałów)

    // Główna pętla przetwarzająca piksele w zadanym zakresie
    for (int i = startIndex; i < startIndex + numberOfIndicesToFilter; i += colorChannels)
    {
        int x = (i / colorChannels) % bitmapWidth; // Obliczenie współrzędnej x na podstawie indeksu
        int y = (i / colorChannels) / bitmapWidth; // Obliczenie współrzędnej y na podstawie indeksu

        // Jeśli piksel znajduje się na krawędzi obrazu, przepisz jego wartości bez zmian
        if (x == 0 || x == bitmapWidth - 1 || y == 0 || y == (bitmapHeight / bitmapWidth) - 1)
        {
            output[i] = input[i]; // Przepisz wartość czerwonego kanału
            output[i + 1] = input[i + 1]; // Przepisz wartość zielonego kanału
            output[i + 2] = input[i + 2]; // Przepisz wartość niebieskiego kanału
            continue; // Przejdź do następnego piksela
        }

        unsigned char fragmentR[9], fragmentG[9], fragmentB[9]; // Bufory dla fragmentów 3x3 dla każdego kanału RGB

        // Pobierz fragment obrazu (3x3) dla każdego kanału kolorów (R, G, B)
        for (int dy = -1; dy <= 1; ++dy) // Iteracja w pionie
        {
            for (int dx = -1; dx <= 1; ++dx) // Iteracja w poziomie
            {
                int offset = (y + dy) * imageWidth + (x + dx) * colorChannels; // Obliczanie przesunięcia w tablicy
                int index = (dy + 1) * 3 + (dx + 1); // Obliczanie indeksu w buforze fragmentu

                fragmentR[index] = input[offset]; // Pobranie wartości czerwonego kanału
                fragmentG[index] = input[offset + 1]; // Pobranie wartości zielonego kanału
                fragmentB[index] = input[offset + 2]; // Pobranie wartości niebieskiego kanału
            }
        }

        // Oblicz nowe wartości dla każdego kanału za pomocą maski Gaussa
        output[i] = ComputeNewPixelValueGaussian(fragmentR, mask); // Nowa wartość dla czerwonego kanału
        output[i + 1] = ComputeNewPixelValueGaussian(fragmentG, mask); // Nowa wartość dla zielonego kanału
        output[i + 2] = ComputeNewPixelValueGaussian(fragmentB, mask); // Nowa wartość dla niebieskiego kanału
    }
}
