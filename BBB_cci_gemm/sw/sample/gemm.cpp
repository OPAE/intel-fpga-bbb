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

#include "gemm.h"
#include <limits>

int main(int argc, char* argv[]) {
  GEMM_MODE mode = FP32;

  uint32_t req_a_rows = 320;
  uint32_t req_b_cols = 512;
  uint32_t req_common = 128;

  uint32_t a_lead_interleave = 32;
  uint32_t b_lead_interleave = 32;
  uint32_t feeder_interleave = 16;

  float alpha = 1.0;
  float beta = 0.0;

  GEMM_CHECK_MODE check_mode = GCM_EXACT;
  bool is_hw = false;
  bool is_packed = false;

  if (argc < 8) {
    printf("** ERROR: Cannot Parse Command Line\n");
    printf(
        "./gemm [MODE M N K A_Interleave B_Interleave F_Interleave Check_Mode] "
        "[--is-packed] [--is-hw]\n\n"
        "Performs matrix mulitplication\n\n"
        "\tC =  A      * B\n"
        "\t   M x K    K x N\n\n"
        "   using Systolic-GEMM\n\n"
        "MODE          GEMM Mode            (default:  FP32)\n"
        "M             Matrix A rows        (default:  320)\n"
        "N             Matrix B columns     (default:  512)\n"
        "K             Common dimension     (default:  128)\n"
        "A_Interleave  A Lead Interleave    (default:   32)\n"
        "B_Interleave  B Lead Interleave    (default:   32)\n"
        "F_Interleave  Feeder Interleave    (default:   16)\n"
        "Check_Mode    Results verification (default: Exact)\n"
        "--is-packed   Int8 results packed  (default: disabled)\n"
        "--is-hw       run test on hw       (default: disabled)\n");

    fflush(stdout);
    return 1;
  } else {
    char *str_arg;

    str_arg = argv[1];
    // Remove leading spaces from command line argument
    while(*str_arg != '\0' && *str_arg == ' ') str_arg++;
    if (!strcmp(str_arg, "FP32")) {
      mode = FP32;
    } else if (!strcmp(str_arg, "FXD16")) {
      mode = FXD16;
    } else if (!strcmp(str_arg, "FXD8")) {
      mode = FXD8;
    } else if (!strcmp(str_arg, "FXD4")) {
      mode = FXD4;
    } else if (!strcmp(str_arg, "BINARY")) {
      mode = BINARY;
    } else if (!strcmp(str_arg, "TFP32")) {
      mode = TFP32;
    } else if (!strcmp(str_arg, "TFXD16")) {
      mode = TFXD16;
    } else if (!strcmp(str_arg, "TFXD8")) {
      mode = TFXD8;
    } else {
      std::cout << "Error: Not a valid mode (" << str_arg << ")" << std::endl;
      exit(1);
    }
    req_a_rows = (uint32_t)atoi(argv[2]);
	req_b_cols = (uint32_t)atoi(argv[3]);
    req_common = (uint32_t)atoi(argv[4]);
    a_lead_interleave = (uint32_t)atoi(argv[5]);
    b_lead_interleave = (uint32_t)atoi(argv[6]);
    feeder_interleave = (uint32_t)atoi(argv[7]);
	
	// Add checkers for all the GEMM parameters
	if( req_a_rows <= 0 || req_a_rows > numeric_limits<int>::max()){
		std::cout<< "Invalid req_a_rows value!"<<std::endl;
		exit(1);
	}
	if( req_b_cols <= 0 || req_b_cols > numeric_limits<int>::max()){
		std::cout<< "Invalid req_b_rows value!"<<std::endl;
		exit(1);
	}
	if( req_common <= 0 || req_common > numeric_limits<int>::max()){
		std::cout<< "Invalid req_common value!"<<std::endl;
		exit(1);
	}
	if( a_lead_interleave <= 0 || a_lead_interleave > 32) {
		std::cout<<"Invalid a_lead_interleave size!"<<std::endl;
		exit(1);
	}
	if( b_lead_interleave <= 0 || b_lead_interleave > 32) {
		std::cout<<"Invalid b_lead_interleave size!"<<std::endl;
		exit(1);
	}

	if( feeder_interleave < 2 || feeder_interleave > 16) {
		std::cout<<"Invalid feeder_interleave size!"<<std::endl;
		exit(1);
	}
	str_arg = argv[8];
    // Remove leading spaces from command line argument
    while(*str_arg != '\0' && *str_arg == ' ') str_arg++;
    if (!strcasecmp(str_arg, "None")) {
      check_mode = GCM_NONE;
    } else if (!strcasecmp(str_arg, "Exact")) {
      check_mode = GCM_EXACT;
    } else if (!strcasecmp(str_arg, "MKL")) {
      check_mode = GCM_MKL;
    } else {
      std::cout << "Error: Not a valid check_mode (" << str_arg << ")" << std::endl;
      exit(1);
    }
    
    if (argc > 9) {
      for (int i = 9; i < argc; i++) {
        if (!strcmp(argv[i], "--is-hw")) {
          is_hw = true;
        } else if (!strcmp(argv[i], "--is-packed")) {
          is_packed = true;
        }
      }
    }
  }
  
  int res = 0;
  switch (mode) {
    case FP32: {
      gemmRunner<float, float> runner(req_a_rows, req_b_cols, req_common,
                                      a_lead_interleave, b_lead_interleave,
                                      feeder_interleave, alpha, beta, check_mode,
                                      is_hw, is_packed, FP32);
      runner.prepareRandomA();
      runner.prepareRandomB();
      runner.prepareRandomC();
      res = runner.run();
      if(!res) {
        runner.abscaling();
        res = runner.validate();
      }
      break;
    }
    case TFP32: {
      gemmRunner<float, int> runner(req_a_rows, req_b_cols, req_common,
                                    a_lead_interleave, b_lead_interleave,
                                    feeder_interleave, alpha, beta, check_mode,
                                    is_hw, is_packed, TFP32);
      runner.prepareRandomA();
      runner.prepareRandomB();
      runner.prepareRandomC();
      res = runner.run();
      if(!res) {
        runner.abscaling();
        res = runner.validate();
      }
      break;
    }
    default: {
      gemmRunner<int, int> runner(req_a_rows, req_b_cols, req_common,
                                  a_lead_interleave, b_lead_interleave,
                                  feeder_interleave, alpha, beta, check_mode,
                                  is_hw, is_packed, mode);
      runner.prepareRandomA();
      runner.prepareRandomB();
      runner.prepareRandomC();
      res = runner.run();
      if(!res) {
        runner.abscaling();
        res = runner.validate();
      }
      break;
    }
  }
  return res;
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
