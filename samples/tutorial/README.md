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


All of the tutorials have two components: CPU-side software in the sw tree
and FPGA-side RTL in the hw tree.  While in a sw directory, run "make".
One or two binaries will be generated.  The binary with an "_ase" suffix
connects only to RTL simulated in ASE.  Some examples also generate a
binary with the same prefix and no "_ase" suffix.  These binaries connect
to actual FPGAs.  If you run the non-ASE version on a machine without an
FPGA it will print an error that the target hardware was not found.

Building RTL for simulation in ASE requires multiple steps.  The steps
are identical for all examples:

1. Configure an ASE environment for the RTL.  Each example contains a
   setup script: hw/sim/setup_ase.  The script takes one argument: the name
   of a directory in which to build an ASE environment.  The following
   sequence constructs an environment in 01_hello_world/hw/build:

   ```
       cd 01_hello_world/hw
       rm -rf build
       ./sim/setup_ase build
       cd build
   ```

2. Compile the simulator:

   ```
       make
   ```


Execution requires two shells: one to run the RTL simulator and the other
to run the software.  The RTL simulator is started first.

1. In the build directory (e.g. 01_hello_world/hw/build from above):

   ```
       make sim
   ```

   The simulator will start, eventually printing a message to set the
   ASE_WORKDIR environment variable in the software-side shell.  The
   ASE run-time environment connects software to the simulator with
   this pointer.

2. The other shell should be in the corresponding sw directory, e.g.
   01_hello_world/sw.  The software is compiled by typing "make".  Set the
   ASE_WORKDIR environment variable using the value printed in step 1 and
   run the binary with the _ase suffix:

   ```
       export ASE_WORKDIR=<path from step 1>/01_hello_world/hw/build/work
       ./cci_hello_ase
   ```

   The software will start and connect to ASE.  The ASE RTL simulation will
   indicate that a session has connected.  When the software side is done, ASE
   will also exit.
