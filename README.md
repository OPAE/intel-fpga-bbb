# Intel FPGA Basic Building Blocks (BBB) #

Basic Building Blocks (BBB) for Intel FPGAs is a suite of application
building blocks and shims for transforming the CCI-P interface.

For detailed documentation of the building blocks, please visit the [BBB
Wiki](https://github.com/OPAE/intel-fpga-bbb/wiki "BBB Wiki").

## [BBB_cci_mpf](https://github.com/OPAE/intel-fpga-bbb/wiki/BBB_cci_mpf) ##

**Memory Properties Factory (MPF)**: MPF shims may be mixed and matched to
add features to the base CCI-P memory interface. Features include: virtual
memory, ordered read responses, read/write hazard detection, and masked
(partial) writes.

## [BBB_ccip_async](https://github.com/OPAE/intel-fpga-bbb/wiki/BBB_ccip_async) ##

**CCI-P Async-shim (CCI-P ASYNC)**: A clock crossing shim, allowing users to
attach slower-running accelerators to the CCI-P interface.

## BBB_ccip_mux ##

**CCI-P Multiplexer (CCI-P MUX)**: Allows multiple CCI-P compliant agents to
share a single CCI-P interface.
 
These building blocks are implemented in SystemVerilog RTL and C or C++.

# Versions #

Interfaces and scripts in the BBB repository track changes in the [OPAE
SDK](https://github.com/OPAE/opae-sdk). Master here may require OPAE SDK's
master as well. There are release branches here in the BBB repository
corresponding to OPAE SDK releases.

# [Samples and Tutorial](https://github.com/OPAE/intel-fpga-bbb/wiki/Tutorial) #

A tutorial on CCI-P and Basic Building Blocks (BBB) is in the top-level
[samples](https://github.com/OPAE/intel-fpga-bbb/tree/master/samples)
directory.

# Release Quality #

The BBBs should be considered reference sample code that customers may use or
modify for their own work. No kernel modules are released in the BBB
project. All Basic Building Blocks are tested with supplied examples on an
Ubuntu 14.04 64-bit OS machine with an Integrated Xeon-FPGA. All the BBBs are
known to work with the OPAE AFU Simulation Environment (ASE). The project
must be considered Alpha quality, and must be used "as-is".

# How To Contribute #

Feel free to fork, contribute and share your code as-is in accordance with
the BSD-3 license. We encourage submitting bug fixes to the repository via a
pull request in line with our [contribution
guidelines](https://github.com/OPAE/intel-fpga-bbb/blob/master/CONTRIBUTING.md).

The Intel FPGA Basic Building Blocks (BBB) project uses a recommended
(minimum) directory structure. All BBBs must start with a ```BBB_```
prefix. In your pull-requests, please use the following format:

```

	BBB_<name>
	|-- hw          : Hardware must be staged here
	|   |-- rtl     :   RTL files
	|   |-- sim     :   Simulation files list (if available)
	|   `-- par     :   PAR-specific files
	|-- sw          : BBB-specific SW code
	`-- samples     : Samples showing how to use the BBB

```

**NOTE:**

* For the sake of space do not check in application objects, libraries, or
  bitstreams into the repository.
  * In the 'par' directory, check in only Quartus settings snippets.
  * Do the same for SDC files.
  * Do not check in Quartus projects here.
* Please provide a list of required files for 'par' and 'sim'.
* If the BBB requires a common set of steps, please consider providing SW
  helper functions that can be reused.
