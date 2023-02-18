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
// ARE DISCLAIMED.  IN NO EVENT  SHALL THE COPYRIGHT OWNER  OR CONTRIBUTORS BE
// LIABLE  FOR  ANY  DIRECT,  INDIRECT,  INCIDENTAL,  SPECIAL,  EXEMPLARY,  OR
// CONSEQUENTIAL  DAMAGES  (INCLUDING,  BUT  NOT LIMITED  TO,  PROCUREMENT  OF
// SUBSTITUTE GOODS OR SERVICES;  LOSS OF USE,  DATA, OR PROFITS;  OR BUSINESS
// INTERRUPTION)  HOWEVER CAUSED  AND ON ANY THEORY  OF LIABILITY,  WHETHER IN
// CONTRACT,  STRICT LIABILITY,  OR TORT  (INCLUDING NEGLIGENCE  OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,  EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.


/**
 * \file mpf_shim_vtp_pt.h
 * \brief Internal functions and data structures for managing VTP page tables.
 */

#ifndef __FPGA_MPF_SHIM_VTP_PT_H__
#define __FPGA_MPF_SHIM_VTP_PT_H__

#include <opae/mpf/shim_vtp.h>

/**
 * Flags that may be set in page table entries.  These are ORed into the low
 * address bits which are guaranteed to be 0 since the smallest page is 4KB
 * aligned.
 */
typedef enum
{
    // Terminal entry in table hierarchy -- indicates an actual address
    // translation as opposed to an intra-table pointer
    MPF_VTP_PT_FLAG_TERMINAL = 1,
    // Set when buffer is allocated by MPF
    MPF_VTP_PT_FLAG_ALLOC = 2,
    // Set at the head of a buffer added with mpfVtpPrepareBuffer when
    // the buffer is allocated outside MPF.
    MPF_VTP_PT_FLAG_PREALLOC = 4,
    // Entry is invalid. This bit is used on the FPGA side to detect
    // empty entries.
    MPF_VTP_PT_FLAG_INVALID = 8,
    // Page may be in FPGA-side VTP caches.
    MPF_VTP_PT_FLAG_IN_USE = 16,
    // Page is mapped read-only
    MPF_VTP_PT_FLAG_READ_ONLY = 32,

    // All flags (mask)
    MPF_VTP_PT_FLAG_MASK = 63
}
mpf_vtp_pt_flag;


/**
 * The VTP page table is structured like the standard x86 hierarchical table.
 * Each level in the table is an array of 512 pointers to the next level
 * in the table (512 * 8B == 4KB).  Eventually, a terminal node is reached
 * containing the translation.
 *
 * Nodes in the VTP page table have parallel data structures, each with 512
 * entries. The first group is the vector of virtual to physical translation
 * entries, which is pinned and shared with the FPGA's hardware page table
 * walker. Other groups hold data used by software, such as a parallel virtual
 * to physical translation table with internal virtual instead of physical
 * pointers.
 */


/**
 * Physical address.
 */
typedef uint64_t mpf_vtp_pt_paddr;


/**
 * Virtual address.
 */
typedef void* mpf_vtp_pt_vaddr;


/**
 * Other meta-data stored in the page table.
 */
typedef struct
{
    uint64_t wsid;
    uint64_t refcnt;
}
mpf_vtp_pt_meta;


#define MPF_VTP_PT_VEC_LEN 512

/**
 * Full page table node.
 */
typedef struct
{
    mpf_vtp_pt_paddr ptable[MPF_VTP_PT_VEC_LEN];
    mpf_vtp_pt_vaddr vtable[MPF_VTP_PT_VEC_LEN];
    mpf_vtp_pt_meta meta[MPF_VTP_PT_VEC_LEN];
}
mpf_vtp_pt_node;


/**
 * VTP page table handle to all page table state.
 */
