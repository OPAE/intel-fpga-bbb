# Tutorial

The sample designs in this tree are deliberately simple. They are intended
to demonstrate simulation, synthesis and the Platform Interface Manager
without the details of an actual accelerator getting in the way.

All the designs may either be simulated with ASE or synthesized for FPGA
hardware.

The Platform Interface Manager (PIM) is an abstraction layer, enabling AFU
portability across hardware despite variations in hardware topology and native
interfaces. The PIM implementation is documented both for platform developers
and for AFU developers in its [source repository](https://github.com/OPAE/ofs-platform-afu-bbb/).
Use of the PIM for AFU developers is optional. As the tutorial
is intended to be platform-agnostic, all of the examples use the PIM. See
below for a short discussion of [non-PIM AFU development](#non-pim-afu-development).

This tutorial assumes that OPAE has been installed already, that your
OPAE\_PLATFORM\_ROOT environment variable points to a release updated with
PIM v2, and that the BBB (Basic Building Blocks) release is present. Please
follow the instructions in the README file in the [../samples](..) directory.

The tutorial documentation is written in Markdown. We suggest you pull a local
copy of the tutorial in order to compile the examples and that you read the
tutorial's documentation with a browser. The current version of the tutorial
is on GitHub in the
[OPAE Basic Building Blocks tree](https://github.com/OPAE/intel-fpga-bbb/tree/master/samples/tutorial).

## Structure

All of the tutorials have two components: CPU-side software in the sw tree
and FPGA-side RTL in the hw tree.

AFU sources are stored in directories named hw/rtl, which contain:

- A file specifying the set of sources to compile: sources.txt.
- A JSON file containing meta-data that describes the AFU.
- RTL sources.

Each example also includes software to drive the AFUs. While in a sw directory,
run "make".

## Topics

- [Section 1](01_hello_world/) describes the basic structure of an AFU, simulation
  with ASE and synthesis for hardware. It also covers the AXI, Avalon and CCI-P host
  interface options available through the PIM. __This section is a prerequisite for all
  subsequent sections. All of the later examples are compiled using the steps
  described here.__

- [Section 2](02_clocks/) documents the global clocks passed into AFUs and
  PIM-based clock management.

- [Section 3](03_local_memory/) covers the top-level interface to local
  memory, including clock management.

- [Section 4](04_PIM/) covers some more advanced PIM features.

## Non-PIM AFU Development

AFU developers may choose to connect directly to the PR interface or to the
platform-provided green\_bs() interface. Perhaps your AFU provides its own bridges
from native interfaces. Even then, we strongly suggest taking a hybrid approach
and attaching your AFU through the PIM's top-level ofs\_plat\_afu() module and
the plat\_ifc top-level interface wrapper. There is no performance or area cost
for this style compared to directly attaching to green\_bs(). The plat\_ifc
wrapper is only wires and all PR interfaces are available, mapped through plat\_ifc.
There are several advantages to connecting through ofs\_plat\_afu():

- AFUs can be simulated with ASE as long as they connect through ofs\_plat\_afu().
  The ASE environment emulates the plat\_ifc interface and is fully functional,
  whether or not an AFU uses PIM-provided bridge modules.
- The wired PIM interface wrappers in plat\_ifc offer both transaction logging
  and some error checking during simulation, whether or not PIM bridges are used.
- AFUs might use PIM bridges for some interfaces and not others. For example,
  an AFU that provides its own shell for PCIe and connects directly to the host
  channel port may still use the PIM to map local memory to a target interface
  and clock.
- The PIM's tie-off module for unused interfaces is available for AFUs that
  don't use other PIM modules.
