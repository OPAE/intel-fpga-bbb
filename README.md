# Intel FPGA Basic Building Blocks (BBB) #

Basic Building Blocks (BBB) for Intel FPGAs is a suite of reference sample code and helper shims on CCI-P interface that support these features.
* **Memory Protocol Factory (MPF)**: This helps in reordering Read/Write transactions, large memory support, hazard resolution, non-atomic partial writes.
* **CCI-P Async-shim (CCI-P ASYNC)**: Allows users to attach slower running accelerators to the CCI-P interface.
* **CCI-P Multiplexer (CCI-P MUX)**: Allows multiple CCI-P compliant agents to share a single CCI-P interface.
 
These shims are realized in SystemVerilog RTL and the software support is through Userspace libraries in C/C++.

BBB must be considered reference sample code that customers may learn from, use or modify for their own work. No kernel modules are released in the BBB project.

# Sub-Projects #

Currently, three sub-projects are available under Basic Building Blocks (BBB).

## BBB_cci_mpf ##

CCI-MPF supports Large buffer, virtual address, response sorting support, hazard mitigation, and non-atomic partial write support.

## BBB_ccip_async ##

CCI-P compatible Clock-crossing shim that allows slower AFUs to connect to either one of the CCI-P interface or user clocks.
               
## BBB_ccip_mux ##

Allows multiple CCI-P compatible agents to share a single CCI-P interface to the Intel Blue Bitstream.

# Samples and tutorial #

A tutorial on CCI-P and Basic Building Blocks (BBB) is in the top-level samples directory.

# Release Quality #

All Basic Building Blocks (BBB) are tested with supplied examples on an Ubuntu 14.04 64-bit OS machine with an Integrated Xeon-FPGA. All the Basic Building Blocks (BBB) are known to work with OPAE AFU Simulation Environment (ASE). The project must be considered Alpha quality, and must be used "as-is".

# How To Contribute #

Feel free to fork, contribute and share your code as-is in accordance with BSD-3 license

The Intel FPGA Basic Building Blocks (BBB) project uses a recommended (minimum) directory structure. In your pull-requests, please use the following format. All BBBs must start with a ```BBB_``` prefix.

```

	BBB_<name>
	|-- hw          : Hardware must be staged here
	|   |-- rtl     :   RTL files
	|   |-- sim     :   Simulation files list (if available)
	|   `-- par     :   PAR specific files
	|-- sw          : BBB-specific SW code
	`-- samples     : Samples showing how to use the BBB

```

**NOTE:**

* For the sake of space do not check in application objects, libraries, or bitstreams into the repo.
  * In the 'par' directory, check in only Quartus settings' snippets
  * Same as above for SDC files
  * Do not check in Quartus projects here.
* Please provide a list of files for 'par' and 'sim' to reduce support churn
  * If the BBB requires a common set of steps, please consider providing SW helper functions that can be reused (eg: libMPF.so::setup_VTP)
