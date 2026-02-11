# X3F for Lightroom Classic (X3FforLrC)

> **English** | [日本語](README_ja.md)

A Lightroom Classic plugin for batch converting SIGMA Merrill / Quattro series X3F files into DNG format.
It utilizes the `x3f_extract` tool (from the Kalpanika project) for DNG conversion and `exiftool` for metadata copying, providing a seamless workflow within Lightroom.

## Features
- Accessible directly from Lightroom Classic's "Plug-in Extras" menu.
- Batch converts X3F files within a specified folder to DNG.
- **High-speed conversion with multi-processing**: Utilizes multi-core CPUs for parallel processing of large numbers of files.
- **Lossless JPEG (LJPEG) Compression**: Compresses DNG files losslessly, reducing file size by approximately 60% without any quality loss (Enabled by default).
- **Automatic Recursive Subfolder Processing**: Automatically detects and converts X3F files in subfolders.
- **Denoise Toggle**: Option to disable denoising during conversion to allow noise reduction in post-processing software.
- **Custom Output Folder**: Select any destination folder for the converted DNG files.
- Automatically copies EXIF data (shooting date, ISO, aperture, shutter speed, etc.) to DNG using `exiftool`.
- **Green Noise Fix**: Applies a patch to correct the green noise (color cast on the right edge) specific to the Merrill series (DP1M/DP2M/DP3M).
- macOS binaries (`x3f_extract` and `exiftool`) are included, so no separate installation is required.

## System Requirements
- **OS**: macOS (Apple Silicon / Intel)
  - The included `x3f_extract` has been verified to work on Apple Silicon (arm64).
- **Host App**: Adobe Lightroom Classic

## Installation
1. Download (or Clone) this repository.
2. Save the `X3FforLrC.lrplugin` folder to any location (e.g., `~/Documents/Plugins/`).
3. Launch Lightroom Classic and open **File > Plug-in Manager**.
4. Click the **Add** button in the bottom left and select the `X3FforLrC.lrplugin` folder you saved.
5. Confirm that the plugin is added to the list and status is "Enabled", then click "Done".

## Note on First Run (macOS Security)
Due to macOS security restrictions, the execution of the included binaries may be blocked, showing a dialog "Application cannot be opened because the developer cannot be verified". In such cases, please allow execution using one of the following methods:

- **Method 1: Allow in System Settings**
  Open **System Settings > Privacy & Security** on macOS, scroll down to the "Security" section, and click the **Open Anyway** button to allow execution.
- **Method 2: Remove Quarantine Attribute via Terminal**
  Open Terminal and run the following command to remove the extended attributes (quarantine flag) from the plugin folder:
  ```bash
  xattr -cr /path/to/X3FforLrC.lrplugin
  ```

## Usage
1. Open the "Library" module in Lightroom Classic.
2. Select **File > Plug-in Extras > Convert X3F (Kalpanika)** from the menu bar.
3. A file selection dialog will appear. Select the **folder containing your X3F files**.
4. The **X3F Conversion Settings** dialog will appear.
   - **Parallel Processing**: Check to enable parallel processing.
   - **Concurrent Jobs**: Select the number of simultaneous processes (recommended value is set automatically based on CPU cores).
   - **Compression**: Check "Use Lossless JPEG" to compress DNGs losslessly (Default: Enabled). Reduces file size significantly with no impact on image quality.
   - **Denoise**: Toggle denoise processing during conversion (Default: Enabled). Uncheck if you prefer to handle noise reduction in Lightroom or other software.
   - **Output Folder**: Select the destination folder for the DNG files.
5. Click "OK" to start the conversion process automatically.
   - Progress is shown in the progress bar at the top left.
   - If converted DNG files already exist, processing for those files is skipped.
   - After conversion, EXIF data is copied to the DNG files.
   - Total processing time is displayed upon completion.
6. A dialog appears when processing is complete. Import the generated DNG files into Lightroom for editing.

> [!IMPORTANT]
> **Converting directly from SD Cards**
> When converting directly from an SD card, the read/write speed of the card itself becomes a bottleneck. Increasing parallelism may not improve speed or could even slow it down. for high-speed processing, it is recommended to copy files to a fast storage device like an internal SSD before execution.

## ⚠️ Note on DNG Preview (macOS Limitation)

When viewing converted DNG files in **macOS Preview or Quick Look, the entire image may appear reddish**. This is a **limitation of macOS** and not an issue with the converted data itself.

- **Cause**: The standard macOS RAW engine does not support the RAW data from Sigma Foveon sensors, resulting in incorrect color rendering.
- **Solution**: Please use **Adobe Lightroom Classic** or other compatible software to view and edit DNG files. They will be imported and edited with correct colors.

## For Developers

### About the Bundle
This repository includes not only the `exiftool` executable but also the necessary Perl libraries (`lib` folder).
This ensures `exiftool` works without additional dependencies in environments where Perl is installed.
If it fails to run, it will fallback to using the system-installed `/usr/local/bin/exiftool`.

### Building x3f_extract
You can build `x3f_extract` by running `make` in the `x3f_source/` directory.
LJPEG compression is implemented in `x3f_source/src/x3f_ljpeg.c` and is available via the `-ljpeg` command line option.

```bash
# Build
cd x3f_source && make

# Command line usage example
./bin/osx-x86_64/x3f_extract -dng -ljpeg -o /output/dir input.X3F
```

## Troubleshooting
- **If errors occur**:
  - Check the log file at the path shown in the dialog (usually `~/Library/Logs/Adobe/Lightroom/LrClassicLogs/X3FforLrC.log`).
  - If processing files on an external drive, check the drive's access permissions.

## License and Credits
This plugin itself is provided under the **MIT License**. See the `LICENSE` file for details.

This plugin bundles and uses the following excellent open-source software. They are redistributed under their respective license terms.

### x3f_extract (Kalpanika)
- **Project**: [https://github.com/kalpanika/x3f](https://github.com/kalpanika/x3f)
- **License**: BSD-style License
- **Copyright**: (c) 2015, Roland Karlsson, Erik Karlsson, Mark Roden and contributors.

### ExifTool
- **Project**: [https://exiftool.org/](https://exiftool.org/)
- **License**: Perl Artistic License / GNU GPL
- **Copyright**: (c) 2003-2025, Phil Harvey

## Maintenance and Disclaimer
This project is created and published as a personal hobby.
**Requests for new features, bug reports, and Pull Requests are not accepted.** Please understand this in advance.
The source code is released under the MIT License, so please feel free to Fork and use it as needed.
The author assumes no responsibility for any damages arising from the use of this software.
