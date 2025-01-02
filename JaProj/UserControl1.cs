﻿using System;
using System.Diagnostics;
using System.Drawing;
using System.Windows;
using System.Windows.Media.Imaging;
using Microsoft.Win32;
using System.Threading.Tasks;
using System.Windows.Controls;

namespace JaProj
{
    public partial class MainWindow : Window
    {
        private Bitmap originalBitmap;
        private Bitmap resultBitmap;

        public MainWindow()
        {
            InitializeComponent();
            ThreadSlider.ValueChanged += ThreadSlider_ValueChanged;
        }

        private void ThreadSlider_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
        {
            ThreadCountDisplay.Text = ((int)ThreadSlider.Value).ToString();
        }

        private void PrzegladajPlikiPrzycisk_Click(object sender, RoutedEventArgs e)
        {
            OpenFileDialog openFileDialog = new OpenFileDialog();
            openFileDialog.Filter = "Pliki BMP|*.bmp";
            if (openFileDialog.ShowDialog() == true)
            {
                SciezkaDoPlikuBox.Text = openFileDialog.FileName;
                originalBitmap = new Bitmap(openFileDialog.FileName);
                ObrazPodglad.Source = BitmapToImageSource(originalBitmap);
                FiltrujBitmapePrzycisk.IsEnabled = true;
            }
        }

        private void FiltrujBitmapePrzycisk_Click(object sender, RoutedEventArgs e)
        {
            if (!int.TryParse(RepetitionsBox.Text, out int repetitions) || repetitions < 1 || repetitions > 10)
            {
                MessageBox.Show("Wprowadź liczbę powtórzeń od 1 do 10.", "Błąd danych wejściowych", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            int threadCount = (int)ThreadSlider.Value;
            string selectedDll = (DllSelector.SelectedItem as ComboBoxItem)?.Content.ToString();

            Task.Run(() =>
            {
                Stopwatch stopwatch = new Stopwatch();
                stopwatch.Start();

                resultBitmap = (Bitmap)originalBitmap.Clone();

                for (int i = 0; i < repetitions; i++)
                {
                    if (selectedDll == "C++")
                    {
                        resultBitmap = GaussianFilter.ApplyGaussianFilterCpp(resultBitmap, threadCount);
                    }
                    else if (selectedDll == "Assembler")
                    {
                        resultBitmap = GaussianFilter.ApplyGaussianFilterAsm(resultBitmap, threadCount);
                    }
                }

                stopwatch.Stop();
                Dispatcher.Invoke(() =>
                {
                    ObrazPodglad.Source = BitmapToImageSource(resultBitmap);
                    ZapiszBitmapePrzycisk.IsEnabled = true;

                    // Wyświetl komunikat o zakończeniu działania
                    MessageBox.Show($"Operacja zakończona pomyślnie w {stopwatch.ElapsedMilliseconds} ms.",
                                    "Informacja", MessageBoxButton.OK, MessageBoxImage.Information);

                    // Zaktualizuj pole czasu
                    WykorzystanyCzasBlock.Text = $"Czas obliczeń: {stopwatch.ElapsedMilliseconds} ms";
                });
            });
        }

        private void ZapiszBitmapePrzycisk_Click(object sender, RoutedEventArgs e)
        {
            SaveFileDialog saveFileDialog = new SaveFileDialog();
            saveFileDialog.Filter = "Pliki BMP|*.bmp";
            if (saveFileDialog.ShowDialog() == true)
            {
                resultBitmap.Save(saveFileDialog.FileName);
            }
        }

        private System.Windows.Media.ImageSource BitmapToImageSource(Bitmap bitmap)
        {
            using (System.IO.MemoryStream memory = new System.IO.MemoryStream())
            {
                bitmap.Save(memory, System.Drawing.Imaging.ImageFormat.Png);
                memory.Seek(0, System.IO.SeekOrigin.Begin);
                BitmapImage bitmapImage = new BitmapImage();
                bitmapImage.BeginInit();
                bitmapImage.StreamSource = memory;
                bitmapImage.EndInit();
                return bitmapImage;
            }
        }
    }
}
