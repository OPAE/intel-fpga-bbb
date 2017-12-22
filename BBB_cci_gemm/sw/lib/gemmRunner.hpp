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

#include <math.h>
#include "gemmLib.hpp"
#include "gemmHelper.hpp"
#ifdef AAL
	#include "gemmALIVTP.hpp"
#endif
#ifdef OPAE
	#include "opaeMPFGEMM.hpp"
#endif

template <typename T1, typename T2>
class gemmRunner {
 private:
  const static uint32_t BUFFER_OFFSET = 8;
  const static uint32_t SGEMM_COLS = 16;
  const static uint32_t SGEMM_ROWS = 10;

  uint32_t req_a_rows;
  uint32_t req_b_cols;
  uint32_t req_common;
  uint32_t a_lead_interleave;
  uint32_t b_lead_interleave;
  uint32_t feeder_interleave;
  uint32_t feeder_interleave_rnd;

  uint32_t data_width;
  uint32_t pack_size;
  uint32_t comm_width;

  uint32_t min_a_rows;
  uint32_t min_b_cols;
  uint32_t min_common;

  uint32_t num_partsa;
  uint32_t num_partsb;
  uint32_t num_blocks;

  uint32_t num_a_rows;
  uint32_t num_a_cols;
  uint32_t num_b_rows;
  uint32_t num_b_cols;

  uint32_t num_a_cols_pack;
  uint32_t num_b_rows_pack;

  float alpha;
  float beta;

  bool is_hw;
  bool is_packed;

  GEMM_MODE mode;
  GEMM_CHECK_MODE check_mode;

  vector<T1> matrixA;
  vector<T1> matrixA_pad;
  vector<T1> matrixA_pack;
  vector<T1> matrixA_fpga;

  vector<T2> matrixB;
  vector<T2> matrixB_pad;
  vector<T2> matrixB_pack;
  vector<T2> matrixB_fpga;

  vector<T1> matrixC;
  vector<T1> matrixC_unpack;
  vector<T1> matrixC_unpad;
  vector<T1> matrixC_fpga;

  gemmHelper<T1> aHelper;
  gemmHelper<T2> bHelper;
  gemmHelper<T1> cHelper;
#ifdef AAL
  gemmALIVTP<T1, T2> aal_hw;
#endif

#ifdef OPAE
  opaeMPFGEMM<T1, T2> opae_hw;
#endif
  int checkResult(vector<T1> &mat, vector<T1> &matExp, const uint32_t nrows,
                  const uint32_t ncols);

  void cpuGEMM(vector<T1> &matA, vector<T2> &matB, vector<T1> &matC,
               const uint32_t narows, const uint32_t nbcols,
               const uint32_t ncommon, float scale_alpha, float scale_beta);

  void printParameters();

 public:
  gemmRunner(uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, uint32_t, float,
             float, GEMM_CHECK_MODE, bool, bool, GEMM_MODE);

  void prepareRandomA();
  void prepareRandomB();
  void prepareRandomC();

  void prepareA(T1 *);
  void prepareB(T2 *);
  void prepareC(T1 *);

  void getC(T1 *);

  int run();
  void abscaling();
  int validate();
};

template <typename T1, typename T2>
void gemmRunner<T1, T2>::printParameters() {
  printf("\n==================\n");
  printf(" SGEMM Parameters \n");
  printf("==================\n");

  printf("DATA_WIDTH:\t%d\n", data_width);
  printf("COMM_WIDTH:\t%d\n", comm_width);
  printf("SGEMM_ROWS:\t%d\n", SGEMM_ROWS);
  printf("SGEMM_COLS:\t%d\n", SGEMM_COLS);
  printf("NUM_BLOCKS:\t%d\n", num_blocks);
  printf("NUM_PARTSA:\t%d\n", num_partsa);
  printf("NUM_PARTSB:\t%d\n", num_partsb);
  printf("NUM_A_ROWS:\t%d\n", num_a_rows);
  printf("NUM_A_COLS:\t%d\n", num_a_cols);
  printf("NUM_B_ROWS:\t%d\n", num_b_rows);
  printf("NUM_B_COLS:\t%d\n", num_b_cols);
  printf("A_LEAD_INTERLEAVE:\t%d\n", a_lead_interleave);
  printf("B_LEAD_INTERLEAVE:\t%d\n", b_lead_interleave);
}

