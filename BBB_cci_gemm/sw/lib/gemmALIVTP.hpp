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

#include <aalsdk/AALTypes.h>
#include <aalsdk/Runtime.h>
#include <aalsdk/AALLoggerExtern.h>

#include <string.h>

#include "gemmLib.hpp"

// MPF Include
#include "IMPF.h"

using namespace std;
using namespace AAL;

// Convenience macros for printing messages and errors.
#ifdef MSG
#undef MSG
#endif  // MSG
#define MSG(x)                                                              \
  std::cout << __AAL_SHORT_FILE__ << ':' << __LINE__ << ':' << __AAL_FUNC__ \
            << "() : " << x << std::endl
#ifdef ERR
#undef ERR
#endif  // ERR
#define ERR(x)                                                              \
  std::cerr << __AAL_SHORT_FILE__ << ':' << __LINE__ << ':' << __AAL_FUNC__ \
            << "() **Error : " << x << std::endl

// Print/don't print the event ID's entered in the event handlers.
#if 1
#define EVENT_CASE(x) \
  case x:             \
    MSG(#x);
#else
#define EVENT_CASE(x) case x:
#endif

#ifndef CL
#define CL(x) ((x)*64)
#endif  // CL
#ifndef LOG2_CL
#define LOG2_CL 6
#endif  // LOG2_CL
#ifndef MB
#define MB(x) ((x)*1024 * 1024)
#endif  // MB

#define LPBK1_DSM_SIZE MB(20)

#define NANO 1000000000LL

#define DSM_STATUS_TEST_COMPLETE 0x40
static const uint32_t CSR_AFU_DSM_BASE = 0x0100;

static const uint32_t CSR_VERSION = 0x0110;
static const uint32_t CSR_CTL = 0x0118;
static const uint32_t CSR_CFG = 0x0120;

static const uint32_t CSR_SRC_ADDR_A = 0x0128;
static const uint32_t CSR_SRC_ADDR_B = 0x0130;
static const uint32_t CSR_DST_ADDR_C = 0x0138;

static const uint32_t CSR_NUM_BLOCKS = 0x0140;
static const uint32_t CSR_NUM_PARTS_A = 0x0148;
static const uint32_t CSR_NUM_PARTS_B = 0x0150;
static const uint32_t CSR_NUM_PARTS_C = 0x0158;

static const uint32_t CSR_NUM_ROWS_X_BLOCK = 0x0160;
static const uint32_t CSR_NUM_COLS_X_BLOCK = 0x0168;
static const uint32_t CSR_TEST_COMPLETE = 0x0170;
static const uint32_t CSR_A_LEAD_INTERLEAVE = 0x178;
static const uint32_t CSR_B_LEAD_INTERLEAVE = 0x180;
static const uint32_t CSR_FEEDER_INTERLEAVE = 0x188;
static const uint32_t CSR_FEEDER_INTERLEAVE_RND = 0x190;
static const uint32_t CSR_GAMMA = 0x198;
static const uint32_t CSR_BETA = 0x10A;

static const uint32_t CSR_NUM_CLOCKS = 0x0300;
static const uint32_t CSR_READ_BW = 0x0308;
static const uint32_t CSR_WRITE_BW = 0x0310;
static const uint32_t CSR_READ_PE_STALL = 0x0318;
static const uint32_t CSR_WRITE_PE_STALL = 0x0320;
static const uint32_t CSR_READ_MEM_ALMFULL = 0x0328;
static const uint32_t CSR_WRITE_MEM_ALMFULL = 0x0330;
static const uint32_t CSR_PE_COMPUTE_CLOCKS = 0x0338;

// Debug CSRs
// -- Feeder Controller
static const uint32_t CSR_FSM_STATES = 0x0400;
static const uint32_t CSR_NUM_WORKLOAD_A = 0x0408;
static const uint32_t CSR_NUM_WORKLOAD_B = 0x0410;
static const uint32_t CSR_NUM_WORKLOAD_BLOCK = 0x0418;
// -- PE Controller
static const uint32_t CSR_PE_SECTIONS = 0x0420;
static const uint32_t CSR_PE_BLOCKS = 0x0428;
static const uint32_t CSR_PE_COMPLETED = 0x0430;

template <typename T1, typename T2>
class gemmALIVTP : public CAASBase,
                   public IRuntimeClient,
                   public IServiceClient,
                   public IALIReconfigure_Client {
 public:
  gemmALIVTP();
  ~gemmALIVTP();

  btInt configSGEMM(const char *pathname);
  btInt initSGEMM(int, int, int, int, int, int, int, int, int);
  btInt runSGEMM(vector<T1> &matrixA, vector<T2> &matrixB, vector<T1> &matrixC,
                 int, int, int, int, int, int, int, int, int, int, int, int,
                 int, int, int, int,
                 int);  ///< Return 0 if success
  btInt cleanup();

  void setMode(GEMM_MODE);
  void setHW(bool);
  void setPacked(bool);

  // <begin IServiceClient interface>
  void serviceAllocated(IBase *pServiceBase, TransactionID const &rTranID);

  void serviceAllocateFailed(const IEvent &rEvent);

  void serviceReleased(const AAL::TransactionID &);
  void serviceReleaseRequest(IBase *pServiceBase, const IEvent &rEvent);
  void serviceReleaseFailed(const AAL::IEvent &);

  void serviceEvent(const IEvent &rEvent);
  // <end IServiceClient interface>

  // <begin IRuntimeClient interface>
  void runtimeCreateOrGetProxyFailed(IEvent const &rEvent){};  // Not Used

  void runtimeStarted(IRuntime *pRuntime, const NamedValueSet &rConfigParms);

  void runtimeStopped(IRuntime *pRuntime);

  void runtimeStartFailed(const IEvent &rEvent);

  void runtimeStopFailed(const IEvent &rEvent);

  void runtimeAllocateServiceFailed(IEvent const &rEvent);

  void runtimeAllocateServiceSucceeded(IBase *pClient,
                                       TransactionID const &rTranID);

  void runtimeEvent(const IEvent &rEvent);

  btBool isOK() { return m_bIsOK; }

  // <end IRuntimeClient interface>

  // <IALIReconfigure_Client interface>
  virtual void deactivateSucceeded(TransactionID const &rTranID);
  virtual void deactivateFailed(IEvent const &rEvent);
  virtual void configureSucceeded(TransactionID const &rTranID);
  virtual void configureFailed(IEvent const &rEvent);
  virtual void activateSucceeded(TransactionID const &rTranID);
  virtual void activateFailed(IEvent const &rEvent);
  // <end IALIReconfigure_Client interface>
  void PrintReconfExceptionDescription(IEvent const &theEvent);

 protected:
  Runtime m_Runtime;     ///< AAL Runtime
  IBase *m_pAALService;  ///< The generic AAL Service interface for the AFU.
  IALIBuffer *m_pALIBufferService;  ///< Pointer to Buffer Service
  IALIMMIO *m_pALIMMIOService;      ///< Pointer to MMIO Service
  IALIReset *m_pALIResetService;    ///< Pointer to AFU Reset Service
  CSemaphore m_Sem;                 ///< For synchronizing with the AAL runtime.
  btInt m_Result;                   ///< Returned result value; 0 if success
  TransactionID m_ALIAFUTranID;

  // VTP Service Info
  IBase *m_pVTP_AALService;
  IMPFVTP *m_pVTPService;
  btCSROffset m_VTPDFHOffset;
  TransactionID m_VTPTranID;

  // FME Service Info
  IBase *m_pFMEAALService;  ///< The generic AAL Service interface for the FME
  IALIMMIO *m_pFMEMMIOService;  ///< Pointer to MMIO Service
  TransactionID m_tranIDFME;    ///< Transaction ID for FME service

  // PR Service Info
  IBase *m_pALIReconfAALService;  ///< The generic AAL Service interface for the
                                  ///Reconf.
  IALIReconfigure *m_pALIReconfService;  ///< Pointer to Buffer Service
  TransactionID m_tranIDPR;              ///< Transaction ID for PR service

  // Workspace info
  btVirtAddr m_pDSM;   ///< DSM workspace virtual address.
  btWSSize m_DSMSize;  ///< DSM workspace size in bytes.

  btVirtAddr m_pInput;   ///< Input workspace virtual address.
  btWSSize m_InputSize;  ///< Input workspace size in bytes.

  btVirtAddr m_pInputB;   ///< Input workspace virtual address.
  btWSSize m_InputSizeB;  ///< Input workspace size in bytes.

  btVirtAddr m_pOutputC;   ///< Output workspace virtual address.
  btWSSize m_OutputSizeC;  ///< Output workspace size in bytes.
  btUnsigned64bitInt m_vtp_debug;
  t_cci_mpf_vtp_stats mpf_stats;
  btUnsigned64bitInt m_mpf_num_address_translation_fail;  ///< Number for failed
  /// address translation
  /// in MPF>

  GEMM_MODE m_mode;
  bool m_is_hw;
  bool m_is_packed;
};

template <typename T1, typename T2>
void gemmALIVTP<T1, T2>::setMode(GEMM_MODE i_mode) {
  m_mode = i_mode;
}

template <typename T1, typename T2>
void gemmALIVTP<T1, T2>::setHW(bool i_is_hw) {
  m_is_hw = i_is_hw;
}

template <typename T1, typename T2>
void gemmALIVTP<T1, T2>::setPacked(bool i_is_packed) {
  m_is_packed = i_is_packed;
}

template <typename T1, typename T2>
btInt gemmALIVTP<T1, T2>::configSGEMM(const char *pathname) {
  struct ALIConfigCommandLine {
    btUIntPtr flags;
#define ALICONIFG_CMD_FLAG_HELP 0x00000001
#define ALICONIFG_CMD_FLAG_VERSION 0x00000002
#define ALICONIFG_CMD_PARSE_ERROR 0x00000003

#define ALICONIFG_CMD_FLAG_BUS 0x00000008
#define ALICONIFG_CMD_FLAG_DEV 0x00000010
#define ALICONIFG_CMD_FLAG_FUNC 0x00000020

    char bitstream_file[200];
    int reconftimeout;
    int reconfAction;
    bool reactivateDisabled;
    int bus;
    int device;
    int function;
  };
  struct ALIConfigCommandLine configCmdLine = {0, "", 1, 0, 0, 0, 0, 0};

  // Copy in the name of the file to configure from
  strncpy(configCmdLine.bitstream_file, pathname,
          sizeof(configCmdLine.bitstream_file) - 1);
  configCmdLine.bitstream_file[sizeof(configCmdLine.bitstream_file) - 1] = 0;

  // Verify the specified file name
  std::ifstream bitfile(configCmdLine.bitstream_file, std::ios::binary);
  if (!bitfile.good()) {
    printf("Invalid File : %s\n", configCmdLine.bitstream_file);
    return 3;
  }

  cout << "=============================" << endl;
  cout << "= ALI AFU Configure Sample  =" << endl;
  cout << "=============================" << endl;

  // Request the Servcie we are interested in.

  // NOTE: This example is bypassing the Resource Manager's configuration record
  // lookup
  //  mechanism.  Since the Resource Manager Implementation is a sample, it is
  //  subject to change.
  //  This example does illustrate the utility of having different
  //  implementations of a service all
  //  readily available and bound at run-time.
  NamedValueSet Manifest;
  NamedValueSet ConfigArgs;
  NamedValueSet ConfigRecord;
  NamedValueSet reconfnvs;

  if (m_is_hw) {
    // Specify that the remote resource manager is to be used.
    ConfigRecord.Add(AALRUNTIME_CONFIG_BROKER_SERVICE, "librrmbroker");
    ConfigArgs.Add(AALRUNTIME_CONFIG_RECORD, &ConfigRecord);
  }

  // Start the Runtime and wait for the callback by sitting on the semaphore.
  //  the runtimeStarted() or runtimeStartFailed() callbacks should set m_bIsOK
  //  appropriately.
  if (!m_Runtime.start(ConfigArgs)) {
    m_bIsOK = false;
    return -1;
  }
  m_Sem.Wait();

  //
  // Check green bitstream file agains BBS interface ID
  //  The BBS interface ID is retrieved from FME registers
  //
  btUnsigned32bitInt magic;
  btUnsigned64bitInt expected_ifid_l;
  btUnsigned64bitInt expected_ifid_h;
  btUnsigned64bitInt bitstream_id;
  btUnsigned64bitInt ifid_l;
  btUnsigned64bitInt ifid_h;

  // Read and check metadata header
  bitfile.read((char *)&magic, sizeof(magic));
  if (magic !=
      0x1d1f8680) {  // little endian, magic sequence is 0x80 0x86 0x1f 0x1d
    ERR(configCmdLine.bitstream_file
        << " does not appear to be a valid GBS file (header mismatch).");
    goto done_0;
  }

  // Read and store expected bitstream ID from GBS metadata
  bitfile.read((char *)&expected_ifid_l, sizeof(expected_ifid_l));
  bitfile.read((char *)&expected_ifid_h, sizeof(expected_ifid_h));

  // Read interface ID off blue bitstream (FME registers)
  //  this functionality will eventually be part of the driver
  //  FME_PR_INTFC_ID_L: FME offset 0x50A8
  //  FME_PR_INTFC_ID_H: FME offset 0x50B0

  // Prepare FME service allocation
  ConfigRecord.Add(AAL_FACTORY_CREATE_CONFIGRECORD_FULL_SERVICE_NAME, "libALI");
  ConfigRecord.Add(keyRegAFU_ID, CCIP_FME_AFUID);

  // Select specific bus/device/function, if desired
  if (flag_is_set(configCmdLine.flags, ALICONIFG_CMD_FLAG_BUS)) {
    ConfigRecord.Add(keyRegBusNumber, btUnsigned32bitInt(configCmdLine.bus));
  }
  if (flag_is_set(configCmdLine.flags, ALICONIFG_CMD_FLAG_DEV)) {
    ConfigRecord.Add(keyRegDeviceNumber,
                     btUnsigned32bitInt(configCmdLine.device));
  }
  if (flag_is_set(configCmdLine.flags, ALICONIFG_CMD_FLAG_FUNC)) {
    ConfigRecord.Add(keyRegFunctionNumber,
                     btUnsigned32bitInt(configCmdLine.function));
  }
  Manifest.Add(AAL_FACTORY_CREATE_CONFIGRECORD_INCLUDED, &ConfigRecord);
  Manifest.Add(AAL_FACTORY_CREATE_SERVICENAME, "FME");

  // Allocate FME service
  MSG("Allocating FME Service to check interface ID");
  m_Runtime.allocService(dynamic_cast<IBase *>(this), Manifest, m_tranIDFME);
  m_Sem.Wait();
  if (!m_bIsOK) {
    ERR("Allocation failed\n");
    goto done_0;
  }

  // Read FME CSRs
  m_pFMEMMIOService->mmioRead64(0x60, &bitstream_id);
  m_pFMEMMIOService->mmioRead64(0x50A8, &ifid_l);
  m_pFMEMMIOService->mmioRead64(0x50B0, &ifid_h);
  MSG("BBS bitstream ID is 0x" << std::hex << bitstream_id << std::dec);
  MSG("BBS interface ID is 0x" << std::hex << ifid_h << ifid_l << std::dec);

  // Release FME service
  MSG("Releasing FME Service");
  (dynamic_ptr<IAALService>(iidService, m_pFMEAALService))
      ->Release(TransactionID());
  m_Sem.Wait();

  // Compare expected and actual interface ID
  if (expected_ifid_l != ifid_l || expected_ifid_h != ifid_h) {
    ERR("BBS interface ID does not match GBS metadata (0x"
        << std::hex << expected_ifid_h << expected_ifid_l << ")");
    goto done_0;
  }
  MSG("Interface ID matches");

  // Clear ConfigRecord and Manifest for next service allocation
  ConfigRecord.Empty();
  Manifest.Empty();

  //
  // Allocate PR service
  //

  if (m_is_hw) {
    // Service Library to use
    ConfigRecord.Add(AAL_FACTORY_CREATE_CONFIGRECORD_FULL_SERVICE_NAME,
                     "libALI");

    // the AFUID to be passed to the Resource Manager. It will be used to locate
    // the appropriate device.
    ConfigRecord.Add(keyRegAFU_ID, ALI_AFUID_UAFU_CONFIG);

    ConfigRecord.Add(keyRegSubDeviceNumber, 0);

    if (flag_is_set(configCmdLine.flags, ALICONIFG_CMD_FLAG_BUS)) {
      ConfigRecord.Add(keyRegBusNumber, btUnsigned32bitInt(configCmdLine.bus));
    }
    if (flag_is_set(configCmdLine.flags, ALICONIFG_CMD_FLAG_DEV)) {
      ConfigRecord.Add(keyRegDeviceNumber,
                       btUnsigned32bitInt(configCmdLine.device));
    }
    if (flag_is_set(configCmdLine.flags, ALICONIFG_CMD_FLAG_FUNC)) {
      ConfigRecord.Add(keyRegFunctionNumber,
                       btUnsigned32bitInt(configCmdLine.function));
    }
  } else {
    Manifest.Add(keyRegHandle, 20);

    ConfigRecord.Add(AAL_FACTORY_CREATE_CONFIGRECORD_FULL_SERVICE_NAME,
                     "libASEALIAFU");
    ConfigRecord.Add(AAL_FACTORY_CREATE_SOFTWARE_SERVICE, true);
  }

  // Add the Config Record to the Manifest describing what we want to allocate
  Manifest.Add(AAL_FACTORY_CREATE_CONFIGRECORD_INCLUDED, &ConfigRecord);

  // in future, everything could be figured out by just giving the service name
  Manifest.Add(AAL_FACTORY_CREATE_SERVICENAME, "ALI Conf AFU");

  MSG("Allocating Service");

  // Allocate the Service and wait for it to complete by sitting on the
  //  semaphore. The serviceAllocated() callback will be called if successful.
  //  If allocation fails the serviceAllocateFailed() should set m_bIsOK
  //  appropriately.
  //  (Refer to the serviceAllocated() callback to see how the Service's
  //  interfaces
  //   are collected.)
  m_Runtime.allocService(dynamic_cast<IBase *>(this), Manifest, m_tranIDPR);
  m_Sem.Wait();
  if (!m_bIsOK) {
    ERR("Allocation failed\n");
    goto done_0;
  }

  //=============================
  // Now we have the ALIReconfigure Service
  //  now we can use it
  //=============================
  MSG("Running Test");
  if (true == m_bIsOK) {
    // Reconfigure timeout
    reconfnvs.Add(
        AALCONF_MILLI_TIMEOUT,
        (static_cast<btUnsigned64bitInt>(configCmdLine.reconftimeout)) * 1000);

    // Reconfigure action
    if (AALCONF_RECONF_ACTION_HONOR_OWNER_ID == configCmdLine.reconfAction) {
      reconfnvs.Add(AALCONF_RECONF_ACTION,
                    AALCONF_RECONF_ACTION_HONOR_OWNER_ID);
    } else {
      reconfnvs.Add(AALCONF_RECONF_ACTION,
                    AALCONF_RECONF_ACTION_HONOR_REQUEST_ID);
    }

    // ReActivated state
    if (configCmdLine.reactivateDisabled) {
      reconfnvs.Add(AALCONF_REACTIVATE_DISABLED, true);
    } else {
      reconfnvs.Add(AALCONF_REACTIVATE_DISABLED, false);
    }

    // reconfnvs.Add(AALCONF_FILENAMEKEY,"/home/lab/pr/bitstream.rbf");
    reconfnvs.Add(AALCONF_FILENAMEKEY, configCmdLine.bitstream_file);

    /*// Deactivate AFU Resource
    m_pALIReconfService->reconfDeactivate(TransactionID(), reconfnvs);
    m_Sem.Wait();
    if(!m_bIsOK){
      ERR("Deactivate failed\n");
      goto done_1;
    }*/

    // reconfigure with Bitstream
    m_pALIReconfService->reconfConfigure(TransactionID(), reconfnvs);
    m_Sem.Wait();
    if (!m_bIsOK) {
      ERR("ReConfigure failed\n");
      goto done_1;
    }

    // reactivate AFU Resource
    if (configCmdLine.reactivateDisabled) {
      m_pALIReconfService->reconfActivate(TransactionID(), NamedValueSet());
      m_Sem.Wait();
      if (!m_bIsOK) {
        ERR("Activate failed\n");
        goto done_1;
      }
    }
  }
  MSG("Done Running Test");

done_1:
  // Clean-up and return
  // Release() the Service through the Services IAALService::Release() method
  MSG("Release Service");
  (dynamic_ptr<IAALService>(iidService, m_pALIReconfAALService))
      ->Release(TransactionID());
  m_Sem.Wait();

done_0:
  m_Runtime.stop();
  m_Sem.Wait();

  return m_Result;
}

template <typename T1, typename T2>
btInt gemmALIVTP<T1, T2>::runSGEMM(
    vector<T1> &matrixA, vector<T2> &matrixB, vector<T1> &matrixC,
    int num_a_rows, int num_a_cols, int num_b_rows, int num_b_cols,
    int num_partsa, int num_partsb, int num_blocks, int a_lead_interleave,
    int b_lead_interleave, int feeder_interleave, int req_a_rows,
    int req_b_cols, int req_common, int SGEMM_ROWS, int SGEMM_COLS,
    int BUFFER_OFFSET, int PACK_SIZE) {
  bt64bitInt errpos = -1;
  btVirtAddr p1;
  btVirtAddr p2;
  btInt exit_state = 0;
  //=============================
  // Now we have the NLB Service
  //   now we can use it
  //=============================
  MSG("Running Test");

  if (true == m_bIsOK) {
    // Clear the DSM
    ::memset(m_pDSM, 0, m_DSMSize);

    // Initialize the source and destination buffers
    ::memset(m_pInput, 0, m_InputSize);      // Input initialized to 0
    ::memset(m_pInputB, 0, m_InputSizeB);    // Input initialized to 0
    ::memset(m_pOutputC, 0, m_OutputSizeC);  // Output initialized to 0

    // Setup A
    MSG("Matrix A");
    struct CacheLineA {  // Operate on cache lines
      T1 a[16];
    };
    struct CacheLineA *pCLA = reinterpret_cast<struct CacheLineA *>(m_pInput);
    int clptr_a = 0;

    for (btUnsigned32bitInt i = 0; i < (num_a_rows * num_a_cols); i++) {
      if ((i % (16) == 0) && i != 0) clptr_a++;
      pCLA[clptr_a].a[i % (16)] = matrixA[i];
    }

    // Setup B
    MSG("Matrix B");
    struct CacheLineB {  // Operate on cache lines
      T2 b[16];
    };

    struct CacheLineB *pCLB = reinterpret_cast<struct CacheLineB *>(m_pInputB);
    int clptr_b = 0;

    for (btUnsigned32bitInt i = 0; i < (num_b_rows * num_b_cols); i++) {
      if ((i % (16) == 0) && i != 0) clptr_b++;
      pCLB[clptr_b].b[i % (16)] = matrixB[i];
    }

    // Original code puts DSM Reset prior to AFU Reset, but ccipTest
    //    reverses that. We are following ccipTest here.

    // Initiate AFU Reset
    m_pALIResetService->afuReset();

    // Initiate VTP Reset
    m_pVTPService->vtpReset();

    // Initiate DSM Reset
    MSG("DSM base set");
    // Set DSM base, high then low
    m_pALIMMIOService->mmioWrite64(CSR_AFU_DSM_BASE,
                                   (btUnsigned64bitInt)m_pDSM);

    MSG("Set input workspace");
    // Set input workspace address for A
    m_pALIMMIOService->mmioWrite64(CSR_SRC_ADDR_A,
                                   (btUnsigned64bitInt)(m_pInput) / CL(1));

    // Set input workspace address for B
    m_pALIMMIOService->mmioWrite64(CSR_SRC_ADDR_B,
                                   (btUnsigned64bitInt)(m_pInputB) / CL(1));

    MSG("Set output workspace");
    // Set output workspace address
    m_pALIMMIOService->mmioWrite64(CSR_DST_ADDR_C,
                                   (btUnsigned64bitInt)(m_pOutputC) / CL(1));

    MSG("Test Parameters");
    m_pALIMMIOService->mmioWrite64(CSR_A_LEAD_INTERLEAVE, a_lead_interleave);
    m_pALIMMIOService->mmioWrite64(CSR_B_LEAD_INTERLEAVE, b_lead_interleave);
    m_pALIMMIOService->mmioWrite64(CSR_FEEDER_INTERLEAVE, feeder_interleave);
    //m_pALIMMIOService->mmioWrite64(CSR_FEEDER_INTERLEAVE_RND,
    //                               feeder_interleave + (feeder_interleave % 2));

    // Set the number of blocks inside 1 workload
    m_pALIMMIOService->mmioWrite64(CSR_NUM_BLOCKS, num_blocks);

    // Set the number of workloads (A mxn -> m/320 for 10 NUM_ROWS)
    m_pALIMMIOService->mmioWrite64(CSR_NUM_PARTS_A, num_partsa);

    // Set the number of workloads (B nxk -> k/512 for 16 NUM_COL)
    m_pALIMMIOService->mmioWrite64(CSR_NUM_PARTS_B, num_partsb);

    m_pALIMMIOService->mmioWrite64(CSR_NUM_PARTS_C, num_partsb * num_partsa);
    m_pALIMMIOService->mmioWrite64(CSR_NUM_ROWS_X_BLOCK,
                                   SGEMM_ROWS * num_blocks);
    m_pALIMMIOService->mmioWrite64(CSR_NUM_COLS_X_BLOCK,
                                   SGEMM_COLS * num_blocks);
	
   int packing = m_is_packed ? 4 : 1;

    m_pALIMMIOService->mmioWrite64(
        CSR_TEST_COMPLETE,
        ((SGEMM_ROWS * a_lead_interleave * b_lead_interleave) * num_partsa *
         num_partsb) /
            packing);

    volatile bt32bitCSR *StatusAddr =
        (volatile bt32bitCSR *)(m_pDSM + DSM_STATUS_TEST_COMPLETE);

    // Configure the AFU
    uint32_t wrreq_type = 0x0;
    uint32_t rdreq_type = 0x000;
    uint32_t chsel_type = 0x00000;
    m_pALIMMIOService->mmioWrite64(CSR_CFG,
                                   wrreq_type + rdreq_type + chsel_type);
	
	m_pALIMMIOService->mmioWrite64(CSR_GAMMA,0x40000000);
    m_pALIMMIOService->mmioWrite64(CSR_BETA,0x40400000);

    // Start the Timer
    timespec start = start_timer();

    MSG("Start the test");
    // Start the test
    m_pALIMMIOService->mmioWrite64(CSR_CTL, 1);

    long f = 0;

    long long total_a_read_req = clptr_a;
    long long total_b_read_req = clptr_b;
    long long total_read_req = total_a_read_req + total_b_read_req;
    long long total_write_req =
        (SGEMM_ROWS * a_lead_interleave * b_lead_interleave) * num_partsa *
        num_partsb * packing;

    btUnsigned64bitInt curr_read[1];
    btUnsigned64bitInt curr_write[1];

    int barWidth = 20;

    // Wait for test completion
    while ((0 == ((*StatusAddr) & 0x1)) && (f < 1000000)) {
      SleepMicro(100);
      if (m_is_hw) {
        f++;
      }
    }
    if(0 == ((*StatusAddr) & 0x1)) {
      exit_state = -1;
      printf("ERROR: GEMM Timed Out during execution\n");
    }
    std::cout << std::endl;
    // End the Timer
    timespec diff = end_timer(start);

    m_pVTPService->vtpGetStats(&mpf_stats);

    m_mpf_num_address_translation_fail = mpf_stats.numFailedTranslations;
    cout << "Num of TLBHitsF:" << mpf_stats.numTLBHits4KB << endl;
    cout << "Num of Failed Address translation in MPF:"
         << m_mpf_num_address_translation_fail << endl;
    cout << "Num of TLBMisses:" << mpf_stats.numTLBMisses4KB << endl;
    cout << "Num of WalkBusyCycles:" << mpf_stats.numPTWalkBusyCycles << endl;
    cout << "Num of TLBHits2MB:" << mpf_stats.numTLBHits2MB << endl;
    cout << "Num of TLBMisses2MB:" << mpf_stats.numTLBMisses2MB << endl;

    // Total Number of Operations
    long long total_op = (long long)2 * (long long)num_a_rows *
                         (long long)num_b_cols * (long long)num_a_cols *
                         (long long)PACK_SIZE;

    // Total Number of Operations
    long long total_req_op = (long long)2 * (long long)req_a_rows *
                             (long long)req_b_cols * (long long)req_common;

    // Total Time taken in Seconds
    double time_in_secs = diff.tv_sec + (double)diff.tv_nsec / ((double)NANO);

    // OPs - Operations Per Second
    double ops = (double)total_op / time_in_secs;
    double req_ops = (double)total_req_op / time_in_secs;

    printf("OPs: %.2e\n", ops);
    printf("REQ OPs: %.2e\n", req_ops);
    MSG("Done Running Test");

#ifdef PERF_DBG
    // Read out the Stats
    btUnsigned64bitInt num_clocks[1];
    m_pALIMMIOService->mmioRead64(CSR_NUM_CLOCKS, num_clocks);
    printf("CLOCK: %ld\n", num_clocks[0]);

#ifdef PERF_DBG_PERFORMANCE
    btUnsigned64bitInt read_bw[1];
    btUnsigned64bitInt write_bw[1];
    btUnsigned64bitInt read_pe_stall[1];
    btUnsigned64bitInt write_pe_stall[1];
    btUnsigned64bitInt read_mem_almfull[1];
    btUnsigned64bitInt write_mem_almfull[1];
    btUnsigned64bitInt pe_compute_clocks[1];

    m_pALIMMIOService->mmioRead64(CSR_READ_BW, read_bw);
    m_pALIMMIOService->mmioRead64(CSR_WRITE_BW, write_bw);
    m_pALIMMIOService->mmioRead64(CSR_READ_PE_STALL, read_pe_stall);
    m_pALIMMIOService->mmioRead64(CSR_WRITE_PE_STALL, write_pe_stall);
    m_pALIMMIOService->mmioRead64(CSR_READ_MEM_ALMFULL, read_mem_almfull);
    m_pALIMMIOService->mmioRead64(CSR_WRITE_MEM_ALMFULL, write_mem_almfull);
    m_pALIMMIOService->mmioRead64(CSR_PE_COMPUTE_CLOCKS, pe_compute_clocks);

    //
    printf("READ_BW: %ld\n", read_bw[0]);
    printf("WRITE_BW: %ld\n", write_bw[0]);
    printf("READ_PE_STALL: %ld\n", read_pe_stall[0]);
    printf("WRITE_PE_STALL: %ld\n", write_pe_stall[0]);
    printf("READ_MEM_ALMFULL: %ld\n", read_mem_almfull[0]);
    printf("WRITE_MEM_ALMFULL: %ld\n", write_mem_almfull[0]);
    printf("PE_COMPUTE_CLOCKS: %ld\n", pe_compute_clocks[0]);
#endif
#ifdef PERF_DBG_DEBUG
    btUnsigned64bitInt fsm_states[1];
    btUnsigned64bitInt num_workload_a[1];
    btUnsigned64bitInt num_workload_b[1];
    btUnsigned64bitInt num_workload_block[1];
    btUnsigned64bitInt pe_sections[1];
    btUnsigned64bitInt pe_blocks[1];
    btUnsigned64bitInt pe_completed[1];

    m_pALIMMIOService->mmioRead64(CSR_FSM_STATES, fsm_states);
    m_pALIMMIOService->mmioRead64(CSR_NUM_WORKLOAD_A, num_workload_a);
    m_pALIMMIOService->mmioRead64(CSR_NUM_WORKLOAD_B, num_workload_b);
    m_pALIMMIOService->mmioRead64(CSR_NUM_WORKLOAD_BLOCK, num_workload_block);
    m_pALIMMIOService->mmioRead64(CSR_PE_SECTIONS, pe_sections);
    m_pALIMMIOService->mmioRead64(CSR_PE_BLOCKS, pe_blocks);
    m_pALIMMIOService->mmioRead64(CSR_PE_COMPLETED, pe_completed);

    printf("FSM_STATES: %ld\n", fsm_states[0]);
    printf("NUM_WORKLOAD_A: %ld\n", num_workload_a[0]);
    printf("NUM_WORKLOAD_B: %ld\n", num_workload_b[0]);
    printf("NUM_WORKLOAD_BLOCK: %ld\n", num_workload_block[0]);
    printf("PE_SECTIONS: %ld\n", pe_sections[0]);
    printf("PE_BLOCKS: %ld\n", pe_blocks[0]);
    printf("PE_COMPLETED: %ld\n", pe_completed[0]);
#endif
#endif

    // Stop the device
    m_pALIMMIOService->mmioWrite32(CSR_CTL, 7);

    MSG("C Matrix");

    struct CacheLineC {
      T1 c[16];
    };

    struct CacheLineC *pCLC = reinterpret_cast<struct CacheLineC *>(m_pOutputC);
    for (btUnsigned32bitInt i = 0; i < total_write_req; ++i) {
      for (btUnsigned32bitInt j = 0; j < 16; ++j) {
        matrixC[i * 16 + j] = pCLC[i].c[j];
      }
    }
  }
  MSG("Done Running Test");
  return exit_state;
}

template <typename T1, typename T2>
gemmALIVTP<T1, T2>::gemmALIVTP()
    : m_Runtime(this),
      m_pAALService(NULL),
      m_pALIBufferService(NULL),
      m_pALIMMIOService(NULL),
      m_pALIResetService(NULL),
      m_Result(0),

      m_pVTP_AALService(NULL),
      m_pVTPService(NULL),
      m_VTPDFHOffset(-1),

      m_pFMEAALService(NULL),
      m_pFMEMMIOService(NULL),

      m_pALIReconfAALService(NULL),
      m_pALIReconfService(NULL),

      m_pDSM(NULL),
      m_DSMSize(0),

      m_pInput(NULL),
      m_InputSize(0),

      m_pInputB(NULL),
      m_InputSizeB(0),

      m_pOutputC(NULL),
      m_OutputSizeC(0),

      m_ALIAFUTranID(),
      m_VTPTranID(),
      m_tranIDFME(),
      m_tranIDPR() {
  // Register our Client side interfaces so that the Service can acquire them.
  //   SetInterface() is inherited from CAASBase
  SetInterface(iidServiceClient, dynamic_cast<IServiceClient *>(this));
  SetInterface(iidRuntimeClient, dynamic_cast<IRuntimeClient *>(this));
  SetInterface(iidALI_CONF_Service_Client,
               dynamic_cast<IALIReconfigure_Client *>(this));

  // Initialize our internal semaphore
  m_Sem.Create(0, 1);
  m_bIsOK = true;
}

template <typename T1, typename T2>
gemmALIVTP<T1, T2>::~gemmALIVTP() {
  m_Sem.Destroy();
}

template <typename T1, typename T2>
btInt gemmALIVTP<T1, T2>::initSGEMM(int num_partsa, int num_partsb,
                                    int num_blocks, int a_lead_interleave,
                                    int b_lead_interleave, int SGEMM_ROWS,
                                    int SGEMM_COLS, int COMM_WIDTH,
                                    int BUFFER_OFFSET) {
  // Calculating Buffer Sizes
  btWSSize a_buffer_size = CL((static_cast<btWSSize> (a_lead_interleave) * 
                               static_cast<btWSSize> (SGEMM_ROWS) * 
                               static_cast<btWSSize> (num_partsa) *
                               static_cast<btWSSize> (COMM_WIDTH) *
                               static_cast<btWSSize> (num_blocks))/ (16));
                                                 
  btWSSize b_buffer_size = CL((static_cast<btWSSize> (b_lead_interleave) *
                               static_cast<btWSSize> (SGEMM_COLS) * 
                               static_cast<btWSSize> (num_partsb) *
                               static_cast<btWSSize> (COMM_WIDTH) * 
                               static_cast<btWSSize> (num_blocks)) / (16));
  
  btWSSize c_buffer_size = CL(static_cast<btWSSize> (a_lead_interleave) * 
                              static_cast<btWSSize> (b_lead_interleave) * 
                              static_cast<btWSSize> (SGEMM_ROWS) *
                              static_cast<btWSSize> (num_partsa) * 
                              static_cast<btWSSize> (num_partsb));

  // Start the AAL Runtime, setting any startup options via a NamedValueSet

  // Using Hardware Services requires the Remote Resource Manager Broker Service
  //  Note that this could also be accomplished by setting the environment
  //  variable
  //   AALRUNTIME_CONFIG_BROKER_SERVICE to librrmbroker
  NamedValueSet Manifest;
  NamedValueSet ConfigArgs;
  NamedValueSet ConfigRecord;

  if (m_is_hw) {
    // Specify that the remote resource manager is to be used.
    ConfigRecord.Add(AALRUNTIME_CONFIG_BROKER_SERVICE, "librrmbroker");
    ConfigArgs.Add(AALRUNTIME_CONFIG_RECORD, &ConfigRecord);
  }

  // Start the Runtime and wait for the callback by sitting on the semaphore.
  //   the runtimeStarted() or runtimeStartFailed() callbacks should set m_bIsOK
  //   appropriately.
  if (!m_Runtime.start(ConfigArgs)) {
    m_bIsOK = false;
    return -1;
  }
  m_Sem.Wait();

  if (m_is_hw) {
    ConfigRecord.Add(AAL_FACTORY_CREATE_CONFIGRECORD_FULL_SERVICE_NAME,
                     "libALI");
    if ((m_mode == FP32) || (m_mode == TFP32))
      ConfigRecord.Add(keyRegAFU_ID, "64F6FA35-6025-4E72-AD92-15C3A43173A9");
    else if ((m_mode == FXD16) || (m_mode == TFXD16))
      ConfigRecord.Add(keyRegAFU_ID, "311791DC-97E9-4783-87B7-0D33B1190613");
    else if ((m_mode == FXD8) || (m_mode == TFXD8))
      ConfigRecord.Add(keyRegAFU_ID, "DA52758F-3F2A-45C1-89DE-7762706430EA");
    else if (m_mode == FXD4)
      ConfigRecord.Add(keyRegAFU_ID, "EB8AD95C-CD7F-4689-8F08-BE95163369E7");
    else if (m_mode == BINARY)
      ConfigRecord.Add(keyRegAFU_ID, "D0B60D89-F1FF-4082-9B76-7E339BC1D6B6");
    else {
      ERR("Define a Mode");
      exit(1);
    }
  } else {  // ASE
    Manifest.Add(keyRegHandle, 20);

    Manifest.Add(ALIAFU_NVS_KEY_TARGET, ali_afu_ase);

    ConfigRecord.Add(AAL_FACTORY_CREATE_CONFIGRECORD_FULL_SERVICE_NAME,
                     "libALI");
    ConfigRecord.Add(AAL_FACTORY_CREATE_SOFTWARE_SERVICE, true);
  }

  Manifest.Add(AAL_FACTORY_CREATE_CONFIGRECORD_INCLUDED, &ConfigRecord);
  Manifest.Add(AAL_FACTORY_CREATE_SERVICENAME, "Systolic GEMM Bring-Up SW");
  MSG("Allocating Service");

  m_Runtime.allocService(dynamic_cast<IBase *>(this), Manifest, m_ALIAFUTranID);
  m_Sem.Wait();
  if (!m_bIsOK) {
    ERR("Allocation failed\n");
    goto done_0;
  }

  Manifest.Empty();
  ConfigRecord.Empty();

  ConfigRecord.Add(AAL_FACTORY_CREATE_CONFIGRECORD_FULL_SERVICE_NAME, "libMPF");
  ConfigRecord.Add(AAL_FACTORY_CREATE_SOFTWARE_SERVICE, true);

  Manifest.Add(AAL_FACTORY_CREATE_CONFIGRECORD_INCLUDED, &ConfigRecord);
  Manifest.Add(ALIAFU_IBASE_KEY,
               static_cast<ALIAFU_IBASE_DATATYPE>(m_pAALService));
  Manifest.Add(MPF_FEATURE_ID_KEY, static_cast<MPF_FEATURE_ID_DATATYPE>(1));
  Manifest.Add(AAL_FACTORY_CREATE_SERVICENAME, "VTP");
  MSG("Allocating VTP Service");

  m_Runtime.allocService(dynamic_cast<IBase *>(this), Manifest, m_VTPTranID);
  m_Sem.Wait();
  if (!m_bIsOK) {
    ERR("VTP Service allocation failed\n");
    goto done_0;
  }

  if (ali_errnumOK != m_pVTPService->bufferAllocate(LPBK1_DSM_SIZE, &m_pDSM)) {
    m_bIsOK = false;
    m_Result = -1;
    goto done_2;
  }

  // Save the size
  m_DSMSize = LPBK1_DSM_SIZE;

  // Repeat for the Input and Output Buffers
  if (ali_errnumOK != m_pVTPService->bufferAllocate(a_buffer_size, &m_pInput)) {
    m_bIsOK = false;
    m_Sem.Post(1);
    m_Result = -1;
    goto done_3;
  }

  m_InputSize = a_buffer_size;

  if (ali_errnumOK !=
      m_pVTPService->bufferAllocate(b_buffer_size, &m_pInputB)) {
    m_bIsOK = false;
    m_Sem.Post(1);
    m_Result = -1;
    goto done_4;
  }

  m_InputSizeB = b_buffer_size;

  if (ali_errnumOK !=
      m_pVTPService->bufferAllocate(c_buffer_size, &m_pOutputC)) {
    m_bIsOK = false;
    m_Sem.Post(1);
    m_Result = -1;
    goto done_6;
  }

  m_OutputSizeC = c_buffer_size;

  return m_Result;

// Clean-up and return
done_6:
  m_pVTPService->bufferFree(m_pOutputC);
done_5:
  m_pVTPService->bufferFree(m_pInputB);
done_4:
  m_pVTPService->bufferFree(m_pInput);
done_3:
  m_pVTPService->bufferFree(m_pDSM);

done_2:
  // Freed all three so now Release() the VTP Service through the Services
  // IAALService::Release() method
  (dynamic_ptr<IAALService>(iidService, m_pVTP_AALService))
      ->Release(TransactionID());
  m_Sem.Wait();

done_1:
  // Freed all three so now Release() the Service through the Services
  // IAALService::Release() method
  (dynamic_ptr<IAALService>(iidService, m_pAALService))
      ->Release(TransactionID());
  m_Sem.Wait();

done_0:
  m_Runtime.stop();
  m_Sem.Wait();

  return m_Result;
}

template <typename T1, typename T2>
btInt gemmALIVTP<T1, T2>::cleanup() {
  // Clean-up and return
  m_pVTPService->bufferFree(m_pOutputC);
  m_pVTPService->bufferFree(m_pInputB);
  m_pVTPService->bufferFree(m_pInput);
  m_pVTPService->bufferFree(m_pDSM);

  // Freed all three so now Release() the VTP Service through the Services
  // IAALService::Release() method
  (dynamic_ptr<IAALService>(iidService, m_pVTP_AALService))
      ->Release(TransactionID());
  m_Sem.Wait();

  // Freed all three so now Release() the Service through the Services
  // IAALService::Release() method
  (dynamic_ptr<IAALService>(iidService, m_pAALService))
      ->Release(TransactionID());
  m_Sem.Wait();

  m_Runtime.stop();
  m_Sem.Wait();

  return 0;
}

//=================
//  IServiceClient
//=================

// <begin IServiceClient interface>
template <typename T1, typename T2>
void gemmALIVTP<T1, T2>::serviceAllocated(IBase *pServiceBase,
                                          TransactionID const &rTranID) {
  // This application will allocate two different services (HWALIAFU and
  //  VTPService). We can tell them apart here by looking at the TransactionID.
  if (rTranID == m_ALIAFUTranID) {
    // Save the IBase for the Service. Through it we can get any other
    //  interface implemented by the Service
    m_pAALService = pServiceBase;
    ASSERT(NULL != m_pAALService);
    if (NULL == m_pAALService) {
      m_bIsOK = false;
      return;
    }

    // Documentation says HWALIAFU Service publishes
    //    IALIBuffer as subclass interface. Used in Buffer Allocation and Free
    m_pALIBufferService =
        dynamic_ptr<IALIBuffer>(iidALI_BUFF_Service, pServiceBase);
    ASSERT(NULL != m_pALIBufferService);
    if (NULL == m_pALIBufferService) {
      m_bIsOK = false;
      return;
    }

    // Documentation says HWALIAFU Service publishes
    //    IALIMMIO as subclass interface. Used to set/get MMIO Region
    m_pALIMMIOService =
        dynamic_ptr<IALIMMIO>(iidALI_MMIO_Service, pServiceBase);
    ASSERT(NULL != m_pALIMMIOService);
    if (NULL == m_pALIMMIOService) {
      m_bIsOK = false;
      return;
    }

    // Documentation says HWALIAFU Service publishes
    //    IALIReset as subclass interface. Used for resetting the AFU
    m_pALIResetService =
        dynamic_ptr<IALIReset>(iidALI_RSET_Service, pServiceBase);
    ASSERT(NULL != m_pALIResetService);
    if (NULL == m_pALIResetService) {
      m_bIsOK = false;
      return;
    }
  } else if (rTranID == m_VTPTranID) {
    // Save the IBase for the VTP Service.
    m_pVTP_AALService = pServiceBase;
    ASSERT(NULL != m_pVTP_AALService);
    if (NULL == m_pVTP_AALService) {
      m_bIsOK = false;
      return;
    }

    // Documentation says VTP Service publishes
    //    IVTP as subclass interface. Used for allocating shared
    //    buffers that support virtual addresses from AFU
    m_pVTPService = dynamic_ptr<IMPFVTP>(iidMPFVTPService, pServiceBase);
    ASSERT(NULL != m_pVTPService);
    if (NULL == m_pVTPService) {
      m_bIsOK = false;
      return;
    }
  } else if (rTranID == m_tranIDFME) {
    // FME service allocated:
    //   Save generic service pointer and IALIMMIO pointer to FME service
    m_pFMEAALService = pServiceBase;
    ASSERT(NULL != m_pFMEAALService);
    if (NULL == m_pFMEAALService) {
      m_bIsOK = false;
      return;
    }

    m_pFMEMMIOService =
        dynamic_ptr<IALIMMIO>(iidALI_MMIO_Service, pServiceBase);
    ASSERT(NULL != m_pFMEMMIOService);
    if (NULL == m_pFMEMMIOService) {
      m_bIsOK = false;
      return;
    }
  } else if (rTranID == m_tranIDPR) {
    // PR service allocated:
    //   Save generic service pointer and IALIReconfigure pointer to PR
    //   service
    m_pALIReconfAALService = pServiceBase;
    ASSERT(NULL != m_pALIReconfAALService);
    if (NULL == m_pALIReconfAALService) {
      m_bIsOK = false;
      return;
    }

    m_pALIReconfService =
        dynamic_ptr<IALIReconfigure>(iidALI_CONF_Service, pServiceBase);
    ASSERT(NULL != m_pALIReconfService);
    if (NULL == m_pALIReconfService) {
      m_bIsOK = false;
      return;
    }
  } else {
    ERR("Unknown transaction ID encountered on serviceAllocated().");
    m_bIsOK = false;
    return;
  }

  MSG("Service Allocated");
  m_Sem.Post(1);
}

template <typename T1, typename T2>
void gemmALIVTP<T1, T2>::serviceAllocateFailed(const IEvent &rEvent) {
  ERR("Failed to allocate Service");
  PrintExceptionDescription(rEvent);
  ++m_Result;  // Remember the error
  m_bIsOK = false;

  m_Sem.Post(1);
}

template <typename T1, typename T2>
void gemmALIVTP<T1, T2>::serviceReleased(TransactionID const &rTranID) {
  MSG("Service Released");
  // Unblock Main()
  m_Sem.Post(1);
}

template <typename T1, typename T2>
void gemmALIVTP<T1, T2>::serviceReleaseRequest(IBase *pServiceBase,
                                               const IEvent &rEvent) {
  MSG("Service unexpected requested back");
  if (NULL != m_pAALService) {
    IAALService *pIAALService =
        dynamic_ptr<IAALService>(iidService, m_pAALService);
    ASSERT(pIAALService);
    pIAALService->Release(TransactionID());
  }
}

template <typename T1, typename T2>
void gemmALIVTP<T1, T2>::serviceReleaseFailed(const IEvent &rEvent) {
  ERR("Failed to release a Service");
  PrintExceptionDescription(rEvent);
  m_bIsOK = false;
  m_Sem.Post(1);
}

template <typename T1, typename T2>
void gemmALIVTP<T1, T2>::serviceEvent(const IEvent &rEvent) {
  ERR("unexpected event 0x" << hex << rEvent.SubClassID());
  // The state machine may or may not stop here. It depends upon what happened.
  // A fatal error implies no more messages and so none of the other Post()
  //    will wake up.
  // OTOH, a notification message will simply print and continue.
}
// <end IServiceClient interface>

//=================
//  IRuntimeClient
//=================

// <begin IRuntimeClient interface>
// Because this simple example has one object implementing both IRuntieCLient
// and IServiceClient
//   some of these interfaces are redundant. We use the IServiceClient in such
//   cases and ignore
//   the RuntimeClient equivalent e.g.,. runtimeAllocateServiceSucceeded()

template <typename T1, typename T2>
void gemmALIVTP<T1, T2>::runtimeStarted(IRuntime *pRuntime,
                                        const NamedValueSet &rConfigParms) {
  m_bIsOK = true;
  m_Sem.Post(1);
}

template <typename T1, typename T2>
void gemmALIVTP<T1, T2>::runtimeStopped(IRuntime *pRuntime) {
  MSG("Runtime stopped");
  m_bIsOK = false;
  m_Sem.Post(1);
}

template <typename T1, typename T2>
void gemmALIVTP<T1, T2>::runtimeStartFailed(const IEvent &rEvent) {
  ERR("Runtime start failed");
  PrintExceptionDescription(rEvent);
}

template <typename T1, typename T2>
void gemmALIVTP<T1, T2>::runtimeStopFailed(const IEvent &rEvent) {
  MSG("Runtime stop failed");
  m_bIsOK = false;
  m_Sem.Post(1);
}

template <typename T1, typename T2>
void gemmALIVTP<T1, T2>::runtimeAllocateServiceFailed(IEvent const &rEvent) {
  ERR("Runtime AllocateService failed");
  PrintExceptionDescription(rEvent);
}

template <typename T1, typename T2>
void gemmALIVTP<T1, T2>::runtimeAllocateServiceSucceeded(
    IBase *pClient, TransactionID const &rTranID) {
  MSG("Runtime Allocate Service Succeeded");
}

template <typename T1, typename T2>
void gemmALIVTP<T1, T2>::runtimeEvent(const IEvent &rEvent) {
  MSG("Generic message handler (runtime)");
}

// <begin IALIReconfigure_Client interface>
template <typename T1, typename T2>
void gemmALIVTP<T1, T2>::deactivateSucceeded(TransactionID const &rTranID) {
  MSG("deactivateSucceeded");
  m_Sem.Post(1);
}

template <typename T1, typename T2>
void gemmALIVTP<T1, T2>::deactivateFailed(IEvent const &rEvent) {
  ERR("Failed deactivate");
  PrintExceptionDescription(rEvent);
  PrintReconfExceptionDescription(rEvent);
  ++m_Result;  // Remember the error
  m_bIsOK = false;
  m_Sem.Post(1);
}

template <typename T1, typename T2>
void gemmALIVTP<T1, T2>::configureSucceeded(TransactionID const &rTranID) {
  MSG("configureSucceeded");
  m_Sem.Post(1);
}

template <typename T1, typename T2>
void gemmALIVTP<T1, T2>::configureFailed(IEvent const &rEvent) {
  ERR("configureFailed");
  PrintExceptionDescription(rEvent);
  PrintReconfExceptionDescription(rEvent);
  ++m_Result;  // Remember the error
  m_bIsOK = false;
  m_Sem.Post(1);
}

template <typename T1, typename T2>
void gemmALIVTP<T1, T2>::activateSucceeded(TransactionID const &rTranID) {
  MSG("activateSucceeded");
  m_Sem.Post(1);
}

template <typename T1, typename T2>
void gemmALIVTP<T1, T2>::activateFailed(IEvent const &rEvent) {
  ERR("activateFailed");
  PrintExceptionDescription(rEvent);
  PrintReconfExceptionDescription(rEvent);
  ++m_Result;  // Remember the error
  m_bIsOK = false;
  m_Sem.Post(1);
}

template <typename T1, typename T2>
void gemmALIVTP<T1, T2>::PrintReconfExceptionDescription(IEvent const &rEvent) {
  if (rEvent.Has(iidExTranEvent)) {
    std::cerr << "Description: "
              << dynamic_ref<IExceptionTransactionEvent>(iidExTranEvent, rEvent)
                     .Description() << std::endl;
    std::cerr << "ExceptionNumber: "
              << dynamic_ref<IExceptionTransactionEvent>(iidExTranEvent, rEvent)
                     .ExceptionNumber() << std::endl;
    std::cerr << "Reason: "
              << dynamic_ref<IExceptionTransactionEvent>(iidExTranEvent, rEvent)
                     .Reason() << std::endl;
  }
}
