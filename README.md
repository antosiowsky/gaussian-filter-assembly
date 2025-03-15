  <h1>Gaussian Filter</h1>
  <h2>Project Overview</h2>
  <p><strong>Topic:</strong> Image filtering using a Gaussian filter</p>
  <p><strong>Objective:</strong> The goal of this project was to implement an image processing application using a Gaussian filter. The application ensures fast and efficient image filtering by utilizing assembly optimizations and multi-core processing.</p>
  
  <h2>Algorithm Description</h2>
  <p>The filtering process involves applying a 3x3 Gaussian filter matrix to each pixel in an image. The steps include:</p>
  <ul>
      <li>Retrieving neighboring pixels within a 3x3 region.</li>
      <li>Multiplying pixels by the corresponding weights in the Gaussian filter matrix.</li>
      <li>Summing the results and normalizing with a normalization coefficient.</li>
      <li>Writing the filtered pixel to the output image.</li>
  </ul>
  <p>Optimization is achieved through the use of SIMD (Single Instruction Multiple Data) instructions and multi-threading, allowing simultaneous processing of multiple pixels.</p>
  
  <h2>Input Parameters</h2>
  <ul>
      <li><strong>Input Image:</strong> BMP format image file to be processed.</li>
      <li><strong>Number of Threads:</strong> Specifies the number of threads used for processing (1, 2, 4, 8, 16, 32, 64).</li>
      <li><strong>Input Data Type:</strong> Various image types (e.g., uniform, gradient, random) for testing the algorithm.</li>
      <li><strong>Computation Library:</strong> Specifies the computational method (pure assembly vs. C++ implementation).</li>
  </ul>
  
  <h2>Assembly Code Snippet</h2>
  <pre>
; Loading neighboring pixels
pinsrb xmm1, byte ptr[RCX + R11 - 3], 0
pinsrb xmm3, byte ptr[RCX + R11], 1
pinsrb xmm1, byte ptr[RCX + R11 + 3], 2
pinsrb xmm3, byte ptr[RCX - 3], 3
pinsrb xmm3, byte ptr[RCX + 3], 5
<br>
      
; Multiplying pixels by filter weights
pmullw xmm3, xmm4 
pxor xmm2, xmm2 
psadbw xmm1, xmm2 
paddsw xmm1, xmm3 
  </pre>
  <p>This code is optimized for SIMD operations, reducing memory overhead and increasing processing speed.</p>
  
  <h2>User Interface</h2>
  <p>The application provides a graphical user interface (GUI) where users can:</p>
  <ul>
      <li>Select a BMP image file for processing.</li>
      <li>Specify the number of filtering iterations.</li>
      <li>Choose a processing library (C++ or Assembly).</li>
      <li>Adjust the number of threads using a slider.</li>
      <li>Apply the Gaussian filter and save the output image.</li>
  </ul>
  
  <h2>Performance Measurements</h2>
  <p>Testing was performed on three different image sizes: small (640x426), medium (1280x853), and large (1920x1280).</p>
  <p>Performance comparisons were made between ASM and C++ implementations using various threading configurations (1, 2, 4, 8, 16, 32, 64 threads).</p>
  <p>For each configuration, execution time was measured over 5 runs, with the first run excluded as a warm-up.</p>
  
  <h3>Sample Performance Data (Small Image, Assembly)</h3>
  <table border="1">
      <tr>
          <th>Threads</th>
          <th>Run 1</th>
          <th>Run 2</th>
          <th>Run 3</th>
          <th>Run 4</th>
          <th>Run 5</th>
          <th>Avg Time (ms)</th>
          <th>Standard Deviation</th>
      </tr>
      <tr>
          <td>1</td><td>57</td><td>13</td><td>12</td><td>17</td><td>16</td><td>14.5</td><td>2.38</td>
      </tr>
      <tr>
          <td>2</td><td>18</td><td>6</td><td>9</td><td>7</td><td>8</td><td>7.5</td><td>1.29</td>
      </tr>
      <tr>
          <td>4</td><td>24</td><td>5</td><td>8</td><td>6</td><td>5</td><td>6</td><td>1.41</td>
      </tr>
  </table>
  
  <h2>Conclusion</h2>
  <p>The project demonstrates a significant performance boost using SIMD assembly optimization and multi-threading. The assembly implementation outperforms the C++ version, particularly with higher thread counts.</p>
  
  <h2>License</h2>
  <p>This project is licensed under the MIT License.</p>

