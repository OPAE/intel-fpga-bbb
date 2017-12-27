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

#include "gemmLib.hpp"
#include "gemmRunner.hpp"
void cblas_afu_sgemm(const CBLAS_ORDER Order,
                     const CBLAS_TRANSPOSE TransA,
                     const CBLAS_TRANSPOSE TransB, const int M, const int N,
                     const int K, const float alpha, float *A, const int lda,
                     float *B, const int ldb, const float beta, float *C,
                     const int ldc) {
  bool transpose_a = false;
  bool transpose_b = false;
  bool transpose_c = false;
  // Here are need to Figure out if I need to flip any of the matrixies to match
  // what we are expecting.
  if (Order == CblasColMajor) {
    transpose_a = (TransA == CblasNoTrans);
    transpose_b = (TransB == CblasNoTrans);
    transpose_c = true;
  } else {
    transpose_a = (TransA == CblasTrans);
    transpose_b = (TransB == CblasTrans);
    transpose_c = false;
  }

  // Now Perform the Transposes
  std::vector<float> t_A(M * K);
  if (transpose_a) {
    for (uint32_t i = 0; i < K; ++i)
      for (uint32_t j = 0; j < M; ++j) t_A[j * K + i] = A[i * M + j];
  }

  std::vector<float> t_B(K * N);
  if (transpose_b) {
    for (uint32_t i = 0; i < N; ++i)
      for (uint32_t j = 0; j < K; ++j) t_B[j * N + i] = B[i * K + j];
  }

  std::vector<float> t_C(M * N);
  if (transpose_c) {
    for (uint32_t i = 0; i < N; ++i)
      for (uint32_t j = 0; j < M; ++j) t_C[j * N + i] = C[i * M + j];
  }

  // Find the best Interleaving for A
  // When diving through by the interleaveing we want to smallest remainder
  uint32_t a_lead_interleave = 1;
  uint32_t curr_a_remain = (1 << 30);
  uint32_t b_lead_interleave = 1;
  uint32_t curr_b_remain = (1 << 30);
  for (uint32_t i = 1; i < 33; ++i) {
    uint32_t curr_b = 16 * i;
    uint32_t curr_a = 10 * i;
    uint32_t a_mod = M % curr_a;
    uint32_t b_mod = N % curr_b;

    if ((a_mod < curr_a_remain) || (a_mod == 0)) {
      a_lead_interleave = i;
      curr_a_remain = a_mod;
    }
    if ((b_mod < curr_b_remain) || (b_mod == 0)) {
      b_lead_interleave = i;
      curr_b_remain = b_mod;
    }
  }

  // We only support Interleaving: 50 < a_interleave*b_interleave < 1024
  // This is not the optimal way of doing this, but it will work as a first
  // implementation
  while (a_lead_interleave * b_lead_interleave < 50) {
    if (a_lead_interleave < b_lead_interleave)
      a_lead_interleave++;
    else if (b_lead_interleave < a_lead_interleave)
      b_lead_interleave++;
    else
      a_lead_interleave++;
  }

  gemmRunner<float, float> runner(M, N, K, a_lead_interleave, b_lead_interleave,
                                  16, alpha, beta, GCM_NONE, false, false, FP32);
  if (transpose_a)
    runner.prepareA(t_A.data());
  else
    runner.prepareA(A);

  if (transpose_b)
    runner.prepareB(t_B.data());
  else
    runner.prepareB(B);

  if (transpose_c)
    runner.prepareC(t_C.data());
  else
    runner.prepareC(C);

  runner.run();
  runner.abscaling();
  // runner.validate();
  if (transpose_c) {
    runner.getC(t_C.data());
    for (uint32_t i = 0; i < M; ++i)
      for (uint32_t j = 0; j < N; ++j) C[j * M + i] = t_C[i * N + j];

  } else {
    runner.getC(C);
  }
}

timespec start_timer() {
  timespec start;
  clock_gettime(CLOCK_MONOTONIC, &start);
  return start;
}

timespec end_timer(timespec start) {
  timespec end;
  clock_gettime(CLOCK_MONOTONIC, &end);

  timespec diff;
  if ((end.tv_nsec - start.tv_nsec) < 0) {
    diff.tv_sec = end.tv_sec - start.tv_sec - 1;
    diff.tv_nsec = 1000000000 + end.tv_nsec - start.tv_nsec;
  } else {
    diff.tv_sec = end.tv_sec - start.tv_sec;
    diff.tv_nsec = end.tv_nsec - start.tv_nsec;
  }

  long long time_in_nanos = diff.tv_sec * NANO + diff.tv_nsec;

  printf("Time: %lld ns\n", time_in_nanos);

  return diff;
}
