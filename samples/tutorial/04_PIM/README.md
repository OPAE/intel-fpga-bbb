# Advanced PIM Topics

There are currently no code or sample AFUs for this section. It describes PIM
parameterization and features.

## Simulation-Time Error Checking

Most PIM interfaces include automatic simulation-time checks for malformed encodings.
See, for example, the validation block in
[ofs\_plat\_avalon\_mem\_if](https://github.com/OPAE/ofs-platform-afu-bbb/blob/master/plat_if_develop/ofs_plat_if/src/rtl/base_ifcs/avalon/ofs_plat_avalon_mem_if.sv), which
detects un-driven read and write signals. It also detects un-driven address and other
control fields during read or write transactions.

## Simulation-Time Logging

Many PIM interfaces can emit transaction logs during simulation. Logging is disabled
by default and is enabled by setting the LOG\_CLASS parameter in a specific instance.
LOG\_CLASS is an enumeration defined in
[ofs\_plat\_log\_pkg.sv](https://github.com/OPAE/ofs-platform-afu-bbb/blob/master/plat_if_develop/ofs_plat_if/src/rtl/utils/ofs_plat_log_pkg.sv). Each entry in the enumeration
corresponds to a transaction log file shared by all instances assigned to the class.
Several examples in the tutorial discuss LOG\_CLASS and logging.

## Interface Parameterization

The AXI and Avalon interfaces defined in the PIM are generic, with parameters used to
set data width, address width, maximum burst size, etc. The PIM provides macros for
managing parameters of particular interface instances:
[ofs\_plat\_axi\_mem\_if.vh](https://github.com/OPAE/ofs-platform-afu-bbb/blob/master/plat_if_develop/ofs_plat_if/src/rtl/base_ifcs/axi/ofs_plat_axi_mem_if.vh),
[ofs\_plat\_avalon\_mem\_if.vh](https://github.com/OPAE/ofs-platform-afu-bbb/blob/master/plat_if_develop/ofs_plat_if/src/rtl/base_ifcs/avalon/ofs_plat_avalon_mem_if.vh)
(standard Avalon bus) and
[ofs\_plat\_avalon\_mem\_rdwr\_if.vh](https://github.com/OPAE/ofs-platform-afu-bbb/blob/master/plat_if_develop/ofs_plat_if/src/rtl/base_ifcs/avalon/ofs_plat_avalon_mem_rdwr_if.vh)
(separate read and write buses). These files are included automatically by the standard
"ofs\_plat\_if.vh" wrapper.

All three interface's macros are basically the same. The following examples use AXI
names. Avalon names similar.

### Standard Definitions, Burst Mapping and Alignment

Host channel and local memory interfaces provide macros with values that match the
physical interface. The AFU may set other parameters, such as maximum burst count.
The PIM provides burst count gearboxes automatically, when needed, to map AFU bursts
to bursts in the physical channel. The AFU burst size may be arbitrarily large,
independent of the native maximum. PIM-based burst mapping also guarantees to
enforce alignment as needed. For PCIe channels, bursts will be split apart to avoid
crossing 4KB boundaries. On native CCI-P platforms, bursts will be decomposed into
naturally aligned groups.

```SystemVerilog
ofs_plat_axi_mem_if
  #(
    `HOST_CHAN_AXI_MEM_PARAMS,
    .BURST_CNT_WIDTH(7)
    )
    host_mem_to_afu();
```

### Replication

An identically configured interface may be copied from one interface instance to
another. For example:

```SystemVerilog
ofs_plat_axi_mem_if
  #(
    `OFS_PLAT_AXI_MEM_IF_REPLICATE_PARAMS(other_if)
    )
    new_mem_if();
```

Most provide macros for setting subsets of the parameters. For example, data and
address can be configured without AFU-defined parameters:

```SystemVerilog
ofs_plat_axi_mem_if
  #(
    `OFS_PLAT_AXI_MEM_IF_REPLICATE_MEM_PARAMS(other_if),
    .BURST_CNT_WIDTH(7)
    )
    new_mem_if();
```

## Response Order

Avalon memory interfaces are inherently ordered. AXI and CCI-P memory interfaces are
not. The PIM provides several guarantees in bridges:

- AXI host channel DMA read responses are guaranteed to return in response order.
  This implementation choice is largely a side-effect of the AXI-MM maximum burst
  typically being larger than the native burst of the underlying native interface.
  (See the discussion of burst sizes above.) The AXI memory specification requires
  that read responses within a burst be returned in order. When an AXI burst is
  broken apart into multiple native host channel read requests, the host channel
  might return responses out of order. Sorting host read responses ensures compliance
  with AXI ordering rules.
  
- The PIM offers sorted CCI-P read and write responses, controlled individually
  by parameters to ofs\_plat\_host\_chan\_as\_ccip(). Set SORT\_READ\_RESPONSES to 1
  for ordered read responses and SORT\_WRITE\_RESPONSES to 1 for ordered write
  responses.
  
- If a native interface is ordered then the AXI interface will also return read
  responses in order. For example, local memory is assumed to return responses in
  request order.

## Write Fences and Interrupts

Neither AXI nor Avalon define fences or interrupts as part of the main interface.
The PIM maps both to bits in the user field on write request channels. (The PIM's
Avalon interface adds a user field as an extension.) Both fences and interrupts
return responses on the write channel, similar to normal write responses.

The tutorial does have specific examples of fences or interrupts. Relatively simple
examples do exist in the PIM's test suite:

- AXI write fences (ofs\_plat\_host\_chan\_axi\_mem\_pkg::HC\_AXI\_UFLAG\_FENCE) in
  [host\_chan\_params](https://github.com/OPAE/ofs-platform-afu-bbb/blob/master/plat_if_tests/host_chan_params/hw/rtl/host_mem_rdwr_engine_axi.sv).
- AXI interrupts (ofs\_plat\_host\_chan\_axi\_mem\_pkg::HC\_AXI\_UFLAG\_INTERRUPT) in
  [host\_chan\_intr](https://github.com/OPAE/ofs-platform-afu-bbb/blob/master/plat_if_tests/host_chan_intr/hw/rtl/axi/afu.sv).
- Avalon write fences (ofs\_plat\_host\_chan\_avalon\_mem\_pkg::HC\_AVALON\_UFLAG\_FENCE) in
  [host\_chan\_params](https://github.com/OPAE/ofs-platform-afu-bbb/blob/master/plat_if_tests/host_chan_params/hw/rtl/host_mem_rdwr_engine_avalon.sv).
- Avalon interrupts (ofs\_plat\_host\_chan\_avalon\_mem\_pkg::HC\_AVALON\_UFLAG\_INTERRUPT) in
  [host\_chan\_intr](https://github.com/OPAE/ofs-platform-afu-bbb/blob/master/plat_if_tests/host_chan_intr/hw/rtl/avalon/afu.sv).