typedef struct
{
    // Root of the page table.
    mpf_vtp_pt_node* pt_root;

    // Physical address of the root of the page table
    mpf_vtp_pt_paddr pt_root_paddr;

    // wsid of the root of the page table
    uint64_t pt_root_wsid;

    // Opaque parent MPF handle.  It is opaque because the internal MPF handle
    // points to the page table, so the dependence would be circular.
    _mpf_handle_p _mpf_handle;

    // PT mutex (one update at a time)
    mpf_os_mutex_handle mutex;

    // Cache of most recent node in findTerminalNodeAndIndex().
    mpf_vtp_pt_node* prev_find_term_node;
    mpf_vtp_pt_vaddr prev_va;
    uint32_t prev_depth;
    uint32_t prev_idx;

    // Is there a harware page table walker? If yes, the page table must be
    // pinned.
    bool hw_pt_walker_present;
}
mpf_vtp_pt;


/**
 * Initialize a page table manager.
 *
 * Allocates and initializes a page table.
 *
 * @param[in]  _mpf_handle Internal handle to MPF state.
 * @param[out] pt          Allocated page table.
 * @returns                FPGA_OK on success.
 */
fpga_result mpfVtpPtInit(
    _mpf_handle_p _mpf_handle,
    mpf_vtp_pt** pt
);


/**
 * Destroy a page table manager.
 *
 * Terminate and deallocate a page table.
 *
 * @param[in]  pt          Page table.
 * @returns                FPGA_OK on success.
 */
fpga_result mpfVtpPtTerm(
    mpf_vtp_pt* pt
);


/**
 * Acquire the page table manager lock.
 */
static inline void mpfVtpPtLockMutex(
    mpf_vtp_pt* pt
)
{
    mpfOsLockMutex(pt->mutex);
}


/**
 * Release the page table manager lock.
 */
static inline void mpfVtpPtUnlockMutex(
    mpf_vtp_pt* pt
)
{
    mpfOsUnlockMutex(pt->mutex);
}


/**
 * Return the root physical address of the page table.
 *
 * @param[in]  pt          Page table.
 * @returns                Root PA.
 */
mpf_vtp_pt_paddr mpfVtpPtGetPageTableRootPA(
    mpf_vtp_pt* pt
);


/**
 * Insert a mapping in the page table.
 *
 * @param[in]  pt          Page table.
 * @param[in]  va          Virtual address to insert.
 * @param[in]  pa          Physical address corresponding to the virtual address.
 * @param[in]  wsid        Driver's handle to the page.
 * @param[in]  size        Size of the page.
 * @param[in]  flags       ORed mpf_vtp_pt_flag values.
 * @returns                FPGA_OK on success.
 */
fpga_result mpfVtpPtInsertPageMapping(
    mpf_vtp_pt* pt,
    mpf_vtp_pt_vaddr va,
    mpf_vtp_pt_paddr pa,
    uint64_t wsid,
    mpf_vtp_page_size size,
    uint32_t flags
);


/**
 * Clear the MPF_VTP_PT_FLAG_IN_USE flag for the page table entry
 * matching "va". Clearing this flag is part of the FPGA-side
 * shootdown process. When the software translation server is
 * being used, this flag indicates whether the address may be cached
 * in the FPGA.
 *
 * @param[in]  pt          Page table.
 * @param[in]  va          Virtual address of the buffer start.
 * @returns                FPGA_OK on success.
 */
fpga_result mpfVtpPtClearInUseFlag(
    mpf_vtp_pt* pt,
    mpf_vtp_pt_vaddr va
);


/**
 * Remove a page from the table.
 *
 * Some state from the page is returned as it is dropped.
 * State pointers are not written if they are NULL.
 *
 * @param[in]  pt          Page table.
 * @param[in]  va          Virtual address to remove.
 * @param[out] pa          PA corresponding to VA.  (Ignored if NULL.)
 * @param[out] wsid        Workspace ID corresponding to VA.  (Ignored if NULL.)
 * @param[out] size        Physical page size.  (Ignored if NULL.)
 * @param[out] flags       Page flags.  (Ignored if NULL.)
 * @returns                FPGA_OK on success.
 */
