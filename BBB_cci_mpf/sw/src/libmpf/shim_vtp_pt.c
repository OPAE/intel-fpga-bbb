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

static mpf_vtp_page_size ptDepthToSize(
    uint32_t depth
)
{
    mpf_vtp_page_size s;

    switch (depth)
    {
      case 0:
        s = MPF_VTP_PAGE_4KB;
        break;
      case 1:
        s = MPF_VTP_PAGE_2MB;
        break;
      case 2:
        s = MPF_VTP_PAGE_1GB;
        break;
      default:
        s = MPF_VTP_PAGE_NONE;
    }

    return s;
}

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
    if (node == NULL)
    {
        return true;
    }

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
    if (idx >= 512 || node == NULL)
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

static inline void nodeSetTranslatedAddrFlags(
    mpf_vtp_pt_node* node,
    uint64_t idx,
    uint32_t flags
)
{
    if (idx < 512)
    {
        node->vtable[idx] = (mpf_vtp_pt_vaddr)((uint64_t)node->vtable[idx] | flags);
    }
}

static inline void nodeClearTranslatedAddrFlags(
    mpf_vtp_pt_node* node,
    uint64_t idx,
    uint32_t flags
)
{
    if (idx < 512)
    {
        node->vtable[idx] = (mpf_vtp_pt_vaddr)((uint64_t)node->vtable[idx] & ~(uint64_t)flags);
    }
}

static inline void nodeInsertChildNode(
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
        node->meta[idx].refcnt = 1;
    }
}

static inline void nodeInsertTranslatedAddr(
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
        node->meta[idx].refcnt = 1;
    }
}

static inline uint64_t nodeGetRefCnt(
    mpf_vtp_pt_node* node,
    uint64_t idx
)
{
    if (idx < 512)
    {
        return node->meta[idx].refcnt;
    }

    return 0;
}

static inline void nodeDecrRefCnt(
    mpf_vtp_pt_node* node,
    uint64_t idx
)
{
    if (idx < 512)
    {
        assert(node->meta[idx].refcnt != 0);
        node->meta[idx].refcnt -= 1;
    }
}

static inline void nodeIncrRefCnt(
    mpf_vtp_pt_node* node,
    uint64_t idx,
    int64_t flags
)
{
    // Incrementing a page's reference count may only happen on user memory
    // pages and not the page table itself. Failing this test is a VTP
    // internal problem, so just abort.
    assert(nodeEntryIsTerminal(node, idx));

    if (idx < 512)
    {
        // It should never happen that both prealloc and alloc are set,
        // but we'll give prealloc precendence to avoid unmapping pages
        // the user claims to have mapped.
        if (MPF_VTP_PT_FLAG_PREALLOC & flags)
        {
            mpf_vtp_pt_paddr pa = node->ptable[idx] | MPF_VTP_PT_FLAG_PREALLOC;
            // Clear MPF_VTP_PT_FLAG_ALLOC in case it was set. If it
            // really was set this may well lead to a memory leak, but
            // it avoids a crash.
            pa = pa & ~(mpf_vtp_pt_paddr)MPF_VTP_PT_FLAG_ALLOC;
            node->ptable[idx] = pa;
            node->vtable[idx] = (mpf_vtp_pt_vaddr)pa;
        }

        node->meta[idx].refcnt += 1;
    }
}

