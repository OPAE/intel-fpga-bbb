//
// Copyright (c) 2017, Intel Corporation
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of the Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#pragma once

#include <stdint.h>
#include <cstdlib>
#include <iostream>
#include <vector>

#include "gemmLib.hpp"

using namespace std;

template <typename T>
class gemmHelper {
 public:
  gemmHelper();

  T randRange(T min, T max);
  void fillMatrix(vector<T> &mat, const uint32_t nrwos, const uint32_t ncols,
                  bool isRands);

  void fillPadded(vector<T> &matIn, vector<T> &matOut, const uint32_t req_lead,
                  const uint32_t req_common, const uint32_t num_lead,
                  const uint32_t num_common);

  void fillUnPadded(vector<T> &matIn, vector<T> &matOut,
                    const uint32_t req_lead, const uint32_t req_common,
                    const uint32_t num_lead, const uint32_t num_common);

  void zeroMatrix(vector<T> &mat, const uint32_t nrows, const uint32_t ncols);

  void printMatrix(vector<T> &mat, const uint32_t nrows, const uint32_t ncols);

  void pack(vector<T> &mat, vector<T> &matOut, const uint32_t nrows,
            const uint32_t ncols, bool type, const uint32_t DATA_WIDTH,
            const uint32_t PACK_SIZE);

  void unpack(vector<T> &matIn, vector<T> &matOut, const uint32_t num_partsb,
              const uint32_t num_partsa, const uint32_t sgemm_rows,
              const uint32_t sgemm_cols, const uint32_t a_lead_interleave,
              const uint32_t b_lead_interleave);

  void prepareBuffer(vector<T> &matIn, vector<T> &matOut, const uint32_t nrows,
                     const uint32_t ncols, const uint32_t nworkloads,
                     const uint32_t nblocks, const uint32_t interleaving,
                     bool type);

  // Specialized for Binary and Ternary
  void fillTMatrix(vector<int> &mat, const uint32_t nrows, const uint32_t ncols,
                   bool isRands);
  void fillBMatrix(vector<int> &mat, const uint32_t nrows, const uint32_t ncols,
                   bool isRands);
  void zeroBMatrix(vector<int> &mat, const uint32_t nrows,
                   const uint32_t ncols);

  void packB(vector<int> &mat, vector<int> &matOut, const uint32_t nrows,
             const uint32_t ncols, bool type, const uint32_t PACK_SIZE);
};

template <typename T>
gemmHelper<T>::gemmHelper() {}

template <typename T>
void gemmHelper<T>::printMatrix(vector<T> &mat, const uint32_t nrows,
                                const uint32_t ncols) {
  int i, j;
  for (i = 0; i < nrows; i++) {
    for (j = 0; j < ncols; j++) {
      std::cout << mat[i * ncols + j] << ", ";
    }
    std::cout << std::endl;
  }
}

template <typename T>
void gemmHelper<T>::pack(vector<T> &matIn, vector<T> &matOut,
                         const uint32_t nrows, const uint32_t ncols, bool type,
                         const uint32_t DATA_WIDTH, const uint32_t PACK_SIZE) {
  uint32_t MAX = (1 << DATA_WIDTH) - 1;
  if (type) {
    // Pack A
    for (int mm = 0; mm < nrows; mm++)                    // each row
      for (int kk = 0; kk < (ncols / PACK_SIZE); kk++) {  // each 32 cols in row
        int packbits = 0;

        // Pack 32 A row elements into bin32
        for (int t = 0; t < PACK_SIZE; t++) {
          int val = matIn[(mm * ncols) + (kk * PACK_SIZE) + t];
          packbits |= ((MAX & val) << ((PACK_SIZE - 1 - t) * DATA_WIDTH));
        }
        matOut[(mm * (ncols / PACK_SIZE)) + kk] = packbits;
      }
  } else {
    // Pack B
    for (int nn = 0; nn < nrows / PACK_SIZE; nn++)  // each col
      for (int kk = 0; kk < ncols; kk++) {          // each 32 rows in col
        int packbits = 0;

        // Pack 32 B col elements into bin32
        for (int t = 0; t < PACK_SIZE; t++) {
          int val = matIn[(nn * ncols * PACK_SIZE) + (kk) + (t * ncols)];
          packbits |= ((MAX & val) << ((PACK_SIZE - 1 - t) * DATA_WIDTH));
        }
        matOut[(nn * ncols) + kk] = packbits;
      }
  }
}