template <typename T1, typename T2>
void gemmRunner<T1, T2>::prepareRandomA() {
  // Prepare A Matrix
  aHelper.fillMatrix(matrixA, req_a_rows, req_common, is_hw);
  aHelper.zeroMatrix(matrixA_pad, num_a_rows, num_a_cols);
  aHelper.fillPadded(matrixA, matrixA_pad, req_a_rows, req_common, num_a_rows,
                     num_a_cols);
  aHelper.pack(matrixA_pad, matrixA_pack, num_a_rows, num_a_cols, true,
               data_width, pack_size);
  aHelper.prepareBuffer(matrixA_pack, matrixA_fpga, num_a_rows, num_a_cols_pack,
                        num_partsa, num_blocks, a_lead_interleave, true);
}

template <typename T1, typename T2>
void gemmRunner<T1, T2>::prepareRandomB() {
  // Prepare B Matrix
  bHelper.fillMatrix(matrixB, req_common, req_b_cols, is_hw);
  bHelper.zeroMatrix(matrixB_pad, num_b_rows, num_b_cols);
  bHelper.fillPadded(matrixB, matrixB_pad, req_common, req_b_cols, num_b_rows,
                     num_b_cols);
  bHelper.pack(matrixB_pad, matrixB_pack, num_b_rows, num_b_cols, false,
               data_width, pack_size);
  bHelper.prepareBuffer(matrixB_pack, matrixB_fpga, num_b_rows_pack, num_b_cols,
                        num_partsb, num_blocks, b_lead_interleave, false);
}

template <typename T1, typename T2>
void gemmRunner<T1, T2>::prepareRandomC() {
  // Prepare C Matrix
  cHelper.fillMatrix(matrixC, req_a_rows, req_b_cols, true);
}

template <typename T1, typename T2>
void gemmRunner<T1, T2>::prepareA(T1 *A) {
  // Prepare A Matrix
  for (uint32_t i = 0; i < req_a_rows * req_common; ++i) matrixA[i] = A[i];

  aHelper.zeroMatrix(matrixA_pad, num_a_rows, num_a_cols);
  aHelper.fillPadded(matrixA, matrixA_pad, req_a_rows, req_common, num_a_rows,
                     num_a_cols);
  aHelper.pack(matrixA_pad, matrixA_pack, num_a_rows, num_a_cols, true,
               data_width, pack_size);
  aHelper.prepareBuffer(matrixA_pack, matrixA_fpga, num_a_rows, num_a_cols_pack,
                        num_partsa, num_blocks, a_lead_interleave, true);
}

template <typename T1, typename T2>
void gemmRunner<T1, T2>::prepareB(T2 *B) {
  // Prepare B Matrix
  for (uint32_t i = 0; i < req_common * req_b_cols; ++i) matrixB[i] = B[i];

  bHelper.zeroMatrix(matrixB_pad, num_b_rows, num_b_cols);
  bHelper.fillPadded(matrixB, matrixB_pad, req_common, req_b_cols, num_b_rows,
                     num_b_cols);
  bHelper.pack(matrixB_pad, matrixB_pack, num_b_rows, num_b_cols, false,
               data_width, pack_size);
  bHelper.prepareBuffer(matrixB_pack, matrixB_fpga, num_b_rows_pack, num_b_cols,
                        num_partsb, num_blocks, b_lead_interleave, false);
}

template <typename T1, typename T2>
void gemmRunner<T1, T2>::prepareC(T1 *C) {
  for (uint32_t i = 0; i < req_a_rows * req_b_cols; ++i) matrixC[i] = C[i];
}

