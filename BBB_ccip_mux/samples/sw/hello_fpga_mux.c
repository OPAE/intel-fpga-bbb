#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <uuid/uuid.h>
#include <opae/fpga.h>
#include <stdlib.h>
#include <getopt.h>

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

#define LPBK1_BUFFER_SIZE            CL(1)
#define LPBK1_BUFFER_ALLOCATION_SIZE MB(2)
#define LPBK1_DSM_SIZE               MB(2)

#define DSM_STATUS_TEST_COMPLETE     0x40

//          SUB_AFU 1 CSR ADDRESS MAP
#define CSR_SRC_ADDR1             0x0120
#define CSR_DST_ADDR1             0x0128
#define CSR_CTL1                  0x0138
#define CSR_CFG1                  0x0140
#define CSR_NUM_LINES1            0x0130
#define CSR_AFU_DSM_BASEL1        0x0110
#define CSR_AFU_DSM_BASEH1        0x0114

//          SUB_AFU 2 CSR ADDRESS MAP
#define CSR_SRC_ADDR2             0x10120
#define CSR_DST_ADDR2             0x10128
#define CSR_CTL2                  0x10138
#define CSR_CFG2                  0x10140
#define CSR_NUM_LINES2            0x10130
#define CSR_AFU_DSM_BASEL2        0x10110
#define CSR_AFU_DSM_BASEH2        0x10114

//          SUB_AFU 3 CSR ADDRESS MAP
#define CSR_SRC_ADDR3             0x20120
#define CSR_DST_ADDR3             0x20128
#define CSR_CTL3                  0x20138
#define CSR_CFG3                  0x20140
#define CSR_NUM_LINES3            0x20130
#define CSR_AFU_DSM_BASEL3        0x20110
#define CSR_AFU_DSM_BASEH3        0x20114

//          SUB_AFU 4 CSR ADDRESS MAP
#define CSR_SRC_ADDR4             0x30120
#define CSR_DST_ADDR4             0x30128
#define CSR_CTL4                  0x30138
#define CSR_CFG4                  0x30140
#define CSR_NUM_LINES4            0x30130
#define CSR_AFU_DSM_BASEL4        0x30110
#define CSR_AFU_DSM_BASEH4        0x30114

/* NLB0 AFU_ID */
#define NLB0_AFUID "D8424DC4-A4A3-C413-F89E-433683F9040B"

/*
 * macro to check return codes, print error message, and goto cleanup label
 * NOTE: this changes the program flow (uses goto)!
 */
#define ON_ERR_GOTO(res, label, desc)                    \
    do {                                       \
        if ((res) != FPGA_OK) {            \
            print_err((desc), (res));  \
            goto label;                \
        }                                  \
    } while (0)

/* Type definitions */
typedef struct {
    uint32_t uint[16];
} cache_line;

void print_err(const char *s, fpga_result res)
{
    fprintf(stderr, "Error %s: %s\n", s, fpgaErrStr(res));
}