static inline void nodeRemoveTranslatedAddr(
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

static inline void invalFindNodeCache(
    mpf_vtp_pt* pt
)
{
    pt->prev_find_term_node = NULL;
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

    if (pt->hw_pt_walker_present)
    {
        // Pin the first page
        r = fpgaPrepareBuffer(pt->_mpf_handle->handle, 4096, (void*)&node,
                              wsid_p, FPGA_BUF_PREALLOCATED);
        if (r != FPGA_OK) goto fail;

        // Get the FPGA-side physical address
        r = fpgaGetIOAddress(pt->_mpf_handle->handle, *wsid_p, pa_p);
        // This failure would be a catastrophic internal OPAE failure.
        // Just give up.
        assert(FPGA_OK == r);

        if (pt->_mpf_handle->dbg_mode)
        {
            MPF_FPGA_MSG("allocate I/O mapped TLB node VA %p, PA 0x%016" PRIx64 ", wsid 0x%" PRIx64,
                         *node_p, *pa_p, *wsid_p);
        }
    }
    else
    {
        if (pt->_mpf_handle->dbg_mode)
        {
            MPF_FPGA_MSG("allocate host-only TLB node VA %p, PA 0x%016" PRIx64,
                         *node_p, *pa_p);
        }
    }

    return FPGA_OK;

  fail:
    mpfOsUnmapMemory((void*)node, 4096);
    return r;
}


static fpga_result ptFreeTableNode(
    mpf_vtp_pt* pt,
    mpf_vtp_pt_node* node,
    uint64_t wsid,
    bool do_inval
)
{
    if (NULL == node) return FPGA_OK;

    // Unpin the page
    fpga_result r = FPGA_OK;
    if (pt->hw_pt_walker_present)
    {
        if (pt->_mpf_handle->dbg_mode)
        {
            MPF_FPGA_MSG("free I/O mapped TLB node VA %p, wsid 0x%" PRIx64, node, wsid);
        }

        // Invalidate the address in any hardware tables (page table walker cache)
        if (do_inval)
        {
            vtpInvalHWVAMapping(pt->_mpf_handle, (mpf_vtp_pt_vaddr)node, true);
        }

        r = fpgaReleaseBuffer(pt->_mpf_handle->handle, wsid);
    }
    else
    {
        if (pt->_mpf_handle->dbg_mode)
        {
            MPF_FPGA_MSG("free host-only TLB node VA %p", node);
        }
    }

    // Free the storage
    mpfOsUnmapMemory((void*)node, sizeof(mpf_vtp_pt_node));
    invalFindNodeCache(pt);

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
        // is already mapped? If so, just increment the refcnt.
        if (nodeEntryIsTerminal(table, idx))
        {
            nodeIncrRefCnt(table, idx, flags);
            return FPGA_OK;
        }

        // Continue down the tree
        table = nodeGetChildNode(table, idx);

        // This should never happen. The check for nodeEntryExists() above should
        // guarantee the child table exists.
        assert(NULL != table);
    }

    invalFindNodeCache(pt);

    // Now at the leaf.  Add the translation.
    if (nodeEntryExists(table, leaf_idx))
    {
        if ((cur_depth >= 2) && ! nodeEntryIsTerminal(table, leaf_idx))
        {
            // Entry exists while trying to add a huge entry. Perhaps there
            // is an old leaf that used to hold smaller pages. If the existing
            // entry has no active pages then get rid of it.
            mpf_vtp_pt_node* child_node = nodeGetChildNode(table, leaf_idx);

            if (! nodeIsEmpty(child_node)) return FPGA_EXCEPTION;

            // The old page that held 4KB translations is now empty and the
            // pointer will be overwritten with a huge page pointer.
            ptFreeTableNode(pt, child_node, table->meta[leaf_idx].wsid, true);
            nodeEntryReset(table, leaf_idx);
        }
        else if (nodeEntryIsTerminal(table, leaf_idx))
        {
            // Another request to map an existing page. Just count it.
            nodeIncrRefCnt(table, leaf_idx, flags);
            return FPGA_OK;
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
    //
    // This function may be on a critical path, so we cache the result of
    // the last tree walk. When the FPGA is streaming through memory, the
    // cache will often hit since virtually contiguous translations are
    // likely to be on the same node.
    //
    uint32_t depth = pt->prev_depth + 1;
    mpf_vtp_pt_node* node = pt->prev_find_term_node;
    uint64_t mask = addrMaskFromPtDepth(pt->prev_depth);
    if (! node ||
        // Previous VA and current one's bits must match in the node index portion
        (0 != (mask & ((uint64_t)pt->prev_va ^ (uint64_t)va))))
    {
        // Last result was on a different node. Start from the root.
        depth = depth_max;
        node = pt->pt_root;
    }

    if (depth_p)
    {
        *depth_p = depth;
    }

    if (NULL == node) return FPGA_NOT_FOUND;

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

            pt->prev_depth = depth;
            pt->prev_va = va;
            pt->prev_find_term_node = node;
            pt->prev_idx = idx;

            return FPGA_OK;
        }

        // Walk down to child. We already know that the child exists since
        // the code above proves that the entry at idx exists and is not
        // terminal.
        node = nodeGetChildNode(node, idx);
    }

    pt->prev_find_term_node = NULL;
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
    if (NULL == node) return;

    mpf_vtp_page_size page_size = ptDepthToSize(depth);

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
                        MPF_FPGA_MSG("release virtual buffer VA 0x%016" PRIx64 "-0x%016" PRIx64 " (%d KB)",
                                     va, va + page_size, page_size / 1024);
                    }

                    mpfOsUnmapMemory((void*)va, page_size);
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
    ptFreeTableNode(pt, node, node_wsid, false);
}


