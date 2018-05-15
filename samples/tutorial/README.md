# Tutorial

The sample designs in this tree are deliberately simple. They are intended
to demonstrate simulation, synthesis and proper use of CCI (Core-Cache
Interface) without the details of an actual accelerator getting in the way.

All the designs may either be simulated with ASE or synthesized for FPGA
hardware.

This tutorial assumes that OPAE has been installed already and that the BBB
(Basic Building Blocks) release for CCI is present. Please follow the
instructions in the README file in the
[../samples](..)
directory.

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
run "make". Two binaries will be generated. The binary with an "\_ase" suffix
connects only to RTL simulated in ASE.  Binaries without the "\_ase" suffix
connect to actual FPGAs.  If you run the non-ASE version on a machine without
an FPGA it will print an error that the target hardware was not found.

## Topics

- [Section 1](01_hello_world/) describes the minimum requirements for a CCI-P
  compliant AFU, simulation with ASE and synthesis for hardware. __This
  section is a prerequisite for all subsequent sections. All of the later
  examples are compiled using the steps described here.__

- [Section 2](02_platform_ifc/) introduces the OPAE Platform Interface Manager
  (PIM). The PIM constructs a shim that mates an AFU's top-level interface to
  the base system. The PIM manages top-level clocking, allowing AFUs to
  request automatic instantiation of clock-crossing shims for device
  interfaces. AFU's may also instruct the PIM to constrain the frequency of
  the user clock, including an automatic mode similar to OpenCL in which the
  user clock frequency is set to the Fmax achieved during compilation.

- [Section 3](03_ccip/) covers basic CCI-P concepts and introduces the Memory
  Properties Factory
  ([MPF](https://github.com/OPAE/intel-fpga-bbb/wiki/BBB_cci_mpf)) Basic
  Building Block (BBB). MPF is a collection of configurable shims that
  transform CCI-P semantics. MPF adds options such as ordered memory
  transactions and AFU-side virtual addressing managed by a TLB.

- [Section 4](04_local_memory/) covers the top-level interface to local
  memory, including clock management.
