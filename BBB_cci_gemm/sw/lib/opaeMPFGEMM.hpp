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

#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <float.h>
#include <iostream>
#include <string>
#include <time.h>
#include "opae_svc_wrapper.h"
#include <math.h>
#include "gemmHelper.hpp"
#include "gemmLib.hpp"

using namespace std;

int usleep(unsigned);
#ifndef CL
# define CL(x)                       ((x) * 64)
#endif // CL
#ifndef LOG2_CL
# define LOG2_CL                     6
#endif // LOG2_CL
#ifndef MB
# define MB(x)                       ((x) * 1024 * 1024)
#endif // MB

#define CACHELINE_ALIGNED_ADDR(p) ((p) >> LOG2_CL)

#define LPBK1_DSM_SIZE MB(20)

#define NANO 1000000000LL

#define DSM_STATUS_TEST_COMPLETE 0x40
static const uint32_t	CSR_AFU_DSM_BASE = 0x0100;

static const uint32_t	CSR_VERSION = 0x0110;
static const uint32_t	CSR_CTL = 0x0118;
static const uint32_t   CSR_CFG = 0x0120;

static const uint32_t	CSR_SRC_ADDR_A = 0x0128;
static const uint32_t	CSR_SRC_ADDR_B = 0x0130;
static const uint32_t	CSR_SRC_ADDR_C = 0x0138;

static const uint32_t   CSR_NUM_BLOCKS = 0x0140;
static const uint32_t	CSR_NUM_PARTS_A = 0x0148;
static const uint32_t	CSR_NUM_PARTS_B = 0x0150;
static const uint32_t 	CSR_NUM_PARTS_C = 0x0158;

static const uint32_t 	CSR_NUM_ROWS_X_BLOCK = 0x0160;
static const uint32_t	CSR_NUM_COLS_X_BLOCK = 0x0168;
static const uint32_t	CSR_TEST_COMPLETE = 0x0170;
static const uint32_t	CSR_A_LEAD_INTERLEAVE = 0x0178;
static const uint32_t	CSR_B_LEAD_INTERLEAVE = 0x0180;
static const uint32_t	CSR_FEEDER_INTERLEAVE = 0x0188;
static const uint32_t 	CSR_FEEDER_INTERLEAVE_RND = 0x0190;
static const uint32_t	CSR_GAMMA = 0x0198;
static const uint32_t	CSR_BETA = 0x010A;

static const uint32_t	CSR_NUM_CLOCKS = 0x0300;
static const uint32_t	CSR_READ_BW = 0x0308;
static const uint32_t	CSR_WRITE_BW = 0x0310;
static const uint32_t	CSR_READ_PE_STALL = 0x0318;
static const uint32_t	CSR_WRITE_PE_STALL = 0x0320;
static const uint32_t	CSR_READ_MEM_ALMFULL = 0x0328;
static const uint32_t	CSR_WRITE_MEM_ALMFULL = 0x0330;
static const uint32_t	CSR_PE_COMPUTE_CLOCKS = 0x0338;

// DEBUG CSRs
// -- Feeder Controller
static const uint32_t	CSR_FSM_STATES = 0x0400;
static const uint32_t	CSR_NUM_WORKLOAD_A = 0x0408;
static const uint32_t	CSR_NUM_WORKLOAD_B = 0x0410;
static const uint32_t	CSR_NUM_WORKLOAD_BLOCK = 0x0418;
// -- PE Controller
static const uint32_t	CSR_PE_SECTIONS = 0x0420;
static const uint32_t	CSR_PE_BLOCKS = 0x0428;
static const uint32_t	CSR_PE_COMPLETED = 0x0430;



template <typename T1, typename T2>
class	opaeMPFGEMM {
	
 public:
 opaeMPFGEMM();
 ~opaeMPFGEMM() {};
 
