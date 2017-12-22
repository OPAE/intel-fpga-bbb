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

#include "gemmRunner.hpp"

//////////////////////////////////////////////////////////////////////////////
// Generic Function Implementations
//////////////////////////////////////////////////////////////////////////////
template <typename T1, typename T2>
int gemmRunner<T1, T2>::checkResult(vector<T1> &mat, vector<T1> &matExp,
                                    const uint32_t nrows,
                                    const uint32_t ncols) {
  int err_c = 0;

  printf("\nChecking Results:\n");
  printf("-----------------\n");

  int threshold = 0;
  if (check_mode == GCM_MKL) {
#ifdef MKL
    // Here we need to decided what value of ulp we want to flag at.
    threshold = 1 << 20;
#else
    std::cout << "ERROR: MKL check not supported when compiling without MKL"
              << std::endl;
    err_c = 1;
    goto done_0;
#endif
  }

  threshold = (mode != FP32) ? ((mode == BINARY) ? 1 : 0) : threshold;
  for (int i = 0; i < nrows; i++) {
    for (int j = 0; j < ncols; j++) {
      unsigned int got = *(unsigned int *)&mat[i * ncols + j];
      unsigned int exp = *(unsigned int *)&matExp[i * ncols + j];

      int cmp = got - exp;
      if (abs(cmp) > threshold) {
        //std::cout << "Mismatch[" << i << "][" << j << "]\t";
        //std::cout << "GOT: " << mat[i * ncols + j] << "\t";
        //std::cout << "EXP: " << matExp[i * ncols + j] << "\t";
        //std::cout << "ERR: " << cmp;
        //std::cout << std::endl;
        err_c++;
      }
    }
  }

done_0:
  if (err_c == 0) {
    printf("Result Match!!\n");
  } else {
    printf("You have [%d] Mismatches\n", err_c);
  }
  return !(err_c == 0);
}

template <typename T1, typename T2>
void gemmRunner<T1, T2>::cpuGEMM(vector<T1> &matA, vector<T2> &matB,
                                 vector<T1> &matC, const uint32_t narows,
                                 const uint32_t nbcols, const uint32_t ncommon,
                                 float scale_alpha, float scale_beta) {
  if (check_mode == GCM_MKL) {
#ifdef MKL
    uint32_t i;
    float *fA, *fB, *fC;
    fA = (float *)mkl_malloc(narows * ncommon * sizeof(float), 64);
    fB = (float *)mkl_malloc(ncommon * nbcols * sizeof(float), 64);
    fC = (float *)mkl_malloc(narows * nbcols * sizeof(float), 64);

    for (i = 0; i < narows * ncommon; i++) {
      fA[i] = static_cast<float>(matA[i]);
    }

    for (i = 0; i < nbcols * ncommon; i++) {
      fB[i] = static_cast<float>(matB[i]);
    }

    for (i = 0; i < narows * nbcols; i++) {
      fC[i] = static_cast<float>(matC[i]);
    }

    cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, narows, nbcols,
                ncommon, scale_alpha, fA, ncommon, fB, nbcols, scale_beta, fC,
                nbcols);

    for (i = 0; i < narows * nbcols; i++) {
      matC[i] = static_cast<T1>(fC[i]);
    }
#endif
  } else if (check_mode == GCM_EXACT) {
//#pragma omp parallel shared(matA, matB, matC)
    {
//#pragma omp for schedule(dynamic)
      for (uint32_t i = 0; i < narows; i++) {
        for (uint32_t j = 0; j < nbcols; j++) {
          T1 sum = 0;
          for (uint32_t k = 0; k < ncommon; k++) {
            sum += matA[i * ncommon + k] * matB[k * nbcols + j];
          }
          matC[i * nbcols + j] = scale_alpha * sum + scale_beta * matC[i * nbcols + j];
        }
      }
    }
  }
}

