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

#include <time.h>

#ifdef MKL
#include "mkl.h"
#endif

#ifdef __cplusplus
extern "C" {
#endif

enum GEMM_MODE { FP32, FXD16, FXD8, FXD4, BINARY, TFP32, TFXD16, TFXD8 };
enum GEMM_CHECK_MODE { GCM_NONE = 0, GCM_EXACT = 1, GCM_MKL = 2};

#ifndef MKL
typedef enum CBLAS_ORDER {
  CblasRowMajor = 101,
  CblasColMajor = 102
} CBLAS_ORDER;

typedef enum CBLAS_TRANSPOSE {
  CblasNoTrans = 111,
  CblasTrans = 112,
  CblasConjTrans = 113,
  CblasConjNoTrans = 114
} CBLAS_TRANSPOSE;
#endif

#define PERF_DBG
#define PERF_DBG_PERFORMANCE
#define PERF_DBG_DEBUG
#define OPAE
#define MPF_PLATFORM_BDX

int config_afu_sgemm(const char *pathname);

void cblas_afu_sgemm(const CBLAS_ORDER Order,
                     const CBLAS_TRANSPOSE TransA,
                     const CBLAS_TRANSPOSE TransB, const int M, const int N,
                     const int K, const float alpha, float *A, const int lda,
                     float *B, const int ldb, const float beta, float *C,
                     const int ldc);

timespec start_timer();
timespec end_timer(timespec start);

#ifdef __cplusplus
}
#endif