//
// Release a virtual range of pinned pages.
//
static bool releaseRange(
    mpf_vtp_pt* pt,
    mpf_vtp_pt_node* node,
    uintptr_t min_va,
    uintptr_t max_va,
    uintptr_t partial_va,
    uint32_t depth)
{
    bool node_active = false;

    // Address span of a node's region at current depth
    uint64_t depth_addr_shift = 12 + 9 * (depth - 1);
    uint64_t depth_addr_span = 1LL << depth_addr_shift;

    for (uint64_t idx = 0; idx < 512; idx++)
    {
        if (nodeEntryExists(node, idx))
        {
            uintptr_t va = partial_va | (idx << depth_addr_shift);
            uintptr_t va_next = va + depth_addr_span;
            uint64_t child_wsid = node->meta[idx].wsid;

            // Is the node within the address range being unpinned?
            if ((min_va < va_next) && (va < max_va))
            {
                if (pt->_mpf_handle->dbg_mode)
                {
                    MPF_FPGA_MSG("depth %" PRId32 ": idx %" PRId64 ", 0x%016" PRIx64 " - 0x%016" PRIx64,
                                 depth, idx, va, va_next);
                }

                // Yes, address is in range. Keep walking down the tree.
                if (nodeEntryIsTerminal(node, idx))
                {
                    if (nodeGetRefCnt(node, idx) > 1)
                    {
                        // Multiple references exist to the page. Decrement the
                        // counter and leave the page pinned.
                        nodeDecrRefCnt(node, idx);
                        node_active = true;

                        if (pt->_mpf_handle->dbg_mode)
                        {
                            mpf_vtp_pt_paddr child_pa = node->ptable[idx] & ~(uint64_t)MPF_VTP_PT_FLAG_MASK;
                            MPF_FPGA_MSG("decrement refcnt pinned page PA 0x%016" PRIx64 ", wsid 0x%" PRIx64 ", refcnt %" PRId64,
                                         child_pa, child_wsid, nodeGetRefCnt(node, idx));
                        }
                    }
                    else
                    {
                        vtpInvalHWVAMapping(pt->_mpf_handle, (mpf_vtp_pt_vaddr)va, true);
                        fpgaReleaseBuffer(pt->_mpf_handle->handle, child_wsid);
                        nodeRemoveTranslatedAddr(node, idx);

                        if (pt->_mpf_handle->dbg_mode)
                        {
                            mpf_vtp_pt_paddr child_pa = node->ptable[idx] & ~(uint64_t)MPF_VTP_PT_FLAG_MASK;
                            MPF_FPGA_MSG("release pinned page PA 0x%016" PRIx64 ", wsid 0x%" PRIx64,
                                         child_pa, child_wsid);
                        }
                    }
                }
                else
                {
                    // The entry is a pointer internal to the page table.
                    // Follow it to the next level.
                    assert(depth != 1);

                    mpf_vtp_pt_node* child_node = nodeGetChildNode(node, idx);
                    bool child_active;
                    child_active = releaseRange(pt, child_node,
                                                min_va, max_va,
                                                va, depth - 1);

                    if (child_active)
                    {
                        node_active = true;
                    }
                    else
                    {
                        // Drop the page table node for the subtree since nothing
                        // below it is active.
                        ptFreeTableNode(pt, child_node, child_wsid, true);
                        nodeEntryReset(node, idx);
                    }
                }
            }
            else
            {
                // Node is outside the range being unpinned. Part of the node
                // remains active.
                node_active = true;
                // No point in testing other entries. We already know the node
                // remains active.
                if (va > max_va) break;
            }
        }
    }

    // Done with this node
    return node_active;
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
                  case 3:
                    kind = "1GB";
                    break;
                  default:
                    kind = "?";
                    break;
                }

                mpf_vtp_pt_paddr pa = nodeGetTranslatedAddr(node, idx);

                printf("%s    VA 0x%016" PRIx64 " -> PA 0x%016" PRIx64 " (%s)  wsid 0x%" PRIx64 " refcnt %" PRId64,
                       indent, va, pa, kind, node->meta[idx].wsid, node->meta[idx].refcnt);

                uint32_t flags = nodeGetTranslatedAddrFlags(node, idx);
                if (flags & (MPF_VTP_PT_FLAG_MASK - MPF_VTP_PT_FLAG_TERMINAL))
                {
                    printf(" [");
                    if (flags & MPF_VTP_PT_FLAG_ALLOC) printf(" ALLOC");
                    if (flags & MPF_VTP_PT_FLAG_PREALLOC) printf(" PREALLOC");
                    if (flags & MPF_VTP_PT_FLAG_INVALID) printf(" INVALID");
                    if (flags & MPF_VTP_PT_FLAG_IN_USE) printf(" IN_USE");
                    if (flags & MPF_VTP_PT_FLAG_READ_ONLY) printf(" READ_ONLY");
                    printf(" ]");
                }
                printf("\n");
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

    // Is there a VTP hardware page table walker instantiated on the FPGA?
    new_pt->hw_pt_walker_present = false;
    if (mpfShimPresent(_mpf_handle, CCI_MPF_SHIM_VTP))
    {
        // The VTP hardware miss handler may either walk the page table itself
        // or call a service, in which case the page table doesn't need to
        // be pinned. This is indicated in bit 3 of the VTP mode CSR.
        uint64_t vtp_mode = mpfReadCsr(_mpf_handle, CCI_MPF_SHIM_VTP,
                                       CCI_MPF_VTP_CSR_MODE, NULL);
        bool sw_translation = (vtp_mode & 8);
        new_pt->hw_pt_walker_present = ! sw_translation;
    }

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
    invalFindNodeCache(pt);
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
    if (size == MPF_VTP_PAGE_2MB)
    {
        // 2MB page is one node up in the table hierarchy
        depth -= 1;
    }
    else if (size == MPF_VTP_PAGE_1GB)
    {
        // 1GB page is two nodes up in the table hierarchy
        depth -= 2;
    }

    return addVAtoTable(pt, va, pa, wsid, depth, flags);
}


