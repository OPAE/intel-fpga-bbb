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

/**
 * \file shim_vtp_buffers.h
 * \brief Track buffer start addresses and sizes to support freeing them.
 */

#ifndef __FPGA_MPF_SHIM_VTP_BUFFERS_H__
#define __FPGA_MPF_SHIM_VTP_BUFFERS_H__

/**
 * Descriptor for a single buffer.
 */
typedef struct mpf_vtp_buffer_desc *mpf_vtp_buffer_desc_p;

struct mpf_vtp_buffer_desc
{
    void* vaddr;
    size_t size;
    void* page_vaddr;
    
    // Linked list for hash table
    mpf_vtp_buffer_desc_p next;
};


/**
 * Hash table, indexed by start address.
 */
#define MPF_VTP_BUFFERS_TABLE_SIZE 1021

typedef struct
{
    mpf_vtp_buffer_desc_p buckets[MPF_VTP_BUFFERS_TABLE_SIZE];

    // mutex (one update at a time)
    mpf_os_mutex_handle mutex;
}
mpf_vtp_buffer_hash_table;


/**
 * Allocate a buffer table.
 *
 * Called internally from VTP.
 *
 * @param[in]  _mpf_handle Internal handle to MPF state.
 * @returns                FPGA_OK on success.
 */
fpga_result mpfVtpBuffersInit(
    _mpf_handle_p _mpf_handle
);


/**
 * Release the buffer table.
 *
 * Called internally from VTP.
 *
 * @param[in]  _mpf_handle Internal handle to MPF state.
 * @returns                FPGA_OK on success.
 */
fpga_result mpfVtpBuffersTerm(
    _mpf_handle_p _mpf_handle
);


/**
 * Track a new buffer.
 *
 * @param[in]  _mpf_handle Internal handle to MPF state.
 * @param[in]  vaddr       Buffer start virtual address.
 * @param[in]  size        Buffer size (bytes).
 * @param[in]  page_vaddr  Page address containing the buffer start.
 * @returns                FPGA_OK on success.
 */
fpga_result mpfVtpBuffersInsert(
    _mpf_handle_p _mpf_handle,
    void* vaddr,
    size_t size,
    void* page_vaddr
);


/**
 * Remove a tracked buffer and return its size.
 *
 * @param[in]  _mpf_handle Internal handle to MPF state.
 * @param[in]  vaddr       Buffer start virtual address.
 * @param[out] page_vaddr  Page address containing the buffer start.
 *                         (Ignored if NULL.)
 * @returns                Buffer size. Zero when address not found.
 */
size_t mpfVtpBuffersRemove(
    _mpf_handle_p _mpf_handle,
    void* vaddr,
    void** page_vaddr
);


/**
 * Dump the buffer table.
 *
 * @param[in]  _mpf_handle Internal handle to MPF state.
 */
void mpfVtpDumpBuffers(
    _mpf_handle_p _mpf_handle
);

#endif // __FPGA_MPF_SHIM_VTP_BUFFERS_H__
