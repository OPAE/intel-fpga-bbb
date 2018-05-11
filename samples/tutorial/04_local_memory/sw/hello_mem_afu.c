// Copyright(c) 2017, Intel Corporation
//
// Redistribution  and  use  in source  and  binary  forms,  with  or  without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of  source code  must retain the  above copyright notice,
//   this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
// * Neither the name  of Intel Corporation  nor the names of its contributors
//   may be used to  endorse or promote  products derived  from this  software
//   without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,  BUT NOT LIMITED TO,  THE
// IMPLIED WARRANTIES OF  MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMEdesc.  IN NO EVENT  SHALL THE COPYRIGHT OWNER  OR CONTRIBUTORS BE
// LIABLE  FOR  ANY  DIRECT,  INDIRECT,  INCIDENTAL,  SPECIAL,  EXEMPLARY,  OR
// CONSEQUENTIAL  DAMAGES  (INCLUDING,  BUT  NOT LIMITED  TO,  PROCUREMENT  OF
// SUBSTITUTE GOODS OR SERVICES;  LOSS OF USE,  DATA, OR PROFITS;  OR BUSINESS
// INTERRUPTION)  HOWEVER CAUSED  AND ON ANY THEORY  OF LIABILITY,  WHETHER IN
// CONTRACT,  STRICT LIABILITY,  OR TORT  (INCLUDING NEGLIGENCE  OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,  EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <stdbool.h>
#include <uuid/uuid.h>
#include <opae/fpga.h>

// State from the AFU's JSON file, extracted using OPAE's afu_json_mgr script
#include "afu_json_info.h"

#define AFU_ID                   AFU_ACCEL_UUID  // Defined in afu_json_info.h
#define SCRATCH_REG              0X80
#define AVM_ADDRESS_REG          0x100
#define AVM_BURSTCOUNT_REG       0x108
#define AVM_RDWR_REG             0x110
#define AVM_WRITEDATA_REG        0x118
#define AVM_READDATA_REG         0x120
#define TESTMODE_CONTROL_REG     0x128
#define TESTMODE_STATUS_REG      0x180
#define AVM_RDWR_STATUS_REG      0x188
#define MEM_BANK_SELECT          0x190
#define READY_FOR_SW_CMD         0X198
#define AVM_BYTEENABLE_REG       0X1A0
// Record memory errors, write any value to clear
#define MEM_ERRORS               0X1A8

#define SCRATCH_VALUE            ((uint64_t)0xbaddcafedeadbeef)
#define SCRATCH_RESET            0
#define BYTE_OFFSET              8

#define AFU_DFH_REG              0x0
#define AFU_ID_LO                0x8 
#define AFU_ID_HI                0x10
#define AFU_NEXT                 0x18
#define AFU_RESERVED             0x20

static int s_error_count = 0;

typedef struct test_params {
   fpga_handle afc_handle;
   uint64_t test_data; 
   uint64_t burst_count;
   uint64_t mem_bank;
   uint64_t byteenable;
   bool use_ase;
   uint64_t start_address;
} test_params_t;

/*
 * macro to check return codes, print error message, and goto cleanup label
 * NOTE: this changes the program flow (uses goto)!
 */
#define ON_ERR_GOTO(res, label, desc)                    \
   do {                                       \
      if ((res) != FPGA_OK) {            \
         print_err((desc), (res));  \
         s_error_count += 1; \
         goto label;                \
      }                                  \
   } while (0)

/*
 * macro to check return codes, print error message, and goto cleanup label
 * NOTE: this changes the program flow (uses goto)!
 */
#define ASSERT_GOTO(condition, label, desc)                    \
   do {                                       \
      if (condition == 0) {            \
         fprintf(stderr, "Error %s\n", desc); \
         s_error_count += 1; \
         goto label;                \
      }                                  \
   } while (0)
      
void print_err(const char *s, fpga_result res)
{
   fprintf(stderr, "Error %s: %s\n", s, fpgaErrStr(res));
}

uint64_t expected_value(uint64_t burst_count, uint64_t write_data)
{
    // The burst count overwrites the high 10 bits of write data
    return (burst_count << (uint64_t)53) | (write_data & 0x3fffffffffffff);
}

