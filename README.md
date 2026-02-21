# X3F Plugins (Lightroom & Capture One)

> **English** | [日本語](README_ja.md)

A suite of plugins for batch converting SIGMA Merrill / Quattro series X3F files into DNG format.
It utilizes the `x3f_extract` tool (Kalpanika project) and `exiftool` to provide a seamless workflow within your preferred RAW processor.

## Main Features
- **High-speed multi-processing**: Leverages multi-core CPUs for rapid parallel processing of large file sets.
- **Lossless JPEG (LJPEG) Compression**: Reduces DNG file sizes by ~60% without any quality loss (Enabled by default).
- **Recursive Subfolder Processing**: Automatically detects and converts X3F files in subdirectories.
- **Denoise Toggle**: Option to disable in-conversion denoising if you prefer handling it in post.
- **Metadata Preservation**: Automatically copies EXIF data (Date, ISO, Aperture, Sped, etc.) to the DNG files.
- **Green Noise Fix**: Integrated patch for Merrill series (DP1M/DP2M/DP3M) right-edge color cast.
- **Bundled Binaries**: Includes macOS binaries for `x3f_extract` and `exiftool`; no extra installation required.

## System Requirements
- **OS**: macOS (Apple Silicon / Intel)
- **Supported Apps**: 
  - Adobe Lightroom Classic
  - Capture One (macOS only)

---

## Usage in Adobe Lightroom Classic

### 1. Installation
1. Download (or Clone) this repository and save `Lightroom/X3FforLrC.lrplugin` to a location of your choice (e.g., `~/Documents/Plugins/`).
2. Launch Lightroom Classic and open **File > Plug-in Manager**.
3. Click the **Add** button and select the `.lrplugin` folder you saved.
4. Ensure the status is "Enabled" and click "Done".

### 2. How to Use
1. Select **File > Plug-in Extras > Convert X3F (Kalpanika)** from the menu bar.
2. Select the **folder containing your X3F files**.
3. Configure settings in the **X3F Conversion Settings** dialog and click "OK".
   - **Parallel Processing**: Enable multi-core usage.
   - **Concurrent Jobs**: Number of simultaneous processes (auto-set based on your CPU).
   - **Output Folder**: Choose any destination for the DNG files.
4. A progress bar will appear. Once finished, import and edit the generated DNG files.

---

## Usage in Capture One

### 1. Installation
The installation is automated using a script that places everything in the correct location and handles permissions.
1. Open Terminal and navigate to the `CaptureOne` folder in this repository:
   ```bash
   cd CaptureOne
   bash install_fix.sh
   ```
2. Open Capture One and go to **"Scripts" > "Update Scripts Menu"**.

*Note: If you have an old `.c1plugin` version in your `Plug-ins` folder, `install_fix.sh` will automatically remove it to avoid conflicts.*

### 2. How to Use
1. Select **Scripts > X3F Converter** from the menu bar.
2. Select the **folder containing your X3F files**.
3. In the **X3F Conversion Settings** dialog, enter the **Concurrent Jobs** (default is 4) and click "OK".
4. Choose whether to apply **Denoise** processing in the subsequent dialog.
5. Conversion runs in the background (progress is shown via macOS notifications).
6. Once complete, Capture One's Import window will open automatically for you to import the DNGs.

---

## Common Notes

### First Run Security (macOS)
If execution is blocked by macOS, allow it via:
- **Method 1**: Click "Open Anyway" in **System Settings > Privacy & Security**.
- **Method 2**: Run `xattr -cr /path/to/plugin` in Terminal to remove the quarantine flag.

### ⚠️ DNG Preview Limitation
Viewing DNG files in **macOS Preview or Quick Look may show a reddish tint**. This is a macOS limitation. **The files will display and edit with correct colors in Lightroom, Capture One, and other compatible software.**

### Converting from SD Cards
SD card speeds can be a bottleneck. For best performance, copy files to an internal SSD before conversion.

## Developers & Credits
- **Troubleshooting**: Check the Lightroom logs at `~/Library/Logs/Adobe/Lightroom/LrClassicLogs/X3FforLrC.log` if issues occur.
- **License**: This project is under the **MIT License**. Included tools: `x3f_extract` (Kalpanika) is BSD, `ExifTool` is Perl Artistic/GPL.
- **Disclaimer**: This is a personal project. Requests for new features or PRs are not accepted. The author is not responsible for any damages resulting from the use of this software.
