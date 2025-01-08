#include "pch.h"
#include <algorithm>
#include <vector>
using namespace std;

// Funkcja inicjalizująca maskę Gaussa (3x3).
long* InicjalizujMaskeGaussa()
{
    static long maska[9] = { 1, 2, 1, 2, 4, 2, 1, 2, 1 };
    return maska;
}

// Funkcja obliczająca wartość piksela na podstawie maski Gaussa.
unsigned char ObliczNowaWartoscPikselaGauss(const unsigned char* fragment, const long* maska)
{
    int wartosc = 0;
    const int sumaWag = 16; //273 // 16 Suma wag maski Gaussa
    const int iloscPikseli = 9;

    for (int i = 0; i < iloscPikseli; ++i)
    {
        wartosc += fragment[i] * maska[i];
    }

    wartosc /= sumaWag; // Normalizacja
    wartosc = clamp(wartosc, 0, 255);

    return static_cast<unsigned char>(wartosc);
}

// Główna funkcja nakładająca filtr Gaussa.
extern "C" __declspec(dllexport) void __stdcall NalozFiltrGaussa(
    unsigned char* wejscie,
    unsigned char* wyjscie,
    int dlugoscBitmapy,
    int szerokoscBitmapy,
    int indeksStartowy,
    int ileIndeksowFiltrowac)


{
    const long* maska = InicjalizujMaskeGaussa();

    const int liczbaKolorow = 3; // RGB
    const int szerokoscObrazu = szerokoscBitmapy * liczbaKolorow;

    for (int i = indeksStartowy; i < indeksStartowy + ileIndeksowFiltrowac; i += liczbaKolorow)
    {
        int x = (i / liczbaKolorow) % szerokoscBitmapy;
        int y = (i / liczbaKolorow) / szerokoscBitmapy;

        // Piksele krawędziowe - przepisz wartości bez zmian.
        if (x == 0 || x == szerokoscBitmapy - 1 || y == 0 || y == (dlugoscBitmapy / szerokoscBitmapy) - 1)
        {
            wyjscie[i] = wejscie[i];
            wyjscie[i + 1] = wejscie[i + 1];
            wyjscie[i + 2] = wejscie[i + 2];
            continue;
        }

        unsigned char fragmentR[9], fragmentG[9], fragmentB[9];

        // Pobranie fragmentu obrazu (3x3) dla każdego kanału RGB.
        for (int dy = -1; dy <= 1; ++dy)
        {
            for (int dx = -1; dx <= 1; ++dx)
            {
                int offset = (y + dy) * szerokoscObrazu + (x + dx) * liczbaKolorow;
                int index = (dy + 1) * 3 + (dx + 1);

                fragmentR[index] = wejscie[offset];
                fragmentG[index] = wejscie[offset + 1];
                fragmentB[index] = wejscie[offset + 2];
            }
        }

        // Obliczenie nowych wartości dla każdego kanału.
        wyjscie[i] = ObliczNowaWartoscPikselaGauss(fragmentR, maska);
        wyjscie[i + 1] = ObliczNowaWartoscPikselaGauss(fragmentG, maska);
        wyjscie[i + 2] = ObliczNowaWartoscPikselaGauss(fragmentB, maska);
    }
}
