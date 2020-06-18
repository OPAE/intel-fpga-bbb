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
 * \file mpf_os.h
 * \brief OS-specific functions required by other MPF modules.
 */

#ifndef __FPGA_MPF_OS_H__
#define __FPGA_MPF_OS_H__


/**
 * Initialize the mpfOs module.
 *
 * @param[in] is_simulated Is the FPGA real or simulated?
 * @returns                FPGA_OK on success.
 */
fpga_result mpfOsInit(
    _mpf_handle_p _mpf_handle
);


/**
 * Memory barrier.
 *
 */
void mpfOsMemoryBarrier(void);


/**
 * Anonymous mutex type.
 */
typedef void* mpf_os_mutex_handle;


/**
 * Allocate and initialize a mutex object.
 *
 * @param[out] mutex       Mutex object.
 * @returns                FPGA_OK on success.
 */
fpga_result mpfOsPrepareMutex(
    mpf_os_mutex_handle* mutex
);


/**
 * Delete a mutex object.
 *
 * @param[in] mutex        Mutex object.
 * @returns                FPGA_OK on success.
 */
fpga_result mpfOsDestroyMutex(
    mpf_os_mutex_handle mutex
);


/**
 * Lock a mutex.
 *
 * @param[in] mutex        Pointer to mutex object.
 * @returns                FPGA_OK on success.
 */
fpga_result mpfOsLockMutex(
    mpf_os_mutex_handle mutex
);


/**
 * Unlock a mutex.
 *
 * @param[in] mutex        Pointer to mutex object.
 * @returns                FPGA_OK on success.
 */
fpga_result mpfOsUnlockMutex(
    mpf_os_mutex_handle mutex
);


/**
 * Test whether a mutex is already locked.
 *
 * @param[in] mutex        Pointer to mutex object.
 * @returns                True iff already locked.
 */
bool mpfOsTestMutexIsLocked(
    mpf_os_mutex_handle mutex
);


/*
 * Macro for debugging a mutex, testing whether it is locked only when
 * compiling in debug mode.
 */
#ifndef DEBUG_BUILD
    // Nothing in optimized mode
    #define DBG_MPF_OS_TEST_MUTEX_IS_LOCKED(mutex)
#else
    #define DBG_MPF_OS_TEST_MUTEX_IS_LOCKED(mutex) assert(mpfOsTestMutexIsLocked(mutex))
#endif


/**
 * Map a memory buffer.
 *
 * @param[in]  num_bytes   Number of bytes to map.
 * @param[inout] page_size Physical page size requested.  On return the page_size
 *                         is set to the actual size used.  If big pages are
 *                         unavailable, smaller physical pages may be permitted.
 * @param[out] buffer      Address of the allocated buffer
 * @returns                FPGA_OK on success.
 */
fpga_result mpfOsMapMemory(
    size_t num_bytes,
    mpf_vtp_page_size* page_size,
    void** buffer
);


/**
 * Unmap a memory buffer.
 *
 * @param[in]  buffer      Buffer to release.
 * @param[in]  num_bytes   Number of bytes to map.
 * @returns                FPGA_OK on success.
 */
fpga_result mpfOsUnmapMemory(
    void* buffer,
    size_t num_bytes
);


/**
 * Find out the size of the page at vaddr.
 *
 * @param[in]  vaddr       Virtual address.
 * @param[out] page_size   Physical page size mapped at vaddr.
 * @returns                FPGA_OK on success. FPGA_NOT_FOUND is returned when
 *                         no mapping is found. FPGA_EXCEPTION is returned for
 *                         errors encountered while reading the page mapping.
 */
fpga_result mpfOsGetPageSize(
    void* vaddr,
    mpf_vtp_page_size* page_size
);

#endif // __FPGA_MPF_OS_H__
