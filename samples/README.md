# Samples

All samples depend on proper configuration of the OPAE and build
environments. Both are described below.

This tree contains sample workloads, typically written as small examples of
specific concepts.  A set of [tutorials]
(https://github.com/OPAE/intel-fpga-bbb/tree/master/samples/tutorial) progresses
through defining RTL sources, configuring for simulation or synthesis, and
connecting to device interfaces.

## OPAE Version

All samples require the [OPAE Platform Interface
Manager](https://github.com/OPAE/opae-sdk/tree/master/platforms) (PIM).  The
PIM is available in [OPAE sources on
GitHub](https://github.com/OPAE/opae-sdk) on master as of March 1st,
2018. The first OPAE release supporting the PIM is 0.14.

__Platform releases predating March 1st, 2018, such as SR-5.0.3, SR-6.3.0 and
DCP 1.0, must be updated to work with the PIM.  Please see the section below
on updating releases.__

If you must use an older version of the OPAE SDK, older versions of the
tutorial are available as branches in this
[intel-fpga-bbb](https://github.com/OPAE/intel-fpga-bbb) repository. The
branch names are release/\<number\>.

## OPAE Environment

1. Install the OPAE SDK according to the [standard
   instructions](https://opae.github.io/).

2. Some samples depend on building blocks contained in this repository, such
   as [MPF](https://github.com/OPAE/intel-fpga-bbb/wiki/BBB_cci_mpf).  Build
   and add BBB software libraries to the OPAE installation by following the
   [BBB installation
   instructions](https://github.com/OPAE/intel-fpga-bbb/wiki/Installation).

3. Define environment variables. The samples and tutorial make the following
   assumptions about the environment:

   - FPGA_BBB_CCI_SRC points to the top of the BBB release tree.  RTL for
     MPF is imported by some scripts through ${FPGA_BBB_CCI_SRC}/BBB_cci_mpf.

   - If you have installed a specific platform release, such as SR-5.0.3 for
     Broadwell Xeon+FPGA or DCP 1.0 for a discrete PCIe board, the
     OPAE_PLATFORM_ROOT environment variable should point to the root of the
     installation tree.  Please note the section below on updating old
     releases for compatibility with the samples.

   - If OPAE and the BBBs are installed to standard system directories they
     may already be found on header and library search paths.  If not, they
     must be added explicitly:

     - Header files from OPAE and MPF must either be on the default compiler
       search paths or on both C_INCLUDE_PATH and CPLUS_INCLUDE_PATH.

     - OPAE and MPF libraries must either be on the default linker search
       paths or on both LIBRARY_PATH and LD_LIBRARY_PATH.

## Updating Releases for use with the Platform Interface Manager

A set of scripts is provided in
[../platform-ifc-mgr-compat](https://github.com/OPAE/intel-fpga-bbb/tree/master/platform-ifc-mgr-compat)
to update older platform releases.  These one-time scripts must be run in
order to configure both simulation and Quartus environments with the PIM.
Please follow the instructions there.  Once properly configured, the PIM will
target the configured platform by reading the contents of
${OPAE_PLATFORM_ROOT}/hw/lib/fme-platform-class.txt.

ASE may still be used for simulation even if no platform specific library is
installed or OPAE_PLATFORM_ROOT is not defined.  It will default to
configuring builds for integrated Xeon+FPGA platforms.  Synthesis with
Quartus requires a platform release and a valid OPAE_PLATFORM_ROOT.
