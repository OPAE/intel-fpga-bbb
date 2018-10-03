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
#include <cstring>

#include <opae/mpf/cxx/mpf_shared_buffer.h>

namespace opae {
namespace fpga {
namespace bbb {
namespace mpf {
namespace types {

using namespace opae::fpga::types;

mpf_shared_buffer::~mpf_shared_buffer() {
  // If the allocation was successful.
  if (virt_) {
    fpga_result r = mpfVtpReleaseBuffer(*mpf_handle_, virt_);
    virt_ = nullptr;

    if (FPGA_OK != r) {
      std::cerr << "mpf_shared_buffer destructor, mpfVtpBufferFree error: "
                << fpgaErrStr(r) << std::endl;
    }
  }
}

mpf_shared_buffer::ptr_t mpf_shared_buffer::allocate(mpf_handle::ptr_t mpf_handle,
                                                     size_t len) {
  ptr_t p;

  if (!len) {
    throw except(OPAECXX_HERE);
  }

  if (!mpfVtpIsAvailable(*mpf_handle)) {
    throw except(OPAECXX_HERE);
  }

  uint8_t *virt = nullptr;
  uint64_t wsid = 0;

  fpga_result res = mpfVtpPrepareBuffer(*mpf_handle, len,
                                        reinterpret_cast<void **>(&virt),
                                        0);
  ASSERT_FPGA_OK(res);

  uint64_t iova = mpfVtpGetIOAddress(*mpf_handle, virt);

  p.reset(new mpf_shared_buffer(mpf_handle, len, virt, iova));

  return p;
}

mpf_shared_buffer::ptr_t mpf_shared_buffer::attach(mpf_handle::ptr_t mpf_handle,
                                                   uint8_t *base,
                                                   size_t len) {
  ptr_t p;

  if (!len) {
    throw except(OPAECXX_HERE);
  }

  if (!mpfVtpIsAvailable(*mpf_handle)) {
    throw except(OPAECXX_HERE);
  }

  uint8_t *virt = base;
  uint64_t wsid = 0;

  fpga_result res = mpfVtpPrepareBuffer(*mpf_handle, len,
                                        reinterpret_cast<void **>(&virt),
                                        FPGA_BUF_PREALLOCATED);
  ASSERT_FPGA_OK(res);

  uint64_t iova = mpfVtpGetIOAddress(*mpf_handle, virt);

  p.reset(new mpf_shared_buffer(mpf_handle, len, virt, iova));

  return p;
}

mpf_shared_buffer::mpf_shared_buffer(mpf_handle::ptr_t mpf_handle,
                                     size_t len, uint8_t *virt, uint64_t iova)
    : mpf_handle_(mpf_handle),
      shared_buffer(nullptr, len, virt, 0, iova) {}

}  // end of namespace types
}  // end of namespace mpf
}  // end of namespace bbb
}  // end of namespace fpga
}  // end of namespace opae
