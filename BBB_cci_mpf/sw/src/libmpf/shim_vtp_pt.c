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

#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <assert.h>
#include <inttypes.h>

#include <opae/mpf/mpf.h>
#include "mpf_internal.h"


// ========================================================================
//
// Operations on levels within the hierarchical page table.  A VTP page
// table is similar to x86_64 page tables, where 9-bit chunks of an
// address are direct mapped into a tree of 512 entry (4KB) pointers.
//
// ========================================================================

static const uint32_t depth_max = 4;

static void nodeReset(
    mpf_vtp_pt_node* node
)
{
    memset(node, -1, sizeof(mpf_vtp_pt_node));
}

static void nodeEntryReset(
    mpf_vtp_pt_node* node,
    uint64_t idx
)
{
    if (idx < 512)
    {
        node->ptable[idx] = (mpf_vtp_pt_paddr)-1;
        node->vtable[idx] = (mpf_vtp_pt_vaddr)-1;
        memset(&node->meta[idx], -1, sizeof(mpf_vtp_pt_meta));
    }
}

static bool nodeIsEmpty(
    mpf_vtp_pt_node* node
)
{
    for (int idx = 0; idx < 512; idx++)
    {
        // Test vaddr so that all lookup operations in software are on the
        // same vector. The ptable and vtable entries are parallel.
        if (node->vtable[idx] != (mpf_vtp_pt_vaddr)-1) return false;
    }

    return true;
}

// Does an entry exist at the index?
static inline bool nodeEntryExists(
    mpf_vtp_pt_node* node,
    uint64_t idx
)
{
    if (idx >= 512)
    {
        return false;
    }

    return (node->vtable[idx] != (mpf_vtp_pt_vaddr)-1);
}

// Is the entry at idx terminal? If so, use GetTranslatedAddr(). If not,
// use GetChildAddr().
static inline bool nodeEntryIsTerminal(
    mpf_vtp_pt_node* node,
    uint64_t idx
)
{
    if (idx >= 512)
    {
        return false;
    }

    return ((uint64_t)node->vtable[idx] & MPF_VTP_PT_FLAG_TERMINAL) != 0;
}

// Walk the tree.
static inline mpf_vtp_pt_node* nodeGetChildNode(
    mpf_vtp_pt_node* node,
    uint64_t idx
)
{
    if ((idx >= 512) || nodeEntryIsTerminal(node, idx))
    {
        return NULL;
    }

    // Mask the flags in order to recover the true pointer
    return (mpf_vtp_pt_node*)((uint64_t)node->vtable[idx] & ~(uint64_t)MPF_VTP_PT_FLAG_MASK);
}

static inline mpf_vtp_pt_paddr nodeGetTranslatedAddr(
    mpf_vtp_pt_node* node,
    uint64_t idx
)
{
    if ((idx >= 512) || ! nodeEntryIsTerminal(node, idx))
    {
        return -1;
    }

    // The terminal entry holds a physical address, even in the vtable.
    // Clear the flags stored in low bits.
    return (mpf_vtp_pt_paddr)node->vtable[idx] & ~(mpf_vtp_pt_paddr)MPF_VTP_PT_FLAG_MASK;
}

static inline uint32_t nodeGetTranslatedAddrFlags(
    mpf_vtp_pt_node* node,
    uint64_t idx
)
{
    if ((idx >= 512) || ! nodeEntryIsTerminal(node, idx))
    {
        return 0;
    }

    return (uint64_t)node->vtable[idx] & (uint32_t)MPF_VTP_PT_FLAG_MASK;
}

static void nodeInsertChildNode(
    mpf_vtp_pt_node* node,
    uint64_t idx,
    mpf_vtp_pt_node* child_node,
    mpf_vtp_pt_paddr child_paddr,
    uint64_t child_wsid
)
{
    if (idx < 512)
    {
        node->ptable[idx] = child_paddr;
        node->vtable[idx] = child_node;
        node->meta[idx].wsid = child_wsid;
        node->meta[idx].alloc_buf_len = 0;
    }
}