template <typename T1, typename T2>
void gemmRunner<T1, T2>::getC(T1 *C) {
  for (uint32_t i = 0; i < req_a_rows * req_b_cols; ++i)
    C[i] = matrixC_unpad[i];
}

template <typename T1, typename T2>
void gemmRunner<T1, T2>::abscaling() {
  cHelper.unpack(matrixC_fpga, matrixC_unpack, num_partsb, num_partsa,
                 SGEMM_ROWS, SGEMM_COLS, a_lead_interleave, b_lead_interleave);

  cHelper.fillUnPadded(matrixC_unpack, matrixC_unpad, req_a_rows, req_b_cols,
                       num_a_rows, num_b_cols);

  for (uint32_t i = 0; i < req_a_rows * req_b_cols; ++i)
    matrixC_unpad[i] = alpha * matrixC_unpad[i] + beta * matrixC[i];
}

template <typename T1, typename T2>
int gemmRunner<T1, T2>::validate() {
  int result = 0;
  if (check_mode != GCM_NONE) {
    cpuGEMM(matrixA, matrixB, matrixC, req_a_rows, req_b_cols, req_common,
            alpha, beta);
    // Compare FPGA results to software results
    result = checkResult(matrixC_unpad, matrixC, req_a_rows, req_b_cols);
  }
  return result;
}

template <typename T1, typename T2>
int gemmRunner<T1, T2>::run() {
	int fpga_hw_ok;
#ifdef AAL
  if (!aal_hw.isOK()) {
    std::cout << "Failed to start runtime" << std::endl;
    exit(1);
  }
  printParameters();

  fpga_hw_ok = aal_hw.initSGEMM(num_partsa, num_partsb, num_blocks, a_lead_interleave,
                                b_lead_interleave, SGEMM_ROWS, SGEMM_COLS, comm_width,
                                BUFFER_OFFSET);
  if(!fpga_hw_ok) {
    fpga_hw_ok = aal_hw.runSGEMM(matrixA_fpga, matrixB_fpga, matrixC_fpga, num_a_rows,
                            num_a_cols_pack, num_b_rows_pack, num_b_cols, num_partsa,
                            num_partsb, num_blocks, a_lead_interleave, b_lead_interleave,
                            feeder_interleave, req_a_rows, req_b_cols, req_common, SGEMM_ROWS,
                            SGEMM_COLS, BUFFER_OFFSET, pack_size);
    aal_hw.cleanup();
  }
  return fpga_hw_ok;
#endif
#ifdef OPAE
  printParameters();
  fpga_hw_ok = opae_hw.initGEMM(num_partsa, num_partsb, num_blocks, a_lead_interleave,
								b_lead_interleave, SGEMM_ROWS, SGEMM_COLS, comm_width,
								BUFFER_OFFSET);
  if(!fpga_hw_ok) {
	fpga_hw_ok = opae_hw.runGEMM(matrixA_fpga, matrixB_fpga, matrixC_fpga, num_a_rows,
								  num_a_cols_pack, num_b_rows_pack, num_b_cols, num_partsa,
								  num_partsb, num_blocks, a_lead_interleave, b_lead_interleave,
								  feeder_interleave, req_a_rows, req_b_cols, req_common, SGEMM_ROWS,
								  SGEMM_COLS, BUFFER_OFFSET, pack_size);
	opae_hw.cleanup();
  }
#endif
return 0;
}

