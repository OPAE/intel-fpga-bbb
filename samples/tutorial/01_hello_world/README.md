This example is nearly the simplest possible accelerator. The RTL receives an
address via a memory mapped I/O (MMIO) write and generates a CCI write to the
memory line at that address, containing the string "Hello World!". The
software spins, waiting for the line to update. Once available, the software
prints the string.

The RTL is contained entirely in
[hw/rtl/cci_hello_afu.sv](hw/rtl/cci_hello_afu.sv) and demonstrates the
following universal AFU requirements:

- The CCI request and response ports are clocked by pClk.

- Reset (pck_cp2af_softReset) is synchronous with pClk.

- Outgoing request and incoming response wires must be registered.

- All AFUs must implement a read-only device feature header (DFH) in MMIO
  space at MMIO address 0. The DFH holds a 128 bit AFU ID, mapped to a pair of
  64 bit MMIO "registers". The AFU ID that uniquely identifies the design is
  stored in [hw/rtl/cci_hello.json](hw/rtl/cci_hello.json) and is extracted by
  the OPAE afu_json_mgr script into both Verilog and C header files.
  afu_json_mgr is invoked by the simulation and synthesis setup scripts
  described below for RTL and by [sw/Makefile](sw/Makefile) for software.

  AFU JSON will be covered in greater detail in [Section 2](../02_platform_ifc/).

- CCI request rates are limited by off-chip physical bus speeds and by
  buffering inside the Intel-supplied FIU (the blue bitstream). User RTL
  must honor the CCI almost full signals to avoid lost requests.

The software side is contained entirely in [sw/cci_hello.c](sw/cci_hello.c):

- The AFU ID in the software must match the AFU ID in the hardware's DFH.

- The FPGA-accessible shared memory is mapped explicitly.

- Memory addresses passed to the FIU's CCI request wires are in a
  physical I/O address space. Since all CCI requests refer to entire 512
  bit memory lines, the example passes the line-based physical address
  to which "Hello World!" should be written.

- The code in connect_to_accel() is a simplification of the ideal
  sequence. The code detects at most one accelerator matching the
  desired UUID.  Later examples detect when multiple instances of the
  same hardware are available in case one is already in use.


## AFU RTL Source Specification

OPAE provides a collection of scripts for configuring both simulation and
synthesis environments, driven by a common source specification. All tutorial
AFUs define their RTL sources in hw/rtl/sources.txt. These sources.txt files
are parsed by an OPAE script, "rtl_src_config", which is invoked by the
configuration tools described below. For source configuration syntax, run
"rtl_src_config --help".


## Simulation with ASE

Follow the steps in the root of the [samples tree](../..) for configuring your
environment. In particular, ensure that the OPAE SDK is properly installed.
OPAE SDK scripts must be on PATH and include files and libraries must be
available to the C compiler.

Simulation requires two software processes: one for RTL simulation and
the other to run the connected software. To construct an RTL simulation
environment execute the following in the directory containing this
README:

```console
$ afu_sim_setup --source hw/rtl/sources.txt build_sim
```

Many samples provide wrapper scripts for convenience as hw/sim/setup_ase. The
following is equivalent to afu_sim_setup above:

```console
$ ./hw/sim/setup_ase build_sim
```

Either of these will construct an ASE environment in the build_sim
subdirectory. If the command fails, confirm that afu_sim_setup is on your PATH
(in the OPAE SDK bin directory) and that your Python version is at least 2.7.

To build and execute the simulator:

```console
$ cd build_sim
$ make
$ make sim
```

This will build and run the RTL simulator.  If this step fails it is
likely that your RTL simulator is not installed properly. ModelSim,
Questa and VCS are supported.

The simulator prints a message that it is ready for simulation. It also
prints a message to set the ASE_WORKDIR environment variable. Open
another shell and cd to the directory holding this README. To build and
run the software:

```console
# Set ASE_WORKDIR as directed by the simulator
$ cd sw
$ make
$ ./cci_hello_ase
```

The software and simulator should both run quickly, log transactions and
exit. If the software prints "Accelerator not found" you ran the wrong
binary (./cci_hello instead of ./cci_hello_ase). The binary without the "ase"
suffix is for execution on an FPGA.


## Synthesis with Quartus

RTL simulation and synthesis are driven by the same sources.txt and underlying
OPAE scripts. Unlike simulation with ASE, a platform-specific release must be
installed and the OPAE_PLATFORM_ROOT environment variable must be set, as
described in the [samples directory](../..). To construct a Quartus synthesis
environment for this AFU, enter:

```console
$ afu_synth_setup --source hw/rtl/sources.txt build_synth
$ cd build_synth
$ ${OPAE_PLATFORM_ROOT}/bin/run.sh
```

run.sh will invoke Quartus, which must be properly installed. Note that each
platform release requires a specific Quartus version in order to match the
FIU. The end result will be a file named hello_afu.gbs in the build_synth
directory. This GBS file may be loaded onto a compatible FPGA using OPAE's
fpgaconf tool.

To run the software connected to an FPGA, compile it as above, but invoke the
main binary. If you have already run ASE simulation, the binary has already
been compiled and make will do nothing:

```console
# Continue in the build_synth directory where run.sh was invoked...

# Load the AFU into the partial reconfiguration region
$ sudo fpgaconf cci_hello.gbs

$ cd ../sw
$ make
# sudo may be required to invoke cci_hello, depending on your environment.
$ ./cci_hello
```