static void nodeInsertTranslatedAddr(
    mpf_vtp_pt_node* node,
    uint64_t idx,
    mpf_vtp_pt_paddr paddr,
    uint64_t wsid,
    // Flags, ORed from mpf_vtp_pt_flag
    int64_t flags
)
{
    if (idx < 512)
    {
        // In the terminal entry both the ptable and the vtable hold the same
        // value: the translated physical address, plus some flags in the low
        // bits. The low bits are otherwise guaranteed to be 0 since the page
        // is aligned at least to 4KB.
        mpf_vtp_pt_paddr pa = paddr | MPF_VTP_PT_FLAG_TERMINAL | flags;
        node->ptable[idx] = pa;
        node->vtable[idx] = (mpf_vtp_pt_vaddr)pa;
        node->meta[idx].wsid = wsid;
        node->meta[idx].alloc_buf_len = 0;
    }
}

static void nodeRemoveTranslatedAddr(
    mpf_vtp_pt_node* node,
    uint64_t idx
)
{
    if (idx < 512)
    {
        node->ptable[idx] = (mpf_vtp_pt_paddr)-1;
        node->vtable[idx] = (mpf_vtp_pt_vaddr)-1;
    }
}


// ========================================================================
//
// Internal page table manipulation functions.
//
// ========================================================================

//
// Compute the node index at specified depth in the tree of a page table
// for the given address.
//
static uint64_t ptIdxFromAddr(
    uint64_t addr,
    uint32_t depth
)
{
    // Drop 4KB page offset
    uint64_t idx = addr >> 12;

    // Get index for requested depth
    if (depth)
    {
        idx >>= (depth * 9);
    }

    return idx & 0x1ff;
}


//
// Address mask, given a table depth.
//
static uint64_t addrMaskFromPtDepth(
    uint32_t depth
)
{
    uint64_t mask = ~(uint64_t)0;

    // Shift the low bits out and back in to clear them
    mask >>= (12 + (depth * 9));
    mask <<= (12 + (depth * 9));

    return mask;
}


//
// Allocate a page table node. The first 4KB region is the virtual to physical
// table, which is pinned and shared with the FPGA.
//
static fpga_result ptAllocTableNode(
    mpf_vtp_pt* pt,
    mpf_vtp_pt_node** node_p,
    mpf_vtp_pt_paddr* pa_p,
    uint64_t* wsid_p
)
{
    fpga_result r;

    *node_p = NULL;
    *pa_p = 0;
    *wsid_p = 0;

    // Map the node's memory
    mpf_vtp_pt_node* node;
    mpf_vtp_page_size page_size = MPF_VTP_PAGE_4KB;
    r = mpfOsMapMemory(sizeof(mpf_vtp_pt_node), &page_size, (void**)&node);
    if (r != FPGA_OK) return r;
    *node_p = node;

    // Initialize it
    nodeReset(node);

    // Pin the first page
    r = fpgaPrepareBuffer(pt->_mpf_handle->handle, 4096, (void*)&node,
                          wsid_p, FPGA_BUF_PREALLOCATED);
    if (r != FPGA_OK) goto fail;

    // Get the FPGA-side physical address
    r = fpgaGetIOAddress(pt->_mpf_handle->handle, *wsid_p, pa_p);
    // This failure would be a catastrophic internal OPAE failure. Just give up.
    assert(FPGA_OK == r);

    if (pt->_mpf_handle->dbg_mode)
    {
        MPF_FPGA_MSG("allocate I/O mapped TLB node VA %p, PA 0x%016" PRIx64 ", wsid 0x%" PRIx64,
                     *node_p, *pa_p, *wsid_p);
    }

    return FPGA_OK;

  fail:
    mpfOsUnmapMemory((void*)node, 4096);
    return r;
}


static fpga_result ptFreeTableNode(
    mpf_vtp_pt* pt,
    mpf_vtp_pt_node* node,
    uint64_t wsid
)
{
    if (pt->_mpf_handle->dbg_mode)
    {
        MPF_FPGA_MSG("free I/O mapped TLB node VA %p, wsid 0x%" PRIx64, node, wsid);
    }

    // Invalidate the address in any hardware tables (page table walker cache)
    mpfVtpInvalVAMapping(pt->_mpf_handle, (mpf_vtp_pt_vaddr)node);

    // Unpin the page
    fpga_result r = fpgaReleaseBuffer(pt->_mpf_handle, wsid);

    // Free the storage
    mpfOsUnmapMemory((void*)node, sizeof(mpf_vtp_pt_node));

    return r;
}