 uint32_t	initGEMM(int, int, int, int, int, int,int, int, int );
 uint32_t	runGEMM(vector<T1> &matrixA, vector<T2> &matrixB, vector<T1> &matrixC,
					int, int, int, int, int, int, int, int, int, int, int, int,
					int, int, int, int, int);
 void 		cleanup();
 void		setMode(GEMM_MODE);
 void		setHW(bool);
 void		setPacked(bool);
 void		getOPAESVCHandle(GEMM_MODE);
 void		setPacking(bool);
 
 // To Do: Function for MPF Stats
 // To Do: Function for GEMM stats
 
 
 
 protected:
 
 uint32_t				m_Result;
 // Workspace info
 volatile uint64_t*		a_matrix;
 size_t					a_matrix_size;
 
 volatile uint64_t*		b_matrix;
 size_t					b_matrix_size;
 
 volatile uint64_t*		c_matrix;
 size_t					c_matrix_size;
 
 volatile uint64_t*		dsm_status;
 size_t					dsm_size;
 
 OPAE_SVC_WRAPPER*		fpga_gemm;
 GEMM_MODE				m_mode;
 bool 					m_is_hw;
 bool					m_is_packed;
 uint32_t				packing;
					
};

template<typename T1, typename T2>
void opaeMPFGEMM<T1, T2>::cleanup(){
	fpga_gemm->freeBuffer((void*)a_matrix);
	fpga_gemm->freeBuffer((void*)b_matrix);
	fpga_gemm->freeBuffer((void*)c_matrix);
	fpga_gemm->freeBuffer((void*)dsm_status);
}
template <typename T1, typename T2>
void opaeMPFGEMM<T1, T2>::getOPAESVCHandle(GEMM_MODE m_mode){

 if(m_is_hw){
	if ((m_mode == FP32) || (m_mode == TFP32)){
	fpga_gemm = new OPAE_SVC_WRAPPER("64f6fa35-6025-4e72-ad92-15c3a43173a9");
	assert(fpga_gemm->isOk());
	}
	else if((m_mode == FXD16) || (m_mode == TFXD16)) {
	fpga_gemm= new OPAE_SVC_WRAPPER("311791dc-97e9-4783-87b7-0d33b1190613");
	assert(fpga_gemm->isOk());
	}
	else if((m_mode == FXD8) || (m_mode == TFXD8)) {
	fpga_gemm = new OPAE_SVC_WRAPPER("da52758f-3f2a-45c1-89de-7762706430ea");
	assert(fpga_gemm->isOk());
	}
	else if(m_mode == FXD4){
	fpga_gemm = new OPAE_SVC_WRAPPER("eb8ad95c-cd7f-4689-8f08-be95163369e7");
	assert(fpga_gemm->isOk());
	}
	else if(m_mode == BINARY){
	fpga_gemm = new OPAE_SVC_WRAPPER("d0b60d89-f1ff-4082-9b76-7e339bc1d6b6");
	assert(fpga_gemm->isOk());
	}
 } // Simulation mode AFU ID
 else{
	 fpga_gemm = new OPAE_SVC_WRAPPER("c000c966-0d82-4272-9aef-fe5f84570612");
	 assert(fpga_gemm->isOk());
 }
 
}
template <typename T1, typename T2>
void opaeMPFGEMM<T1, T2>::setPacking(bool i_is_packed){
packing = m_is_packed ? 4: 1;
}
template <typename T1, typename T2>
void opaeMPFGEMM<T1, T2>::setMode(GEMM_MODE i_mode){
m_mode = i_mode;
}

template <typename T1, typename T2>
void opaeMPFGEMM<T1, T2>::setHW(bool i_is_hw){
m_is_hw = i_is_hw;
}

template <typename T1, typename T2>
void opaeMPFGEMM<T1, T2>::setPacked(bool i_is_packed){
m_is_packed = i_is_packed;
}

