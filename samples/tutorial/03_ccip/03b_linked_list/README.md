This example builds on the previous one. It uses the same infrastructure,
including the C++ class wrapping OPAE, the CSR manager and the top-level
RTL module that manages clocking and instantiates MPF. The procedure for
building and running is unchanged.

The [sw/linked_list.cpp](sw/linked_list.cpp) software begins by allocating a
buffer shared with the FPGA. The software then constructs a linked list, using
virtual addresses to connect the chain. Unique data is written to each record.
The linked structure is padded so that each record spans four lines -- in this
case purely to demonstrate multi-line reads. Once initialized, the software
sends the virtual address of the head of the list to the hardware in CSR 1 and
waits for a response.

The hardware consumes the address of the list, walks all nodes in the list,
and computes a CRC-like checksum of the data fields. Once all nodes are
visited the hardware writes the checksum to a result buffer and waits for a
new command.

New concepts introduced in this example:

- The FPGA walks the list using virtual memory and requires a mechanism for
  managing that translation. The software allocates a 16MB region and uses it
  sparsely, forcing the allocation of multiple physical pages and making the
  translation from virtual to physical addresses non-trivial. The [VTP
  shim](https://github.com/OPAE/intel-fpga-bbb/wiki/MPF-VTP-Virtual-to-Physical)
  in the [MPF BBB](https://github.com/OPAE/intel-fpga-bbb/wiki/BBB_cci_mpf)
  handles the translation.

- The base [OPAE_SVC_WRAPPER](../base/sw/opae_svc_wrapper.h) software class
  automatically detects the presence of VTP and switches to the VTP memory
  allocator. The VTP allocator is capable of allocating large, virtually
  contiguous buffers that are shared with an FPGA. VTP populates a virtual to
  physical translation page table as a side effect of memory allocation.

- Order matters in the checksum calculation. The algorithm depends on read
  responses arriving in the order they were requested. MPF's [response reorder
  buffer](https://github.com/OPAE/intel-fpga-bbb/wiki/MPF-ROB-Reorder-Buffer)
  is instantiated to sort responses.

The base top-level module,
[../base/hw/rtl/cci_afu_with_mpf.sv](../base/hw/rtl/cci_afu_with_mpf.sv),
loads application-specific preprocessor variables from
[hw/rtl/cci_mpf_app_conf.vh](hw/rtl/cci_mpf_app_conf.vh). Note there that two
MPF options are set: MPF_CONF_ENABLE_VTP and MPF_CONF_SORT_READ_RESPONSES. MPF
itself is instantiated in
[../base/hw/rtl/cci_afu_with_mpf.sv](../base/hw/rtl/cci_afu_with_mpf.sv). The
configuration options that control MPF's transformation of CCI semantics are
documented there and in the BBB sources:
[BBB_cci_mpf/hw/rtl/cci_mpf.sv](https://github.com/OPAE/intel-fpga-bbb/blob/master/BBB_cci_mpf/hw/rtl/cci_mpf.sv).

The most significant new concept in
[hw/rtl/linked_list_afu.sv](hw/rtl/linked_list_afu.sv) is the read logic that
traverses the linked list. It is found in the section labeled "Read logic":

- A single 4 line read request is generated for each record. Read
  responses arrive as four separate messages. The messages include a tag
  indicating the line number within a multi-line group (hdr.cl_num).

- VTP virtual to physical translation is enabled by setting MPF's
  extension flag, addrIsVirtual, as a side effect of initializing the
  read header from cci_mpf_defaultReqHdrParams(1).

- With VTP enabled, the hardware is operating in the same address space
  as the software. The only address transformation needed is conversion
  from byte granularity to 64 byte line granularity -- just a matter of
  dropping 6 low bits since the linked list records are aligned by the
  software to cache lines. This address transformation is handled in
  byteAddrToClAddr().

Note that this linked list traversal lacks parallelism and will clearly run
more slowly than equivalent software.  Only one read is in flight at a
time.


## Experiment

After running the example successfully, try the following experiment:

- Edit hw/rtl/cci_mpf_app_conf.vh and set MPF_CONF_SORT_READ_RESPONSES to 0.

- Reconfigure the simulator, choosing intg_xeon as the platform to
  simulate. We choose Integrated Xeon specifically because it has multiple
  memory channels active to the host, increasing the probability that read
  responses will arrive out of order:

```console
$ afu_sim_setup --source hw/rtl/sources.txt build_sim --platform intg_xeon
```

- Rebuild the simulator by typing "make" in the ASE shell.

- Rerun the experiment by typing "make sim" in the ASE shell and then
  running sw/linked_list_ase in the software shell.

- Note the failure. You have disabled the reorder buffer and read responses
  now arrive out of order. The "Received entry" messages printed by the
  simulator are unordered and the CRC is incorrect.

Sorting responses has a cost. Response latency necessarily increases and a 512
bit wide block RAM is required. The whole point of making application-specific
memory tuning possible with MPF is to enable only the semantics required for a
given application. Only enable the reorder buffer if your application needs
it!
