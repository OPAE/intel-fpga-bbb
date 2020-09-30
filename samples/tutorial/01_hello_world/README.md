This example is nearly the simplest possible accelerator. The RTL receives an
address via a memory mapped I/O (MMIO) write and generates a DMA write to the
memory line at that address, containing the string "Hello World!". The
software spins, waiting for the line to update. Once available, the software
prints the string.

There are three functionally equivalent RTL implementations: one using AXI memory
interfaces, one using Avalon memory interfaces, and one using CCI-P. All three
can be compiled on any PIM-based platform. The PIM instantiates bridges to the
interface expected by each version of the AFU. Each version has a single
SystemVerilog source file, found in subdirectories of [hw/rtl](hw/rtl).

The details of individual RTL examples and interfaces are discussed at the end
of this README.

## AFU RTL Source Specification

OPAE provides a collection of scripts for configuring both simulation and
synthesis environments, driven by a common source specification. All tutorial
AFUs define their RTL sources within their hw/rtl trees in files with variations
of the name "sources.txt". These "sources.txt" files are parsed by an OPAE
script, "rtl\_src\_config", which is invoked by the configuration tools
described below. For source configuration syntax, run "rtl\_src\_config --help".

Every AFU requires a JSON file that holds meta-data required when it is compiled
and loaded on an FPGA. The JSON holds a 128 bit UUID that identifies the accelerator.
It also declares interface requirements that are consumed by the PIM. The current
version of the PIM expects only that the afu-top-interface name be set to
"ofs\_plat\_afu" in the JSON — a signficant change from previous versions. JSON
files are also used to define the AFU-specific frequency of the user configurable
clock (uClk). The three hello\_world examples share a JSON file, since they are
functionally identical and have identical CSR mapping.

## Simulation with ASE

Follow the steps in the root of the [samples tree](../..) for configuring your
environment. In particular, ensure that the OPAE SDK is properly installed.
OPAE SDK scripts must be on PATH and include files and libraries must be
available to the C compiler. Also confirm that the OPAE\_PLATFORM\_ROOT
environment variable points to a release tree that has been configured with
the Platform Interface Manager (PIM). (If the steps below work, then you can
be confident that your environment is properly configured.)

Simulation requires two software processes: one for RTL simulation and
the other to run the connected software. To construct an RTL simulation
environment execute the following in the directory containing this
README:

```console
$ afu_sim_setup --source hw/rtl/axi/sources.txt build_sim
```
The Avalon and CCI-P verions are built by changing "axi" to the directories
with the other variants.

The afu\_sim\_setup script constructs an ASE environment in the build\_sim
subdirectory. If the command fails, confirm that afu\_sim\_setup is on your PATH
(in the OPAE SDK bin directory) and that your Python version is at least 2.7.

### Simulation

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
$ ./hello_world_ase
```

The software and simulator should both run quickly, log transactions and
exit. If the software prints "Accelerator not found" you ran the wrong
binary (./hello\_world instead of ./hello\_world\_ase). The binary without
the "ase" suffix is for execution on an FPGA.

### Debugging

Several transaction logs are generated in the "work" subdirectory during RTL
simulation, all named with the suffix ".tsv". The PIM's primary interfaces
have built-in logging that can be enabled or disabled in each instance of an
interface by setting the LOG\_CLASS parameter. The parameter is set in both the
AXI and Avalon hello world samples. The enumeration passed to LOG\_CLASS
corresponds to .tsv log files, with ofs\_plat\_log\_pkg::HOST\_CHAN mapping
to log\_ofs\_plat\_host\_chan.tsv. All interfaces with logging enabled write
to the same file, making it possible to see transactions in logical order as they
pass through the hierarchy. Log entries are tagged with the full path of the
interface instance. Specific interfaces instances may be isolated with search
tools such as "grep".

ASE also logs transactions at the boundary between the AFU and the simulated
platform. Platforms with native PCIe TLP interfaces log to work/log\_ase\_events.tsv
and platforms with native CCI-P interfaces log to work/ccip\_transactions.tsv.

Waveform debugging is also available after simulation by executing:

```console
$ make wave
```

## Synthesis with Quartus

RTL simulation and synthesis are driven by the same sources.txt and underlying
OPAE scripts. To construct a Quartus synthesis environment for this AFU, enter:

```console
$ afu_synth_setup --source hw/rtl/axi/sources.txt build_synth
$ cd build_synth
$ ${OPAE_PLATFORM_ROOT}/bin/afu_synth
```

afu\_synth will invoke Quartus, which must be properly installed. Note that each
platform release requires a specific Quartus version in order to match the
FIM. The end result will be a file named "hello\_world.gbs" in the build\_synth
directory. This GBS file may be loaded onto a compatible FPGA using OPAE's
fpgaconf tool.

To run the software connected to an FPGA, compile it as above, but invoke the
main binary. If you have already run ASE simulation, the binary has already
been compiled and make will do nothing:

```console
# Continue in the build_synth directory where afu_synth was invoked...

# Load the AFU into the partial reconfiguration region.
# sudo may be required, depending on your environment.
$ fpgaconf hello_world.gbs

