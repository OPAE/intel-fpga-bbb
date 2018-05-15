# PIM-Managed CCI-P Clocks

Two major CCI-P clocking details can be managed by AFU JSON and the Platform
Interface Manager (PIM). First, the PIM can be instructed to insert clock
crossing FIFOs from the native CCI-P pClk domain to any other available
clock. Second, the frequency of the user-specified clock, uClk_usr, can be
set.

## Assigning the CCI-P Clock

By default, CCI-P interface ports are clocked by pClk. We can see this
demonstrated by the clock_freq_test program that will be used throughout this
example. In hw/rtl there are several source configuration files. The
configurations select different AFU JSON files and common RTL files. The
clock_freq_test RTL implements counters on a variety of clocks that are all
run for the same amount of time. Using a reference frequency, the individual
clock frequencies are computed.

### Default pClk

The default PIM behavior passes CCI-P wires directly from the FIU to the AFU,
leaving the signaling governed by pClk. This configuration is defined by
[hw/rtl/clock_freq_pClk.json](hw/rtl/clock_freq_pClk.json) and can be simulated
using a simulation configured with:

```console
$ afu_sim_setup --source hw/rtl/sources_pClk.txt build_sim_pClk
$ cd build_sim_pClk
$ make
$ make sim
```

and then making and running sw/clock_freq_test_ase in another shell. Like
other ASE simulations, the ASE_WORKDIR environment variable must point to
build_sim_pClk.

### Alternate clock (pClkDiv2)

A clock crossing shim for CCI-P to pClkDiv2 can be instantiated by the PIM
automatically with the addition of a clock specification to the AFU JSON:
[hw/rtl/clock_freq_pClkDiv2.json](hw/rtl/clock_freq_pClkDiv2.json). For this
to work, the AFU RTL must use a Verilog macro to name both the CCI-P clock and
reset. By mapping CCI-P clock and reset to the PLATFORM_PARAM_CCI_P_CLOCK and
PLATFORM_PARAM_CCI_P_RESET macros, RTL automatically connects to the
JSON-specified clock. [hw/rtl/ccip_std_afu.sv](hw/rtl/ccip_std_afu.sv)
uses this code:

```verilog
assign clk = `PLATFORM_PARAM_CCI_P_CLOCK;
assign reset = `PLATFORM_PARAM_CCI_P_RESET;
```

The example can be recompiled with pClkDiv2 selected using
[hw/rtl/clock_freq_pClkDiv2.json](hw/rtl/clock_freq_pClkDiv2.json):

```console
$ afu_sim_setup --source hw/rtl/sources_pClkDiv2.txt build_sim_pClkDiv2
$ cd build_sim_pClkDiv2
$ make
$ make sim
```

Rerun sw/clock_freq_test_ase after updating ASE_WORKDIR and note that the
CCI-P clock frequency now matches pClkDiv2.

## User Clock Frequency

The frequency of the user clock can be set in the AFU JSON. The setting
triggers two changes:

1. The Quartus project updates the configuration of the user clock and sets
the proper frequency, enabling timing analysis to apply the chosen
frequency. The frequency is read directly from the AFU JSON during timing
analysis.

2. The AFU JSON is packaged with the compiled bitstream in the generated GBS
file. At load time, fpgaconf configures the user-specified clocks.

__The following examples only have interesting behavior when synthesized for
FPGA hardware. They can be simulated with ASE, but ASE doesn't modify the
simulated frequency of uClk_usr. Furthermore, the concept of achieved
frequency doesn't apply to simulation.__

__Setting the frequency of uClk_usr is not currently supported on Broadwell
integrated Xeon+FPGA systems using SR-5.0.3. While the examples above that
insert clock crossing to fixed frequency clocks do work on SR-5.0.3, the user
clock frequency examples do not. These examples are fully supported on all
other systems. OPAE release 1.1 supports the feature natively. Earlier
releases must be updated using the [PIM update
scripts](https://github.com/OPAE/intel-fpga-bbb/tree/master/platform-ifc-mgr-compat).__

### User Clock Fixed Frequency

A fixed frequency may be chosen for the user clock, as demonstrated in 
[hw/rtl/clock_freq_uClk_310.json](hw/rtl/clock_freq_uClk_310.json). Note that
the frequency of the slow user clock must be half the frequency of the fast
clock.

The example may be synthesized with:

```console
$ afu_synth_setup --source hw/rtl/sources_uClk_310.txt build_uClk_310
$ cd build_uClk_310
$ $OPAE_PLATFORM_ROOT/bin/run.sh
```

Once complete, load the GBS file with fpgaconf (perhaps requiring root access)
and execute sw/clock_freq_test. Note that the frequency of uClk_usr is
approximately 310 MHz, uClk_usrDiv2 is about 155 and the CCI-P frequency
matches uClk_usr because it was selected in the AFU JSON as the CCI-P clock.

### Auto User Clock Frequency

Two of the examples set the user clock frequency to "auto":
[hw/rtl/clock_freq_pClk.json](hw/rtl/clock_freq_pClk.json) and
[hw/rtl/clock_freq_uClk_auto.json](hw/rtl/clock_freq_uClk_auto.json). The
"pClk" version maintains the default pClk-goverend CCI-P signals. The uClk
version adds a clock crossing for CCI-P to uClk_usr. The two AFUs can be
synthesized with:

```console
$ afu_synth_setup --source hw/rtl/sources_pClk.txt build_pClk
$ cd build_pClk
$ $OPAE_PLATFORM_ROOT/bin/run.sh
```

and

```console
$ afu_synth_setup --source hw/rtl/sources_uClk_auto.txt build_uClk_auto
$ cd build_uClk_auto
$ $OPAE_PLATFORM_ROOT/bin/run.sh
```

When loading these on hardware, note that the achieved frequency of uClk in
the pClk version is likely higher. This is because the uClk frequency in this
case is limited mainly by the length of the carry chain in the uClk_usr cycle
counter. When CCI-P signals are tied to uClk_usr, CCI-P becomes the rate
limiter.
