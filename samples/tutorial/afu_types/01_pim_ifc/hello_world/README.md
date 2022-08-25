# Host Channels: Hello World!

This example is nearly the simplest possible accelerator. The RTL receives an address via a memory mapped I/O (MMIO) write and generates a DMA write with the payload "Hello World!" to the memory line at that address. The software spins, waiting for the line to update. Once available, the software prints the string.

There are three functionally equivalent RTL implementations: one using AXI memory interfaces, one using Avalon memory interfaces, and one using CCI-P. All three can be compiled on any PIM-based platform. The PIM instantiates bridges to the interface expected by each version of the AFU.

The Platform Interface Manager \(PIM\) is used to transform the physical host channel, e.g. PCIe, to memory mapped interfaces. The details of the transformation, such as generating PCIe TLP packets, are left to the PIM. As you will see, the AFU RTL requires no knowledge of the host channel's protocol and can be compiled on FIMs with a wide variety of host channel's.

The details of individual RTL examples and interfaces are discussed at the end of this README.

## AFU RTL Source Specification

OPAE provides a collection of scripts for configuring both simulation and synthesis environments, driven by a common source specification. All tutorial AFUs define their RTL sources within their hw/rtl trees in files with variations of the name *sources.txt*. These *sources.txt* files are parsed by an OPAE script, *rtl\_src\_config*, which is invoked by the configuration tools described below. For source configuration syntax, run "rtl\_src\_config --help".

Every AFU requires a JSON file that holds meta-data required when it is compiled and loaded on an FPGA. The JSON holds a 128 bit UUID that identifies the accelerator. It also declares interface requirements that are consumed by the PIM. The current version of the PIM expects only that the afu-top-interface name be set to *ofs\_plat\_afu* in the JSON — a significant change from previous versions. JSON files are also used to define the AFU-specific frequency of the user configurable clock (uClk). The three *hello\_world* examples share a JSON file, since they are functionally identical and have identical CSR mapping.

## Simulation with ASE

Follow the steps in the root of the [samples tree](../../..) for configuring your environment. In particular, ensure that the OPAE SDK is properly installed. OPAE SDK scripts must be on PATH and include files and libraries must be available to the C compiler. The ASE simulator must be compiled and installed into the OPAE environment. Also confirm that the OPAE\_PLATFORM\_ROOT environment variable points to a release tree that has been configured with the PIM. All OFS FIM builds automatically embed the PIM. If the steps below work, you can be confident that your environment is properly configured.

Simulation requires two software processes: one for RTL simulation and the other to run the connected software. To construct an RTL simulation environment execute the following in the directory containing this README:

```bash
afu_sim_setup --source hw/rtl/axi/sources.txt build_sim
```
The Avalon and CCI-P versions are built by changing *axi* to the directories with the other variants. CCI-P is a legacy interface that was used instead of PCIe on previous OPAE-based systems. New designers are unlikely to find it valuable.

The *afu\_sim\_setup* script constructs an ASE environment in the *build\_sim* subdirectory. If the command fails, confirm that *afu\_sim\_setup* is on your PATH (in the OPAE SDK bin directory) and that your Python version is at least 2.7.

### Simulation

To build and execute the simulated RTL:

```bash
cd build_sim
make
make sim
```

This will build and run the RTL simulator.  If this step fails it is likely that your RTL simulator is not installed properly. ModelSim, Questa and VCS are supported.

The simulator prints a message that it is ready for simulation. It also prints a message to set the ASE_WORKDIR environment variable. Open another shell and cd to the directory holding this README. To build and run the software:

```bash
# Set ASE_WORKDIR as directed by the simulator
cd sw
make
with_ase ./hello_world
```

The *with\_ase* prefix transforms an existing binary to load the ASE emulation shared library instead of the normal OPAE shared library. Without *with\_ase*, the program would look for an AFU running on an actual FPGA.

The software and simulator should both run quickly, log transactions and exit. If the software prints "Accelerator not found" you ran without *with\_ase* (./hello\_world instead of with\_ase ./hello\_world). The binary did not find the AFU on an attached FPGA and failed.

### Debugging

