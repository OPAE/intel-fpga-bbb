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

#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <inttypes.h>
#include <pthread.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/eventfd.h>
#include <sys/ioctl.h>

#include <opae/mpf/mpf.h>
#include "mpf_internal.h"
#include "mmu_monitor.h"


static void *mpfVtpMonitorMain(void *args)
{
    mpf_vtp_monitor* mon = (mpf_vtp_monitor*)args;
    int mon_fd = mon->mon_fd;
    int evt_fd = mon->evt_fd;
    _mpf_handle_p _mpf_handle = mon->_mpf_handle;
    mpf_vtp_pt* pt = _mpf_handle->vtp.pt;

    struct mmu_monitor_event mon_event;
    uint64_t count;
    uint64_t i;

    // Server loop
    while (true)
    {
        // Wait for an event from the driver.
        if (read(evt_fd, &count, sizeof(count)) != sizeof(count))
        {
            fprintf(stderr, "Error reading mmu_notifier event counter\n");
            exit(1);
        }

        // Get the page pinning lock.
        mpfVtpPtLockMutex(pt);

        int oldstate;
        pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, &oldstate);

        for (i = 0; i < count; i++)
        {
            // Get each mmu_notifier event's details.
            mon_event.flags = 0;
            mon_event.argsz = sizeof(struct mmu_monitor_event);
            mon_event.start = 0;
            mon_event.end = 0;

            ioctl(mon_fd, MMU_MON_GET_EVENT, &mon_event);
            if (_mpf_handle->dbg_mode)
            {
                MPF_FPGA_MSG("mon_event[%ld] start = 0x%" PRIx64 " end = 0x%" PRIx64 ", len = %" PRId64,
                             i,
                             (uint64_t)mon_event.start, (uint64_t)mon_event.end,
                             (uint64_t)(mon_event.end - mon_event.start));
            }

            mpfVtpPtReleaseRange(pt,
                                 (void*)mon_event.start,
                                 (void*)mon_event.end);
        }

        mpfVtpPtUnlockMutex(pt);
        pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, &oldstate);
    }

    close(mon_fd);
    mon->mon_fd = 0;
    close(evt_fd);
    mon->evt_fd = 0;
    return NULL;
}


//
// Initialization happens as a side-effect of calling mpfVtpMonitorWaitWhenBusy(),
// so this is an internal (static) function.
//
static fpga_result mpfVtpMonitorInit(
    _mpf_handle_p _mpf_handle
)
{
    mpf_vtp_monitor* mon;

    if (_mpf_handle->dbg_mode)
    {
        MPF_FPGA_MSG("Attempting to active MMU monitor");
    }

    mon = malloc(sizeof(mpf_vtp_monitor));
    if (NULL == mon) return FPGA_NO_MEMORY;
    memset(mon, 0, sizeof(mpf_vtp_monitor));

    _mpf_handle->vtp.munmap_monitor = mon;
    mon->_mpf_handle = _mpf_handle;

    int fd = open("/dev/mmu_monitor", O_RDONLY);

    int mon_version = -1;
    if (-1 != fd)
    {
        mon_version = ioctl(fd, MMU_MON_GET_API_VERSION);
    }

    if ((-1 == fd) || (mon_version < 2))
    {
        if (-1 != fd)
        {
            close(fd);
        }

        // Ignore the error?
        if (getenv("MPF_NO_MMU_MONITOR_WARNING"))
        {
            return FPGA_OK;
        }

        if (-1 == fd)
        {
            MPF_FPGA_MSG_FH(stderr, "Failed to open munmap monitor device /dev/mmu_monitor");
            fprintf(stderr, "        -- %s\n", strerror(errno));
        }
        else
        {
            MPF_FPGA_MSG_FH(stderr, "Device /dev/mmu_monitor API is too old.\n");
        }
        fprintf(stderr,
                "\n"
                "  *** See /drivers/mmu_monitor in the intel-fpga-bbb repository ***\n"
                "  *** (https://github.com/OPAE/intel-fpga-bbb).                 ***\n"
                "\n"
                "  MPF/VTP will continue to work, even without the driver, as long as\n"
                "  no virutally addressed buffers are remapped to new physical pages\n"
                "  after first use on the FPGA.\n"
                "\n"
                "  This warning can be disabled by setting the environment variable\n"
                "  MPF_NO_MMU_MONITOR_WARNING.\n"
                "\n");

        return FPGA_EXCEPTION;
    }

    // Create an eventfd for monitoring events from the monitor device.
    int evt_fd;
    struct mmu_monitor_evtfd mon_evtfd;
    evt_fd = eventfd(0, 0);
    mon_evtfd.flags = MMU_MON_FILTER_MAPPED;
    mon_evtfd.argsz = sizeof(struct mmu_monitor_evtfd);
    mon_evtfd.evtfd = evt_fd;
    if (ioctl(fd, MMU_MON_SET_EVTFD, &mon_evtfd))
    {
        close(evt_fd);
        close(fd);
        MPF_FPGA_MSG_FH(stderr, "ERROR: Failed to create /dev/mmu_monitor event file descriptor!");
        return FPGA_EXCEPTION;
    }

    mon->mon_fd = fd;
    mon->evt_fd = evt_fd;

    int st = pthread_create(&mon->mon_tid, NULL, &mpfVtpMonitorMain, (void*)mon);
    if (st != 0)
    {
        if (_mpf_handle->dbg_mode)
        {
            MPF_FPGA_MSG("ERROR: Failed to start VTP server thread! (errno=%d)", errno);
            MPF_FPGA_MSG("  %s", strerror(errno));
        }

        close(evt_fd);
        mon->evt_fd = 0;
        close(fd);
        mon->mon_fd = 0;
        return FPGA_EXCEPTION;
    }

    return FPGA_OK;
}


