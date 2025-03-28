﻿using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using JaProj;

namespace JaProj
{
    class GaussianFilter
    {
        // Import funkcji z bibliotek Assembler i C++
        [DllImport(@"C:\Users\grawe\source\repos\JA_PROJEKT\JaProj\x64\Debug\JaAsm.dll")]
        public static extern void AsmProc(byte[] inputData, byte[] outputData, int startIndex, int endIndex, int width);

        [DllImport(@"C:\Users\grawe\source\repos\JA_PROJEKT\JaProj\x64\Debug\JaCpp.dll")]
        public static extern void CppProc(byte[] inputData, byte[] outputData, int startIndex, int endIndex, int width, int length);


        // Metoda wywołania filtra C++ (multithreaded)
        public static Bitmap ApplyGaussianFilterCpp(Bitmap sourceImage, int threadCount)
        {
            return ApplyFilterMultithreaded(sourceImage, threadCount, (input, output, startIndex, endIndex, width) =>
            {
                int height = input.Length;
                CppProc(input, output, startIndex, endIndex, width, height);
            });
        }

        // Metoda wywołania filtra Assembler (multithreaded)
        public static Bitmap ApplyGaussianFilterAsm(Bitmap sourceImage, int threadCount)
        {
            return ApplyFilterMultithreaded(sourceImage, threadCount, (input, output, startIndex, endIndex, width) =>
            {
                AsmProc(input, output, startIndex, endIndex, width * 3);
            });
        }

        // Funkcja wspólna dla C++ i Assemblera, z obsługą wielu wątków
        private static Bitmap ApplyFilterMultithreaded(
     Bitmap sourceImage,
     int threadCount,
     Action<byte[], byte[], int, int, int> filterFunction)
        {
            if (sourceImage.PixelFormat != PixelFormat.Format24bppRgb &&
                sourceImage.PixelFormat != PixelFormat.Format32bppArgb)
            {
                throw new NotSupportedException("Only 24bppRgb and 32bppArgb formats are supported.");
            }

            var rect = new Rectangle(0, 0, sourceImage.Width, sourceImage.Height);
            var bmpData = sourceImage.LockBits(rect, ImageLockMode.ReadOnly, sourceImage.PixelFormat);

            int bytesPerPixel = Image.GetPixelFormatSize(sourceImage.PixelFormat) / 8;
            int stride = bmpData.Stride;
            int byteCount = stride * sourceImage.Height;

            byte[] pixelData = new byte[byteCount];
            Marshal.Copy(bmpData.Scan0, pixelData, 0, byteCount);
            sourceImage.UnlockBits(bmpData);
            int width = sourceImage.Width;

            byte[] resultData = new byte[byteCount];

            // Podział danych na fragmenty
            int fragmentSize = byteCount / threadCount;
            fragmentSize -= fragmentSize % bytesPerPixel;

            List<Task> tasks = new List<Task>();


            for (int i = 0; i < threadCount; i++)
            {
                int startIndex = i * fragmentSize;
                int endIndex = (i == threadCount - 1) ? byteCount : startIndex + fragmentSize;

                tasks.Add(Task.Run(() =>
                {
                    filterFunction(pixelData, resultData, startIndex, endIndex, width);
                }));
            }

            // Czekaj na zakończenie wszystkich wątków
            Task.WaitAll(tasks.ToArray());

            // Zapis danych wynikowych do nowego obrazu
            var resultImage = new Bitmap(sourceImage.Width, sourceImage.Height, sourceImage.PixelFormat);
            var resultBmpData = resultImage.LockBits(rect, ImageLockMode.WriteOnly, resultImage.PixelFormat);
            Marshal.Copy(resultData, 0, resultBmpData.Scan0, byteCount);
            resultImage.UnlockBits(resultBmpData);

            return resultImage;
        }

    }
}
    class Program
{
    [STAThread]
    static void Main(string[] args)
    {
        var app = new App();
        app.InitializeComponent();
        app.Run();
    }
}