fpga_result mpfVtpPtRemovePageMapping(
    mpf_vtp_pt* pt,
    mpf_vtp_pt_vaddr va,
    mpf_vtp_pt_paddr *pa,
    uint64_t *wsid,
    mpf_vtp_page_size *size,
    uint32_t *flags
);


/**
 * Release a virtual range of pinned pages.
 *
 * @param[in]  pt          Page table.
 * @param[in]  min_va      Start address to release.
 * @param[in]  max_va      End address to release (exclusive).
 * @returns                FPGA_OK on success.
 */
fpga_result mpfVtpPtReleaseRange(
    mpf_vtp_pt* pt,
    void* min_va,
    void* max_va
);


/**
 * Translate an address from virtual to physical.
 *
 * @param[in]  pt          Page table.
 * @param[in]  va          Virtual address to translate. The address does not
 *                         have to be page aligned. Low address bits will
 *                         be ignored.
 * @param[in]  set_in_use  Set the MPF_VTP_PT_FLAG_IN_USE in the page table
 *                         indicating that the translation has been sent
 *                         to the FPGA.
 * @param[out] start_va    Starting VA of the page, aligned to page size.
 *                         (Ignored if NULL.)
 * @param[out] pa          PA corresponding to VA.
 * @param[out] size        Physical page size. Even on failed translations,
 *                         size indicates the level in the page table at
 *                         which translation failed. If the appropriate
 *                         page table node exists at the 4KB level that is
 *                         a hint that the target page must be a 4KB page.
 *                         Knowing this may avoid wasting time walking
 *                         through kernel tables to figure out whether to
 *                         pin a huge page. (Ignored if NULL.)
 * @param[out] flags       Page flags. (Ignored if NULL.)
 * @returns                FPGA_OK on success.
 */
fpga_result mpfVtpPtTranslateVAtoPA(
    mpf_vtp_pt* pt,
    mpf_vtp_pt_vaddr va,
    bool set_in_use,
    mpf_vtp_pt_vaddr* start_va,
    mpf_vtp_pt_paddr *pa,
    mpf_vtp_page_size *size,
    uint32_t *flags
);


/**
 * Return an extended vector of VA to PA translations for a virtually
 * contiguous region, continuing from the most recent result from
 * mpfVtpPtTranslateVAtoPA(). Results from the same node in the page table
 * are returned, up to max_pages. Anywhere from 0 to max_pages may be
 * returned.
 *
 * The page table MUTEX must be held from before the call to
 * mpfVtpPtTranslateVAtoPA() until after the call to mpfVtpPtExtendVecVAtoPA()
 * returns in order to ensure that the cached page table node pointer and
 * index remain consistent.
 *
 * @param[in]  pt          Page table.
 * @param[in]  max_pages   The maximum number of virtually contiguous pages
 *                         that may be returned.
 * @param[in]  set_in_use  Set the MPF_VTP_PT_FLAG_IN_USE for each returned
 *                         page in the page table, indicating that the
 *                         translation has been sent to the FPGA.
 * @param[out] pa          Vector for storing PAs corresponding to VA. The
 *                         vector must have at least max_pages entries.
 * @param[out] flags       Page flags vector, one per pa entry. (Ignored if
 *                         NULL.)
 * @returns                Number of page translations stored in pa/flags.
 */
int mpfVtpPtExtendVecVAtoPA(
    mpf_vtp_pt* pt,
    int max_pages,
    bool set_in_use,
    mpf_vtp_pt_paddr *pa,
    uint32_t *flags
);


/**
 * Dump page table for debugging.
 *
 * @param[in]  pt          Page table.
 */
void mpfVtpPtDumpPageTable(
    mpf_vtp_pt* pt
);

#endif // __FPGA_MPF_SHIM_VTP_PT_H__