static fpga_result addVAtoTable(
    mpf_vtp_pt* pt,
    mpf_vtp_pt_vaddr va,
    mpf_vtp_pt_paddr pa,
    uint64_t wsid,
    uint32_t depth,
    uint32_t flags
)
{
    mpf_vtp_pt_node* table = pt->pt_root;

    // Index in the leaf page
    uint64_t leaf_idx = ptIdxFromAddr((uint64_t)va, depth_max - depth);

    uint32_t cur_depth = depth_max;
    while (--depth)
    {
        // Table index for the current level
        uint64_t idx = ptIdxFromAddr((uint64_t)va, --cur_depth);

        // Need a new page in the table?
        if (! nodeEntryExists(table, idx))
        {
            mpf_vtp_pt_node* child_node;
            mpf_vtp_pt_paddr child_pa;
            uint64_t child_wsid;
            if (FPGA_OK != ptAllocTableNode(pt, &child_node, &child_pa, &child_wsid))
            {
                return FPGA_NO_MEMORY;
            }

            // Add new page to the table
            nodeInsertChildNode(table, idx, child_node, child_pa, child_wsid);
        }

        // Are we being asked to add an entry below a larger region that
        // is already mapped?
        if (nodeEntryIsTerminal(table, idx)) return FPGA_EXCEPTION;

        // Continue down the tree
        table = nodeGetChildNode(table, idx);

        // This should never happen. The check for nodeEntryExists() above should
        // guarantee the child table exists.
        assert(NULL != table);
    }

    // Now at the leaf.  Add the translation.
    if (nodeEntryExists(table, leaf_idx))
    {
        if ((cur_depth == 2) && ! nodeEntryIsTerminal(table, leaf_idx))
        {
            // Entry exists while trying to add a 2MB entry.  Perhaps there is
            // an old leaf that used to hold 4KB pages.  If the existing
            // entry has no active pages then get rid of it.
            mpf_vtp_pt_node* child_node = nodeGetChildNode(table, leaf_idx);

            if (! nodeIsEmpty(child_node)) return FPGA_EXCEPTION;

            // The old page that held 4KB translations is now empty and the
            // pointer will be overwritten with a 2MB page pointer.
            ptFreeTableNode(pt, child_node, table->meta[leaf_idx].wsid);
            nodeEntryReset(table, leaf_idx);
        }
        else
        {
            return FPGA_EXCEPTION;
        }
    }

    nodeInsertTranslatedAddr(table, leaf_idx, pa, wsid, flags);

    // Memory fence for updates before claiming the table is ready
    mpfOsMemoryBarrier();

    return FPGA_OK;
}


//
// Primitive function to search the table for a VA and return the node containing
// the terminal pointer.
//
static inline fpga_result findTerminalNodeAndIndex(
    mpf_vtp_pt* pt,
    mpf_vtp_pt_vaddr va,
    mpf_vtp_pt_node** node_p,
    uint64_t* idx_p,
    uint32_t* depth_p
)
{
    if (depth_p)
    {
        *depth_p = depth_max;
    }

    mpf_vtp_pt_node* node = pt->pt_root;
    if (NULL == node) return FPGA_NOT_FOUND;

    uint32_t depth = depth_max;
    while (depth--)
    {
        // Index in the current level
        uint64_t idx = ptIdxFromAddr((uint64_t)va, depth);

        // Depth is always updated because it may be used, even on failure.
        if (depth_p)
        {
            *depth_p = depth;
        }

        if (! nodeEntryExists(node, idx)) return FPGA_NOT_FOUND;

        if (nodeEntryIsTerminal(node, idx))
        {
            *node_p = node;
            *idx_p = idx;

            return FPGA_OK;
        }

        // Walk down to child. We already know that the child exists since
        // the code above proves that the entry at idx exists and is not
        // terminal.
        node = nodeGetChildNode(node, idx);
    }

    return FPGA_NOT_FOUND;
}