Several transaction logs are generated in the *work* subdirectory during RTL simulation, all named with the suffix *.tsv*. The PIM's primary interfaces have built-in logging that can be enabled or disabled in each instance of an interface by setting the LOG\_CLASS parameter. The parameter is set in both the AXI and Avalon hello world samples. The enumeration passed to LOG\_CLASS corresponds to .tsv log files, with ofs\_plat\_log\_pkg::HOST\_CHAN mapping to log\_ofs\_plat\_host\_chan.tsv. All interfaces with logging enabled write to the same file, making it possible to see transactions in logical order as they pass through the hierarchy. Log entries are tagged with the full path of the interface instance. Specific interfaces instances may be isolated with search tools such as *grep*.

ASE also logs transactions at the boundary between the AFU and the simulated platform. Platforms with native PCIe TLP interfaces log to *work/log\_ase\_events.tsv* and platforms with native CCI-P interfaces log to *work/ccip\_transactions.tsv*.

Waveform debugging is available after simulation by executing:

```bash
make wave
```

## Synthesis with Quartus

RTL simulation and synthesis are driven by the same sources.txt and underlying OPAE scripts. To construct a Quartus synthesis environment for this AFU, enter:

```bash
afu_synth_setup --source hw/rtl/axi/sources.txt build_synth
cd build_synth
${OPAE_PLATFORM_ROOT}/bin/afu_synth
```

afu\_synth will invoke Quartus, which must be properly installed. Note that each platform release requires a specific Quartus version in order to match the FIM. The end result will be a file named *hello\_world.gbs* in the build\_synth directory. This GBS file may be loaded onto a compatible FPGA using OPAE's fpgaconf tool.

To run the software connected to an FPGA, compile it as above and invoke the binary. If you have already run ASE simulation, the binary has already been compiled and make will do nothing:

```bash
# Continue in the build_synth directory where afu_synth was invoked...

# Load the AFU into the partial reconfiguration region.
# sudo may be required, depending on your environment.
fpgaconf hello_world.gbs

cd ../sw
make
# sudo may be required to invoke hello_world, depending on your environment.
./hello_world
```

## PIM: Avalon, AXI and CCI-P

Platform interface wires are passed to the AFU's top-level *ofs\_plat\_afu* module in a single wrapper interface: *plat\_ifc*. The wrapper interface holds vectors of sub-interfaces. These sub-interfaces are deliberately given protocol-independent names. Connections to the host (PCIe, etc.) are named *host\_chan*, connections to FPGA local memory are called *local\_mem*. Device interfaces are always vectors, even if only one is present. This allows for portability: an AFU may work as long as at least the required number of instances of a device category (e.g. memory banks) are available.

The PIM provides modules with standardized names that map platform interfaces to AFU interfaces chosen by AFU developers. A module that maps a host channel to AXI-MM will have the same name on all platforms, though the implementation within the PIM may vary significantly. Platforms exposing PCIe TLPs and platforms exposing CCI-P from the FIM will have quite different internal PIM implementations, but the same PIM/AFU interface.

The choice of interface is up to each AFU developer. The area costs of any required bridges tends to be small. The largest structures in bridges are typically reorder buffers that sort responses in request order. AFUs that require ordered responses will need this structure anyway.

The hello world example is implemented three times. In each version, *ofs_plat_afu.sv* is the top-level module and uses the PIM to map the FIM's host channel to memory mapped interfaces. The hello world SystemVerilog modules connect only to the memory mapped CSR and DMA interfaces, leaving the PIM to manage the host channel protocol.

### Avalon

