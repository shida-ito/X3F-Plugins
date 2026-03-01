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
- **Normalize WhiteLevel (Capture One highlight fix)**: Eliminates the yellow highlight cast that Capture One produces with Foveon RAW files. See details below.
- **Bundled Binaries**: Includes macOS binaries for `x3f_extract` and `exiftool`; no extra installation required.

## System Requirements
- **OS**: macOS (Apple Silicon / Intel)
- **Supported Apps**: 
  - Adobe Lightroom Classic
  - Capture One (macOS only)

---

## Usage in Adobe Lightroom Classic

### 1. Installation
1. Download the latest release from the [Releases page](https://github.com/shida-ito/X3F-Plugins/releases) and extract the archive. Save `Lightroom/X3FforLrC.lrplugin` to a location of your choice (e.g., `~/Documents/Plugins/`).
2. Launch Lightroom Classic and open **File > Plug-in Manager**.
3. Click the **Add** button and select the `.lrplugin` folder you saved.
4. Ensure the status is "Enabled" and click "Done".

### 2. How to Use
1. Select **File > Plug-in Extras > Convert X3F (Kalpanika)** from the menu bar.
2. Select the **folder containing your X3F files**.
3. Configure settings in the **X3F Conversion Settings** dialog and click "OK".
   - **Parallel Processing**: Enable multi-core usage.
   - **Concurrent Jobs**: Number of simultaneous processes (auto-set based on your CPU).
   - **Compression**: Use Lossless JPEG (LJPEG) to reduce file size by ~60% (enabled by default).
   - **Denoise**: Apply denoising during conversion (disable if you prefer to handle it in post).
   - **Output Folder**: Choose any destination for the DNG files.
4. A progress bar will appear. Once finished, import and edit the generated DNG files.

> **First run note**: macOS may block the bundled binaries on first use. If a security warning appears, see [First Run Security](#first-run-security-macos) below. Since the dialog appears **once per file**, test with a single X3F file first to clear it before processing a full batch.

---

## Usage in Capture One

### 1. Installation
The installation is automated using a script that places everything in the correct location and handles permissions.
1. Download the latest release from the [Releases page](https://github.com/shida-ito/X3F-Plugins/releases), extract the archive, then open Terminal and navigate to the `CaptureOne` folder:
   ```bash
   cd CaptureOne
   bash install_fix.sh
   ```
2. Open Capture One and go to **"Scripts" > "Update Scripts Menu"**.

### 2. How to Use
1. Select **Scripts > X3F Converter** from the menu bar.
2. Select the **folder containing your X3F files**.
3. Configure all settings in the **X3F Conversion Settings** dialog and click "OK":
   - **Jobs**: Number of simultaneous processes (default: 4)
   - **LJPEG**: Lossless JPEG compression — `yes` to reduce file size ~60% (default: yes)
   - **Denoise**: Apply denoising during conversion — `no` to handle it in post (default: yes)
   - **Normalize WL**: Normalize white levels to fix yellow highlights in Capture One (default: no, recommended: yes)
4. Conversion runs in the background (progress is shown via macOS notifications).
5. Once complete, Capture One's Import window will open automatically for you to import the DNGs.

> **First run note**: macOS may block the bundled binaries on first use. If a security warning appears, see [First Run Security](#first-run-security-macos) below. Since the dialog appears **once per file**, test with a single X3F file first to clear it before processing a full batch.

---

## Normalize WhiteLevel — Capture One Highlight Fix

### Background
Foveon sensors have different physical white levels per channel (e.g., R=16383, G=6828, B=3790 on DP2M). The blue channel saturates first. Capture One ignores per-channel white levels and applies the R channel value to all channels, causing the blue channel to clip well before Capture One considers it saturated — resulting in a **yellow cast in highlights**.

### How it works
The **Normalize WhiteLevel** option (`-normalize-wl`) applies the following pipeline before writing the DNG:

1. **K-scale normalization**: All channels are scaled by `K = 1/max(ASN)` so the earliest-saturating channel maps to 1.0 in `AsShotNeutral`. White levels are made uniform.
2. **Highlight clamp**: When the saturating channel (B) approaches its physical limit, the other channels are smoothly blended toward their neutral-gray cap values via a smoothstep curve. This prevents yellow from appearing even in extreme highlights.
3. **Exposure compensation**: `BaselineExposure` is adjusted by `+log2(1/K)` EV so Lightroom and Capture One display the image at the same brightness as without normalization.

The fix is compatible with LJPEG compression (`-ljpeg -normalize-wl`).

### How to enable
- **Capture One**: Answer **"Yes (適用する)"** to the Normalize WL dialog that appears during conversion.

> **Note**: This option is for Capture One only. Lightroom handles per-channel white levels correctly on its own, and enabling this option in Lightroom would slightly reduce highlight tonality. The Lightroom plugin does not expose this option.

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

## For Developers

### Building x3f_extract
Run `make` in the `x3f_source/` directory to build `x3f_extract`.

```bash
# Build
cd x3f_source && make

# Command line usage examples
./bin/osx-x86_64/x3f_extract -dng -ljpeg -o /output/dir input.X3F
./bin/osx-x86_64/x3f_extract -dng -ljpeg -normalize-wl -o /output/dir input.X3F
```

**Output Format** — choose one:

| Flag | Description |
|------|-------------|
| `-dng` | Output as DNG (Linear RAW) — recommended for Lightroom / Capture One |
| `-tiff` | Output as 16-bit sRGB TIFF — fully processed, white-balance baked in |
| `-jpg` | Output as JPEG |
| `-ppm` | Output as PPM |

**Compression** — applies to DNG output:

| Flag | Description |
|------|-------------|
| `-ljpeg` | ✅ *Added by this project* — Lossless JPEG compression (~60% size reduction, no quality loss) |

**Processing Options**:

| Flag | Description |
|------|-------------|
| `-normalize-wl` | ✅ *Added by this project* — Normalize per-channel white levels. Eliminates the yellow highlight cast in Capture One. Recommended for Capture One users. |
| `-no-denoise` | Disable in-conversion denoising (handle noise in post instead) |
| `-no-crop` | Disable sensor crop (include masked pixels) |
| `-wb <mode>` | White balance mode (e.g. `auto`, `sunlight`) |

**Output Location**:

| Flag | Description |
|------|-------------|
| `-o <dir>` | Output directory |

After building, copy the binary to the plugin directories:
```bash
cp x3f_source/bin/osx-x86_64/x3f_extract CaptureOne/X3F_Resources/bin/x3f_extract
cp x3f_source/bin/osx-x86_64/x3f_extract Lightroom/X3FforLrC.lrplugin/bin/x3f_extract
```

### About the Bundle
This repository includes not only the `exiftool` executable but also the necessary Perl libraries (`lib` folder), so `exiftool` works without additional dependencies. If it fails, it falls back to the system-installed `/usr/local/bin/exiftool`.

## Troubleshooting
- **If errors occur**: Check the Lightroom log at `~/Library/Logs/Adobe/Lightroom/LrClassicLogs/X3FforLrC.log`.
- **External drives**: If processing files on an external drive, verify access permissions.

## License and Credits
This plugin is provided under the **MIT License**.

### x3f_extract (Kalpanika)
- **Project**: [https://github.com/kalpanika/x3f](https://github.com/kalpanika/x3f)
- **License**: BSD-style License
- **Copyright**: (c) 2015, Roland Karlsson, Erik Karlsson, Mark Roden and contributors.

### ExifTool
- **Project**: [https://exiftool.org/](https://exiftool.org/)
- **License**: Perl Artistic License / GNU GPL
- **Copyright**: (c) 2003-2025, Phil Harvey

## Disclaimer
This is a personal project. Requests for new features or PRs are not accepted. The author is not responsible for any damages resulting from the use of this software.
