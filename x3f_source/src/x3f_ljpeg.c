/* x3f_ljpeg.c
 * Minimal Lossless JPEG (Process 14) encoder.
 */

#include "x3f_ljpeg.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* -------------------------------------------------------------------------- */
/* Bit Writer                                                                 */
/* -------------------------------------------------------------------------- */

typedef struct {
  uint8_t *data;
  size_t allocated;
  size_t size;
  uint64_t bit_buf;
  int bit_cnt;
} bit_writer_t;

static void bw_init(bit_writer_t *bw, size_t initial_size) {
  bw->data = (uint8_t *)malloc(initial_size);
  bw->allocated = initial_size;
  bw->size = 0;
  bw->bit_buf = 0;
  bw->bit_cnt = 0;
}

static void bw_ensure(bit_writer_t *bw, size_t needed) {
  if (bw->size + needed > bw->allocated) {
    size_t new_size = bw->allocated * 2;
    if (new_size < bw->size + needed)
      new_size = bw->size + needed;
    bw->data = (uint8_t *)realloc(bw->data, new_size);
    bw->allocated = new_size;
  }
}

static void bw_put_byte(bit_writer_t *bw, uint8_t b) {
  bw_ensure(bw, 1);
  bw->data[bw->size++] = b;
}

static void bw_put_bits(bit_writer_t *bw, uint32_t bits, int nbits) {
  bw->bit_buf = (bw->bit_buf << nbits) | (bits & ((1 << nbits) - 1));
  bw->bit_cnt += nbits;

  while (bw->bit_cnt >= 8) {
    uint8_t b = (bw->bit_buf >> (bw->bit_cnt - 8)) & 0xFF;
    bw_put_byte(bw, b);
    if (b == 0xFF)
      bw_put_byte(bw, 0x00); /* Byte stuffing */
    bw->bit_cnt -= 8;
  }
}

static void bw_flush(bit_writer_t *bw) {
  if (bw->bit_cnt > 0) {
    uint8_t b =
        ((bw->bit_buf << (8 - bw->bit_cnt)) | ((1 << (8 - bw->bit_cnt)) - 1)) &
        0xFF;
    bw_put_byte(bw, b);
    if (b == 0xFF)
      bw_put_byte(bw, 0x00);
    bw->bit_cnt = 0;
  }
}

static void bw_write_marker(bit_writer_t *bw, uint8_t marker) {
  /* Flush bits before marker */
  bw_flush(bw); // But standard says align to byte? Yes.
  /* Direct write, no stuffing */
  bw_ensure(bw, 2);
  bw->data[bw->size++] = 0xFF;
  bw->data[bw->size++] = marker;
}

static void bw_write_u16(bit_writer_t *bw, uint16_t val) {
  bw_ensure(bw, 2);
  bw->data[bw->size++] = (val >> 8) & 0xFF;
  bw->data[bw->size++] = val & 0xFF;
}

static void bw_write_u8(bit_writer_t *bw, uint8_t val) {
  bw_ensure(bw, 1);
  bw->data[bw->size++] = val;
}

/* -------------------------------------------------------------------------- */
/* Huffman Utils                                                              */
/* -------------------------------------------------------------------------- */

/* Max categories for 16-bit differences: 0..16 -> 17 categories */
#define MAX_CATS 17

typedef struct {
  uint8_t bits[MAX_CATS + 1]; /* Count of codes for each length (1..16) */
  uint8_t huffval[MAX_CATS];  /* Symbols sorted by code length */
  uint32_t codes[MAX_CATS];   /* Code values for each symbol */
  uint8_t lens[MAX_CATS];     /* Length for each symbol */
} huff_table_t;

