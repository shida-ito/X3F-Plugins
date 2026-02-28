/* X3F_OUTPUT_TIFF.C
 *
 * Library for writing the image as TIFF.
 *
 * Copyright 2015 - Roland and Erik Karlsson
 * BSD-style - see doc/copyright.txt
 *
 */

#include "x3f_output_tiff.h"
#include "x3f_process.h"
#include "x3f_matrix.h"
#include "x3f_printf.h"
#include "x3f_meta.h"

#include <stdlib.h>
#include <math.h>
#include <tiffio.h>

/* Compute K = 1/max(ASN) so the highest-ASN channel (B for DP2M) maps to 1.0 */
static double tiff_compute_k_scale(x3f_t *x3f, char *wb)
{
  double gain[3], gain_inv[3];
  double max_asn;
  int c;

  if (!x3f_get_gain(x3f, wb, gain))
    return 1.0;
  x3f_3x1_invert(gain, gain_inv);

  max_asn = gain_inv[0];
  for (c = 1; c < 3; c++)
    if (gain_inv[c] > max_asn)
      max_asn = gain_inv[c];

  return (max_asn > 0.0) ? 1.0 / max_asn : 1.0;
}

/* Normalize per-channel [black,white] to uniform [0,wl0] and apply
 * Foveon highlight clamp: when the highest-ASN channel (B for DP2M)
 * is near physical saturation, smoothstep-blend other channels toward
 * their neutral-gray cap values to prevent yellow highlights. */
static void tiff_normalize_and_clamp(x3f_t *x3f, char *wb,
                                     x3f_area16_t *image,
                                     x3f_image_levels_t *ilevels,
                                     double k_scale)
{
  int row, col, c;
  double wl0 = floor((double)ilevels->white[0] * k_scale);

  for (row = 0; row < (int)image->rows; row++) {
    uint16_t *p = image->data + image->row_stride * row;
    for (col = 0; col < (int)image->columns; col++) {
      for (c = 0; c < 3; c++) {
        double bl = ilevels->black[c];
        double wl = (double)ilevels->white[c];
        double v = ((double)p[col * 3 + c] - bl) / (wl - bl) * wl0;
        if (v < 0.0) v = 0.0;
        if (v > wl0) v = wl0;
        p[col * 3 + c] = (uint16_t)(v + 0.5);
      }
    }
  }

  ilevels->black[0] = ilevels->black[1] = ilevels->black[2] = 0.0;
  ilevels->white[0] = ilevels->white[1] = ilevels->white[2] = (uint32_t)wl0;

  /* Highlight clamp */
  {
    double gain_clamp[3], gain_inv_clamp[3];
    if (x3f_get_gain(x3f, wb, gain_clamp)) {
      double max_asn = 0.0;
      int sat_ch = 0;
      double cap[3], thresh;

      x3f_3x1_invert(gain_clamp, gain_inv_clamp);
      for (c = 0; c < 3; c++)
        if (gain_inv_clamp[c] > max_asn) {
          max_asn = gain_inv_clamp[c];
          sat_ch = c;
        }
      for (c = 0; c < 3; c++)
        cap[c] = wl0 * gain_inv_clamp[c] / max_asn;
      thresh = wl0 * 0.9;

      for (row = 0; row < (int)image->rows; row++) {
        uint16_t *p = image->data + image->row_stride * row;
        for (col = 0; col < (int)image->columns; col++) {
          double p_sat = (double)p[col * 3 + sat_ch];
          if (p_sat >= thresh) {
            double t = (p_sat - thresh) / (wl0 - thresh);
            if (t > 1.0) t = 1.0;
            t = t * t * (3.0 - 2.0 * t); /* smoothstep */
            for (c = 0; c < 3; c++) {
              double pv, limit;
              if (c == sat_ch) continue;
              pv = (double)p[col * 3 + c];
              limit = pv * (1.0 - t) + cap[c] * t;
              if (pv > limit)
                p[col * 3 + c] = (uint16_t)(limit + 0.5);
            }
          }
        }
      }
    }
  }
}

/* extern */
x3f_return_t x3f_dump_raw_data_as_tiff(x3f_t *x3f,
				       char *outfilename,
				       x3f_color_encoding_t encoding,
				       int crop,
				       int fix_bad,
				       int denoise,
				       int apply_sgain,
				       char *wb,
				       int compress,
				       int normalize_wl)
{
  x3f_area16_t image;
  TIFF *f_out = TIFFOpen(outfilename, "w");
  int row;

  if (f_out == NULL) return X3F_OUTFILE_ERROR;

  if (wb == NULL)
    wb = x3f_get_wb(x3f);

  if (normalize_wl) {
    x3f_image_levels_t ilevels;
    double k_scale;

    if (!x3f_get_image(x3f, &image, &ilevels, NONE, crop, fix_bad, denoise,
                       apply_sgain, wb) ||
        image.channels != 3) {
      x3f_printf(ERR, "Could not get raw image\n");
      TIFFClose(f_out);
      return X3F_ARGUMENT_ERROR;
    }

    k_scale = tiff_compute_k_scale(x3f, wb);
    tiff_normalize_and_clamp(x3f, wb, &image, &ilevels, k_scale);

    if (!x3f_convert_image(x3f, &image, &ilevels, encoding, apply_sgain, wb)) {
      x3f_printf(ERR, "Could not convert image\n");
      TIFFClose(f_out);
      free(image.buf);
      return X3F_ARGUMENT_ERROR;
    }
  } else {
    if (!x3f_get_image(x3f, &image, NULL, encoding,
		       crop, fix_bad, denoise, apply_sgain, wb)) {
      TIFFClose(f_out);
      return X3F_ARGUMENT_ERROR;
    }
  }

  TIFFSetField(f_out, TIFFTAG_IMAGEWIDTH, image.columns);
  TIFFSetField(f_out, TIFFTAG_IMAGELENGTH, image.rows);
  TIFFSetField(f_out, TIFFTAG_ROWSPERSTRIP, 32);
  TIFFSetField(f_out, TIFFTAG_SAMPLESPERPIXEL, image.channels);
  TIFFSetField(f_out, TIFFTAG_BITSPERSAMPLE, 16);
  TIFFSetField(f_out, TIFFTAG_PLANARCONFIG, PLANARCONFIG_CONTIG);
  TIFFSetField(f_out, TIFFTAG_COMPRESSION,
	       compress ? COMPRESSION_DEFLATE : COMPRESSION_NONE);
  TIFFSetField(f_out, TIFFTAG_PHOTOMETRIC, image.channels == 1 ?
	       PHOTOMETRIC_MINISBLACK : PHOTOMETRIC_RGB);
  TIFFSetField(f_out, TIFFTAG_ORIENTATION, ORIENTATION_TOPLEFT);
  TIFFSetField(f_out, TIFFTAG_XRESOLUTION, 72.0);
  TIFFSetField(f_out, TIFFTAG_YRESOLUTION, 72.0);
  TIFFSetField(f_out, TIFFTAG_RESOLUTIONUNIT, RESUNIT_INCH);

  for (row=0; row < image.rows; row++)
    TIFFWriteScanline(f_out, image.data + image.row_stride*row, row, 0);

  TIFFWriteDirectory(f_out);
  TIFFClose(f_out);
  free(image.buf);

  return X3F_OK;
}