//////////////////////////////////////////////////////////////////////////////
// Specialized Function Implementations
//////////////////////////////////////////////////////////////////////////////
template <>
void gemmRunner<int, int>::prepareRandomA() {
  // Prepare A Matrix
  if (mode == BINARY) {
    aHelper.fillBMatrix(matrixA, req_a_rows, req_common, is_hw);
    aHelper.zeroBMatrix(matrixA_pad, num_a_rows, num_a_cols);
  } else {
    aHelper.fillMatrix(matrixA, req_a_rows, req_common, is_hw);
    aHelper.zeroMatrix(matrixA_pad, num_a_rows, num_a_cols);
  }
  aHelper.fillPadded(matrixA, matrixA_pad, req_a_rows, req_common, num_a_rows,
                     num_a_cols);
  if (mode == BINARY) {
    aHelper.packB(matrixA_pad, matrixA_pack, num_a_rows, num_a_cols, true,
                  pack_size);
  } else {
    aHelper.pack(matrixA_pad, matrixA_pack, num_a_rows, num_a_cols, true,
                 data_width, pack_size);
  }
  aHelper.prepareBuffer(matrixA_pack, matrixA_fpga, num_a_rows, num_a_cols_pack,
                        num_partsa, num_blocks, a_lead_interleave, true);
}

template <>
void gemmRunner<int, int>::prepareRandomB() {
  // Prepare B Matrix
  if (mode == BINARY) {
    bHelper.fillBMatrix(matrixB, req_common, req_b_cols, is_hw);
    bHelper.zeroBMatrix(matrixB_pad, num_b_rows, num_b_cols);

  } else if ((mode == TFXD16) || (mode == TFXD8)) {
    bHelper.fillTMatrix(matrixB, req_common, req_b_cols, is_hw);
    bHelper.zeroMatrix(matrixB_pad, num_b_rows, num_b_cols);

  } else {
    bHelper.fillMatrix(matrixB, req_common, req_b_cols, is_hw);
    bHelper.zeroMatrix(matrixB_pad, num_b_rows, num_b_cols);
  }
  bHelper.fillPadded(matrixB, matrixB_pad, req_common, req_b_cols, num_b_rows,
                     num_b_cols);
  if (mode == BINARY) {
    bHelper.packB(matrixB_pad, matrixB_pack, num_b_rows, num_b_cols, false,
                  pack_size);

  } else {
    bHelper.pack(matrixB_pad, matrixB_pack, num_b_rows, num_b_cols, false,
                 data_width, pack_size);
  }
  bHelper.prepareBuffer(matrixB_pack, matrixB_fpga, num_b_rows_pack, num_b_cols,
                        num_partsb, num_blocks, b_lead_interleave, false);
}

template <>
void gemmRunner<float, int>::prepareRandomB() {
  // Prepare B Matrix
  bHelper.fillTMatrix(matrixB, req_common, req_b_cols, is_hw);
  bHelper.zeroMatrix(matrixB_pad, num_b_rows, num_b_cols);
  bHelper.fillPadded(matrixB, matrixB_pad, req_common, req_b_cols, num_b_rows,
                     num_b_cols);
  bHelper.pack(matrixB_pad, matrixB_pack, num_b_rows, num_b_cols, false,
               data_width, pack_size);
  bHelper.prepareBuffer(matrixB_pack, matrixB_fpga, num_b_rows_pack, num_b_cols,
                        num_partsb, num_blocks, b_lead_interleave, false);
}

template <>
void gemmRunner<float, int>::cpuGEMM(vector<float> &matA, vector<int> &matB,
                                     vector<float> &matC, const uint32_t narows,
                                     const uint32_t nbcols,
                                     const uint32_t ncommon, float scale_alpha,
                                     float scale_beta) {
  uint32_t i, j, k;
//#pragma omp parallel shared(matA, matB, matC) private(i, j, k)
  {
//#pragma omp for schedule(dynamic)
    for (i = 0; i < narows; i++) {
      for (j = 0; j < nbcols; j++) {
        float sum = 0.0;
        for (k = 0; k < ncommon; k++) {
          int b_val = matB[k * nbcols + j];
          float in_val = (b_val == 1)
                             ? matA[i * ncommon + k]
                             : (b_val == 2) ? -matA[i * ncommon + k] : 0;
          sum += in_val;
        }
        matC[i * nbcols + j] =
            scale_alpha * sum + scale_beta * matC[i * nbcols + j];
      }
    }
  }
}