//
// Called on termination to delete all mapped pages and page table nodes.
//
static void freeTableAndPinnedPages(
    mpf_vtp_pt* pt,
    mpf_vtp_pt_node* node,
    uint64_t node_wsid,
    uint64_t partial_va,
    uint32_t depth)
{
    for (uint64_t idx = 0; idx < 512; idx++)
    {
        if (nodeEntryExists(node, idx))
        {
            uint64_t va = partial_va | (idx << (12 + 9 * (depth - 1)));
            uint64_t child_wsid = node->meta[idx].wsid;

            if (nodeEntryIsTerminal(node, idx))
            {
                uint32_t flags = nodeGetTranslatedAddrFlags(node, idx);
                if (MPF_VTP_PT_FLAG_ALLOC & flags)
                {
                    // Free the MPF-allocated virtual buffer
                    if (pt->_mpf_handle->dbg_mode)
                    {
                        MPF_FPGA_MSG("release virtual buffer VA 0x%016" PRIx64 "-0x%016" PRIx64 " (%ld KB)",
                                     va, va + node->meta[idx].alloc_buf_len,
                                     node->meta[idx].alloc_buf_len / 1024);
                    }

                    mpfOsUnmapMemory((void*)va, node->meta[idx].alloc_buf_len);
                }

                fpgaReleaseBuffer(pt->_mpf_handle->handle, child_wsid);

                if (pt->_mpf_handle->dbg_mode)
                {
                    mpf_vtp_pt_paddr child_pa = node->ptable[idx] & ~(uint64_t)MPF_VTP_PT_FLAG_MASK;
                    MPF_FPGA_MSG("release pinned page PA 0x%016" PRIx64 ", wsid 0x%" PRIx64,
                                 child_pa, child_wsid);
                }

            }
            else
            {
                // The entry is a pointer internal to the page table.
                // Follow it to the next level.
                assert(depth != 1);

                freeTableAndPinnedPages(pt, nodeGetChildNode(node, idx),
                                        child_wsid, va, depth - 1);
            }
        }
    }

    // Done with this node
    fpgaReleaseBuffer(pt->_mpf_handle->handle, node_wsid);
    if (pt->_mpf_handle->dbg_mode)
    {
        MPF_FPGA_MSG("release table node VA %p, wsid 0x%" PRIx64, node, node_wsid);
    }
}


static void dumpPageTable(
    mpf_vtp_pt* pt,
    mpf_vtp_pt_node* node,
    mpf_vtp_pt_paddr node_pa,
    uint64_t node_wsid,
    uint64_t partial_va,
    uint32_t depth)
{
    // Generate an indent string as a function of depth
    char indent[17];
    for (int i = 0; i < 16; i++)
    {
        indent[i] = ' ';
    }
    indent[2 * (depth_max - depth)] = 0;

    printf("%s  Node prefix VA 0x%016" PRIx64 " at VA %p, PA 0x%016" PRIx64 ", wsid 0x%" PRIx64 "\n",
           indent, partial_va, node, node_pa, node_wsid);

    for (uint64_t idx = 0; idx < 512; idx++)
    {
        if (nodeEntryExists(node, idx))
        {
            uint64_t va = partial_va | (idx << (12 + 9 * (depth - 1)));
            if (nodeEntryIsTerminal(node, idx))
            {
                // Found a translation
                const char *kind;
                switch (depth)
                {
                  case 1:
                    kind = "4KB";
                    break;
                  case 2:
                    kind = "2MB";
                    break;
                  default:
                    kind = "?";
                    break;
                }

                mpf_vtp_pt_paddr pa = nodeGetTranslatedAddr(node, idx);

                printf("%s    VA 0x%016" PRIx64 " -> PA 0x%016" PRIx64 " (%s)  wsid 0x%" PRIx64,
                       indent, va, pa, kind, node->meta[idx].wsid);

                uint32_t flags = nodeGetTranslatedAddrFlags(node, idx);
                if (flags & (MPF_VTP_PT_FLAG_MASK - MPF_VTP_PT_FLAG_TERMINAL))
                {
                    printf(" [");
                    if (flags & MPF_VTP_PT_FLAG_ALLOC) printf(" ALLOC");
                    if (flags & MPF_VTP_PT_FLAG_PREALLOC) printf(" PREALLOC");
                    if (flags & MPF_VTP_PT_FLAG_INVALID) printf(" INVALID");
                    printf(" ]");
                }
                printf("\n");

                if (flags & (MPF_VTP_PT_FLAG_ALLOC | MPF_VTP_PT_FLAG_PREALLOC))
                {
                    printf("%s      Buffer: VA 0x%016" PRIx64 "-0x%016" PRIx64 " (%ld KB)\n",
                           indent, va, va + node->meta[idx].alloc_buf_len,
                           node->meta[idx].alloc_buf_len / 1024);
                }
            }
            else
            {
                // Follow pointer to another level
                assert(depth != 1);

                mpf_vtp_pt_paddr child_pa = node->ptable[idx] & ~(uint64_t)MPF_VTP_PT_FLAG_MASK;

                dumpPageTable(pt, nodeGetChildNode(node, idx), child_pa,
                              node->meta[idx].wsid, va, depth - 1);
            }
        }
    }
}


