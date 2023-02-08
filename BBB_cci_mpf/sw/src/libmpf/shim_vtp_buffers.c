//
// Copyright (c) 2023, Intel Corporation
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

#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <inttypes.h>
#include <sys/mman.h>

#include <opae/mpf/mpf.h>
#include "mpf_internal.h"


//
// Hash buffer address to a bucket in the table.
//
static inline uint32_t table_hash(void *vaddr)
{
    uint64_t h = (uint64_t)vaddr % 17659;
    return h % MPF_VTP_BUFFERS_TABLE_SIZE;
}


//
// Size of the user_buffers table struct, rounded up to a multiple of pages.
//
static inline size_t table_size_bytes(void)
{
    size_t s = sizeof(mpf_vtp_buffer_hash_table);
    size_t pg_size = getpagesize();

    return (s + pg_size - 1) & ~(pg_size - 1);
}


fpga_result mpfVtpBuffersInit(
    _mpf_handle_p _mpf_handle
)
{
    fpga_result r;

    // Internal double initialization -- fatal
    assert(NULL == _mpf_handle->vtp.user_buffers);

    mpf_vtp_buffer_hash_table* t;
    t = mmap(NULL, table_size_bytes(), (PROT_READ | PROT_WRITE),
             MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);

    if (MAP_FAILED == t)
    {
        return FPGA_NO_MEMORY;
    }

    memset(t, 0, sizeof(mpf_vtp_buffer_hash_table));

    // Allocate a mutex that protects the buffer table manager
    r = mpfOsPrepareMutex(&t->mutex);
    if (FPGA_OK != r)
    {
        munmap(t, table_size_bytes());
        return r;
    }

    _mpf_handle->vtp.user_buffers = t;
    return FPGA_OK;
}


fpga_result mpfVtpBuffersTerm(
    _mpf_handle_p _mpf_handle
)
{
    mpf_vtp_buffer_hash_table* table = _mpf_handle->vtp.user_buffers;

    if (table)
    {
        // Release all the tracked buffers in the hash table.
        for (uint32_t i = 0; i < MPF_VTP_BUFFERS_TABLE_SIZE; i += 1)
        {
            mpf_vtp_buffer_desc_p d = table->buckets[i];
            while (d)
            {
                mpf_vtp_buffer_desc_p next = d->next;
                free(d);
                d = next;
            }
        }

        mpfOsDestroyMutex(table->mutex);
        munmap(table, table_size_bytes());
    }

    _mpf_handle->vtp.user_buffers = NULL;
    return FPGA_OK;
}


fpga_result mpfVtpBuffersInsert(
    _mpf_handle_p _mpf_handle,
    void* vaddr,
    size_t size,
    void* page_vaddr
)
{
    mpf_vtp_buffer_hash_table* table = _mpf_handle->vtp.user_buffers;

    if (NULL == table || NULL == vaddr || 0 == size)
    {
        return FPGA_EXCEPTION;
    }

    uint32_t idx = table_hash(vaddr);
    mpf_vtp_buffer_desc_p desc = malloc(sizeof(struct mpf_vtp_buffer_desc));
    if (NULL == desc)
    {
        return FPGA_NO_MEMORY;
    }

    mpfOsLockMutex(table->mutex);
    desc->vaddr = vaddr;
    desc->size = size;
    desc->page_vaddr = page_vaddr;
    desc->next = table->buckets[idx];
    table->buckets[idx] = desc;

    if (_mpf_handle->dbg_mode)
    {
        printf(" VTP buffer insert: VA %p - %p (0x%" PRIx64 " bytes) - page %p\n",
               vaddr, vaddr + size, size, page_vaddr);
    }
    mpfOsUnlockMutex(table->mutex);

    return FPGA_OK;
}


size_t mpfVtpBuffersRemove(
    _mpf_handle_p _mpf_handle,
    void* vaddr,
    void** page_vaddr
)
{
    mpf_vtp_buffer_hash_table* table = _mpf_handle->vtp.user_buffers;
    if (NULL == table)
    {
        return 0;
    }

    //
    // Find the smallest buffer at address. Unfortunately, this means searching
    // the entire list. We assume that the number of buffers being managed is
    // relatively small. The number of pages may be high, but buffers can span
    // lots of pages.
    //
    // It is possible that multiple buffers will have the same start address
    // since small regions may share the same page and callers may pass in
    // page-aligned addresses. The smallest buffer is returned first since
    // there is no way to know which buffer is actually being released.
    // When multiple buffers map to the same location, reference counts
    // in the VTP page table keep pages allocated until the count reaches 0.
    //

    uint32_t idx = table_hash(vaddr);
    mpf_vtp_buffer_desc_p match_prev = NULL;
    mpf_vtp_buffer_desc_p match = NULL;
    size_t size = 0;

    mpfOsLockMutex(table->mutex);
    mpf_vtp_buffer_desc_p cur = NULL;
    mpf_vtp_buffer_desc_p next = table->buckets[idx];
    while (next)
    {
        // A new smallest match?
        if ((next->vaddr == vaddr) && ((size == 0) || (next->size < size)))
        {
            size = next->size;
            match = next;
            match_prev = cur;
        }

        cur = next;
        next = cur->next;
    }

    if (match)
    {
        // Found a match. Remove it from the table.
        if (match_prev)
            match_prev->next = match->next;
        else
            table->buckets[idx] = match->next;

        if (NULL != page_vaddr)
        {
            *page_vaddr = match->page_vaddr;
        }

        if (_mpf_handle->dbg_mode)
        {
            printf(" VTP buffer remove: VA %p - %p (0x%" PRIx64 " bytes)\n", vaddr, vaddr + size, size);
        }
        free(match);
    }
    else if (_mpf_handle->dbg_mode)
    {
        printf(" VTP buffer no match for VA %p\n", vaddr);
    }

    mpfOsUnlockMutex(table->mutex);

    return size;
}


void mpfVtpDumpBuffers(
    _mpf_handle_p _mpf_handle
)
{
    mpf_vtp_buffer_hash_table* table = _mpf_handle->vtp.user_buffers;
    if (NULL == table)
    {
        return;
    }

    mpfOsLockMutex(table->mutex);
    printf("VTP Buffer Table:\n");
    for (uint32_t i = 0; i < MPF_VTP_BUFFERS_TABLE_SIZE; i += 1)
    {
        mpf_vtp_buffer_desc_p d = table->buckets[i];
        while (d)
        {
            printf("  VA %p - %p (0x%" PRIx64 " bytes) - page %p\n",
                   d->vaddr, d->vaddr + d->size, d->size, d->page_vaddr);
            d = d->next;
        }
    }
    mpfOsUnlockMutex(table->mutex);
}