template <>
void gemmRunner<float, float>::cpuGEMM(vector<float> &matA, vector<float> &matB,
                                       vector<float> &matC,
                                       const uint32_t narows,
                                       const uint32_t nbcols,
                                       const uint32_t ncommon,
                                       float scale_alpha, float scale_beta) {
  if (check_mode == GCM_MKL) {
#ifdef MKL
    uint32_t i;
    double *fA, *fB, *fC;
    fA = (double *)mkl_malloc(narows * ncommon * sizeof(double), 64);
    fB = (double *)mkl_malloc(ncommon * nbcols * sizeof(double), 64);
    fC = (double *)mkl_malloc(narows * nbcols * sizeof(double), 64);

    for (i = 0; i < narows * ncommon; i++) {
      fA[i] = static_cast<double>(matA[i]);
    }

    for (i = 0; i < nbcols * ncommon; i++) {
      fB[i] = static_cast<double>(matB[i]);
    }

    for (i = 0; i < narows * nbcols; i++) {
      fC[i] = static_cast<double>(matC[i]);
    }

    cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans, narows, nbcols,
                ncommon, scale_alpha, fA, ncommon, fB, nbcols, scale_beta, fC,
                nbcols);

    for (i = 0; i < narows * nbcols; i++) {
      matC[i] = static_cast<float>(fC[i]);
    }
#endif
  } else if (check_mode == GCM_EXACT) {
    std::vector<float> v_matB(ncommon * nbcols);
//#pragma omp for schedule(static)
    for (uint32_t y = 0; y < ncommon; ++y)
      for (uint32_t x = 0; x < nbcols; ++x)
        v_matB[y + x * ncommon] = matB[x + y * nbcols];

    uint32_t num_dot8s = ncommon / 8;
    uint32_t p_dot8 = ncommon % 8;
    uint32_t i, j, k;
//#pragma omp parallel shared(matA, v_matB, matC) private(i, j, k)
    {
//#pragma omp for schedule(dynamic)
      for (i = 0; i < narows; i++) {
        for (j = 0; j < nbcols; j++) {
          float sum = 0.0f;
			#ifdef MPF_PLATFORM_BDX
			// FP32 Dot8 Module for MCP_PLATFORM_BDX
			for(k = 0; k < num_dot8s; k++) {
					//clang-format off
				float p_0 = matA[i * ncommon + k * 8] * v_matB[k * 8 + j * ncommon];
				float p_1 = matA[i * ncommon + k * 8 + 1] * v_matB[k * 8 + 1 + j * ncommon];
				float p_2 = matA[i * ncommon + k * 8 + 2] * v_matB[k * 8 + 2 + j * ncommon];
				float p_3 = matA[i * ncommon + k * 8 + 3] * v_matB[k * 8 + 3 + j * ncommon];
				float p_4 = matA[i * ncommon + k * 8 + 4] * v_matB[k * 8 + 4 + j * ncommon];
				float p_5 = matA[i * ncommon + k * 8 + 5] * v_matB[k * 8 + 5 + j * ncommon];
				float p_6 = matA[i * ncommon + k * 8 + 6] * v_matB[k * 8 + 6 + j * ncommon];
				float p_7 = matA[i * ncommon + k * 8 + 7] * v_matB[k * 8 + 7 + j * ncommon];
					// clang-format on
				
				float s_0 = (p_0 + sum) + p_1;
				float s_1 = p_2 + p_3;
				float t_0 = s_0 + s_1;
				float s_2 = (p_4 + t_0) +p_5;
				float s_3 = p_6 + p_7;
				sum = s_2 + s_3;
			}
			if (p_dot8 != 0) {
					// clang-format off
				float p_0 = matA[i * ncommon + k * 8] * v_matB[k * 8 + j * ncommon];
				float p_1 = p_dot8 > 1 ? matA[i * ncommon + k * 8 + 1] * v_matB[k * 8 + 1 + j * ncommon] : 0.0f;
				float p_2 = p_dot8 > 2 ? matA[i * ncommon + k * 8 + 2] * v_matB[k * 8 + 2 + j * ncommon] : 0.0f;
				float p_3 = p_dot8 > 3 ? matA[i * ncommon + k * 8 + 3] * v_matB[k * 8 + 3 + j * ncommon] : 0.0f;
				float p_4 = p_dot8 > 4 ? matA[i * ncommon + k * 8 + 4] * v_matB[k * 8 + 4 + j * ncommon] : 0.0f;
				float p_5 = p_dot8 > 5 ? matA[i * ncommon + k * 8 + 5] * v_matB[k * 8 + 5 + j * ncommon] : 0.0f;
				float p_6 = p_dot8 > 6 ? matA[i * ncommon + k * 8 + 6] * v_matB[k * 8 + 6 + j * ncommon] : 0.0f;
				float p_7 = p_dot8 > 7 ? matA[i * ncommon + k * 8 + 7] * v_matB[k * 8 + 7 + j * ncommon] : 0.0f;
					//clang-format off
			
				float s_0 = (p_0 + sum) + p_1; 
				float s_1 = p_2 + p_3;
				float t_0 = s_0 + s_1;
				float s_2 = (p_4 + t_0) +p_5;
				float s_3 = p_6 + p_7;
				sum = s_2 + s_3;
			}
			#else
			// FP32 Dot8 Module
			for (k = 0; k < num_dot8s; k++) {
				// clang-format off
			float p_0 = matA[i * ncommon + k * 8] * v_matB[k * 8 + j * ncommon];
			float p_1 = matA[i * ncommon + k * 8 + 1] * v_matB[k * 8 + 1 + j * ncommon];
			float p_2 = matA[i * ncommon + k * 8 + 2] * v_matB[k * 8 + 2 + j * ncommon];
			float p_3 = matA[i * ncommon + k * 8 + 3] * v_matB[k * 8 + 3 + j * ncommon];
			float p_4 = matA[i * ncommon + k * 8 + 4] * v_matB[k * 8 + 4 + j * ncommon];
			float p_5 = matA[i * ncommon + k * 8 + 5] * v_matB[k * 8 + 5 + j * ncommon];
			float p_6 = matA[i * ncommon + k * 8 + 6] * v_matB[k * 8 + 6 + j * ncommon];
			float p_7 = matA[i * ncommon + k * 8 + 7] * v_matB[k * 8 + 7 + j * ncommon];
				// clang-format on
	
				float s_0 = (p_0 + sum) + p_1;
				float s_1 = p_2 + p_3;
				float t_0 = s_0 + s_1;
				float s_2 = p_4 + p_5;
				float s_3 = p_6 + p_7;
				float t_1 = s_2 + s_3;
				sum = t_0 + t_1;
			}
			if (p_dot8 != 0) {
				// clang-format off
			float p_0 = matA[i * ncommon + k * 8] * v_matB[k * 8 + j * ncommon];
			float p_1 = p_dot8 > 1 ? matA[i * ncommon + k * 8 + 1] * v_matB[k * 8 + 1 + j * ncommon] : 0.0f;
			float p_2 = p_dot8 > 2 ? matA[i * ncommon + k * 8 + 2] * v_matB[k * 8 + 2 + j * ncommon] : 0.0f;
			float p_3 = p_dot8 > 3 ? matA[i * ncommon + k * 8 + 3] * v_matB[k * 8 + 3 + j * ncommon] : 0.0f;
			float p_4 = p_dot8 > 4 ? matA[i * ncommon + k * 8 + 4] * v_matB[k * 8 + 4 + j * ncommon] : 0.0f;
			float p_5 = p_dot8 > 5 ? matA[i * ncommon + k * 8 + 5] * v_matB[k * 8 + 5 + j * ncommon] : 0.0f;
			float p_6 = p_dot8 > 6 ? matA[i * ncommon + k * 8 + 6] * v_matB[k * 8 + 6 + j * ncommon] : 0.0f;
			float p_7 = p_dot8 > 7 ? matA[i * ncommon + k * 8 + 7] * v_matB[k * 8 + 7 + j * ncommon] : 0.0f;
			//clang-format off
	
			float s_0 = (p_0 + sum) + p_1;
			float s_1 = p_2 + p_3;
			float t_0 = s_0 + s_1;
			float s_2 = p_4 + p_5;
			float s_3 = p_6 + p_7;
			float t_1 = s_2 + s_3;
			sum = t_0 + t_1;
        }
		#endif
        matC[i * nbcols + j] = scale_alpha*sum + scale_beta*matC[i * nbcols + j];
		
      }
    }
  }
  }
}

template class gemmRunner<int, int>;
template class gemmRunner<float, float>;
template class gemmRunner<float, int>;