/* Generate Huffman table from frequencies */
static void build_huffman_table(const uint32_t *freq, huff_table_t *ht) {
  /* Simple package-merge or greedy construct for small N=17 is overkill.
     Use Canonical Huffman Code generation logic. */

  /* 1. Sort symbols by freq (descending) - bubble sort is fine for N=17 */
  int symbols[MAX_CATS];
  uint32_t f[MAX_CATS];
  int i, j;

  for (i = 0; i < MAX_CATS; i++) {
    symbols[i] = i;
    f[i] = freq[i];
  }

  /* Using a robust simplified algorithm or standard Vitter?
     Let's use a simple depth calculation approach.
     Since N is small, we can just use a priority queue approach directly.
  */

  /* Actually for 17 items, we can use a very simple non-optimized table
     if we wanted (DNG default), but let's compute it properly.

     Implementation references standard JPEG "How to generate".
     See Annex K.2 of ISO/IEC 10918-1.
  */

  /* A) Assign code lengths.
     Use a heap (priority queue) of trees.
     Initial: 17 leaf nodes with frequencies.
  */

  uint32_t heap_freq[2 * MAX_CATS];
  int heap_node[2 * MAX_CATS]; /* Index to node */
  int parent[2 * MAX_CATS];
  int bits[MAX_CATS]; /* Length for each symbol */
  int n_heap = 0;

  /* Init leaf nodes */
  for (i = 0; i < MAX_CATS; i++) {
    bits[i] = 0;
    if (freq[i] > 0) {
      heap_freq[n_heap] = freq[i];
      heap_node[n_heap] = i;
      n_heap++;
    }
  }

  /* If empty (solid color), emit at least one code */
  if (n_heap == 0) {
    bits[0] = 1; /* Symbol 0 length 1 */
  } else if (n_heap == 1) {
    bits[heap_node[0]] = 1;
  } else {
    /* Build tree */
    /* Basic Min-Heap implementation or just linear search since N is small */
    /* Build tree */
    /* Basic Min-Heap implementation or just linear search since N is small */
    int next_node_idx = MAX_CATS; /* Internal nodes start at MAX_CATS */

    /* Copy to internal working array to avoid destroying heap structure
     * structure */
    int node_freq[2 * MAX_CATS];
    for (i = 0; i < n_heap; i++)
      node_freq[heap_node[i]] = heap_freq[i];

    /* Identify generic nodes: 0..MAX_CATS-1 are leaves. >=MAX_CATS are internal
     * set parent */
    /* Reset parents */
    for (i = 0; i < 2 * MAX_CATS; i++)
      parent[i] = -1;

    /* While > 1 tree remains */
    /* Find two smallest freq nodes */

    /* We can just use an array of active roots and pick 2 smallest */
    int roots[MAX_CATS];
    for (i = 0; i < n_heap; i++)
      roots[i] = heap_node[i];
    int n_roots = n_heap;

    while (n_roots > 1) {
      int m1 = -1, m2 = -1;
      uint32_t f1 = 0xFFFFFFFF, f2 = 0xFFFFFFFF;
      int i1 = -1, i2 = -1;

      /* Find lowest */
      for (i = 0; i < n_roots; i++) {
        if (node_freq[roots[i]] < f1) {
          f1 = node_freq[roots[i]];
          m1 = roots[i];
          i1 = i;
        }
      }
      /* Remove m1 */
      roots[i1] = roots[n_roots - 1];
      n_roots--;

      /* Find second lowest */
      for (i = 0; i < n_roots; i++) {
        if (node_freq[roots[i]] < f2) {
          f2 = node_freq[roots[i]];
          m2 = roots[i];
          i2 = i;
        }
      }
      /* Remove m2 */
      roots[i2] = roots[n_roots - 1];
      n_roots--;

      /* Create new node */
      int new_node = next_node_idx++;
      node_freq[new_node] = f1 + f2;
      parent[m1] = new_node;
      parent[m2] = new_node;

      /* Add to roots */
      roots[n_roots++] = new_node;
    }

    /* Calculate lengths */
    for (i = 0; i < MAX_CATS; i++) {
      if (freq[i] > 0) {
        int len = 0;
        int p = i;
        while (parent[p] != -1) {
          len++;
          p = parent[p];
        }
        bits[i] = len;
      }
    }
  }

  /* B) Convert lengths to Huffman Table (BITS and HUFFVAL) */
  /* Limit max length to 16? With 17 symbols, max length is likely <= 16.
     If > 16, typically need to adjust. For DC LJPEG, it's very unlikely. */

  memset(ht->bits, 0, sizeof(ht->bits));
  memset(ht->huffval, 0, sizeof(ht->huffval));
  memset(ht->codes, 0, sizeof(ht->codes));
  memset(ht->lens, 0, sizeof(ht->lens));

  for (i = 0; i < MAX_CATS; i++) {
    if (bits[i] > 16)
      bits[i] = 16; /* Clamp (naive, but usually sufficient for simple DC) */
    if (bits[i] > 0)
      ht->bits[bits[i]]++;
  }

  /* Sort symbols by length then by value */
  int k = 0;
  for (i = 1; i <= 16; i++) {
    for (j = 0; j < MAX_CATS; j++) {
      if (bits[j] == i) {
        ht->huffval[k++] = j;
        ht->lens[j] = i;
      }
    }
  }

  /* C) Generate Codes */
  int code = 0;
  int si = 0;
  for (int l = 1; l <= 16; l++) {
    for (int m = 0; m < ht->bits[l]; m++) {
      int sym = ht->huffval[si++];
      ht->codes[sym] = code;
      code++;
    }
    code <<= 1;
  }
}