$ cd ../sw
$ make
# sudo may be required to invoke hello_world, depending on your environment.
$ ./hello_world
```

## PIM: Avalon, AXI and CCI-P

Platform interface wires are passed to the AFU's top-level ofs\_plat\_afu module
in a single wrapper interface: plat\_ifc. The wrapper interface holds vectors of
sub-interfaces. These sub-interfaces are deliberately given protocol-independent
names. Connections to the host (PCIe, etc.) are named "host\_chan", connections to
FPGA local memory are called "local\_mem". Device interfaces are always vectors,
even if only one is present. This allows for portability: an AFU may work as long
as at least the required number of instances of a device (e.g. memory banks) are
available.

The PIM provides modules with standardized names that map platform interfaces to
AFU interfaces chosen by AFU developers. A module that maps a host channel to AXI-MM
will have the same name on all platforms, though the implementation within the PIM
may vary significantly. Platforms exposing PCIe TLPs and platforms exposing CCI-P from
the FIM will have quite different PIM implementations, but the same PIM/AFU interface.

The choice of interface is up to each AFU developer. The area costs of any required
bridges tends to be small. The largest structures in bridges are typically reorder
buffers that sort responses in request order. AFUs that require ordered responses will
need this structure anyway.

This hello world example is implemented three times:

### Avalon

The full Avalon RTL example is contained entirely in
[hw/rtl/avalon/hello\_world\_avalon.sv](hw/rtl/avalon/hello_world_avalon.sv). It
instantiates two Avalon memory interfaces: one for MMIO (the AFU's CSR space) and
one for DMA to host memory. The PIM's Avalon MMIO implementation allows the AFU
to select the width of the MMIO bus. The address space is adjusted automatically
to match. Avalon interfaces are defined in
$OPAE\_PLATFORM\_ROOT/hw/lib/build/platform/ofs\_plat\_if/rtl/base\_ifcs/avalon/,
derived from the PIM sources:
[ofs\_plat\_avalon\_mem\_rdwr\_if.sv](https://github.com/OPAE/ofs-platform-afu-bbb/blob/master/plat_if_develop/ofs_plat_if/src/rtl/base_ifcs/avalon/ofs_plat_avalon_mem_rdwr_if.sv)
and
[ofs\_plat\_avalon\_mem\_if.sv](https://github.com/OPAE/ofs-platform-afu-bbb/blob/master/plat_if_develop/ofs_plat_if/src/rtl/base_ifcs/avalon/ofs_plat_avalon_mem_if.sv).

### AXI

The AXI RTL example is in
[hw/rtl/axi/hello\_world\_axi.sv](hw/rtl/axi/hello_world_axi.sv). It is generally
similar to the Avalon example, though AXI is more complex than Avalon. AXI's
split address and data buses, along with the addition of back-pressure on
response channels, requires significantly more logic. AXI interfaces are defined in
$OPAE\_PLATFORM\_ROOT/hw/lib/build/platform/ofs\_plat\_if/rtl/base\_ifcs/axi/,
derived from the PIM sources:
[ofs\_plat\_axi\_mem\_if.sv](https://github.com/OPAE/ofs-platform-afu-bbb/blob/master/plat_if_develop/ofs_plat_if/src/rtl/base_ifcs/axi/ofs_plat_axi_mem_if.sv)
and
[ofs\_plat\_axi\_mem\_lite\_if.sv](https://github.com/OPAE/ofs-platform-afu-bbb/blob/master/plat_if_develop/ofs_plat_if/src/rtl/base_ifcs/axi/ofs_plat_axi_mem_lite_if.sv).

### CCI-P

The CCI-P RTL example is in
[hw/rtl/ccip/hello\_world\_ccip.sv](hw/rtl/ccip/hello_world_ccip.sv). The CCI-P
protocol was the original protocol offered on OPAE systems. While still available
from the PIM, we expect that architects of new AFUs will choose either Avalon or
AXI. The CCI-P interface is defined in
$OPAE\_PLATFORM\_ROOT/hw/lib/build/platform/ofs\_plat\_if/rtl/ifc\_classes/host\_chan/afu\_ifcs/ccip/ccip\_if\_pkg.sv, derived from the PIM sources:
[ccip\_if\_pkg.sv](https://github.com/OPAE/ofs-platform-afu-bbb/blob/master/plat_if_develop/ofs_plat_if/src/rtl/ifc_classes/host_chan/afu_ifcs/ccip/ccip_if_pkg.sv).

## Software

The software side is contained entirely in [sw/hello_world.c](sw/hello_world.c):

- The AFU ID in the software must match the AFU ID in the hardware's DFH. The OPAE
  SDK provides a tool for generating a C header file from an AFU's JSON file. The
  Makefile implements this flow.

- The FPGA-accessible shared memory is mapped explicitly.

- Memory addresses passed to the AFU wires are in a physical I/O address space.
  The PIM's memory interfaces operate on 512 bit memory lines. The example passes
  the line-based physical address to which "Hello World!" should be written.

- The code in connect\_to\_accel() is a simplification of the ideal
  sequence. The code detects at most one accelerator matching the
  desired UUID.  Later examples detect when multiple instances of the
  same hardware are available in case one is already in use.