template <typename T1, typename T2>
uint32_t opaeMPFGEMM<T1, T2>::initGEMM( int num_partsa, int num_partsb,
										int num_blocks, int a_lead_interleave,
										int b_lead_interleave, int GEMM_ROWS,
										int GEMM_COLS, int COMM_WIDTH,
										int BUFFER_OFFSET){
			
// Calculating Buffer Sizes
   a_matrix_size = CL((static_cast<uint32_t>(a_lead_interleave) *
							  static_cast<uint32_t>(GEMM_ROWS) *
							  static_cast<uint32_t>(num_partsa)*
							  static_cast<uint32_t>(COMM_WIDTH)*
							  static_cast<uint32_t>(num_blocks))/16);
							  
  b_matrix_size = CL((static_cast<uint32_t>(b_lead_interleave) *
							  static_cast<uint32_t>(GEMM_COLS) *
							  static_cast<uint32_t>(num_partsb)*
							  static_cast<uint32_t>(COMM_WIDTH)*
							  static_cast<uint32_t>(num_blocks))/16);
			
			
  c_matrix_size = CL((static_cast<uint32_t>(a_lead_interleave) *
							  static_cast<uint32_t>(b_lead_interleave) *
							  static_cast<uint32_t>(GEMM_ROWS)*
							  static_cast<uint32_t>(num_partsa)*
							  static_cast<uint32_t>(num_partsb)));		
			
	dsm_size			 = 		LPBK1_DSM_SIZE;
			
  getOPAESVCHandle(m_mode);
			
  a_matrix = (volatile uint64_t*)fpga_gemm->allocBuffer(a_matrix_size);
  assert(NULL != a_matrix);
  b_matrix = (volatile uint64_t*)fpga_gemm->allocBuffer(b_matrix_size);
  assert(NULL != b_matrix);
  c_matrix = (volatile uint64_t*)fpga_gemm->allocBuffer(c_matrix_size);
  assert(NULL != c_matrix);
  dsm_status = (volatile uint64_t*)fpga_gemm->allocBuffer(dsm_size);
  
  if((NULL == a_matrix) || (NULL == b_matrix) || (NULL == c_matrix)) {
	m_Result = -1;
 }	  
   
  return m_Result;
}

