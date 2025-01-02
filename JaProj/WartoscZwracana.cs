
namespace JaProj
{
    // Klasa reprezentująca przefiltrowany fragment bitmapy w jednym z wątków.
    public class WartoscZwracana
    {
        // 'Id' wątku aby na końcu wątek  znalazł odpowiedni fragment i zapisał tam swoje wyjście.
        public int IdWatku { get; set; }

        // Ilość indeksów tablicy bajtów, która jest filtrowana w tym fragmencie.
        public int IloscFiltrowanychIndeksow { get; set; }

        // Wynik filtrowania danego fragmentu bitmapy w postaci tablicy bajtów.
        public byte[] TablicaWyjsciowa { get; set; }
    }
}