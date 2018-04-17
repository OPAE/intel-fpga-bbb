# Tutorial

The sample designs in this tree are deliberately simple.  They are intended
to demonstrate proper use of CCI (Core-Cache Interface) without the details
of an actual accelerator getting in the way.  The examples grow in
complexity, starting with "Hello World!" and ending with a design requiring
FPGA-side virtual memory.

All the designs may either be simulated or synthesized for FPGA hardware.

This tutorial assumes that OPAE has been installed already and that the BBB
(Basic Building Blocks) release for CCI is present.  Please follow the
instructions in the README file in the
[../samples](https://github.com/OPAE/intel-fpga-bbb/tree/master/samples)
directory.

## Structure

All of the tutorials have two components: CPU-side software in the sw tree
and FPGA-side RTL in the hw tree.

AFU sources are stored in directories named hw/rtl, which contain:
 - A file specifying the set of sources to compile: sources.txt.
 - A JSON file containing meta-data that describes the AFU.
 - RTL sources.

Each example also includes software to drive the AFUs. While in a sw directory,
run "make".  Two binaries will be generated.  The binary with an "\_ase" suffix
connects only to RTL simulated in ASE.  Binaries without the "\_ase" suffix
connect to actual FPGAs.  If you run the non-ASE version on a machine without
an FPGA it will print an error that the target hardware was not found.

## Configuring the Build Environment

The OPAE SDK must be installed.  The SDK is available through multiple
methods.  Choose one:

1. Pre-compiled Linux RPMs are shipped with platform releases.  Follow
   the installation guide included in a platform release.  Ensure that
   the optional ASE (the AFU Simulation Environment) RPM is installed.

2. OPAE SDK sources and pre-compiled RPMs are stored on GitHub in
   https://github.com/OPAE/opae-sdk.  Installation instructions are available
   at https://opae.github.io.  Ensure that the optional ASE (the AFU
   Simulation Environment) is installed, either using the pre-compiled RPMs
   or by following the ASE documentation at https://opae.github.io.

Ensure that the OPAE SDK and ASE are properly installed.  Confirm that the
afu_sim_setup program is found on the PATH in a shell.

When a platform release is installed, set the OPAE_PLATFORM_ROOT environment
variable to the root of a platform release directory, as described in the
platform's quickstart guide.  Confirm that the variable setting appears valid
by checking that the $OPAE_PLATFORM_ROOT/hw/lib directory exists.  If no
platform release is installed you will still be able to simulate AFUs with ASE.
However, you will not be able to synthesize for hardware.
