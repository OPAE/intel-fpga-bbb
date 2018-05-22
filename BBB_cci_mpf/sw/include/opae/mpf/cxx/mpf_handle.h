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

#include <opae/cxx/core/handle.h>
#include <opae/mpf/mpf.h>

namespace opae {
namespace fpga {
namespace bbb {
namespace mpf {
namespace types {

/** An MPF resource
 *
 * Represents a connection to an MPF BBB that has been instantiated as
 * part of an AFU.
 */
class mpf_handle {
public:
  typedef std::shared_ptr<mpf_handle> ptr_t;

  mpf_handle(const mpf_handle &) = delete;
  mpf_handle &operator=(const mpf_handle &) = delete;

  ~mpf_handle();

  /** Retrieve the underlying mpf_handle.
   */
  mpf_handle_t c_type() const { return mpf_handle_; }

  /** Retrieve the underlying mpf_handle.
   */
  operator mpf_handle_t() const { return mpf_handle_; }

  /** Establish a connection to MPF
   *
   * Scans the feature chain, looking for MPF shims.  MPF has a debug mode
   * in which details such as VTP mapping are printed to stdout.  Debug mode
   * is enabled either by passing MPF_FLAG_DEBUG to mpf_flags or by defining
   * an environment variable at run time named MPF_ENABLE_DEBUG.
   *
   * @param[in] handle An OPAE handle connected to an accelerator.
   *
   * @param[in] csr_space The CSR space to access in the accelerator.
   * This is typically 0.
   *
   * @param[in] csr_offset Byte offset in CSR space at which scanning for MPF
   * features should begin. This is typically 0.
   *
   * @param[in] mpf_flags Bitwise OR of flags to control MPF behavior,
   * such as debugging output.
   */
  static mpf_handle::ptr_t open(opae::fpga::types::handle::ptr_t handle,
                                uint32_t csr_space, uint64_t csr_offset,
                                uint32_t mpf_flags);

  /** Close an MPF connection (if opened)
   *
   * @return fpga_result indication the result of closing the
   * mpf_handle or FPGA_EXCEPTION if mpf_handle is not opened
   *
   * @note This is available for explicitly closing an mpf_handle.
   * The destructor for mpf_handle will call close.
   */
  fpga_result close();

  /** Test whether a given MPF shim is present
   *
   * MPF shims are detected by walking the feature list stored in CSR space
   * when the MPF connection is opened.
   *
   * @param[in] mpf_shim_idx Requested MPF shim.
   *
   * @return true if shim is present.
   */
  bool shim_present(t_cci_mpf_shim_idx mpf_shim_idx);

 private:
  mpf_handle(mpf_handle_t h);

  mpf_handle_t mpf_handle_;
};

}  // end of namespace types
}  // end of namespace mpf
}  // end of namespace bbb
}  // end of namespace fpga
}  // end of namespace opae
