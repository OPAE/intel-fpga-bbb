This example produces the same output as the initial [hello world
example](../../01_hello_world/). However, this example is modular. Instead of
showing the full linear sequence required to produce a working program, this
example adds modules on both the software and hardware sides that reduce the
size and complexity of the algorithm-specific code. The example also switches
to C++ and instantiates C++ classes included in OPAE.

The process for building this example is identical to the original [hello
world](../../01_hello_world/) and is not repeated here.

## Software

- Management of the OPAE code to connect to an accelerator is moved to a
  common C++ class, found in
  [../base/sw/opae_svc_wrapper.h](../base/sw/opae_svc_wrapper.h) and
  [../base/sw/opae_svc_wrapper.cpp](../base/sw/opae_svc_wrapper.cpp). The
  class contains methods that wrap a number of OPAE services: connecting to an
  accelerator, MMIO (CSR register) read and write, and shared buffer
  allocation. The class adds one new concept: a method that detects at run
  time whether the software is connected to an actual accelerator or to ASE.

- A second base class adds a logical vector of CSRs that are layered on
  top of a region of the MMIO address space.  The class defines a
  collection of base CSRs, available in all applications, as well as an
  array of application-specific CSRs.  There is corresponding RTL to
  manage the CSRs in the FPGA.  The base CSRs are enumerated in
  t_csr_common in [../base/sw/csr_mgr.h](../base/sw/csr_mgr.h).

- With FPGA management now wrapped in a separate class, the
  application-specific code in [sw/cci_mpf_hello.cpp](sw/cci_mpf_hello.cpp)
  is quite short. Only the main steps are needed:

  1. Connect to an accelerator with the expected UUID.
  2. Connect to the CSR manager.
  3. Allocate a shared memory buffer.
  4. Send the address of the buffer to the accelerator.
  5. Wait for and print the response.

## Hardware

The hardware side is also modular, using a framework that will be common
to subsequent examples.

- The top-level wrapper is common code:
  [../base/hw/rtl/cci_afu_with_mpf.sv](../base/hw/rtl/cci_afu_with_mpf.sv).
  The wrapper solves a number of typical problems:

  - First, it connects the design to the clock and reset that are specified in
    the AFU's JSON file and managed by the Platform Interface Manager. This
    mechanism was described in [Section 2](../../02_platform_ifc).

  - Next, the CCI signals are transformed to the MPF BBB's SystemVerilog
    interface representation of CCI
    wires. [cci_mpf_if](https://github.com/OPAE/intel-fpga-bbb/blob/master/BBB_cci_mpf/hw/rtl/cci-mpf-if/cci_mpf_if.vh)
    wraps all CCI request and response signals in a single object, thus
    simplifying module interfaces -- especially when the modules have multiple
    CCI connections. The transformation to an MPF interface was not required
    for this hello world example, but will be required in subsequent examples
    that introduce MPF shims.

  - [csr_mgr](../base/hw/rtl/csr_mgr.sv) is instantiated next. This is the
    module corresponding to the software-side CSR class. The common CSR
    manager implements the required AFU device feature header as well as a
    collection of standard event counters. It also implements a vector of CSRs
    that are passed to the application using the SystemVerilog
    [app_csrs](../base/hw/rtl/csr_mgr.vh) interface. These CSRs are controlled
    by simple enable bits, allowing the AFU to access CSRs without the
    complexity of mapping them to CCI MMIO requests.

  - The top-level wrapper then optionally instantiates an MPF instance
    that transforms CCI semantics to those required by the application.
    This hello world example does not need MPF and is compiled with the
    MPF_DISABLED preprocessor variable set. MPF configuration will be
    covered in the next example.  In this example, cci_mpf_null() is
    instantiated, which only adds the c0NotEmpty and c1NotEmpty signals
    that may be used to detect whether any requests are in flight.

  - Finally, the application ([app_afu](hw/rtl/cci_mpf_hello_afu.sv)) is
    instantiated.

- With the CCI glue logic moved to common code, the application-specific RTL
  in [hw/rtl/cci_mpf_hello_afu.sv](hw/rtl/cci_mpf_hello_afu.sv) is
  significantly shortened. It exports the AFU ID and consumes the address to
  which it should write "Hello World!" using the CSR interface.  It uses MPF
  functions to generate request headers (e.g. cci_mpf_c1_genReqHdr). Despite
  using the cci_mpf_if SystemVerilog representation of CCI, the write request
  header and the code that triggers a CCI write are functionally equivalent to
  the original, non-modular hello world example.

- [hw/rtl/sources.txt](hw/rtl/sources.txt) describes the entire collection of
  application RTL. It includes
  [../base/hw/rtl/base_sources.txt](../base/hw/rtl/base_sources.txt), which
  loads the common modules. base_sources.txt also loads BBB (Basic Building
  Blocks) packages.

## Simulator Waveforms

Advanced users may wish to display the waveform debugging view after
executing the program.  In the shell where the ASE RTL simulation
completed, type "make wave" and a waveform viewer will load the result of
the run.  Note:

- ase_top/platform_shim_ccip_std_afu/ccip_std_afu is the top-level module in
  cci_afu_with_mpf.sv.

- .../ccip_std_afu/pClk is the primary CCI clock.

- In this example, the application clock (.../ccip_std_afu/app/clk) is
  connected to the half-speed clock.

- Soft reset completes after .../ccip_std_afu/app/reset goes high and then
  low.

- Notice the single pulse of .../ccip_std_afu/app/is_mem_addr_csr_write
  when the write address arrives in csrs.cpu_wr_csrs[0] and is registered
  in .../ccip_std_afu/app/mem_addr.

- The single write is triggered when .../ccip_std_afu/afu/c1Tx.valid
  is high. The address, in .../ccip_std_afu/afu/c1Tx.hdr.base.address,
  matches mem_addr.
