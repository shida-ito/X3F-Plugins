#!/bin/bash

# Process a single X3F file — called by convert.sh via token pool for parallel execution.
# Environment variables from convert.sh: SOURCE_DIR, OUTPUT_DIR, BINARY_PATH,
# LJPEG_FLAG, DENOISE_FLAG, NORMALIZE_WL_FLAG, EXIFTOOL_PATH

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
    exit 0
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
    exit 1
fi

# Copy metadata using exiftool
"$EXIFTOOL_PATH" -overwrite_original -tagsfromfile "$x3f_path" \
    -EXIF:DateTimeOriginal -EXIF:CreateDate -EXIF:ModifyDate \
    -EXIF:ISO -EXIF:FNumber -EXIF:ExposureTime \
    -EXIF:ShutterSpeedValue -EXIF:ApertureValue -EXIF:FocalLength \
    -EXIF:Make -EXIF:Model -EXIF:LensModel \
    -EXIF:ExposureProgram -EXIF:MeteringMode -EXIF:Flash \
    -EXIF:ExposureBiasValue -EXIF:Orientation -GPS:all \
    "$dng_path"
