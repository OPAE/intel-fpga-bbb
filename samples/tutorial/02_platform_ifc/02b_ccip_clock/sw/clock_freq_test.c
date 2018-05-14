//
// Copyright (c) 2018, Intel Corporation
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

#define CLOCK_FREQ_TEST_AFU_ID  AFU_ACCEL_UUID  // Defined in afu_json_info.h

#define AFU_DFH_REG              0x0
#define AFU_ID_LO                0x8 
#define AFU_ID_HI                0x10
#define AFU_NEXT                 0x18

static int s_error_count = 0;

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


void print_err(const char *s, fpga_result res)
{
    fprintf(stderr, "Error %s: %s\n", s, fpgaErrStr(res));
}


void mmio_read_64(fpga_handle afc_handle, uint64_t addr, uint64_t *data, const char *reg_name)
{
    fpga_result res = fpgaReadMMIO64(afc_handle, 0, addr, data);
    if (res != FPGA_OK)
    {
        print_err("mmio_read_64 failure", res);
        exit(1);
    }

    printf("Reading %s (Byte Offset=%08lx) = %08lx\n", reg_name, addr, *data);
}


void mmio_write_64(fpga_handle afc_handle, uint64_t addr, uint64_t data, const char *reg_name)
{
    fpga_result res = fpgaWriteMMIO64(afc_handle, 0, addr, data);
    if (res != FPGA_OK)
    {
        print_err("mmio_write_64 failure", res);
        exit(1);
    }
    printf("MMIO Write to %s (Byte Offset=%08lx) = %08lx\n", reg_name, addr, data);
}


void print_clock_freq(
    const char *name,
    double clock_counter,
    double pclock_counter,
    double pclock_freq
)
{
    printf("  %s \t%0.1f MHz\n", name, pclock_freq * clock_counter / pclock_counter);
}


void read_final_counters(fpga_handle afc_handle)
{
    uint64_t counter_pclk_value;
    mmio_read_64(afc_handle, 0x28*4, &counter_pclk_value, "counter_pclk_value");
    uint64_t counter_pclk_div2_value;
    mmio_read_64(afc_handle, 0x2a*4, &counter_pclk_div2_value, "counter_pclk_div2_value");
    uint64_t counter_pclk_div4_value;
    mmio_read_64(afc_handle, 0x2c*4, &counter_pclk_div4_value, "counter_pclk_div4_value");
    uint64_t counter_clkusr_value;
    mmio_read_64(afc_handle, 0x2e*4, &counter_clkusr_value, "counter_clkusr_value");
    uint64_t counter_clkusr_div2_value;
    mmio_read_64(afc_handle, 0x30*4, &counter_clkusr_div2_value, "counter_clkusr_div2_value");
    uint64_t counter_clk_value;
    mmio_read_64(afc_handle, 0x32*4, &counter_clk_value, "counter_clk_value");

    uint64_t pclk_freq_value;
    mmio_read_64(afc_handle, 0x34*4, &pclk_freq_value, "pclk_freq_value");
    float PCLK_FREQUENCY = (float)pclk_freq_value;

    printf("\nStandard clocks:\n");
    printf("  pClk \t\t%0.1f MHz\n", PCLK_FREQUENCY);
    print_clock_freq("pClkDiv2", counter_pclk_div2_value, counter_pclk_value, pclk_freq_value);
    print_clock_freq("pClkDiv4", counter_pclk_div4_value, counter_pclk_value, pclk_freq_value);
    print_clock_freq("uClk_usr", counter_clkusr_value, counter_pclk_value, pclk_freq_value);
    print_clock_freq("uClk_usrDiv2", counter_clkusr_div2_value, counter_pclk_value, pclk_freq_value);
    printf("\n");
    printf("The CCI-P clock is chosen from among the available clocks by the AFU's\n");
    printf("JSON (clock_freq_test.json in the rtl directory):\n");
    print_clock_freq("CCI-P clk", counter_clk_value, counter_pclk_value, pclk_freq_value);
    printf("\n");
}


//
// Is the FPGA real or simulated with ASE?
//
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
    uint64_t           data;
    bool               use_ase;
    fpga_result        res = FPGA_OK;

    use_ase = probe_for_ase();

    if (uuid_parse(CLOCK_FREQ_TEST_AFU_ID, guid) < 0) {
        fprintf(stderr, "Error parsing guid '%s'\n", CLOCK_FREQ_TEST_AFU_ID);
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

    res = fpgaMapMMIO(afc_handle, 0, NULL);
    ON_ERR_GOTO(res, out_close, "mapping MMIO space");

    printf("Running Test\n");

    /* Reset AFC */
    res = fpgaReset(afc_handle);
    ON_ERR_GOTO(res, out_close, "resetting AFC");

    // Set the number of cycles to count on pClk.  All other counters will be compared
    // to this.
    mmio_write_64(afc_handle, 0x26*4,
                 use_ase ? 0x10000 : 0x1000000,
                 "counter_max");
    // Disable counter reset
    mmio_write_64(afc_handle, 0x22*4, 0, "reset_counter");
    // Start counting
    mmio_write_64(afc_handle, 0x24*4, 1, "enable_counter");

    do
    {
        // Counting is done when the status register's low bit is 1.
        usleep(use_ase ? 1000000 : 100000);
        mmio_read_64(afc_handle, 0x20*4, &data, "status_reg");
    }
    while ((data & 1) == 0);

    // Read counters and print frequencies
    read_final_counters(afc_handle);

    printf("Done Running Test\n");

    /* Unmap MMIO space */
    res = fpgaUnmapMMIO(afc_handle, 0);
    ON_ERR_GOTO(res, out_close, "unmapping MMIO space");

    /* Release accelerator */
out_close:
    res = fpgaClose(afc_handle);
    ON_ERR_GOTO(res, out_destroy_tok, "closing AFC");

    /* Destroy token */
out_destroy_tok:
    res = fpgaDestroyToken(&afc_token);
    ON_ERR_GOTO(res, out_destroy_prop, "destroying token");

    /* Destroy properties object */
out_destroy_prop:
    res = fpgaDestroyProperties(&filter);
    ON_ERR_GOTO(res, out_exit, "destroying properties object");

out_exit:
    if(s_error_count > 0)
        printf("Test FAILED!\n");

    return s_error_count;
}