fpga_result mpfVtpMonitorWaitWhenBusy(
    _mpf_handle_p _mpf_handle,
    bool wait_for_sync
)
{
    mpf_vtp_monitor* mon = _mpf_handle->vtp.munmap_monitor;
    mpf_vtp_pt* pt = _mpf_handle->vtp.pt;
    fpga_result r;

    if (NULL == mon)
    {
        // First time called. Initialize the monitor thread.
        r = mpfVtpMonitorInit(_mpf_handle);
        if (FPGA_OK != r)
        {
            return r;
        }

        mon = _mpf_handle->vtp.munmap_monitor;
        if (NULL == mon) return FPGA_NO_MEMORY;
    }

    if (0 == mon->mon_fd)
    {
        // No connection to monitoring device. Nothing to do.
        return FPGA_OK;
    }

    struct mmu_monitor_state mon_state;
    do
    {
        mon_state.flags = 0;
        mon_state.argsz = sizeof(struct mmu_monitor_state);

        // Must hold the pt lock in case monitor events are being processed
        mpfVtpPtLockMutex(pt);
        ioctl(mon->mon_fd, MMU_MON_GET_STATE, &mon_state);
        mpfVtpPtUnlockMutex(pt);
    }
    while (mon_state.evtcnt || ! wait_for_sync);

    return (0 == mon_state.evtcnt) ? FPGA_OK : FPGA_BUSY;
}



fpga_result mpfVtpMonitorTerm(
    mpf_vtp_monitor* monitor
)
{
    if (NULL == monitor)
    {
        return FPGA_OK;
    }

    // Kill the monitor thread
    if (monitor->mon_tid)
    {
        if (monitor->_mpf_handle->dbg_mode) MPF_FPGA_MSG("VTP munmap monitor terminating...");

        pthread_cancel(monitor->mon_tid);
        pthread_join(monitor->mon_tid, NULL);
        monitor->mon_tid = 0;
    }

    if (monitor->mon_fd > 0)
    {
        close(monitor->mon_fd);
        monitor->mon_fd = 0;
    }
    if (monitor->evt_fd > 0)
    {
        close(monitor->evt_fd);
        monitor->evt_fd = 0;
    }

    // Release the top-level monitor descriptor
    free(monitor);

    return FPGA_OK;
}
