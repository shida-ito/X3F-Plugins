/* x3f_ljpeg.h
 *
 * Minimal Lossless JPEG (Process 14) encoder for DNG output.
 * Copyright (c) 2026 for X3FforLrC project.
 * License: BSD-style (matching x3f_extract)
 */

#ifndef X3F_LJPEG_H
#define X3F_LJPEG_H

#include <stddef.h>
#include <stdint.h>

/*
 * Compress 16-bit raw image data using Lossless JPEG (Process 14).
 * using Predictor 1 (Ra).
 *
 * inputs:
 *   data: Pointer to 16-bit image data (interleaved RGB or CFA)
 *   width: Image width
 *   height: Image height
 *   channels: Number of channels (1 for CFA, 3 for RGB)
 *   row_stride: Stride in uint16_t elements (typically width * channels)
 *
 * outputs:
 *   out_buffer: Pointer to a buffer allocated by this function (caller must
 * free) out_size: Size of the compressed data
 *
 * returns:
 *   0 on success, non-zero on failure
 */
int x3f_ljpeg_encode(const uint16_t *data, int width, int height, int channels,
                     int row_stride, uint8_t **out_buffer, size_t *out_size);

#endif
