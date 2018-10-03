// Copyright(c) 2018, Intel Corporation
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
#pragma once

#include <opae/cxx/core/shared_buffer.h>
#include <opae/mpf/cxx/mpf_handle.h>

namespace opae {
namespace fpga {
namespace bbb {
namespace mpf {
namespace types {

/** Host/AFU shared memory blocks
 *
 * shared_buffer abstracts a memory block that may be shared
 * between the host cpu and an accelerator. The block may
 * be allocated by the shared_buffer class itself (see allocate),
 * or it may be allocated elsewhere and then attached to
 * a shared_buffer object via attach.
 */
class mpf_shared_buffer : public opae::fpga::types::shared_buffer {
 public:
  typedef std::size_t size_t;
  typedef std::shared_ptr<mpf_shared_buffer> ptr_t;

  mpf_shared_buffer(const mpf_shared_buffer &) = delete;
  mpf_shared_buffer &operator=(const mpf_shared_buffer &) = delete;

  /** shared_buffer destructor.
   */
  virtual ~mpf_shared_buffer();

  /** shared_buffer factory method - allocate a shared_buffer.
   * @param[in] handle The handle used to allocate the buffer.
   * @param[in] len    The length in bytes of the requested buffer.
   * @return A valid shared_buffer smart pointer on success, or an
   * empty smart pointer on failure.
   */
  static mpf_shared_buffer::ptr_t allocate(mpf_handle::ptr_t mpf_handle,
                                           size_t len);

  /** shared_buffer factory method - attach an existing buffer.
   * @param[in] handle The handle used to allocate the buffer.
   * @param[in] base   The base of the pre-allocated memory.
   * @param[in] len    The length in bytes of the requested buffer.
   * @return A valid shared_buffer smart pointer on success, or an
   * empty smart pointer on failure.
   */
  static mpf_shared_buffer::ptr_t attach(mpf_handle::ptr_t mpf_handle,
                                         uint8_t *base,
                                         size_t len);

 protected:
  mpf_shared_buffer(mpf_handle::ptr_t mpf_handle, size_t len,
                    uint8_t *virt, uint64_t iova);

  mpf_handle::ptr_t mpf_handle_;
};

}  // end of namespace types
}  // end of namespace mpf
}  // end of namespace bbb
}  // end of namespace fpga
}  // end of namespace opae
