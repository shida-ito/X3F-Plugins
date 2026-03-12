#!/bin/bash

# X3F Batch Converter for Capture One
# Usage: convert.sh source_dir output_dir binary_path use_ljpeg use_denoise concurrency exiftool_path use_normalize_wl

SOURCE_DIR="$1"
OUTPUT_DIR="$2"
BINARY_PATH="$3"
USE_LJPEG="$4"
USE_DENOISE="$5"
CONCURRENCY="$6"
EXIFTOOL_PATH="$7"
USE_NORMALIZE_WL="$8"

# Prepare flags
LJPEG_FLAG=""
if [ "$USE_LJPEG" = "true" ]; then
    LJPEG_FLAG="-ljpeg"
fi

DENOISE_FLAG=""
if [ "$USE_DENOISE" = "false" ]; then
    DENOISE_FLAG="-no-denoise"
fi

NORMALIZE_WL_FLAG=""
if [ "$USE_NORMALIZE_WL" = "true" ]; then
    NORMALIZE_WL_FLAG="-normalize-wl"
fi

export SOURCE_DIR BINARY_PATH LJPEG_FLAG DENOISE_FLAG NORMALIZE_WL_FLAG OUTPUT_DIR EXIFTOOL_PATH

# Function to process a single file
process_file() {
    x3f_path="$1"
    x3f_dir=$(dirname "$x3f_path")
    filename=$(basename "$x3f_path")
    dng_filename="${filename%.*}.dng"
    
    # If OUTPUT_DIR matches SOURCE_DIR, place DNG next to X3F
    TARGET_OUT="$OUTPUT_DIR"
    if [ "$SOURCE_DIR" = "$OUTPUT_DIR" ]; then
        TARGET_OUT="$x3f_dir"
    fi
    
    dng_path="$TARGET_OUT/$dng_filename"

    if [ -f "$dng_path" ]; then
        echo "Skipping $filename (DNG already exists)"
        return
    fi

    echo "Converting $filename in $x3f_dir..."
    "$BINARY_PATH" -dng $LJPEG_FLAG $DENOISE_FLAG $NORMALIZE_WL_FLAG -o "$TARGET_OUT" "$x3f_path"

    # Check if conversion was successful
    # Binary outputs with original case (ext included), e.g. FOO.X3F -> FOO.X3F.dng
    if [ -f "$TARGET_OUT/$filename.dng" ]; then
        mv "$TARGET_OUT/$filename.dng" "$dng_path" 2>/dev/null
    elif [ -f "$TARGET_OUT/$filename.DNG" ]; then
        mv "$TARGET_OUT/$filename.DNG" "$dng_path" 2>/dev/null
    fi

    if [ ! -f "$dng_path" ]; then
        echo "ERROR: Conversion failed for $filename" >&2
        return 1
    fi

    # Copy metadata using exiftool
    if [ -f "$dng_path" ]; then
        "$EXIFTOOL_PATH" -overwrite_original -tagsfromfile "$x3f_path" \
            -EXIF:DateTimeOriginal -EXIF:CreateDate -EXIF:ModifyDate \
            -EXIF:ISO -EXIF:FNumber -EXIF:ExposureTime \
            -EXIF:ShutterSpeedValue -EXIF:ApertureValue -EXIF:FocalLength \
            -EXIF:Make -EXIF:Model -EXIF:LensModel \
            -EXIF:ExposureProgram -EXIF:MeteringMode -EXIF:Flash \
            -EXIF:ExposureBiasValue -GPS:all \
            "$dng_path"
    fi
}

export -f process_file

# Find X3F files and process in parallel
# Removed -maxdepth 1 to allow recursive processing
find "$SOURCE_DIR" -iname "*.x3f" ! -name "._*" -print0 | xargs -0 -P "$CONCURRENCY" bash -c 'for f; do process_file "$f" || exit 1; done' _
if [ "${PIPESTATUS[1]}" -ne 0 ]; then
    echo "ERROR: One or more conversions failed" >&2
    exit 1
fi
