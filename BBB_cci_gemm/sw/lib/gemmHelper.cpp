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

#include "gemmHelper.hpp"

//////////////////////////////////////////////////////////////////////////////
// Generic Function Implementations
//////////////////////////////////////////////////////////////////////////////
template <typename T>
void gemmHelper<T>::fillMatrix(vector<T> &mat, const uint32_t nrows,
                               const uint32_t ncols, bool isRands) {
  for (int i = 0; i < nrows; i++) {
    for (int j = 0; j < ncols; j++) {
      if (isRands) {
        mat[i * ncols + j] =
            randRange(static_cast<T>(-20), static_cast<T>(20));
      } else {
        if (j > (ncols - 16)) {
          mat[i * ncols + j] =
              randRange(static_cast<T>(-2), static_cast<T>(2));
        } else if ((i == nrows - 1) && (j == ncols - 1)) {
          mat[i * ncols + j] = static_cast<T>(2);
        } else if (i % (16) == 0) {
          mat[i * ncols + j] = static_cast<T>(1);
        } else {
          mat[i * ncols + j] = static_cast<T>(0);
        }
      }
    }
  }
}

template <typename T>
void gemmHelper<T>::fillPadded(vector<T> &matIn, vector<T> &matOut,
                               const uint32_t req_lead,
                               const uint32_t req_common,
                               const uint32_t num_lead,
                               const uint32_t num_common) {
  for (int i = 0; i < req_lead; i++) {
    for (int j = 0; j < req_common; j++) {
      matOut[i * num_common + j] = matIn[i * req_common + j];
    }
  }
}

template <typename T>
void gemmHelper<T>::fillUnPadded(vector<T> &matIn, vector<T> &matOut,
                                 const uint32_t req_lead,
                                 const uint32_t req_common,
                                 const uint32_t num_lead,
                                 const uint32_t num_common) {
  for (int i = 0; i < req_lead; i++) {
    for (int j = 0; j < req_common; j++) {
      matOut[i * req_common + j] = matIn[i * num_common + j];
    }
  }
}

template <typename T>
void gemmHelper<T>::zeroMatrix(vector<T> &mat, const uint32_t nrows,
                               const uint32_t ncols) {
  for (int i = 0; i < nrows; i++) {
    for (int j = 0; j < ncols; j++) {
      mat[i * ncols + j] = static_cast<T>(0);
    }
  }
}

template <typename T>
void gemmHelper<T>::unpack(vector<T> &matIn, vector<T> &matOut,
                           const uint32_t num_partsb, const uint32_t num_partsa,
                           const uint32_t sgemm_rows, const uint32_t sgemm_cols,
                           const uint32_t a_lead_interleave,
                           const uint32_t b_lead_interleave) {
  for (uint32_t bi = 0; bi < num_partsb; bi++) {
    for (uint32_t ai = 0; ai < num_partsa; ai++) {
      for (uint32_t l = 0; l < sgemm_rows; l++) {
        for (uint32_t j = 0; j < sgemm_cols; j++) {
          for (uint32_t i = 0; i < a_lead_interleave; i++) {
            for (uint32_t k = 0; k < b_lead_interleave; k++) {
              uint32_t m_index =
                  (ai * num_partsb * sgemm_rows * sgemm_cols *
                   a_lead_interleave * b_lead_interleave) +
                  (bi * sgemm_cols * b_lead_interleave) +
                  (sgemm_rows - 1 - l) * a_lead_interleave * num_partsb *
                      b_lead_interleave * sgemm_cols +
                  j * b_lead_interleave +
                  i * num_partsb * b_lead_interleave * sgemm_cols + k;

              uint32_t cl_index =
                  (bi * num_partsa * sgemm_rows * a_lead_interleave *
                       b_lead_interleave +
                   ai * sgemm_rows * a_lead_interleave * b_lead_interleave +
                   l * a_lead_interleave * b_lead_interleave +
                   i * b_lead_interleave + k) *
                      sgemm_cols +
                  j;
              matOut[m_index] = matIn[cl_index];
            }
          }
        }
      }
    }
  }
}

//////////////////////////////////////////////////////////////////////////////
// Specialized Function Implementations
//////////////////////////////////////////////////////////////////////////////
template <>
int gemmHelper<int>::randRange(int min, int max) {
  int randNum = rand() % (max - min);
  return randNum + min;
}

template <>
float gemmHelper<float>::randRange(float min, float max) {
  return min + static_cast<float>(
                   rand() / ((static_cast<float>(RAND_MAX) / (max - min))));
}

template <>
void gemmHelper<float>::pack(vector<float> &matIn, vector<float> &matOut,
                             const uint32_t nrows, const uint32_t ncols,
                             bool type, const uint32_t DATA_WIDTH,
                             const uint32_t PACK_SIZE) {
  for (uint32_t ii = 0; ii < nrows; ii++) {
    for (uint32_t jj = 0; jj < ncols; jj++) {
      matOut[ii * ncols + jj] = matIn[ii * ncols + jj];
    }
  }
}

// Special Functions for Binary and Ternary
template <>
void gemmHelper<int>::fillTMatrix(vector<int> &mat, const uint32_t nrows,
                                  const uint32_t ncols, bool isRands) {
  int i, j;
  for (i = 0; i < nrows; i++) {
    for (j = 0; j < ncols; j++) {
      if (isRands) {
        mat[i * ncols + j] = (rand() % 3);
      } else {
        mat[i * ncols + j] = 0x1;
      }
    }
  }
}

template <>
void gemmHelper<int>::fillBMatrix(vector<int> &mat, const uint32_t nrows,
                                  const uint32_t ncols, bool isRands) {
  int i, j;
  for (i = 0; i < nrows; i++) {
    for (j = 0; j < ncols; j++) {
      mat[i * ncols + j] = (rand() % 2) ? 1 : -1;
    }
  }
}

template <>
void gemmHelper<int>::zeroBMatrix(vector<int> &mat, const uint32_t nrows,
                                  const uint32_t ncols) {
  int i, j;
  for (i = 0; i < nrows; i++) {
    for (j = 0; j < ncols; j++) {
      // Special XOR GEMM Zeroing
      mat[i * ncols + j] = (i % 2) ? 1 : -1;
    }
  }
}

template <>
void gemmHelper<int>::packB(vector<int> &matIn, vector<int> &matOut,
                            const uint32_t nrows, const uint32_t ncols,
                            bool type, const uint32_t PACK_SIZE) {
  if (type) {
    // Pack A
    for (int mm = 0; mm < nrows; mm++)                    // each row
      for (int kk = 0; kk < (ncols / PACK_SIZE); kk++) {  // each 32 cols in row
        int packbits = 0;

        // Pack 32 A row elements into bin32
        for (int t = 0; t < PACK_SIZE; t++) {
          if (matIn[(mm * ncols) + (kk * PACK_SIZE) + t] == 1)
            packbits |= (0x00000001 << t);
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
          if (matIn[(nn * ncols * PACK_SIZE) + (kk) + (t * ncols)] == 1)
            packbits |= (0x00000001 << t);
        }
        matOut[(nn * ncols) + kk] = packbits;
      }
  }
}

template class gemmHelper<int>;
template class gemmHelper<float>;