int main(int argc, char *argv[])
{
    fpga_properties    filter = NULL;
    fpga_token         accelerator_token;
    fpga_handle        accelerator_handle;
    fpga_guid          guid;
    uint32_t           num_matches;

    volatile uint64_t *mmio_ptr   = NULL;

    volatile uint64_t *dsm_ptr1    = NULL;
    volatile uint64_t *dsm_ptr2    = NULL;
    volatile uint64_t *dsm_ptr3    = NULL;
    volatile uint64_t *dsm_ptr4    = NULL;

    volatile uint64_t *status_ptr1 = NULL;
    volatile uint64_t *status_ptr2 = NULL;
    volatile uint64_t *status_ptr3 = NULL;
    volatile uint64_t *status_ptr4 = NULL;

    volatile uint64_t *input_ptr1  = NULL;
    volatile uint64_t *input_ptr2  = NULL;
    volatile uint64_t *input_ptr3  = NULL;
    volatile uint64_t *input_ptr4  = NULL;

    volatile uint64_t *output_ptr1 = NULL;
    volatile uint64_t *output_ptr2 = NULL;
    volatile uint64_t *output_ptr3 = NULL;
    volatile uint64_t *output_ptr4 = NULL;

    uint64_t        dsm_wsid1;
    uint64_t        dsm_wsid2;
    uint64_t        dsm_wsid3;
    uint64_t        dsm_wsid4;
    
    uint64_t        input_wsid1;
    uint64_t        input_wsid2;
    uint64_t        input_wsid3;
    uint64_t        input_wsid4;
    
    uint64_t        output_wsid1;
    uint64_t        output_wsid2;
    uint64_t        output_wsid3;
    uint64_t        output_wsid4;
    
    fpga_result     res = FPGA_OK;

	int open_flags = 0;

    if (uuid_parse(NLB0_AFUID, guid) < 0) {
        fprintf(stderr, "Error parsing guid '%s'\n", NLB0_AFUID);
        goto out_exit;
    }

    /* Look for accelerator with MY_ACCELERATOR_ID */
    res = fpgaGetProperties(NULL, &filter);
    ON_ERR_GOTO(res, out_exit, "creating properties object");

    res = fpgaPropertiesSetObjectType(filter, FPGA_ACCELERATOR);
    ON_ERR_GOTO(res, out_exit, "setting object type");

    res = fpgaPropertiesSetGUID(filter, guid);
    ON_ERR_GOTO(res, out_exit, "setting GUID");

    /* TODO: Add selection via BDF / device ID */

    res = fpgaEnumerate(&filter, 1, &accelerator_token,1, &num_matches);
    ON_ERR_GOTO(res, out_exit, "enumerating accelerators");

    if (num_matches < 1) {
        fprintf(stderr, "Accelerator not found.\n");
		res = fpgaDestroyProperties(&filter);
		return FPGA_INVALID_PARAM;
    }

    /* Open Accelerator and map MMIO */
    res = fpgaOpen(accelerator_token, &accelerator_handle, open_flags);
    ON_ERR_GOTO(res, out_exit, "opening accelerator");

    res = fpgaMapMMIO(accelerator_handle, 0, NULL);
    ON_ERR_GOTO(res, out_close, "mapping MMIO space");

    /* Allocate buffers */
    res = fpgaPrepareBuffer(accelerator_handle, LPBK1_DSM_SIZE,
                (void **)&dsm_ptr1, &dsm_wsid1, 0);
    ON_ERR_GOTO(res, out_close, "allocating DSM buffer1");
    res = fpgaPrepareBuffer(accelerator_handle, LPBK1_DSM_SIZE,
                (void **)&dsm_ptr2, &dsm_wsid2, 0);
    ON_ERR_GOTO(res, out_close, "allocating DSM buffer2");
    res = fpgaPrepareBuffer(accelerator_handle, LPBK1_DSM_SIZE,
                (void **)&dsm_ptr3, &dsm_wsid3, 0);
    ON_ERR_GOTO(res, out_close, "allocating DSM buffer3");
    res = fpgaPrepareBuffer(accelerator_handle, LPBK1_DSM_SIZE,
                (void **)&dsm_ptr4, &dsm_wsid4, 0);
    ON_ERR_GOTO(res, out_close, "allocating DSM buffer4");

    res = fpgaPrepareBuffer(accelerator_handle, LPBK1_BUFFER_ALLOCATION_SIZE,
               (void **)&input_ptr1, &input_wsid1, 0);
    ON_ERR_GOTO(res, out_free_dsm, "allocating input buffer1");
    res = fpgaPrepareBuffer(accelerator_handle, LPBK1_BUFFER_ALLOCATION_SIZE,
               (void **)&input_ptr2, &input_wsid2, 0);
    ON_ERR_GOTO(res, out_free_dsm, "allocating input buffer2");
    res = fpgaPrepareBuffer(accelerator_handle, LPBK1_BUFFER_ALLOCATION_SIZE,
               (void **)&input_ptr3, &input_wsid3, 0);
    ON_ERR_GOTO(res, out_free_dsm, "allocating input buffer3");
    res = fpgaPrepareBuffer(accelerator_handle, LPBK1_BUFFER_ALLOCATION_SIZE,
               (void **)&input_ptr4, &input_wsid4, 0);
    ON_ERR_GOTO(res, out_free_dsm, "allocating input buffer4");

    res = fpgaPrepareBuffer(accelerator_handle, LPBK1_BUFFER_ALLOCATION_SIZE,
               (void **)&output_ptr1, &output_wsid1, 0);
    ON_ERR_GOTO(res, out_free_input, "allocating output buffer1");
    res = fpgaPrepareBuffer(accelerator_handle, LPBK1_BUFFER_ALLOCATION_SIZE,
               (void **)&output_ptr2, &output_wsid2, 0);
    ON_ERR_GOTO(res, out_free_input, "allocating output buffer2");
    res = fpgaPrepareBuffer(accelerator_handle, LPBK1_BUFFER_ALLOCATION_SIZE,
               (void **)&output_ptr3, &output_wsid3, 0);
    ON_ERR_GOTO(res, out_free_input, "allocating output buffer3");
    res = fpgaPrepareBuffer(accelerator_handle, LPBK1_BUFFER_ALLOCATION_SIZE,
               (void **)&output_ptr4, &output_wsid4, 0);
    ON_ERR_GOTO(res, out_free_input, "allocating output buffer4");

    printf("Running Test\n");

    /* Initialize buffers */
    memset((void *)dsm_ptr1,    0,    LPBK1_DSM_SIZE);
    memset((void *)dsm_ptr2,    0,    LPBK1_DSM_SIZE);
    memset((void *)dsm_ptr3,    0,    LPBK1_DSM_SIZE);
    memset((void *)dsm_ptr4,    0,    LPBK1_DSM_SIZE);
    memset((void *)input_ptr1,  0xAF, LPBK1_BUFFER_SIZE);
    memset((void *)input_ptr2,  0xAF, LPBK1_BUFFER_SIZE);
    memset((void *)input_ptr3,  0xAF, LPBK1_BUFFER_SIZE);
    memset((void *)input_ptr4,  0xAF, LPBK1_BUFFER_SIZE);
    memset((void *)output_ptr1, 0xBE, LPBK1_BUFFER_SIZE);
    memset((void *)output_ptr2, 0xBE, LPBK1_BUFFER_SIZE);
    memset((void *)output_ptr3, 0xBE, LPBK1_BUFFER_SIZE);
    memset((void *)output_ptr4, 0xBE, LPBK1_BUFFER_SIZE);

    cache_line *cl_ptr1 = (cache_line *)input_ptr1;
    cache_line *cl_ptr2 = (cache_line *)input_ptr2;
    cache_line *cl_ptr3 = (cache_line *)input_ptr3;
    cache_line *cl_ptr4 = (cache_line *)input_ptr4;
    for (uint32_t i = 0; i < LPBK1_BUFFER_SIZE / CL(1); ++i) {
        cl_ptr1[i].uint[15] = i+1; /* set the last uint in every cacheline */
        cl_ptr2[i].uint[15] = i+1; /* set the last uint in every cacheline */
        cl_ptr3[i].uint[15] = i+1; /* set the last uint in every cacheline */
        cl_ptr4[i].uint[15] = i+1; /* set the last uint in every cacheline */
    }

    /* Reset accelerator */
    res = fpgaReset(accelerator_handle);
    ON_ERR_GOTO(res, out_free_output, "resetting accelerator");

    /* Program DMA addresses */
    uint64_t iova;
    res = fpgaGetIOAddress(accelerator_handle, dsm_wsid1, &iova);
    ON_ERR_GOTO(res, out_free_output, "getting DSM IOVA1");
    res = fpgaWriteMMIO64(accelerator_handle, 0, CSR_AFU_DSM_BASEL1, iova);
    ON_ERR_GOTO(res, out_free_output, "writing CSR_AFU_DSM_BASEL1");
    res = fpgaGetIOAddress(accelerator_handle, dsm_wsid2, &iova);
    ON_ERR_GOTO(res, out_free_output, "getting DSM IOVA2");
    res = fpgaWriteMMIO64(accelerator_handle, 0, CSR_AFU_DSM_BASEL2, iova);
    ON_ERR_GOTO(res, out_free_output, "writing CSR_AFU_DSM_BASEL2");
    res = fpgaGetIOAddress(accelerator_handle, dsm_wsid3, &iova);
    ON_ERR_GOTO(res, out_free_output, "getting DSM IOVA3");
    res = fpgaWriteMMIO64(accelerator_handle, 0, CSR_AFU_DSM_BASEL3, iova);
    ON_ERR_GOTO(res, out_free_output, "writing CSR_AFU_DSM_BASEL3");
    res = fpgaGetIOAddress(accelerator_handle, dsm_wsid4, &iova);
    ON_ERR_GOTO(res, out_free_output, "getting DSM IOVA4");
    res = fpgaWriteMMIO64(accelerator_handle, 0, CSR_AFU_DSM_BASEL4, iova);
    ON_ERR_GOTO(res, out_free_output, "writing CSR_AFU_DSM_BASEL4");


    res = fpgaWriteMMIO32(accelerator_handle, 0, CSR_CTL1, 0);
    ON_ERR_GOTO(res, out_free_output, "writing CSR_CFG1");
    res = fpgaWriteMMIO32(accelerator_handle, 0, CSR_CTL2, 0);
    ON_ERR_GOTO(res, out_free_output, "writing CSR_CFG2");
    res = fpgaWriteMMIO32(accelerator_handle, 0, CSR_CTL3, 0);
    ON_ERR_GOTO(res, out_free_output, "writing CSR_CFG3");
    res = fpgaWriteMMIO32(accelerator_handle, 0, CSR_CTL4, 0);
    ON_ERR_GOTO(res, out_free_output, "writing CSR_CFG4");
    res = fpgaWriteMMIO32(accelerator_handle, 0, CSR_CTL1, 1);
    ON_ERR_GOTO(res, out_free_output, "writing CSR_CFG1");
    res = fpgaWriteMMIO32(accelerator_handle, 0, CSR_CTL2, 1);
    ON_ERR_GOTO(res, out_free_output, "writing CSR_CFG2");
    res = fpgaWriteMMIO32(accelerator_handle, 0, CSR_CTL3, 1);
    ON_ERR_GOTO(res, out_free_output, "writing CSR_CFG3");
    res = fpgaWriteMMIO32(accelerator_handle, 0, CSR_CTL4, 1);
    ON_ERR_GOTO(res, out_free_output, "writing CSR_CFG4");

    res = fpgaGetIOAddress(accelerator_handle, input_wsid1, &iova);
    ON_ERR_GOTO(res, out_free_output, "getting input IOVA1");
    res = fpgaWriteMMIO64(accelerator_handle, 0, CSR_SRC_ADDR1, CACHELINE_ALIGNED_ADDR(iova));
    ON_ERR_GOTO(res, out_free_output, "writing CSR_SRC_ADDR1");
    res = fpgaGetIOAddress(accelerator_handle, input_wsid2, &iova);
    ON_ERR_GOTO(res, out_free_output, "getting input IOVA2");
    res = fpgaWriteMMIO64(accelerator_handle, 0, CSR_SRC_ADDR2, CACHELINE_ALIGNED_ADDR(iova));
    ON_ERR_GOTO(res, out_free_output, "writing CSR_SRC_ADDR2");
    res = fpgaGetIOAddress(accelerator_handle, input_wsid3, &iova);
    ON_ERR_GOTO(res, out_free_output, "getting input IOVA3");
    res = fpgaWriteMMIO64(accelerator_handle, 0, CSR_SRC_ADDR3, CACHELINE_ALIGNED_ADDR(iova));
    ON_ERR_GOTO(res, out_free_output, "writing CSR_SRC_ADDR3");
    res = fpgaGetIOAddress(accelerator_handle, input_wsid4, &iova);
    ON_ERR_GOTO(res, out_free_output, "getting input IOVA4");
    res = fpgaWriteMMIO64(accelerator_handle, 0, CSR_SRC_ADDR4, CACHELINE_ALIGNED_ADDR(iova));
    ON_ERR_GOTO(res, out_free_output, "writing CSR_SRC_ADDR4");

    res = fpgaGetIOAddress(accelerator_handle, output_wsid1, &iova);
    ON_ERR_GOTO(res, out_free_output, "getting output IOVA1");
    res = fpgaWriteMMIO64(accelerator_handle, 0, CSR_DST_ADDR1, CACHELINE_ALIGNED_ADDR(iova));
    ON_ERR_GOTO(res, out_free_output, "writing CSR_DST_ADDR1");
    res = fpgaGetIOAddress(accelerator_handle, output_wsid2, &iova);
    ON_ERR_GOTO(res, out_free_output, "getting output IOVA2");
    res = fpgaWriteMMIO64(accelerator_handle, 0, CSR_DST_ADDR2, CACHELINE_ALIGNED_ADDR(iova));
    ON_ERR_GOTO(res, out_free_output, "writing CSR_DST_ADDR2");
    res = fpgaGetIOAddress(accelerator_handle, output_wsid3, &iova);
    ON_ERR_GOTO(res, out_free_output, "getting output IOVA3");
    res = fpgaWriteMMIO64(accelerator_handle, 0, CSR_DST_ADDR3, CACHELINE_ALIGNED_ADDR(iova));
    ON_ERR_GOTO(res, out_free_output, "writing CSR_DST_ADDR3");
    res = fpgaGetIOAddress(accelerator_handle, output_wsid4, &iova);
    ON_ERR_GOTO(res, out_free_output, "getting output IOVA4");
    res = fpgaWriteMMIO64(accelerator_handle, 0, CSR_DST_ADDR4, CACHELINE_ALIGNED_ADDR(iova));
    ON_ERR_GOTO(res, out_free_output, "writing CSR_DST_ADDR4");
    
    res = fpgaWriteMMIO32(accelerator_handle, 0, CSR_NUM_LINES1, LPBK1_BUFFER_SIZE / CL(1));
    ON_ERR_GOTO(res, out_free_output, "writing CSR_NUM_LINES1");
    res = fpgaWriteMMIO32(accelerator_handle, 0, CSR_NUM_LINES2, LPBK1_BUFFER_SIZE / CL(1));
    ON_ERR_GOTO(res, out_free_output, "writing CSR_NUM_LINES2");
    res = fpgaWriteMMIO32(accelerator_handle, 0, CSR_NUM_LINES3, LPBK1_BUFFER_SIZE / CL(1));
    ON_ERR_GOTO(res, out_free_output, "writing CSR_NUM_LINES3");
    res = fpgaWriteMMIO32(accelerator_handle, 0, CSR_NUM_LINES4, LPBK1_BUFFER_SIZE / CL(1));
    ON_ERR_GOTO(res, out_free_output, "writing CSR_NUM_LINES4");
    res = fpgaWriteMMIO32(accelerator_handle, 0, CSR_CFG1, 0x42000);
    ON_ERR_GOTO(res, out_free_output, "writing CSR_CFG1");
    res = fpgaWriteMMIO32(accelerator_handle, 0, CSR_CFG2, 0x42000);
    ON_ERR_GOTO(res, out_free_output, "writing CSR_CFG2");
    res = fpgaWriteMMIO32(accelerator_handle, 0, CSR_CFG3, 0x42000);
    ON_ERR_GOTO(res, out_free_output, "writing CSR_CFG3");
    res = fpgaWriteMMIO32(accelerator_handle, 0, CSR_CFG4, 0x42000);
    ON_ERR_GOTO(res, out_free_output, "writing CSR_CFG4");

    status_ptr1 = dsm_ptr1 + DSM_STATUS_TEST_COMPLETE/8;
    status_ptr2 = dsm_ptr2 + DSM_STATUS_TEST_COMPLETE/8;
    status_ptr3 = dsm_ptr3 + DSM_STATUS_TEST_COMPLETE/8;
    status_ptr4 = dsm_ptr4 + DSM_STATUS_TEST_COMPLETE/8;

    /* Start the test */
    res = fpgaWriteMMIO32(accelerator_handle, 0, CSR_CTL1, 3);
    ON_ERR_GOTO(res, out_free_output, "writing CSR_CFG1");
    res = fpgaWriteMMIO32(accelerator_handle, 0, CSR_CTL2, 3);
    ON_ERR_GOTO(res, out_free_output, "writing CSR_CFG2");
    res = fpgaWriteMMIO32(accelerator_handle, 0, CSR_CTL3, 3);
    ON_ERR_GOTO(res, out_free_output, "writing CSR_CFG3");
    res = fpgaWriteMMIO32(accelerator_handle, 0, CSR_CTL4, 3);
    ON_ERR_GOTO(res, out_free_output, "writing CSR_CFG4");

    /* Wait for test completion from all PEs*/
    while ((0 == ((*status_ptr1) & 0x1))||(0 == ((*status_ptr2) & 0x1))||(0 == ((*status_ptr3) & 0x1))||(0 == ((*status_ptr4) & 0x1))) {
        usleep(100);
    }

    /* Stop the device */
    res = fpgaWriteMMIO32(accelerator_handle, 0, CSR_CTL1, 7);
    ON_ERR_GOTO(res, out_free_output, "writing CSR_CFG1");
    res = fpgaWriteMMIO32(accelerator_handle, 0, CSR_CTL2, 7);
    ON_ERR_GOTO(res, out_free_output, "writing CSR_CFG2");
    res = fpgaWriteMMIO32(accelerator_handle, 0, CSR_CTL3, 7);
    ON_ERR_GOTO(res, out_free_output, "writing CSR_CFG3");
    res = fpgaWriteMMIO32(accelerator_handle, 0, CSR_CTL4, 7);
    ON_ERR_GOTO(res, out_free_output, "writing CSR_CFG4");
    
    /* Check output buffer contents */
    for (uint32_t i = 0; i < LPBK1_BUFFER_SIZE; i++) {
        if (((uint8_t*)output_ptr1)[i] != ((uint8_t*)input_ptr1)[i]) {
            fprintf(stderr, "Output does NOT match input from SUB_AFU 1"
                "at offset %i!\n", i);
            break;
        }
        if (((uint8_t*)output_ptr2)[i] != ((uint8_t*)input_ptr2)[i]) {
            fprintf(stderr, "Output does NOT match input from SUB_AFU 2"
                "at offset %i!\n", i);
            break;
        }
        if (((uint8_t*)output_ptr3)[i] != ((uint8_t*)input_ptr3)[i]) {
            fprintf(stderr, "Output does NOT match input from SUB_AFU 3"
                "at offset %i!\n", i);
            break;
        }
        if (((uint8_t*)output_ptr4)[i] != ((uint8_t*)input_ptr4)[i]) {
            fprintf(stderr, "Output does NOT match input from SUB_AFU 4"
                "at offset %i!\n", i);
            break;
        }
    }

    printf("Done Running Test\n");
        // /* Reset accelerator */
    // res = fpgaReset(accelerator_handle);
    // ON_ERR_GOTO(res, out_free_output, "resetting accelerator");
    /* Release buffers */
out_free_output:
    res = fpgaReleaseBuffer(accelerator_handle, output_wsid1);
    res = fpgaReleaseBuffer(accelerator_handle, output_wsid2);
    res = fpgaReleaseBuffer(accelerator_handle, output_wsid3);
    res = fpgaReleaseBuffer(accelerator_handle, output_wsid4);
    ON_ERR_GOTO(res, out_free_input, "releasing output buffer");
out_free_input:
    res = fpgaReleaseBuffer(accelerator_handle, input_wsid1);
    res = fpgaReleaseBuffer(accelerator_handle, input_wsid2);
    res = fpgaReleaseBuffer(accelerator_handle, input_wsid3);
    res = fpgaReleaseBuffer(accelerator_handle, input_wsid4);
    ON_ERR_GOTO(res, out_free_dsm, "releasing input buffer");
out_free_dsm:
    res = fpgaReleaseBuffer(accelerator_handle, dsm_wsid1);
    res = fpgaReleaseBuffer(accelerator_handle, dsm_wsid2);
    res = fpgaReleaseBuffer(accelerator_handle, dsm_wsid3);
    res = fpgaReleaseBuffer(accelerator_handle, dsm_wsid4);
	ON_ERR_GOTO(res, out_unmap, "releasing DSM buffer");
	/* Unmap MMIO space */
out_unmap:
	res = fpgaUnmapMMIO(accelerator_handle, 0);
	ON_ERR_GOTO(res, out_close, "unmapping MMIO space");
    /* Release accelerator */
    
out_close:
    res = fpgaClose(accelerator_handle);
    ON_ERR_GOTO(res, out_destroy_tok, "closing accelerator");

	/* Destroy token */
out_destroy_tok:
	res = fpgaDestroyToken(&accelerator_token);
	ON_ERR_GOTO(res, out_destroy_prop, "destroying token");

	/* Destroy properties object */
out_destroy_prop:
	res = fpgaDestroyProperties(&filter);
	ON_ERR_GOTO(res, out_exit, "destroying properties object");

out_exit:
	return res;

}


