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
#include <opae/mpf/cxx/mpf_handle.h>

namespace opae {
namespace fpga {
namespace bbb {
namespace mpf {
namespace types {

using namespace opae::fpga::types;

mpf_handle::mpf_handle(mpf_handle_t h) : mpf_handle_(h) {}

mpf_handle::~mpf_handle() {
  try {
    close();
  }
  catch (...) {
    std::cerr << "Error destroying mpf_handle!" << std::endl;
  }
}

mpf_handle::ptr_t mpf_handle::open(handle::ptr_t handle,
                                   uint32_t csr_space, uint64_t csr_offset,
                                   uint32_t mpf_flags) {
  mpf_handle_t c_handle = nullptr;
  ptr_t p;

  auto res = mpfConnect(*handle, csr_space, csr_offset, &c_handle, mpf_flags);
  ASSERT_FPGA_OK(res);
  p.reset(new mpf_handle(c_handle));

  return p;
}

fpga_result mpf_handle::close() {
  if (mpf_handle_ != nullptr) {
    auto res = mpfDisconnect(mpf_handle_);
    ASSERT_FPGA_OK(res);
    mpf_handle_ = nullptr;
    return FPGA_OK;
  }

  return FPGA_OK;
}

bool mpf_handle::shim_present(t_cci_mpf_shim_idx mpf_shim_idx) {
  if (mpf_handle_ != nullptr) {
    return mpfShimPresent(mpf_handle_, mpf_shim_idx);
  }

  return false;
}

}  // end of namespace types
}  // end of namespace mpf
}  // end of namespace bbb
}  // end of namespace fpga
}  // end of namespace opae
