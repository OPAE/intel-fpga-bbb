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

/**
 * \file shim_vtp.h
 * \brief MPF VTP (virtual to physical) translation shim
 */

#ifndef __FPGA_MPF_SHIM_VTP_H__
#define __FPGA_MPF_SHIM_VTP_H__

#include <opae/mpf/csrs.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * The page table supports two physical page sizes.
 */
typedef enum
{
    // Enumeration values are log2 of the size
    MPF_VTP_PAGE_NONE = 0,
    MPF_VTP_PAGE_4KB = 12,
    MPF_VTP_PAGE_2MB = 21,
    MPF_VTP_PAGE_1GB = 30
}
mpf_vtp_page_size;

/**
 * mpf_vtp_page_size enum to string.
 *
 * @param[in]  page_size   mpf_vtp_page_size.
 * @returns                String.
 */
__MPF_API__ const char* mpfVtpPageSizeToString(
    mpf_vtp_page_size page_size
);

// mpf_vtp_page_size values are the log2 of the size.  Convert to bytes.
#define mpfPageSizeEnumToBytes(page_size) ((size_t)1 << page_size)



/**
 * Test whether the VTP service is available on the FPGA.
 *
 * @param[in]  mpf_handle  MPF handle initialized by mpfConnect().
 * @returns                True if VTP is available.
 */
bool __MPF_API__ mpfVtpIsAvailable(
    mpf_handle_t mpf_handle
);


/**
 * Allocate a shared host/FPGA buffer.
 *
 * This function has similar behavior to the OPAE SDK function
 * fpgaPrepareBuffer, but with a significant difference: the buffer may
 * may be arbitrarily large. The allocated buffer may be composed of
 * multiple physical pages that do not have to be physically contiguous.
 * VTP maintains a page-level translation table. The calling process may
 * pass any virtual address within the returned buffer to the FPGA and
 * the FPGA-side VTP will translate automatically to physical (IOVA)
 * addresses.
 *
 * The FPGA_BUF_PREALLOCATED flag has requirements and semantics that
 * match fpgaPrepareBuffer. When set, buf_addr must point to an
 * existing virtual buffer. There are NO ALIGNMENT REQUIREMENTS for
 * buf_addr. VTP will determine the underlying page alignment and call
 * OPAE to share the buffer with the FPGA and will also add the
 * buffer to VTP's address translation table.
 *
 * @param[in]  mpf_handle  MPF handle initialized by mpfConnect().
 * @param[in]  len         Length of the buffer to allocate in bytes.
 * @param[out] buf_addr    Virtual base address of the allocated buffer.
 * @param[in]  flags       The same flags as fpgaPrepareBuffer().
 *                         FPGA_BUF_PREALLOCATED indicates that memory
 *                         pointed at in '*buf_addr' is already allocated
 *                         and mapped into virtual memory.
 * @returns                FPGA_OK on success.
 */
fpga_result __MPF_API__ mpfVtpPrepareBuffer(
    mpf_handle_t mpf_handle,
    uint64_t len,
    void** buf_addr,
    int flags
);


/**
 * Legacy function -- replaced by mpfVtpPrepareBuffer.
 *
 * Equivalent to mpfVtpPrepareBuffer with flags set to 0.
 *
 * @param[in]  mpf_handle  MPF handle initialized by mpfConnect().
 * @param[in]  len         Length of the buffer to allocate in bytes.
 * @param[out] buf_addr    Virtual base address of the allocated buffer.
 * @returns                FPGA_OK on success.
 */
fpga_result __MPF_API__ mpfVtpBufferAllocate(
    mpf_handle_t mpf_handle,
    uint64_t len,
    void** buf_addr
);