template <typename T>
void gemmHelper<T>::prepareBuffer(vector<T> &matIn, vector<T> &matOut,
                                  const uint32_t nrows, const uint32_t ncols,
                                  const uint32_t nworkloads,
                                  const uint32_t nblocks,
                                  const uint32_t interleaving, bool type) {
  if (type) {
    int num_el = 0;

    int row_ptr_offset = 0;
    int col_ptr_offset = 0;
    for (int workload_ptr = 0; workload_ptr < nworkloads; workload_ptr++) {
      for (int num_block_ptr = 0; num_block_ptr < nblocks; num_block_ptr++) {
        for (int row_ptr = row_ptr_offset;
             row_ptr < (row_ptr_offset + (nrows / nworkloads));
             row_ptr = row_ptr + interleaving) {
          for (int col_ptr = col_ptr_offset;
               col_ptr < (col_ptr_offset + (ncols / nblocks));
               col_ptr = (col_ptr + 8)) {
            for (int i = row_ptr; i < row_ptr + interleaving; i++) {
              for (int j = col_ptr; j < col_ptr + 8; j++) {
                num_el++;
                matOut[num_el - 1] = matIn[i * ncols + j];
              }
            }
          }
        }
        col_ptr_offset = col_ptr_offset + (ncols / nblocks);
      }
      row_ptr_offset = row_ptr_offset + (nrows / nworkloads);
      col_ptr_offset = 0;
    }
  } else {
    int num_el = 0;
    int col_ptr = 0;
    int row_ptr = 0;
    int row_ptr_offset = 0;
    int col_ptr_offset = 0;

    for (int workload_ptr = 0; workload_ptr < nworkloads; workload_ptr++) {
      for (int num_block_ptr = 0; num_block_ptr < nblocks; num_block_ptr++) {
        for (col_ptr = col_ptr_offset;
             col_ptr < (col_ptr_offset + (ncols / nworkloads));
             col_ptr = col_ptr + interleaving) {
          for (row_ptr = row_ptr_offset;
               row_ptr < (row_ptr_offset + (nrows / nblocks));
               row_ptr = row_ptr + 8) {
            for (int i = col_ptr; i < (col_ptr + interleaving); i++) {
              for (int j = row_ptr; j < (row_ptr + 8); j++) {
                num_el++;
                matOut[num_el - 1] = matIn[j * ncols + i];
              }
            }
          }
        }
        row_ptr_offset = row_ptr_offset + (nrows / nblocks);
      }

      col_ptr_offset = col_ptr_offset + (ncols / nworkloads);
      row_ptr_offset = 0;
    }
  }
}

template <>
int gemmHelper<int>::randRange(int min, int max);

template <>
float gemmHelper<float>::randRange(float min, float max);

template <>
void gemmHelper<float>::pack(vector<float> &matIn, vector<float> &matOut,
                             const uint32_t nrows, const uint32_t ncols,
                             bool type, const uint32_t DATA_WIDTH,
                             const uint32_t PACK_SIZE);

// Special Functions for Binary and Ternary
template <>
void gemmHelper<int>::fillTMatrix(vector<int> &mat, const uint32_t nrows,
                                  const uint32_t ncols, bool isRands);

template <>
void gemmHelper<int>::fillBMatrix(vector<int> &mat, const uint32_t nrows,
                                  const uint32_t ncols, bool isRands);

template <>
void gemmHelper<int>::zeroBMatrix(vector<int> &mat, const uint32_t nrows,
                                  const uint32_t ncols);

template <>
void gemmHelper<int>::packB(vector<int> &matIn, vector<int> &matOut,
                            const uint32_t nrows, const uint32_t ncols,
                            bool type, const uint32_t PACK_SIZE);
