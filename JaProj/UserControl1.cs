using System;
using System.Diagnostics;
using System.Drawing;
using System.Windows;
using System.Windows.Media.Imaging;
using Microsoft.Win32;
using System.Threading.Tasks;
using System.Windows.Controls;
using ClosedXML.Excel;
using System.Threading;


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

        private void GenerujExcelPrzycisk_Click(object sender, RoutedEventArgs e)
        {
            string selectedDll = (DllSelector.SelectedItem as ComboBoxItem)?.Content.ToString();
            SaveFileDialog saveFileDialog = new SaveFileDialog();
            saveFileDialog.Filter = "Pliki Excel|*.xlsx";
            if (saveFileDialog.ShowDialog() == true)
            {
                string filePath = saveFileDialog.FileName;

                // Stałe konfiguracje
                int[] threadConfigurations = { 1, 2, 4, 8, 16, 32, 64 };
                int repetitions = 5;

                // Tworzenie nowego skoroszytu
                using (var workbook = new XLWorkbook())
                {
                    var worksheet = workbook.Worksheets.Add("Execution Times");

                    // Dodawanie nagłówków
                    worksheet.Cell(1, 1).Value = "Liczba Wątków";
                    for (int rep = 1; rep <= repetitions; rep++)
                    {
                        worksheet.Cell(1, rep + 1).Value = $"Powtórzenie {rep}";
                    }
                    worksheet.Cell(1, repetitions + 2).Value = "Średni Czas [ms]";

                    // Iteracja po konfiguracjach liczby wątków
                    int row = 2;
                    foreach (int threadCount in threadConfigurations)
                    {
                        worksheet.Cell(row, 1).Value = threadCount;

                        long totalAverageTime = 0;

                        for (int rep = 1; rep <= repetitions; rep++)
                        {
                            long totalTime = 0;

                            // Wykonywanie operacji 5 razy dla średniej
                            for (int i = 0; i < 5; i++)
                            {
                                Stopwatch stopwatch = new Stopwatch();
                                stopwatch.Start();

                                Bitmap tempBitmap = (Bitmap)originalBitmap.Clone();
                                try
                                {
                                    if (selectedDll == "C++")
                                    {
                                        tempBitmap = GaussianFilter.ApplyGaussianFilterCpp(tempBitmap, threadCount);
                                    }
                                    else if (selectedDll == "Assembler")
                                    {
                                        tempBitmap = GaussianFilter.ApplyGaussianFilterAsm(tempBitmap, threadCount);
                                    }
                                }
                                finally
                                {
                                    tempBitmap.Dispose();
                                }

                                stopwatch.Stop();
                                totalTime += stopwatch.ElapsedMilliseconds;

                                // Krótka przerwa między iteracjami
                                Thread.Sleep(50);
                            }


                            // Obliczanie średniego czasu dla tego powtórzenia
                            long averageTime = totalTime / 5;
                            worksheet.Cell(row, rep + 1).Value = averageTime;
                            totalAverageTime += averageTime;

                            // Wymuszenie oczyszczenia pamięci
                            GC.Collect();
                            GC.WaitForPendingFinalizers();
                        }

                        // Obliczanie ogólnego średniego czasu dla danej liczby wątków
                        worksheet.Cell(row, repetitions + 2).Value = totalAverageTime / repetitions;

                        // Przerwa między konfiguracjami liczby wątków
                        Thread.Sleep(500);

                        row++;
                    }

                    // Zapisanie skoroszytu do pliku
                    workbook.SaveAs(filePath);

                    MessageBox.Show("Plik Excel został wygenerowany pomyślnie.", "Informacja", MessageBoxButton.OK, MessageBoxImage.Information);
                }
            }
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