/**
 * Free a shared host/FPGA buffer.
 *
 * Release a buffer previously allocated with mpfVtpPrepareBuffer().
 * Associated translations are removed from the VTP-managed page table.
 * If the buffer was allocated without setting FPGA_BUF_PREALLOCATED
 * this call will deallocate/free the memory. Otherwise, the memory
 * will only be returned to it's previous state (unpinned).
 *
 * buf_addr must exactly match an address that is managed by
 * mpfVtpPrepareBuffer().
 *
 * @param[in]  mpf_handle  MPF handle initialized by mpfConnect().
 * @param[in]  buf_addr    Virtual base address of the allocated buffer.
 * @returns                FPGA_OK on success.
 */
fpga_result __MPF_API__ mpfVtpReleaseBuffer(
    mpf_handle_t mpf_handle,
    void* buf_addr
);


/**
 * Legacy function -- replaced by mpfVtpReleaseBuffer.
 *
 * @param[in]  mpf_handle  MPF handle initialized by mpfConnect().
 * @param[in]  buf_addr    Virtual base address of the allocated buffer.
 * @returns                FPGA_OK on success.
 */
fpga_result __MPF_API__ mpfVtpBufferFree(
    mpf_handle_t mpf_handle,
    void* buf_addr
);


/**
 * Return the IOVA associated with a virtual address.
 *
 * The function works only with addresses managed by VTP.
 *
 * @param[in]  mpf_handle  MPF handle initialized by mpfConnect().
 * @param[in]  buf_addr    Virtual base address of the allocated buffer.
 * @returns                The corresponding physical address (IOVA) or
 *                         0 if the address is not managed by VTP.
 */
uint64_t __MPF_API__ mpfVtpGetIOAddress(
    mpf_handle_t mpf_handle,
    void* buf_addr
);


/**
 * Mode for mpfVtpPinAndGetIOAddress.
 */
typedef enum
{
    // Lookup only: don't pin if page isn't already pinned for the FPGA.
    MPF_VTP_PIN_MODE_LOOKUP_ONLY = 0,
    // Standard mode: pin the page if necessary, using the flags
    // passed in to modify fpgaPrepareBuffer().
    MPF_VTP_PIN_MODE_STD = 1,
    // Similar to standard mode, but try pinning the page read-only if
    // pinning in read/write mode fails.
    MPF_VTP_PIN_MODE_TRY_READ_ONLY = 2
}
mpf_vtp_pin_mode;


/**
 * Similar to mpfVtpPinAndGetIOAddress() except that ioaddr and flags are
 * pointers to vectors. The function may return the IO addresses and flags
 * of multiple virtually contiguous pages. Returning a vector may be
 * valuable in performance critical software loops that are requesting
 * translations of small pages in sequence.
 *
 * On input, num_pages sets the limit to the number of translations that
 * may be returned in ioaddr and flags. The function may return fewer. If
 * num_pages is NULL, one result is returned. On output, num_pages is
 * updated with the actual number of page translations returned.
 *
 * The function works only with addresses allocated by VTP.
 *
 * @param[in]  mpf_handle  MPF handle initialized by mpfConnect().
 * @param[in]  mode        Set the behavior when the page isn't already pinned.
 * @param[in]  buf_addr    Virtual address to translate. The address does not
 *                         have to be page aligned. Low address bits will
 *                         be ignored.
 * @param[inout] num_pages Maximum number of virtually contiguous pages for
 *                         which translation is returned. Both ioaddr and flags
 *                         (when flags isn't NULL) must point to vectors with at
 *                         least num_pages entries. The actual number of page
 *                         translations in the returned ioaddr vector is stored
 *                         in num_pages on return. Passing NULL in num_pages is
 *                         equivalent to passing a pointer to 1.
 * @param[out] ioaddr      Vector of corresponding physical addresss (IOVA). The
 *                         first entry is the start of the page corresponding to
 *                         buf_addr, even when it does not point to the page start.
 *                         Subsequent vector entries are the IO addresses of
 *                         virtually contiguous pages. Up to num_pages may be
 *                         returned. The actual number of pages is returned in
 *                         num_pages.
 * @param[out] page_size   Size of the pinned pages. The enumeration values
 *                         are log2(page bytes). All pages returned in the ioaddr
 *                         vector are the same size.
 * @param[inout] flags     Flags passed to fpgaPrepareBuffer(). Assumed to be
 *                         0 if flags is NULL. When not null, flags should point
 *                         to a vector the same size as the ioaddr vector. Only
 *                         the first entry is consumed as an input. The other entries
 *                         may be passed in uninitialized. On return, entries in
 *                         the flags vector correspond to pages in ioaddr.
 *                         FPGA_BUF_READ_ONLY is set when a page is pinned
 *                         in read-only mode. Some input flags make no sense
 *                         here and are ignored (e.g. FPGA_BUF_PREALLOCATED).
 * @returns                FPGA_OK on success.
 */