// block till hw is ready to accept a new s/w command
fpga_result wait_cmd_ready(fpga_handle afc_handle, struct timespec sleep_time)
{
   uint64_t data = 0;
   fpga_result res;
   do {
      res = fpgaReadMMIO64(afc_handle, 0, READY_FOR_SW_CMD, &data);
      if(res != FPGA_OK)
         return res;
      nanosleep(&sleep_time, NULL);
   } while(data != 0x1);
   return FPGA_OK;
}

fpga_result run_test(test_params_t *params) 
{
   fpga_result res;
   uint64_t data = 0;
   struct timespec    sleep_time;
   
   if (params->use_ase) {
      sleep_time.tv_sec = 1;
      sleep_time.tv_nsec = 0;
   }
   else {
      sleep_time.tv_sec = 0;
      sleep_time.tv_nsec = 1000000;
   }
 
   res = wait_cmd_ready(params->afc_handle, sleep_time);
   if(res != FPGA_OK)
      return res;
   
   // Testmode Sweep
   fpgaWriteMMIO64(params->afc_handle, 0, AVM_WRITEDATA_REG, params->test_data);
   fpgaWriteMMIO64(params->afc_handle, 0, TESTMODE_CONTROL_REG, 1);

   res = wait_cmd_ready(params->afc_handle, sleep_time);
   if(res != FPGA_OK)
      return res;
   
   res = fpgaWriteMMIO32(params->afc_handle, 0, AVM_ADDRESS_REG, params->start_address);
   if(res != FPGA_OK)
      return res;

   // Clear memory errors
   fpgaWriteMMIO64(params->afc_handle, 0, MEM_ERRORS, (uint64_t)0);
   
   // Issue write
   fpgaWriteMMIO64(params->afc_handle, 0, AVM_WRITEDATA_REG, params->test_data);
   fpgaWriteMMIO64(params->afc_handle, 0, AVM_BURSTCOUNT_REG, params->burst_count);
   fpgaWriteMMIO64(params->afc_handle, 0, AVM_BYTEENABLE_REG, params->byteenable);      
   fpgaWriteMMIO64(params->afc_handle, 0, AVM_RDWR_REG, 1);

   res = wait_cmd_ready(params->afc_handle, sleep_time);
   if(res != FPGA_OK)
      return res;

   // wait for memory fsm to finish memory access
   do {
      res = fpgaReadMMIO64(params->afc_handle, 0, AVM_RDWR_STATUS_REG, &data);
      if(res != FPGA_OK)
         return res;      
      nanosleep(&sleep_time, NULL);
   } while(0x4 != (data & 0x4));

   // Issue read
   fpgaWriteMMIO64(params->afc_handle, 0, AVM_RDWR_REG, 3);
      
   res = wait_cmd_ready(params->afc_handle, sleep_time);
   if(res != FPGA_OK)
      return res;

   do {
      res = fpgaReadMMIO64(params->afc_handle, 0, AVM_RDWR_STATUS_REG, &data);
      if(res != FPGA_OK)
         return res;
      nanosleep(&sleep_time, NULL);
   } while(0x40 != (data&0x40));

   res = fpgaReadMMIO64(params->afc_handle, 0, AVM_READDATA_REG, &data);
   if(res != FPGA_OK)
      return res;

   // read memory errors
   fpgaReadMMIO64(params->afc_handle, 0, MEM_ERRORS, &data);
   if(data == 0) {
      printf("No memory errors. Test passed.\n");
      return FPGA_OK;
   }
   
   printf("Recorded %08lx memory errors\n", data);
   return FPGA_EXCEPTION;
}

bool probe_for_ase()
{
    fpga_result r = FPGA_OK;
    uint16_t device_id = 0;
    fpga_properties filter = NULL;
    uint32_t num_matches = 1;
    fpga_token fme_token;

    // Connect to the FPGA management engine
    fpgaGetProperties(NULL, &filter);
    fpgaPropertiesSetObjectType(filter, FPGA_DEVICE);

    // Connecting to one is sufficient to find ASE.
    fpgaEnumerate(&filter, 1, &fme_token, 1, &num_matches);
    if (0 != num_matches)
    {
        // Retrieve the device ID of the FME
        fpgaGetProperties(fme_token, &filter);
        r = fpgaPropertiesGetDeviceID(filter, &device_id);
        fpgaDestroyToken(&fme_token);
    }
    fpgaDestroyProperties(&filter);

    // ASE's device ID is 0xa5e
    return ((FPGA_OK == r) && (0xa5e == device_id));
}