The Avalon RTL example's top-level module is [hw/rtl/avalon/ofs\_plat\_afu.sv](hw/rtl/avalon/ofs_plat_afu.sv) and the hello world logic is in [hw/rtl/avalon/hello\_world\_avalon.sv](hw/rtl/avalon/hello_world_avalon.sv). It instantiates two Avalon memory interfaces: one for MMIO (the AFU's CSR space) and one for DMA to host memory. The PIM's Avalon MMIO implementation allows the AFU to select the width of the MMIO bus. The address space is adjusted automatically to match. Avalon interfaces are defined in $OPAE\_PLATFORM\_ROOT/hw/lib/build/platform/ofs\_plat\_if/rtl/base\_ifcs/avalon/, derived from the PIM sources: [ofs\_plat\_avalon\_mem\_rdwr\_if.sv](https://github.com/OPAE/ofs-platform-afu-bbb/blob/master/plat_if_develop/ofs_plat_if/src/rtl/base_ifcs/avalon/ofs_plat_avalon_mem_rdwr_if.sv) and [ofs\_plat\_avalon\_mem\_if.sv](https://github.com/OPAE/ofs-platform-afu-bbb/blob/master/plat_if_develop/ofs_plat_if/src/rtl/base_ifcs/avalon/ofs_plat_avalon_mem_if.sv).

### AXI

The AXI RTL example's top-level module is [hw/rtl/axi/ofs\_plat\_afu.sv](hw/rtl/axi/ofs_plat_afu.sv) and the hello world logic is in [hw/rtl/axi/hello\_world\_axi.sv](hw/rtl/axi/hello_world_axi.sv). It is generally similar to the Avalon example, though AXI is more complex than Avalon. AXI's split address and data buses, along with the addition of back-pressure on response channels, requires significantly more logic. AXI interfaces are defined in $OPAE\_PLATFORM\_ROOT/hw/lib/build/platform/ofs\_plat\_if/rtl/base\_ifcs/axi/, derived from the PIM sources: [ofs\_plat\_axi\_mem\_if.sv](https://github.com/OPAE/ofs-platform-afu-bbb/blob/master/plat_if_develop/ofs_plat_if/src/rtl/base_ifcs/axi/ofs_plat_axi_mem_if.sv) and [ofs\_plat\_axi\_mem\_lite\_if.sv](https://github.com/OPAE/ofs-platform-afu-bbb/blob/master/plat_if_develop/ofs_plat_if/src/rtl/base_ifcs/axi/ofs_plat_axi_mem_lite_if.sv).

### CCI-P

The CCI-P RTL example's top-level module is [hw/rtl/ccip/ofs\_plat\_afu.sv](hw/rtl/ccip/ofs_plat_afu.sv) and the hello world logic is in [hw/rtl/ccip/hello\_world\_ccip.sv](hw/rtl/ccip/hello_world_ccip.sv). The CCI-P protocol was the original protocol offered on OPAE systems. While still available from the PIM, we expect that architects of new AFUs will choose either Avalon or AXI. The CCI-P interface is defined in $OPAE\_PLATFORM\_ROOT/hw/lib/build/platform/ofs\_plat\_if/rtl/ifc\_classes/host\_chan/afu\_ifcs/ccip/ofs\_plat\_host\_ccip\_if.sv, derived from the PIM sources: [ofs\_plat\_host\_ccip\_if.sv](https://github.com/OPAE/ofs-platform-afu-bbb/blob/master/plat_if_develop/ofs_plat_if/src/rtl/ifc_classes/host_chan/afu_ifcs/ccip/ofs_plat_host_ccip_if.sv).

### Tie Offs

AFUs tie off any unused FIM interfaces by instantiating ofs\_plat\_if\_tie\_off\_unused\(\) and setting parameter values to the module indicating which interfaces are used by the AFU. The PIM is aware of all available devices. By indicating which devices are used, PIM code infers which devices are not used and ties them off. The AFU sources do not have to know what devices are available in order to tie off unused ports.

## Software

The software side is contained entirely in [sw/hello_world.c](sw/hello_world.c) and is common to all examples since they all implement the same FPGA-side CSRs:

- The AFU ID in the software must match the AFU ID in the hardware's DFH. The OPAE SDK provides a tool for generating a C header file from an AFU's JSON file. The Makefile implements this flow.

- The FPGA-accessible shared memory is mapped explicitly.

- Memory addresses passed to the AFU wires are in a physical I/O address space. The PIM's memory interfaces operate on 512 bit memory lines. The example passes the line-based physical address to which "Hello World!" should be written.

- The code in connect\_to\_accel() is a simplification of the ideal sequence. The code detects at most one accelerator matching the desired UUID.  Later examples detect when multiple instances of the same hardware are available in case one is already in use.