template <typename T1, typename T2>
gemmRunner<T1, T2>::gemmRunner(uint32_t i_req_a_rows, uint32_t i_req_b_cols,
                               uint32_t i_req_common,
                               uint32_t i_a_lead_interleave,
                               uint32_t i_b_lead_interleave,
                               uint32_t i_feeder_interleave, float i_alpha,
                               float i_beta, GEMM_CHECK_MODE i_check_mode,
                               bool i_is_hw, bool i_is_packed,
                               GEMM_MODE i_mode) {
  // Set Parameters for the Test
  // clang-format off
  switch (i_mode) {
    case FP32:   data_width = 32; break;
    case FXD16:  data_width = 16; break;
    case FXD8:   data_width = 8;  break;
    case FXD4:   data_width = 4;  break;
    case BINARY: data_width = 1;  break;
    case TFP32:  data_width = 32; break;
    case TFXD16: data_width = 16; break;
    case TFXD8:  data_width = 8;  break;
    default:     exit(1);
  }
  //clang-format on

  alpha = i_alpha;
  beta = i_beta;

  req_a_rows = i_req_a_rows > 0 ? i_req_a_rows : 1;
  req_b_cols = i_req_b_cols > 0 ? i_req_b_cols : 1;
  req_common = i_req_common > 0 ? i_req_common : 1;

  a_lead_interleave = i_a_lead_interleave;
  b_lead_interleave = i_b_lead_interleave;
  feeder_interleave = i_feeder_interleave;

  feeder_interleave_rnd = feeder_interleave + (feeder_interleave % 2);

  check_mode = i_check_mode;
  is_hw = i_is_hw;
  is_packed = i_is_packed;
  mode = i_mode;

  // Cacluate GEMM internal parameters
  pack_size = 32 / data_width;
  comm_width = pack_size * feeder_interleave_rnd * BUFFER_OFFSET;

  min_a_rows = a_lead_interleave * SGEMM_ROWS;
  min_b_cols = b_lead_interleave * SGEMM_COLS;
  min_common = comm_width;

  num_partsa = (req_a_rows + min_a_rows - 1) / min_a_rows;
  num_partsb = (req_b_cols + min_b_cols - 1) / min_b_cols;
  num_blocks = (req_common + min_common - 1) / min_common;

  num_a_rows = a_lead_interleave * SGEMM_ROWS * num_partsa;
  num_a_cols = comm_width * num_blocks;
  num_b_rows = comm_width * num_blocks;
  num_b_cols = b_lead_interleave * SGEMM_COLS * num_partsb;

  num_a_cols_pack = num_a_cols / pack_size;
  num_b_rows_pack = num_b_rows / pack_size;
 
  // Setup the HW
 #ifdef AAL 
  aal_hw.setMode(mode);
  aal_hw.setHW(is_hw);
  aal_hw.setPacked(is_packed);
#endif

#ifdef OPAE
	opae_hw.setMode(mode);
	opae_hw.setHW(is_hw);
	opae_hw.setPacking(is_packed);
#endif
  // Reserve some memory
  matrixA.reserve(req_a_rows * req_common);
  matrixA_pad.reserve(num_a_rows * num_a_cols);
  matrixA_pack.reserve(num_a_rows * (num_a_cols / pack_size));
  matrixA_fpga.reserve(num_a_rows * num_a_cols);

  matrixB.reserve(req_common * req_b_cols);
  matrixB_pad.reserve(num_b_rows * num_b_cols);
  matrixB_pack.reserve(num_b_rows * (num_b_cols / pack_size));
  matrixB_fpga.reserve(num_b_rows * num_b_cols);

  matrixC.reserve(req_a_rows * req_b_cols);
  matrixC_unpad.reserve(req_a_rows * req_b_cols);
  matrixC_unpack.reserve(num_a_rows * num_b_cols);
  matrixC_fpga.reserve(num_a_rows * num_b_cols);
}

template <>
void gemmRunner<int, int>::prepareRandomA();

template <>
void gemmRunner<int, int>::prepareRandomB();

template <>
void gemmRunner<float, int>::prepareRandomB();

template <>
void gemmRunner<float, int>::cpuGEMM(vector<float> &matA, vector<int> &matB,
                                     vector<float> &matC, const uint32_t narows,
                                     const uint32_t nbcols,
                                     const uint32_t ncommon, float scale_alpha, float scale_beta);

template <>
void gemmRunner<float, float>::cpuGEMM(vector<float> &matA, vector<float> &matB,
                                       vector<float> &matC,
                                       const uint32_t narows,
                                       const uint32_t nbcols,
                                       const uint32_t ncommon, float scale_alpha, float scale_beta);