int main(int argc, char *argv[])
{
   fpga_properties    filter = NULL;
   fpga_token         afc_token;
   fpga_handle        afc_handle;
   fpga_guid          guid;
   uint32_t           num_matches;
   uint32_t           bank, use_ase;
   uint32_t           num_mem_banks;
   // Access mandatory AFU registers
   uint64_t data = 0;
   fpga_result     res = FPGA_OK;
   test_params_t      params;
   
   if(argc < 2) {
      printf("Usage: hello_mem_afu <bank #>\n");
      return 1;
   }
   bank = atoi(argv[1]);

   use_ase = probe_for_ase();

   // AFU_ACCEL_UUID defined in afu_json_info.h
   if (uuid_parse(AFU_ACCEL_UUID, guid) < 0) {
      fprintf(stderr, "Error parsing guid '%s'\n", AFU_ACCEL_UUID);
      goto out_exit;
   }

   /* Look for AFC with MY_AFC_ID */
   res = fpgaGetProperties(NULL, &filter);
   ON_ERR_GOTO(res, out_exit, "creating properties object");

   res = fpgaPropertiesSetObjectType(filter, FPGA_ACCELERATOR);
   ON_ERR_GOTO(res, out_destroy_prop, "setting object type");

   res = fpgaPropertiesSetGUID(filter, guid);
   ON_ERR_GOTO(res, out_destroy_prop, "setting GUID");

   /* TODO: Add selection via BDF / device ID */
   res = fpgaEnumerate(&filter, 1, &afc_token, 1, &num_matches);
   ON_ERR_GOTO(res, out_destroy_prop, "enumerating AFCs");

   if (num_matches < 1) {
      fprintf(stderr, "AFC not found.\n");
      res = fpgaDestroyProperties(&filter);
      return FPGA_INVALID_PARAM;
   }

   /* Open AFC and map MMIO */
   res = fpgaOpen(afc_token, &afc_handle, 0);
   ON_ERR_GOTO(res, out_destroy_tok, "opening AFC");

   volatile uint64_t *mmio_ptr   = NULL;
   if(!use_ase) {
      res = fpgaMapMMIO(afc_handle, 0, (uint64_t**)&mmio_ptr);
      ON_ERR_GOTO(res, out_close, "mapping MMIO space");
   }

   printf("Running Test\n");

   /* Reset AFC */
   res = fpgaReset(afc_handle);
   ON_ERR_GOTO(res, out_close, "resetting AFC");

   do {
      res = fpgaReadMMIO64(afc_handle, 0, READY_FOR_SW_CMD, &data);
      ON_ERR_GOTO(res, out_close, "reading from MMIO");
   }while(data!=0x1);


   res = fpgaReadMMIO64(afc_handle, 0, AFU_DFH_REG, &data);
   ON_ERR_GOTO(res, out_close, "reading from MMIO");
   printf("AFU DFH REG = %08lx\n", data);
   
   res = fpgaReadMMIO64(afc_handle, 0, AFU_ID_LO, &data);
   ON_ERR_GOTO(res, out_close, "reading from MMIO");
   printf("AFU ID LO = %08lx\n", data);
   
   res = fpgaReadMMIO64(afc_handle, 0, AFU_ID_HI, &data);
   ON_ERR_GOTO(res, out_close, "reading from MMIO");
   printf("AFU ID HI = %08lx\n", data);
   
   res = fpgaReadMMIO64(afc_handle, 0, AFU_NEXT, &data);
   ON_ERR_GOTO(res, out_close, "reading from MMIO");
   printf("AFU NEXT = %08lx\n", data);
   
   res = fpgaReadMMIO64(afc_handle, 0, AFU_RESERVED, &data);
   ON_ERR_GOTO(res, out_close, "reading from MMIO");
   printf("AFU RESERVED = %08lx\n", data);
   
   // How many banks of memory are there?
   res = fpgaReadMMIO64(afc_handle, 0, TESTMODE_STATUS_REG, &data);
   ON_ERR_GOTO(res, out_close, "reading from MMIO");
   // Stored at bit 16
   num_mem_banks = (data >> 16);
   printf("NUM_LOCAL_MEM_BANKS = %d\n", num_mem_banks);
   ON_ERR_GOTO(bank >= num_mem_banks, out_close, "illegal bank number");

   // Access AFU user scratch-pad register
   res = fpgaReadMMIO64(afc_handle, 0, SCRATCH_REG, &data);
   ON_ERR_GOTO(res, out_close, "reading from MMIO");
   printf("Reading Scratch Register (Byte Offset=%08x) = %08lx\n", SCRATCH_REG, data);
   
   printf("MMIO Write to Scratch Register (Byte Offset=%08x) = %08lx\n", SCRATCH_REG, SCRATCH_VALUE);
   res = fpgaWriteMMIO64(afc_handle, 0, SCRATCH_REG, SCRATCH_VALUE);
   ON_ERR_GOTO(res, out_close, "writing to MMIO");
   
   res = fpgaReadMMIO64(afc_handle, 0, SCRATCH_REG, &data);
   ON_ERR_GOTO(res, out_close, "reading from MMIO");
   printf("Reading Scratch Register (Byte Offset=%08x) = %08lx\n", SCRATCH_REG, data);
   ASSERT_GOTO((data == SCRATCH_VALUE), out_close, "MMIO mismatched expected result");
   
   // Set Scratch Register to 0
   printf("Setting Scratch Register (Byte Offset=%08x) = %08x\n", SCRATCH_REG, SCRATCH_RESET);
   res = fpgaWriteMMIO64(afc_handle, 0, SCRATCH_REG, SCRATCH_RESET);
   ON_ERR_GOTO(res, out_close, "writing to MMIO");
   res = fpgaReadMMIO64(afc_handle, 0, SCRATCH_REG, &data);
   ON_ERR_GOTO(res, out_close, "reading from MMIO");
   printf("Reading Scratch Register (Byte Offset=%08x) = %08lx\n", SCRATCH_REG, data);
   ASSERT_GOTO((data == SCRATCH_RESET), out_close, "MMIO mismatched expected result");

   // Perform memory test for each bank
   printf("Testing memory bank %d\n",bank);
   res = fpgaWriteMMIO64(afc_handle, 0, MEM_BANK_SELECT, bank);
   ON_ERR_GOTO(res, out_close, "writing to MEM_BANK_SELECT");   
   
   /******************** Memory Test Starts Here *****************************/
   uint64_t mask = 0;      
   params.afc_handle = afc_handle;
   params.test_data = SCRATCH_VALUE;
   params.burst_count = 1;
   params.mem_bank = 0;
   params.byteenable = ~mask;
   params.use_ase = use_ase;
   params.start_address = 0x11;

   res = run_test(&params);
   ON_ERR_GOTO(res, out_unmap, "Memory test failed");   

   params.burst_count = 32;
   res = run_test(&params);
   ON_ERR_GOTO(res, out_unmap, "Memory test failed");   

   // Test byteenables
   // Datawidth is 64 bytes
   // Successively disable each byte, starting with LSB first 
   params.burst_count = 1;
   params.byteenable = ~mask;
   while(params.byteenable) {
      params.byteenable = params.byteenable << 16;
      res = run_test(&params);
      ON_ERR_GOTO(res, out_unmap, "Memory test failed");   
   }

   params.burst_count = 32;
   params.byteenable = ~mask;
   while(params.byteenable) {
      params.byteenable = params.byteenable << 16;
      res = run_test(&params);
      ON_ERR_GOTO(res, out_unmap, "Memory test failed");   
   }

   // Byteenables in the middle of a word
	params.byteenable = 0xffff << 16;
   res = run_test(&params);
   ON_ERR_GOTO(res, out_unmap, "Memory test failed");   

   printf("Done Running Test\n");

out_unmap:
   /* Unmap MMIO space */
   if(!use_ase) {
      res = fpgaUnmapMMIO(afc_handle, 0);
      ON_ERR_GOTO(res, out_close, "unmapping MMIO space");
   }
   
   /* Release accelerator */
out_close:
   res = fpgaClose(afc_handle);
   ON_ERR_GOTO(res, out_destroy_tok, "closing AFC");

   /* Destroy token */
out_destroy_tok:
   if(!use_ase) {
      res = fpgaDestroyToken(&afc_token);
      ON_ERR_GOTO(res, out_destroy_prop, "destroying token");
   }

   /* Destroy properties object */
out_destroy_prop:
   res = fpgaDestroyProperties(&filter);
   ON_ERR_GOTO(res, out_exit, "destroying properties object");

out_exit:
   if(s_error_count > 0)
      printf("Test FAILED!\n");

   return s_error_count;

}