fpga_result __MPF_API__ mpfVtpPinAndGetIOAddressVec(
    mpf_handle_t mpf_handle,
    mpf_vtp_pin_mode mode,
    void* buf_addr,
    int* num_pages,
    uint64_t* ioaddr,
    mpf_vtp_page_size* page_size,
    int* flags
);


/**
 * Return the IOVA associated with a virtual address.
 *
 * The function works only with addresses allocated by VTP.
 *
 * @param[in]  mpf_handle  MPF handle initialized by mpfConnect().
 * @param[in]  mode        Set the behavior when the page isn't already pinned.
 * @param[in]  buf_addr    Virtual address to translate. The address does not
 *                         have to be page aligned. Low address bits will
 *                         be ignored.
 * @param[out] ioaddr      The corresponding physical address (IOVA). The
 *                         value is always the start of the page, even when
 *                         buf_addr does not point to the page start.
 * @param[out] page_size   Size of the pinned page. The enumeration values
 *                         are log2(page bytes).
 * @param[inout] flags     Flags passed to fpgaPrepareBuffer(). Assumed to be
 *                         0 if flags is NULL. The returned value of flags
 *                         will set FPGA_BUF_READ_ONLY when the page is pinned
 *                         in read-only mode. Some input flags make no sense
 *                         here and are ignored (e.g. FPGA_BUF_PREALLOCATED).
 * @returns                FPGA_OK on success.
 */
static inline fpga_result mpfVtpPinAndGetIOAddress(
    mpf_handle_t mpf_handle,
    mpf_vtp_pin_mode mode,
    void* buf_addr,
    uint64_t* ioaddr,
    mpf_vtp_page_size* page_size,
    int* flags
)
{
    return mpfVtpPinAndGetIOAddressVec(mpf_handle, mode, buf_addr, NULL,
                                       ioaddr, page_size, flags);
}


/**
 * Invalidate the FPGA-side translation cache.
 *
 * This method does not affect allocated storage or the contents of the
 * VTP-managed translation table.  It invalidates the translation caches
 * in the FPGA, forcing the FPGA to refetch virtual to physical translations
 * on demand.
 *
 * @param[in]  mpf_handle  MPF handle initialized by mpfConnect().
 * @returns                FPGA_OK on success.
 */
fpga_result __MPF_API__ mpfVtpInvalHWTLB(
    mpf_handle_t mpf_handle
);


/**
 * Invalidate a single virtual page in the FPGA-side translation cache.
 *
 * This method does not affect allocated storage or the contents of the
 * VTP-managed translation table.  It invalidates one address in the
 * translation caches in the FPGA.
 *
 * @param[in]  mpf_handle  MPF handle initialized by mpfConnect().
 * @param[in]  va          Virtual address to invalidate.
 * @returns                FPGA_OK on success.
 */
fpga_result __MPF_API__ mpfVtpInvalHWVAMapping(
    mpf_handle_t mpf_handle,
    void* va
);


/**
 * Set the maximum allocated physical page size.
 *
 * You probably do not want to call this method.  It is more useful for
 * debugging the allocator than in production.  In most cases an application
 * is better off with large pages, which is the default.
 *
 * @param[in]  mpf_handle  MPF handle initialized by mpfConnect().
 * @param[in]  max_psize   Maximum physical page size.
 * @returns                FPGA_OK on success.
 */