// ========================================================================
//
// Public (though still MPF internal) functions.
//
// ========================================================================

fpga_result mpfVtpPtInit(
    _mpf_handle_p _mpf_handle,
    mpf_vtp_pt** pt
)
{
    fpga_result r;
    mpf_vtp_pt* new_pt;

    new_pt = malloc(sizeof(mpf_vtp_pt));
    *pt = new_pt;
    if (NULL == new_pt) return FPGA_NO_MEMORY;
    memset(new_pt, 0, sizeof(mpf_vtp_pt));

    new_pt->_mpf_handle = _mpf_handle;

    // Allocate a mutex that protects the page table manager
    r = mpfOsPrepareMutex(&new_pt->mutex);
    if (FPGA_OK != r) return r;

    // Virtual to physical map is shared with the FPGA
    r = ptAllocTableNode(new_pt,
                         &new_pt->pt_root,
                         &new_pt->pt_root_paddr,
                         &new_pt->pt_root_wsid);
    if (FPGA_OK != r) return r;

    return FPGA_OK;
}


fpga_result mpfVtpPtTerm(
    mpf_vtp_pt* pt
)
{
    // Release all pinned pages and the table
    mpfOsLockMutex(pt->mutex);
    freeTableAndPinnedPages(pt, pt->pt_root, pt->pt_root_wsid, 0, depth_max);
    mpfOsUnlockMutex(pt->mutex);

    // Drop the allocated mutex
    mpfOsDestroyMutex(pt->mutex);
    pt->mutex = NULL;

    pt->pt_root = NULL;
    pt->_mpf_handle = NULL;

    // Release the top-level page table descriptor
    free(pt);

    return FPGA_OK;
}


mpf_vtp_pt_paddr mpfVtpPtGetPageTableRootPA(
    mpf_vtp_pt* pt
)
{
    return pt->pt_root_paddr;
}


fpga_result mpfVtpPtInsertPageMapping(
    mpf_vtp_pt* pt,
    mpf_vtp_pt_vaddr va,
    mpf_vtp_pt_paddr pa,
    uint64_t wsid,
    mpf_vtp_page_size size,
    uint32_t flags
)
{
    // Caller must lock the mutex
    DBG_MPF_OS_TEST_MUTEX_IS_LOCKED(pt->mutex);

    // Are the addresses reasonable?
    uint64_t mask = (size == MPF_VTP_PAGE_4KB) ? (1 << 12) - 1 :
                                                 (1 << 21) - 1;
    if ((0 != ((uint64_t)va & mask)) || (0 != (pa & mask)))
    {
        return FPGA_INVALID_PARAM;
    }

    uint32_t depth = depth_max;
    if (size != MPF_VTP_PAGE_4KB)
    {
        // 2MB page is one node up in the table hierarchy
        depth -= 1;
    }

    return addVAtoTable(pt, va, pa, wsid, depth, flags);
}


fpga_result mpfVtpPtSetAllocBufSize(
    mpf_vtp_pt* pt,
    mpf_vtp_pt_vaddr va,
    ssize_t buf_size
)
{
    // Caller must lock the mutex
    DBG_MPF_OS_TEST_MUTEX_IS_LOCKED(pt->mutex);

    fpga_result r;
    mpf_vtp_pt_node* node;
    uint64_t idx;

    // Find the containing node
    r = findTerminalNodeAndIndex(pt, va, &node, &idx, NULL);
    if (FPGA_OK != r) return r;

    // One of the ALLOC flags must be set when buffer size is recorded
    uint32_t flags = nodeGetTranslatedAddrFlags(node, idx);
    if (0 == (flags & (MPF_VTP_PT_FLAG_ALLOC | MPF_VTP_PT_FLAG_PREALLOC)))
    {
        return FPGA_EXCEPTION;
    }

    node->meta[idx].alloc_buf_len = buf_size;

    return FPGA_OK;
}


