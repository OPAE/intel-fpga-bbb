# Samples

All samples depend on proper configuration of the OPAE and build
environments. Both are described below.

This tree contains sample workloads, typically written as small examples of
specific concepts.  A set of [tutorials](tutorial) progresses through defining
RTL sources, configuring for simulation or synthesis, and connecting to device
interfaces.

## OPAE Version

All samples require the [OPAE Platform Interface
Manager](https://github.com/OPAE/opae-sdk/tree/master/platforms) (PIM). The
PIM is available in OPAE release 0.14 and later as well as [OPAE sources on
GitHub](https://github.com/OPAE/opae-sdk) on master as of March 1st, 2018.

__Platform releases predating March 1st, 2018, such as SR-5.0.3, SR-6.4.0 and
PAC 1.0, must be updated to work with the PIM.  Please see the section below
on updating releases.__

If you must use an older version of the OPAE SDK, older versions of the
tutorial are available as branches in this
[intel-fpga-bbb](https://github.com/OPAE/intel-fpga-bbb) repository. The
branch names are release/\<number\>.

## OPAE Environment

1. Install the OPAE SDK from packages shipped with a board release or from
   source, by following the [standard instructions](https://opae.github.io/).

2. Some samples depend on building blocks contained in this repository, such
   as [MPF](https://github.com/OPAE/intel-fpga-bbb/wiki/BBB_cci_mpf). Build
   and add BBB software libraries to the OPAE installation by following the
   [BBB installation
   instructions](https://github.com/OPAE/intel-fpga-bbb/wiki/Installation).

3. Define environment variables. The samples and tutorial make the following
   assumptions about the environment:

   - __FPGA_BBB_CCI_SRC__ points to the top of the BBB release tree. RTL for
     MPF is imported by some scripts through
     [${FPGA_BBB_CCI_SRC}/BBB_cci_mpf/hw/rtl/cci_mpf_sources.txt](../BBB_cci_mpf/hw/rtl/cci_mpf_sources.txt).

   - If you have installed a specific platform release, such as SR-5.0.3 for
     Broadwell Xeon+FPGA or PAC with Arria 10 GX FPGA 1.0 for a discrete PCIe
     board, the __OPAE_PLATFORM_ROOT__ environment variable should point to the
     root of the installation tree. __Please note the section below on updating
     old releases for compatibility with the samples.__

   - If OPAE and the BBBs are installed to standard system directories they
     may already be found on C and C++ header and library search paths. If
     not, their installation directories must be added explicitly:

     - Header files from OPAE and MPF must either be on the default compiler
       search paths or on both __C_INCLUDE_PATH__ and __CPLUS_INCLUDE_PATH__.

     - OPAE and MPF libraries must either be on the default linker search
       paths or on both __LIBRARY_PATH__ and __LD_LIBRARY_PATH__.

## Updating Releases for use with the Platform Interface Manager

A set of scripts is provided in
[../platform-ifc-mgr-compat](../platform-ifc-mgr-compat)
to update older platform releases. These one-time scripts must be run in
order to configure both simulation and Quartus environments with the PIM.
Please follow the instructions there. Once properly configured, the PIM will
target the configured platform by reading the contents of
${OPAE_PLATFORM_ROOT}/hw/lib/fme-platform-class.txt.

ASE may still be used for simulation even if no platform specific library is
installed or OPAE_PLATFORM_ROOT is not defined. It will default to
configuring builds for integrated Xeon+FPGA platforms. Synthesis with
Quartus requires a platform release and a valid OPAE_PLATFORM_ROOT.
