using System.IO;

namespace JaProj
{
    public static class CzytnikPlikow
    {
        // Konwertuje bitmapę z podanej lokalizacji w systemie na tablicę bajtów.
        public static byte[] PrzeczytajBitmapeZPliku(string sciezka)
        {
            byte[] bitmapa = File.ReadAllBytes(sciezka);

            return bitmapa;
        }
    }
}