template <typename T1, typename T2>
uint32_t opaeMPFGEMM<T1, T2>::runGEMM(
	vector<T1> &matrixA, vector<T2> &matrixB, vector<T1> &matrixC,
	int num_a_rows, int num_a_cols, int num_b_rows, int num_b_cols,
	int num_partsa, int num_partsb, int num_blocks, int a_lead_interleave,
	int b_lead_interleave, int feeder_interleave, int req_a_rows,
	int req_b_cols , int req_common, int GEMM_ROWS, int GEMM_COLS,
	int BUFFER_OFFSET, int PACK_SIZE) {
		
	std::cout<<"Running GEMM"<<std::endl;
	
	//Setup A
	struct cache_lineA{
	  T1 a[16];
	};
	
	cache_lineA *cl_a_matrix = (cache_lineA *)a_matrix;
	uint32_t clptr_a = 0;
	
	for (uint32_t i =0; i< (num_a_rows * num_a_cols) ; ++i) {
		if((i % 16)==0 && i!= 0) clptr_a++;
		cl_a_matrix[clptr_a].a[i % 16] = matrixA[i];
	}
	
	//Setup B
	struct cache_lineB{
	  T2 b[16];
	};
	
	cache_lineB *cl_b_matrix = (cache_lineB *)b_matrix;
	uint32_t clptr_b = 0;
	
	for (uint32_t i =0; i< (num_b_rows * num_b_cols) ; ++i) {
		if((i % 16)==0 && i!= 0) clptr_b++;
		cl_b_matrix[clptr_b].b[i % 16] = matrixB[i];
	}
	
	// Set DSM 
	
	fpga_gemm->mmioWrite64(CSR_AFU_DSM_BASE, intptr_t(dsm_status));
	// Set Input Workspace address for A
	fpga_gemm->mmioWrite64(CSR_SRC_ADDR_A,intptr_t(a_matrix)/CL(1));
	// Set Input Workspace address for B
	fpga_gemm->mmioWrite64(CSR_SRC_ADDR_B,intptr_t(b_matrix)/CL(1));
	// Set Input Workspace address for C
	fpga_gemm->mmioWrite64(CSR_SRC_ADDR_C,intptr_t(c_matrix)/CL(1));
	// Set GEMM Dynamic parameters
	fpga_gemm->mmioWrite64(CSR_A_LEAD_INTERLEAVE,a_lead_interleave);
	fpga_gemm->mmioWrite64(CSR_B_LEAD_INTERLEAVE,b_lead_interleave);
	fpga_gemm->mmioWrite64(CSR_FEEDER_INTERLEAVE,feeder_interleave);
	fpga_gemm->mmioWrite64(CSR_NUM_BLOCKS, num_blocks);
	fpga_gemm->mmioWrite64(CSR_NUM_PARTS_A, num_partsa);
	fpga_gemm->mmioWrite64(CSR_NUM_PARTS_B, num_partsb);
	fpga_gemm->mmioWrite64(CSR_NUM_PARTS_C, num_partsa*num_partsb);
	fpga_gemm->mmioWrite64(CSR_NUM_ROWS_X_BLOCK, GEMM_ROWS * num_blocks);
	fpga_gemm->mmioWrite64(CSR_NUM_COLS_X_BLOCK, GEMM_COLS * num_blocks);
	fpga_gemm->mmioWrite64(CSR_TEST_COMPLETE, ((GEMM_ROWS * a_lead_interleave * b_lead_interleave) * num_partsa *
	num_partsb)/ packing);
	
	volatile uint64_t*		status_ptr = (volatile uint64_t*)(intptr_t(dsm_status) +DSM_STATUS_TEST_COMPLETE);
	
	// Configure the AFU
	uint32_t wrreq_type = 0x0;
	uint32_t rdreq_type = 0x000;
	uint32_t chsel_type = 0x00000;
	fpga_gemm->mmioWrite64(CSR_CFG, wrreq_type + rdreq_type +chsel_type);
	
	long long total_write_req =
        (GEMM_ROWS * a_lead_interleave * b_lead_interleave) * num_partsa *
        num_partsb * packing;
	
	// Start GEMM Accelerator
	
	fpga_gemm->mmioWrite64(CSR_CTL, 1);
	
	long f = 0;
	//Wait for the GEMM Accelerator to Complete else time out!
	while ((0 == ((*status_ptr) & 0x1) && (f <1000000))){
		usleep(100);
		if(m_is_hw) f++;
	}
	// Stop GEMM Accelerator
	
	fpga_gemm->mmioWrite64(CSR_CTL, 7);
	std::cout<<"Done Running GEMM Accelerator!"<<std::endl;
	
	// Read back C Matrix
	
	struct cache_lineC {
	  T1 c[16];
	};
	
	cache_lineC *cl_c_matrix = (cache_lineC *)c_matrix;
	for( uint32_t i = 0; i < total_write_req; ++i) {
		for( uint32_t j = 0; j <16; ++j) {
			matrixC[i*16 + j] = cl_c_matrix[i].c[j];
		}
	}
	return 0;
	
}

template <typename T1, typename T2>
opaeMPFGEMM<T1, T2>::opaeMPFGEMM():
		m_Result(0),
		m_mode(FP32),		// Default mode for GEMM is always FP32
		packing(1),			// Deafult packing size for FP32
		m_is_packed(false),
		m_is_hw(false),		// Deafult it assumes it is running on ASE
        a_matrix(NULL),
        a_matrix_size(0),
        b_matrix(NULL),
        b_matrix_size(0),
        c_matrix(NULL),
        c_matrix_size(0),
        dsm_status(NULL),
        dsm_size(0),
        fpga_gemm(NULL){
		
		
}
/*
template <typename T1, typename T2>
opaeMPFGEMM<T1, T2>::~opaeMPFGEMM(){
	delete fpga_gemm;
}
*/        