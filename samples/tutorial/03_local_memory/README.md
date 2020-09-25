hello_mem_afu is an AFU that builds a simple state machine capable of a few
access patterns to local memory. By *local memory*, we mean memory that is
directly attached to FPGA pins, such as DDR4 DIMMs. This memory is distinct
from the host memory accessed over CCI-P. In hello_mem_afu, the controller
state machine is managed by CSRs (MMIO requests) written and read by the
host.

This discussion will cover the infrastructure that enables three key aspects
of hello_mem_afu:

- In order to access local memory, the top-level ccip_std_afu() ports are
  different than in the original [hello world example](../01_hello_world).

- By default, the interface controlling each bank of local memory is in its
  own clock domain. CCI-P signals are, by default, clocked by pClk. Despite
  this, there is no clock management in the AFU and all signals are in the
  uClk_usr clock domain.

- The frequencies of the two user clocks are set to "auto", triggering a mode
  in which uClk_usr will be set to whatever frequency is achieved by a
  particular compilation. Like OpenCL, this greatly improves the probability
  of synthesizing a working design free of timing failures.

Both the addition of the local memory port to ccip_std_afu and the automated
clock crossing are driven by the AFU's JSON:
[hw/rtl/hello_mem_afu.json](hw/rtl/hello_mem_afu.json). When a build is
configured using either afu_sim_setup or afu_synth_setup, the OPAE [Platform
Interface Manager](https://github.com/OPAE/opae-sdk/tree/master/platforms) is
invoked to construct an AFU-specific top-level interface. The main Platform
Interface Manager script, afu_platform_config, manages an abstraction layer
between the FIU and the AFU. This layer governs the set of ports that will be
passed to the AFU and the clocks associated with those ports.

afu_platform_config consumes three components:

- The AFU JSON.

- A database of available top-level port classes,
  [afu_top_ifc_db](https://github.com/OPAE/opae-sdk/tree/master/platforms/afu_top_ifc_db).

- A database of physical platforms and their hardware characteristics
  [platform_db](https://github.com/OPAE/opae-sdk/tree/master/platforms/platform_db).
  The platform_db search path may also be extended by specific board releases,
  which are discovered by probing the OPAE_PLATFORM_ROOT environment variable.

"afu_platform_config --help" displays the current database search paths,
available top-level interfaces and platform names.

The AFU JSON is specified in the sources text file passed to afu_sim_setup or
afu_synth_setup (e.g. [hw/rtl/sources.txt](hw/rtl/sources.txt)). The target
physical platform is stored in
${OPAE_PLATFORM_ROOT}/hw/lib/fme-platform-class.txt. An entry matching the name
stored in fme-platform-class.txt must be present in the physical platforms
database. The AFU's top-level interface is stored in the AFU JSON file in the
afu-top-interface:class field. For hello_mem_afu, that entry is
*ccip_std_afu_avalon_mm*. The class of an interface defines the ports
expected by the AFU's top-level module and corresponds to a file in the
afu_top_ifc_db described above. Note that the class defines port collections,
not the AFU's top-level module name. The top-level module name typically
remains ccip_std_afu(). SystemVerilog templates corresponding to interface
classes are stored in the
[afu_top_ifc_db](https://github.com/OPAE/opae-sdk/tree/master/platforms/afu_top_ifc_db).

Given a desired top-level interface and a description of a specific physical
platform, afu_platform_config attempts to satisfy the demands of the AFU. If
an AFU requests only ccip_std_afu (the interface requested in the previous
hello world example), the request is satisfiable whether or not the physical
platform has local memory. In the current example, afu_platform_config will
fail when a target physical platform does not offer local memory connected to
an Avalon MM interface.

When successful, afu_platform_config emits a Verilog header file named
platform_afu_top_config.vh into the build tree. The full path is different
for simulation and synthesis, but it can be found within the hierarchy in both
environments. platform_afu_top_config.vh contains Verilog preprocessor macros
that control compile-time decisions within code that Intel provides. The key
parameters are PLATFORM_PROVIDES_* and AFU_TOP_REQUIRES_*. In the majority of
cases, these details are internal to the Intel-provided glue logic and not
exposed to the AFU.

With this mechanism, an AFU may compile on any platform that satisfies the
interface requirements of the AFU. Older AFUs can be compiled on new physical
platforms, despite the fact that a new platform may offer device interfaces
that were defined after the old AFU was written.

## Port Classes and Clocking

Interface ports are broken down into classes.  The AFU JSON in
[hw/rtl/hello_mem_afu.json](hw/rtl/hello_mem_afu.json) modifies two port
classes: *cci-p* and *local-memory*. The clock field is updated. Setting
*clock* to something other than it's default (*default*) or to the interface's
native clock (e.g. *pClk* for CCI-P) triggers automatic insertion of clock
crossing logic from the native domain to the target domain. Any valid clock
name may be used. Most AFUs will use one of the standard CCI-P clocks
(pClkDiv2, uClk_usr, etc.). Specifying a local memory clock
(e.g. local_mem[0].clk) is legal, though generally a poor choice since each
memory bank may have its own clock.

When no clock is specified in the JSON, a port's native clock is unchanged.
It is not necessary to specify clocks for all interfaces. For example,
hello_mem_afu could run in the pClk domain by removing the *clock* field
from class *cci-p* and specifying *pClk* as the clock in class
*local-memory*.

Note that not all module port classes offer automatic clock crossing.
afu_platform_config will fail if a clock crossing is requested that can not
be satisfied.

For most interfaces, an automated clock crossing changes the clock passed
along with the interface. For example, the local_mem[0].clk port in
hw/rtl/ccip_std_afu.sv is connected to uClk_usr in this example. CCI-P's
standard clocks (pClk, pClkDiv2 and pClkDiv4) are exceptions. Because they may
be used to drive other logic, these clocks are always passed in
unchanged. Instead, afu_platform_config sets two Verilog macros. Note the
definitions of clk and reset in
[hw/rtl/ccip_std_afu.sv](hw/rtl/ccip_std_afu.sv):

```verilog
assign clk = `PLATFORM_PARAM_CCI_P_CLOCK;
assign reset = `PLATFORM_PARAM_CCI_P_RESET;
```

AFUs that use these two macros will always pick the correct CCI-P clock in
response to changes in the AFU JSON.

__The clock and reset macros above and the packages containing CCI-P and
local memory interface definitions should be loaded in AFU sources with:__

```verilog
`include "platform_if.vh"
```

All port selection and automated clock crossing is handled in a combination of
Intel-provided code:

- Either the top-level ASE driver module or the top-level green bitstream
  PR connection module that ships with a physical platform release.

- [Shims that are
  provided](https://github.com/OPAE/opae-sdk/tree/master/platforms/platform_if/rtl/platform_shims)
  as part of OPAE.
  
## Building hello_mem_afu RTL

afu_platform_config will generate an error if the target platform does not
have local memory. For example, the AFU can not be mapped to integrated
Xeon+FPGAs. To simulate the workload, either point OPAE_PLATFORM_ROOT to a
release tree for a product that has local memory or force ASE to simulate a
system with local memory:

```console
$ afu_sim_setup --source hw/rtl/sources.txt --platform discrete_pcie3 build_sim
```

The included [hw/sim/setup_ase](hw/sim/setup_ase) includes this platform
switch.

## Avalon MM SystemVerilog Interface

The local memory banks are passed to the AFU as a vector of SystemVerilog
interfaces:
[avalon_mem_if.vh](https://github.com/OPAE/opae-sdk/blob/master/platforms/platform_if/rtl/device_if/avalon_mem_if.vh).
The SystemVerilog interface wraps the usual Avalon MM signals. These wrapped
signals are easily mapped to individual Avalon wire names or ports, if
desired.

AFU JSON may specify both the minimum and maximum number of banks the AFU will
accept. (See min-entries and max-entries in
[afu_top_ifc_db](https://github.com/OPAE/opae-sdk/tree/master/platforms/afu_top_ifc_db).
While an ideal AFU would adapt to the number of banks available, this is
sometimes too difficult. When a specific range of banks is specified, the
Platform Interface Manager will either fail if the target platform has fewer
banks available than the AFU's minimum or will tie off unused banks beyond the
AFU's maximum.

## Debugging Local Memory Traffic

The SystemVerilog Avalon MM interface includes an optional traffic logger when
running in an RTL simulator. By default, logging is enabled at the FIU
edge. It is also enabled on the AFU side of PIM-instantiated local memory
clock crossing shims. The traffic log from ASE simulator runs is stored in
work/avalon_mem_if.tsv. This is the same directory that holds the CCI-P
transaction log: work/ccip_transactions.tsv.
