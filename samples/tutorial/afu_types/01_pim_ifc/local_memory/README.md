# Local Memory

By *local memory*, we mean memory that is directly attached to FPGA pins. The PIM is consistent in naming any locally attached memory (DDR, HBM, etc.) *local memory*. Ports to host memory are always named *host channels*, since I/O with the host is often a combination of DMA and CSR traffic. *Host channels* were described in the original [hello world](../hello_world) example.

Like host channels and clocks, local memory is passed to the *ofs\_plat\_afu\(\)* top-level module in the *plat\_ifc* wrapper interface. Also similar to host channels, the PIM provides bridges for local memory with protocol translations to Avalon-MM or AXI-MM as well as optional clock crossing.

## Example Code

The sample code here has two variants, one with AXI ports to local memory and one with Avalon. The majority of code is common. Both examples use the same AXI-lite MMIO host interface. AXI-lite can be used in both examples, even with Avalon local memory, because the host interface protocol and local memory protocols are completely independent.

The example builds a simple CSR interface controlled by the host. The CSR logic in [common/mem\_csr.sv](hw/rtl/common/mem_csr.sv) sends commands to an FSM in [common/mem\_fsm.sv](hw/rtl/common/mem_fsm.sv) over an Avalon memory channel. The FSM generates requests to local memory.

The example is driven by software in the [sw](sw) directory. Build and run it using the same steps as the previous examples.

## AXI

The AXI variant instantiates a vector of [ofs\_plat\_axi\_mem\_if](https://github.com/OPAE/ofs-platform-afu-bbb/blob/master/plat_if_develop/ofs_plat_if/src/rtl/base_ifcs/axi/ofs_plat_axi_mem_if.sv) interfaces, one for each memory bank, in [axi/ofs\_plat\_afu.sv](hw/rtl/axi/ofs_plat_afu.sv). The *ofs\_plat\_axi\_mem\_if* interface is the same definition used for AXI DMA streams connected to host memory in the [hello world](../hello_world) example. The module *ofs\_plat\_local\_mem\_as\_axi\_mem* instantiates a bridge from the platform's base interface to AXI. The PIM provides the same portable module name on any platform, independent of the actual protocol of the base interface. The AFU source is thus portable across platforms, even when platforms change the native local memory interface.

In addition to the protocol translation, the example commands *ofs\_plat\_local\_mem\_as\_axi\_mem* to instantiate a clock crossing from each memory bank's native clock to the host channel's clock by setting the ADD\_CLOCK\_CROSSING parameter and specifying a target clock. Most PIM shims offer crossing to AFU-specified clock domains. In this local memory example, all AFU interfaces operate in a common clock domain.

Logic in [axi/afu\_top.sv](hw/rtl/axi/afu_top.sv) maps commands from the FSM to local memory AXI requests. Of course a production AFU is likely to employ a single protocol universally instead of this combination of Avalon and AXI. Avalon is used here in the FSM to avoid rewriting a module that isn't central to the example.

The AXI example can be configured for simulation with:

```console
$ afu_sim_setup --source hw/rtl/sources_axi.txt build_sim
```

or synthesis with:

```console
$ afu_synth_setup --source hw/rtl/sources_axi.txt build_synth
```

## Avalon

The Avalon variant has very similar structure to the AXI variant. It instantiates a vector of [ofs\_plat\_avalon\_mem\_if](https://github.com/OPAE/ofs-platform-afu-bbb/blob/master/plat_if_develop/ofs_plat_if/src/rtl/base_ifcs/avalon/ofs_plat_avalon_mem_if.sv) Avalon interfaces in [avalon/ofs\_plat\_afu.sv](hw/rtl/avalon/ofs_plat_afu.sv) and maps the platform's local memory base interface by invoking *ofs\_plat\_local\_mem\_as\_avalon\_mem*. The logic in [avalon/afu\_top.sv](hw/rtl/avalon/afu_top.sv) passes commands from the FSM to the local memory Avalon interfaces.

Like the AXI code, the Avalon example adds a clock crossing to each local memory bank by passing a target clock to *ofs\_plat\_local\_mem\_as\_avalon\_mem* and setting ADD\_CLOCK\_CROSSING.

The Avalon example can be configured for simulation with:

```console
$ afu_sim_setup --source hw/rtl/sources_avalon.txt build_sim
```

or synthesis with:

```console
$ afu_synth_setup --source hw/rtl/sources_avalon.txt build_synth
```

## Debugging

Like host channels, event logging is available for local memory. Transaction logs are written to log\_ofs\_plat\_local\_mem.tsv (for ASE, in the "work" directory). Any interface with LOG_CLASS set to ofs\_plat\_log\_pkg::LOCAL\_MEM, including interfaces instantiated at any point in AFU sources, will log to this file.
