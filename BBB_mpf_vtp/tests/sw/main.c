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
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <inttypes.h>
#include <assert.h>
#include <getopt.h>

#include <opae/fpga.h>

// State from the AFU's JSON file, extracted using OPAE's afu_json_mgr script
#include "afu_json_info.h"
#include "tests_common.h"
#include "test_host_chan_vtp.h"

static t_target_bdf target;
static bool test_vtp_fail;

//
// Print help
//
static void
help(void)
{
    printf("\n"
           "Usage:\n"
           "    test_chan_vtp [-h] [-B <bus>] [-D <device>] [-F <function>] [-S <socket-id>]\n"
           "\n"
           "        -h,--help           Print this help\n"
           "        -B,--bus            Set target bus number\n"
           "        -D,--device         Set target device number\n"
           "        -F,--function       Set target function number\n"
           "        -S,--socket-id      Set target socket number\n"
           "        --segment           Set target segment number\n"
           "\n"
           "        --test-vtp-fail     Test the VTP failure path\n"
           "\n");
}


//
// Parse command line arguments
//
#define GETOPT_STRING ":hB:D:F:S:"
static int
parse_args(int argc, char *argv[])
{
    struct option longopts[] = {
        {"help",          no_argument,       NULL, 'h'},
        {"bus",           required_argument, NULL, 'B'},
        {"device",        required_argument, NULL, 'D'},
        {"function",      required_argument, NULL, 'F'},
        {"socket-id",     required_argument, NULL, 'S'},
        {"segment",       required_argument, NULL, 0xe},
        {"test-vtp-fail", no_argument,       NULL, 0xf},
        {0, 0, 0, 0}
    };

    int getopt_ret;
    int option_index;
    char *endptr = NULL;

    while (-1
           != (getopt_ret = getopt_long(argc, argv, GETOPT_STRING, longopts,
                        &option_index))) {
        const char *tmp_optarg = optarg;

        if ((optarg) && ('=' == *tmp_optarg)) {
            ++tmp_optarg;
        }

        switch (getopt_ret) {
        case 'h': /* help */
            help();
            return -1;

        case 0xe: /* segment */
            if (NULL == tmp_optarg)
                break;
            endptr = NULL;
            target.segment =
                (int)strtoul(tmp_optarg, &endptr, 0);
            if (endptr != tmp_optarg + strlen(tmp_optarg)) {
                fprintf(stderr, "invalid segment: %s\n",
                    tmp_optarg);
                return -1;
            }
            break;

        case 0xf: /* test-vtp-fail */
            test_vtp_fail = true;
            break;

        case 'B': /* bus */
            if (NULL == tmp_optarg)
                break;
            endptr = NULL;
            target.bus =
                (int)strtoul(tmp_optarg, &endptr, 0);
            if (endptr != tmp_optarg + strlen(tmp_optarg)) {
                fprintf(stderr, "invalid bus: %s\n",
                    tmp_optarg);
                return -1;
            }
            break;

        case 'D': /* device */
            if (NULL == tmp_optarg)
                break;
            endptr = NULL;
            target.device =
                (int)strtoul(tmp_optarg, &endptr, 0);
            if (endptr != tmp_optarg + strlen(tmp_optarg)) {
                fprintf(stderr, "invalid device: %s\n",
                    tmp_optarg);
                return -1;
            }
            break;

        case 'F': /* function */
            if (NULL == tmp_optarg)
                break;
            endptr = NULL;
            target.function =
                (int)strtoul(tmp_optarg, &endptr, 0);
            if (endptr != tmp_optarg + strlen(tmp_optarg)) {
                fprintf(stderr, "invalid function: %s\n",
                    tmp_optarg);
                return -1;
            }
            break;

        case 'S': /* socket */
            if (NULL == tmp_optarg)
                break;
            endptr = NULL;
            target.socket =
                (int)strtoul(tmp_optarg, &endptr, 0);
            if (endptr != tmp_optarg + strlen(tmp_optarg)) {
                fprintf(stderr, "invalid socket: %s\n",
                    tmp_optarg);
                return -1;
            }
            break;

        case ':': /* missing option argument */
            fprintf(stderr, "Missing option argument\n");
            return -1;

        case '?':
        default: /* invalid option */
            fprintf(stderr, "Invalid cmdline options. Use --help.\n");
            return -1;
        }
    }

    if (optind != argc) {
        fprintf(stderr, "Unexpected extra arguments\n");
        return -1;
    }

    return 0;
}


int main(int argc, char *argv[])
{
    fpga_result r;
    fpga_handle accel_handle;

    initTargetBDF(&target);
    if (parse_args(argc, argv) < 0)
        return 1;

    // Find and connect to the accelerator
    accel_handle = connectToAccel(AFU_ACCEL_UUID, &target);
    assert(NULL != accel_handle);
    bool is_ase = probeForASE(&target);
    if (is_ase)
    {
        printf("# Running in ASE mode\n");
    }

    t_csr_handle_p csr_handle = csrAllocHandle(accel_handle, 0);
    assert(csr_handle != NULL);

    printf("# AFU ID:  %016" PRIx64 " %016" PRIx64 "\n",
           csrRead(csr_handle, CSR_AFU_ID_H),
           csrRead(csr_handle, CSR_AFU_ID_L));

    // Run tests
    int status = testHostChanVtp(argc, argv, accel_handle, csr_handle, is_ase,
                                 test_vtp_fail);

    // Done
    csrReleaseHandle(csr_handle);
    fpgaClose(accel_handle);

    return status;
}