fpga_result mpfVtpPtGetAllocBufSize(
    mpf_vtp_pt* pt,
    mpf_vtp_pt_vaddr va,
    mpf_vtp_pt_vaddr* start_va,
    ssize_t* buf_size
)
{
    // Caller must lock the mutex
    DBG_MPF_OS_TEST_MUTEX_IS_LOCKED(pt->mutex);

    fpga_result r;
    mpf_vtp_pt_node* node;
    uint64_t idx;
    uint32_t depth;

    // Find the containing node
    r = findTerminalNodeAndIndex(pt, va, &node, &idx, &depth);
    if (FPGA_OK != r) return r;

    // One of the ALLOC flags must be set when buffer size is recorded
    uint32_t flags = nodeGetTranslatedAddrFlags(node, idx);
    if (0 == (flags & (MPF_VTP_PT_FLAG_ALLOC | MPF_VTP_PT_FLAG_PREALLOC)))
    {
        return FPGA_EXCEPTION;
    }

    *buf_size = node->meta[idx].alloc_buf_len;

    // Mask the start_va so it points to the start of the page
    if (start_va)
    {
        *start_va = (mpf_vtp_pt_vaddr)((uint64_t)va & addrMaskFromPtDepth(depth));
    }

    return FPGA_OK;
}


fpga_result mpfVtpPtRemovePageMapping(
    mpf_vtp_pt* pt,
    mpf_vtp_pt_vaddr va,
    mpf_vtp_pt_paddr *pa,
    uint64_t *wsid,
    mpf_vtp_page_size *size,
    uint32_t *flags
)
{
    // Caller must lock the mutex
    DBG_MPF_OS_TEST_MUTEX_IS_LOCKED(pt->mutex);

    mpf_vtp_pt_node* node = pt->pt_root;

    uint32_t depth = depth_max;
    while (depth--)
    {
        // Index in the current level
        uint64_t idx = ptIdxFromAddr((uint64_t)va, depth);

        if (! nodeEntryExists(node, idx)) return FPGA_NOT_FOUND;

        if (nodeEntryIsTerminal(node, idx))
        {
            if (pa)
            {
                *pa = nodeGetTranslatedAddr(node, idx);
            }

            if (wsid)
            {
                *wsid = node->meta[idx].wsid;
            }

            if (size)
            {
                *size = (depth == 1 ? MPF_VTP_PAGE_2MB : MPF_VTP_PAGE_4KB);
            }

            if (flags)
            {
                *flags = nodeGetTranslatedAddrFlags(node, idx);
            }

            nodeRemoveTranslatedAddr(node, idx);

            mpfOsMemoryBarrier();

            return FPGA_OK;
        }

        // Walk down to child
        node = nodeGetChildNode(node, idx);
    }

    return FPGA_NOT_FOUND;
}


fpga_result mpfVtpPtTranslateVAtoPA(
    mpf_vtp_pt* pt,
    mpf_vtp_pt_vaddr va,
    mpf_vtp_pt_paddr *pa,
    mpf_vtp_page_size *size,
    uint32_t *flags
)
{
    // Caller must lock the mutex
    DBG_MPF_OS_TEST_MUTEX_IS_LOCKED(pt->mutex);

    fpga_result r;
    mpf_vtp_pt_node* node;
    uint64_t idx;
    uint32_t depth;

    r = findTerminalNodeAndIndex(pt, va, &node, &idx, &depth);

    // Update size on every even for failed transactions so callers know
    // at what level searching stopped.
    if (size)
    {
        *size = (depth >= 1 ? MPF_VTP_PAGE_2MB : MPF_VTP_PAGE_4KB);
    }

    if (FPGA_OK != r)
    {
        return FPGA_NOT_FOUND;
    }

    *pa = nodeGetTranslatedAddr(node, idx);
    if (flags)
    {
        *flags = nodeGetTranslatedAddrFlags(node, idx);
    }

    return FPGA_OK;
}


void mpfVtpPtDumpPageTable(
    mpf_vtp_pt* pt
)
{
    // Caller must lock the mutex
    DBG_MPF_OS_TEST_MUTEX_IS_LOCKED(pt->mutex);

    printf("VTP Page Table:\n");
    dumpPageTable(pt, pt->pt_root, pt->pt_root_paddr, pt->pt_root_wsid, 0, depth_max);
}