/* -------------------------------------------------------------------------- */
/* Encode Loop                                                                */
/* -------------------------------------------------------------------------- */

/* Calculate category for diff */
static inline int get_category(int diff) {
  if (diff == 0)
    return 0;
  int abs_diff = (diff < 0) ? -diff : diff;
  /* Unroll or use __builtin_clz for speed? */
  /* 16-bit values usually fit in CAT 16 */
  /* Simple loop */
  int cat = 0;
  while ((1 << cat) <= abs_diff)
    cat++;
  return cat;
}

int x3f_ljpeg_encode(const uint16_t *data, int width, int height, int channels,
                     int row_stride, uint8_t **out_buffer, size_t *out_size) {
  /* 1. Calculate Statistics (One pass if strict, usually we need proper Huffman
   * table) */
  uint32_t freq[MAX_CATS] = {0};

  /* Buffer for differences to avoid re-calculation?
     Memory tradeoff. Image size ~100MB. Allocating diff buffer is okay.
     But raw data is uint16. Diff is int (can be negative).
  */

  /* For simplicity and memory saving, we do TWO PASSES over the raw data.
     Since it's in RAM, it's fast.
  */

  /* For simplicity and memory saving, we do TWO PASSES over the raw data.
     Since it's in RAM, it's fast.
  */

  /* PASS 1: Calculate Frequencies */
  {
    for (int y = 0; y < height; y++) {
      const uint16_t *row_ptr = data + y * row_stride;

      for (int x = 0; x < width; x++) {
        for (int c = 0; c < channels; c++) {
          int val = row_ptr[x * channels + c];
          int pred;

          if (x == 0 && y == 0) {
            /* First pixel of image (per component) */
            pred = 32768; /* 2^(16-1) */
          } else if (x == 0) {
            /* First pixel of row: Predict from above?
               No, DNG usually restarts predictor or uses Left.
               Wait, DNG spec says "Predictor 1 (Ra)".
               If x=0, Ra is undefined or 0?
               Actually standard JPEG says for x=0, predictor is:
               - First line: 2^(P-1)
               - Subsequent lines: Value of pixel above?
               NO, Predictor 1 is exclusively Ra.
               For x=0, common practice is to use previous line's first pixel?
               Or 2^(P-1)?

               Standard DNG SDK implementation (dng_lossless_jpeg.cpp):
               "The predictor for the first column is 2**(Precision-1) for the
               first row, and the pixel from the previous row for subsequent
               rows."

               BUT, that's IF Predictor selection is different?
               Let's stick to DNG SDK behavior.

               Actually, DNG SDK logic:
               if (col == 0) { if (row == 0) left = 32768; else left =
               data[row-1][0]; }

               Wait, if Predictor=1 (Ra), it doesn't mention Rb (Up).
               However, effectively x=0 needs a value.
            */

            /* Re-checking DNG SDK dng_lossless_jpeg.cpp EncodePredict():
               if (j == 0) prev = (i == 0) ? 32768 : srcPtr[-srcStep];
               This implies Up pixel for start of row.
            */

            if (y == 0)
              pred = 32768;
            else
              pred = (data + (y - 1) * row_stride)[x * channels + c];
          } else {
            /* Normal case: Left pixel */
            pred = row_ptr[(x - 1) * channels + c];
          }

          int diff = val - pred;
          int cat = get_category(diff);
          if (cat >= MAX_CATS)
            cat = MAX_CATS - 1; /* Safety */
          freq[cat]++;
        }
      }
    }
  }

  /* Build Huffman Table */
  huff_table_t ht;
  build_huffman_table(freq, &ht);

  /* Initialize Bit Writer */
  bit_writer_t bw;
  bw_init(&bw, width * height * channels + 4096);

  /* Write Headers */

  /* SOI */
  bw_write_marker(&bw, 0xD8);

  /* SOF3 (Lossless) */
  bw_write_marker(&bw, 0xC3);
  bw_write_u16(&bw, 2 + 1 + 2 + 2 + 1 + channels * 3); /* Lf */
  bw_write_u8(&bw, 16);                                /* P (16-bit) */
  bw_write_u16(&bw, height);                           /* Y */
  bw_write_u16(&bw, width);                            /* X */
  bw_write_u8(&bw, channels);                          /* Nf */
  for (int i = 0; i < channels; i++) {
    bw_write_u8(&bw, i + 1); /* C (component ID) */
    bw_write_u8(&bw, 0x11);  /* H=1, V=1 sampling factors */
    bw_write_u8(&bw, 0x00);  /* Tq (quantization table selector, 0) */
  }

  /* DHT (Define Huffman Table) */
  bw_write_marker(&bw, 0xC4);
  /* Lh = 2 + 1 + 16 + total_symbols */
  int total_syms = 0;
  for (int i = 1; i <= 16; i++)
    total_syms += ht.bits[i];
  bw_write_u16(&bw, 2 + 1 + 16 + total_syms);
  bw_write_u8(&bw, 0x00); /* Tc=0 (DC), Th=0 (ID) */
  for (int i = 1; i <= 16; i++)
    bw_write_u8(&bw, ht.bits[i]);
  for (int i = 0; i < total_syms; i++)
    bw_write_u8(&bw, ht.huffval[i]);

  /* SOS (Start of Scan) */
  bw_write_marker(&bw, 0xDA);
  bw_write_u16(&bw, 2 + 1 + channels * 2 + 3); /* Ls */
  bw_write_u8(&bw, channels);                  /* Ns */
  for (int i = 0; i < channels; i++) {
    bw_write_u8(&bw, i + 1); /* Cs */
    bw_write_u8(&bw, 0x00);  /* Td=0, Ta=0 */
  }
  bw_write_u8(&bw, 0x01); /* Ss = 1 (Predictor) */
  bw_write_u8(&bw, 0x00); /* Se = 0 */
  bw_write_u8(&bw, 0x00); /* Ah=0, Al=0 (Point Transform) */

  /* PASS 2: Encode Data */
  {
    for (int y = 0; y < height; y++) {
      const uint16_t *row_ptr = data + y * row_stride;

      for (int x = 0; x < width; x++) {
        for (int c = 0; c < channels; c++) {
          int val = row_ptr[x * channels + c];
          int pred;
          if (x == 0 && y == 0)
            pred = 32768;
          else if (x == 0)
            pred = (data + (y - 1) * row_stride)[x * channels + c];
          else
            pred = row_ptr[(x - 1) * channels + c];

          int diff = val - pred;
          int cat = get_category(diff);
          if (cat >= MAX_CATS)
            cat = MAX_CATS - 1;

          /* Emit Huffman Code */
          bw_put_bits(&bw, ht.codes[cat], ht.lens[cat]);

          /* Emit Extra Bits */
          if (cat > 0) {
            /* For negative differences, subtract 1 (standard JPEG) */
            uint32_t val_bits = diff;
            if (diff < 0) {
              val_bits = diff - 1;
            }
            /* Write lower 'cat' bits */
            bw_put_bits(&bw, val_bits, cat);
          }
        }
      }
    }
  }

  bw_flush(&bw); // Flush bits to byte alignment

  /* EOI */
  bw_write_marker(&bw, 0xD9);

  *out_buffer = bw.data;
  *out_size = bw.size;

  return 0;
}
