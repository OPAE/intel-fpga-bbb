//
// Copyright (c) 2019, Intel Corporation
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
 * \file shim_vtp_monitor.h
 * \brief Monitor munmap events in order to unpin and invalidate device mappings.
 */

#ifndef __FPGA_MPF_SHIM_VTP_MONITOR_H__
#define __FPGA_MPF_SHIM_VTP_MONITOR_H__

#include <pthread.h>
#include <opae/mpf/shim_vtp.h>



/**
 * VTP munmap event monitor state
 */
typedef struct
{
    // Handle for monitor thread
    pthread_t mon_tid;

    // Opaque parent MPF handle.  It is opaque because the internal MPF handle
    // points to the page table, so the dependence would be circular.
    _mpf_handle_p _mpf_handle;

    // Event monitor file handle
    int mon_fd;
    int evt_fd;
}
mpf_vtp_monitor;


/**
 * Block when monitor events are pending.
 *
 * The monitor protocol requires that any pending events be processed before
 * a new page is pinned. This function checks whether any events are pending.
 * The monitor is initialized as a side-effect the first time this function
 * is called.
 *
 * @param[in]  _mpf_handle    Internal handle to MPF state.
 * @param[in]  wait_for_sync  When true, the function waits until state
 *                            is synchronized to return. When false,
 *                            the function returns immediately and
 *                            indicates synchronization state with the
 *                            return value.
 * @returns                   FPGA_OK on success. FPGA_BUSY when not
 *                            synchronized and wait_for_sync is false.
 */
fpga_result mpfVtpMonitorWaitWhenBusy(
    _mpf_handle_p _mpf_handle,
    bool wait_for_sync
);


/**
 * Destroy a munmap monitor.
 *
 * Terminate and deallocate an munmap monitor.
 *
 * @param[in]  monitor     Monitor handle.
 * @returns                FPGA_OK on success.
 */
fpga_result mpfVtpMonitorTerm(
    mpf_vtp_monitor* monitor
);


#endif // __FPGA_MPF_SHIM_VTP_MONITOR_H__