fpga_result mpfVtpPtClearInUseFlag(
    mpf_vtp_pt* pt,
    mpf_vtp_pt_vaddr va
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

    nodeClearTranslatedAddrFlags(node, idx, MPF_VTP_PT_FLAG_IN_USE);

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
                *size = ptDepthToSize(depth);
            }

            if (flags)
            {
                *flags = nodeGetTranslatedAddrFlags(node, idx);
            }

            if (nodeGetRefCnt(node, idx) > 1)
            {
                // Multiple references exist to the page. Decrement the
                // counter and leave the page pinned.
                nodeDecrRefCnt(node, idx);
                return FPGA_BUSY;
            }

            nodeRemoveTranslatedAddr(node, idx);
            invalFindNodeCache(pt);

            mpfOsMemoryBarrier();

            return FPGA_OK;
        }

        // Walk down to child
        node = nodeGetChildNode(node, idx);
    }

    return FPGA_NOT_FOUND;
}


fpga_result mpfVtpPtReleaseRange(
    mpf_vtp_pt* pt,
    void* min_va,
    void* max_va
)
{
    // Caller must lock the mutex
    DBG_MPF_OS_TEST_MUTEX_IS_LOCKED(pt->mutex);

    releaseRange(pt, pt->pt_root,
                 (uintptr_t)min_va, (uintptr_t)max_va,
                 0, depth_max);

    return FPGA_OK;
}


fpga_result mpfVtpPtTranslateVAtoPA(
    mpf_vtp_pt* pt,
    mpf_vtp_pt_vaddr va,
    bool set_in_use,
    mpf_vtp_pt_vaddr* start_va,
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
        *size = ptDepthToSize(depth);
    }

    if (FPGA_OK != r)
    {
        return FPGA_NOT_FOUND;
    }

    if (set_in_use)
    {
        nodeSetTranslatedAddrFlags(node, idx, MPF_VTP_PT_FLAG_IN_USE);
    }

    // Mask the start_va so it points to the start of the page
    if (start_va)
    {
        *start_va = (mpf_vtp_pt_vaddr)((uint64_t)va & addrMaskFromPtDepth(depth));
    }

    *pa = nodeGetTranslatedAddr(node, idx);
    if (flags)
    {
        *flags = nodeGetTranslatedAddrFlags(node, idx);
    }

    return FPGA_OK;
}


int mpfVtpPtExtendVecVAtoPA(
    mpf_vtp_pt* pt,
    int max_pages,
    bool set_in_use,
    mpf_vtp_pt_paddr *pa,
    uint32_t *flags
)
{
    UNUSED_PARAM(set_in_use);

    // Caller must lock the mutex
    DBG_MPF_OS_TEST_MUTEX_IS_LOCKED(pt->mutex);

    mpf_vtp_pt_node* node = pt->prev_find_term_node;
    uint64_t idx = pt->prev_idx;

    // No cached result or pages are larger than 1GB?
    if (! node || (pt->prev_depth > 2)) return 0;

    //
    // Return pages as long as:
    //  - No more than max_pages are returned
    //  - There are translations left in the current 512 entry page table node
    //
    int page_cnt = 0;
    while ((page_cnt < max_pages) && (++idx < 512))
    {
        // Stop as soon as an entry is found with no translation
        if (! nodeEntryExists(node, idx) || ! nodeEntryIsTerminal(node, idx))
        {
            break;
        }

        *pa++ = nodeGetTranslatedAddr(node, idx);
        if (flags)
        {
            *flags++ = nodeGetTranslatedAddrFlags(node, idx);
        }

        page_cnt += 1;
    }

    return page_cnt;
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