fpga_result __MPF_API__ mpfVtpSetMaxPhysPageSize(
    mpf_handle_t mpf_handle,
    mpf_vtp_page_size max_psize
);


/**
 * Test whether the VTP hardware is expecting physical addresses.
 *
 * @param[in]  mpf_handle  MPF handle initialized by mpfConnect().
 * @returns                True if VTP the address mode is physical.
 */
bool __MPF_API__ mpfVtpAddrModeIsPhysical(
    mpf_handle_t mpf_handle
);


/**
 * Bind VTP to a near-memory controller.
 *
 * This is an experimental, platform-dependent method most applications
 * will not use. It queries the fpga_near_mem_map driver (also in the
 * BBB repository) to limit address translation to NUMA domains
 * associated with a memory controller.
 *
 * @param[in]  mpf_handle  MPF handle initialized by mpfConnect().
 * @param[in]  ctrl_num    Controller number.
 * @returns                FPGA_OK on success.
 */
fpga_result __MPF_API__ mpfVtpBindToNearMemCtrl(
    mpf_handle_t mpf_handle,
    uint32_t ctrl_num
);


/**
 * Wait for VTP's state to be in sync with system state.
 *
 * This is a generic entry point for ensuring that all
 * updates to the hardware caches are complete. The most common
 * use is to ensure that VTP TLB cache invalidations, detected
 * automatically by the VTP monitor service, are complete.
 * Code that manages mapping explicitly with mpfVtpPrepareBuffer()
 * does *not* need to call this method.
 *
 * @param[in]  mpf_handle     MPF handle initialized by mpfConnect().
 * @param[in]  wait_for_sync  When true, the function waits until state
 *                            is synchronized to return. When false,
 *                            the function returns immediately and
 *                            indicates synchronization state with the
 *                            return value.
 * @returns                   FPGA_OK on success. FPGA_BUSY when not
 *                            synchronized and wait_for_sync is false.
 */
fpga_result __MPF_API__ mpfVtpSync(
    mpf_handle_t mpf_handle,
    bool wait_for_sync
);


/**
 * VTP statistics
 */
typedef struct
{
    // Hits and misses in the TLB. The VTP pipeline has local caches
    // within the pipeline itself that filter requests to the TLB.
    // The counts here increment only for requests to the TLB service
    // that are not satisfied in the VTP pipeline caches.
    uint64_t numTLBHits4KB;
    uint64_t numTLBMisses4KB;
    uint64_t numTLBHits2MB;
    uint64_t numTLBMisses2MB;

    // Number of cycles spent with the page table walker active.  Since
    // the walker manages only one request at a time the latency of the
    // page table walker can be computed as:
    //   numPTWalkBusyCycles / (numTLBMisses4KB + numTLBMisses2MB)
    uint64_t numPTWalkBusyCycles;

    // Number of failed virtual to physical translations. The VTP page
    // table walker currently goes into a terminal error state when a
    // translation failure is seen and blocks all future requests.
    // If this number is non-zero the program has passed an illegal
    // address and should be fixed.
    uint64_t numFailedTranslations;
    // Last virtual address translated. If numFailedTranslations is non-zero
    // this is the failing virtual address.
    void* ptWalkLastVAddr;
}
mpf_vtp_stats;


/**
 * Return VTP statistics.
 *
 * @param[in]  mpf_handle  MPF handle initialized by mpfConnect().
 * @param[out] stats       Statistics.
 * @returns                FPGA_OK on success.
 */
fpga_result __MPF_API__ mpfVtpGetStats(
    mpf_handle_t mpf_handle,
    mpf_vtp_stats* stats
);


#ifdef __cplusplus
}
#endif

#endif // __FPGA_MPF_SHIM_VTP_H__
