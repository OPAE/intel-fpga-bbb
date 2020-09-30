# Samples

All samples depend on proper configuration of the OPAE and build
environments. Both are described below.

This tree contains sample workloads, typically written as small examples of
specific concepts.  A set of [tutorials](tutorial) progresses through defining
RTL sources, configuring for simulation or synthesis, and connecting to device
interfaces.

## OPAE Version

All samples require version 2 of the [Platform Interface
Manager](https://github.com/OPAE/ofs-platform-afu-bbb/) (PIM), which has been
available since mid-2020. Version 2 is a significant upgrade over the first
version. Version 1 AFUs continue to work on the new codebase in compatibility
mode. An older, v1 version of this tutorial can be found in the git
history of this [samples tree](https://github.com/OPAE/intel-fpga-bbb/tree/release/1.3.0/samples).

__Platform releases predating August 2020, such as SR-5.0.3, SR-6.4.0 and
PAC cards, must be updated to work with the PIM.  Please see the section below
on updating releases.__

## OPAE Environment

1. Install the OPAE SDK from packages shipped with a board release or from
   source, by following the [standard instructions](https://opae.github.io/).

2. Define environment variables. The samples and tutorial make the following
   assumptions about the environment:

   - The __OPAE\_PLATFORM\_ROOT__ environment variable must point to the root
     of a release tree, such as a PAC card release or SR-5.0.3 for Broadwell
     Xeon+FPGA. The release tree is used both for synthesis and to define
     platform characteristics used in simulation. __Please
     note the section below on updating old releases for compatibility with
     the PIM.__  You can determine whether OPAE\_PLATFORM\_ROOT points to an
     updated release tree by confirming that
     ${OPAE\_PLATFORM\_ROOT}/hw/lib/build/platform/ofs\_plat\_if exists.

   - __FPGA\_BBB\_CCI\_SRC__ points to the top of the BBB release tree. RTL for
     MPF is imported by some scripts through
     [${FPGA\_BBB\_CCI\_SRC}/BBB\_cci\_mpf/hw/rtl/cci\_mpf\_sources.txt](../BBB_cci_mpf/hw/rtl/cci_mpf_sources.txt).

   - If OPAE and the BBBs are installed to standard system directories they
     may already be found on C and C++ header and library search paths. If
     not, their installation directories must be added explicitly:

     - Header files from OPAE and MPF must either be on the default compiler
       search paths or on both __C\_INCLUDE\_PATH__ and __CPLUS\_INCLUDE\_PATH__.

     - OPAE and MPF libraries must either be on the default linker search
       paths or on both __LIBRARY\_PATH__ and __LD\_LIBRARY\_PATH__.

3. Some samples depend on building blocks contained in this repository, such
   as [MPF](https://github.com/OPAE/intel-fpga-bbb/wiki/BBB_cci_mpf). Build
   and add BBB software libraries to the OPAE installation by following the
   [BBB installation
   instructions](https://github.com/OPAE/intel-fpga-bbb/wiki/Installation).

## Updating Releases for use with the Platform Interface Manager

A set of scripts is provided in the
[ofs-platform-afu-bbb](https://github.com/OPAE/ofs-platform-afu-bbb)
repository to update older platform releases. The one-time script,
[plat\_if\_release/update\_release.sh](https://github.com/OPAE/ofs-platform-afu-bbb/blob/master/plat_if_release/update_release.sh),
must be run in order to configure both simulation and Quartus environments with the PIM.
Please follow the instructions there. Once properly configured, the PIM will
use the chosen target.

For a detailed description of the inner workings of the PIM, please see the documentation
at [ofs-platform-afu-bbb](https://github.com/OPAE/ofs-platform-afu-bbb).
