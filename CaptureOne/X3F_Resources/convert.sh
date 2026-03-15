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

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROCESS_ONE="$SCRIPT_DIR/process_one.sh"

echo "Parallel jobs: $CONCURRENCY"

# Token pool for parallel execution
FIFO=$(mktemp -u)
mkfifo "$FIFO"
exec 3<>"$FIFO"
rm "$FIFO"
for i in $(seq 1 "$CONCURRENCY"); do echo >&3; done

FAILED=0
while IFS= read -r -d '' x3f_path; do
    read -u 3
    (
        "$PROCESS_ONE" "$x3f_path"
        EXIT=$?
        echo >&3
        exit $EXIT
    ) &
done < <(find "$SOURCE_DIR" -iname "*.x3f" ! -name "._*" -print0)

for job in $(jobs -p); do
    wait "$job" || FAILED=1
done
exec 3>&-

if [ "$FAILED" -ne 0 ]; then
    echo "ERROR: One or more conversions failed" >&2
    exit 1
fi
