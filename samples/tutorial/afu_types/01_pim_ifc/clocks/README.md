# Clocking

Every interface crossing the partial reconfiguration boundary into an AFU has an associated clock. Every PIM interface has an internal *clk* and *reset_n*. A collection of standard global clocks is passed into AFUs. The PIM wraps these clocks in *struct t\_ofs\_plat\_std\_clocks*, defined in $OPAE\_PLATFORM\_ROOT/hw/lib/build/platform/ofs\_plat\_if/rtl/base\_ifcs/clocks/ofs\_plat\_clocks.vh, which is derived from [ofs\_plat\_clocks.vh](https://github.com/OPAE/ofs-platform-afu-bbb/blob/master/plat_if_develop/ofs_plat_if/src/rtl/base_ifcs/clocks/ofs_plat_clocks.vh). The structure is passed to *ofs\_plat\_afu* as *plat\_ifc.clocks*. Both the *pClk* and *uClk\_usr* families defined in *t\_ofs\_plat\_std\_clocks* are aligned. *pClk* is fixed frequency, and is always the clock used for the primary host channel. The frequency of *uClk\_usr* is configurable at AFU load time.

Each of the clocks in *t\_ofs\_plat\_std\_clocks* is a standard *t\_ofs\_plat\_clock\_reset\_pair*, consisting of clock and reset.

## Clock crossing with the PIM

The PIM offers automated insertion of clock crossing bridges for most interfaces, though AFUs are free to manage clock crossing on their own. Modules that support clock crossing have an ADD\_CLOCK\_CROSSING parameter along with *afu\_clk* and *afu\_reset\_n* ports. When ADD\_CLOCK\_CROSSING is set, AFUs must pass in the target clock/reset pair for the AFU interface in *afu\_clk* and *afu\_reset\_n*. When ADD\_CLOCK\_CROSSING is 0 these ports are ignored.

## User Clock Frequency

User clock frequency is not managed by the PIM. Frequency control is available to all AFUs. It is described here to keep the clocking tutorial in one place.

The frequency of the user clock can be set in the AFU JSON. The setting triggers two changes:

1. The Quartus project updates the configuration of the user clock and sets the proper frequency, enabling timing analysis to apply the chosen frequency. The frequency is read directly from the AFU JSON during timing analysis.

2. The AFU JSON is packaged with the compiled bitstream in the generated GBS file. At load time, fpgaconf configures the user-specified clocks.

In addition to specific *uClk\_usr* frequencies, an AFU's JSON descriptor may set the *uClk\_usr* frequency to *auto*. In this case, an aggressive target frequency is set during place and route. At the end of compilation, timing analysis is invoked and the actual fMAX achieved is calculated. The JSON packaged with the resulting compiled bitstream is updated with the actual *uClk\_usr* fMAX achieved. This is similar to the mechanism used by OneAPI and OpenCL kernels.

The frequency of *uClk\_usr* reported during ASE simulation is often incorrect, even in a properly configured system. The frequency the sample program reports when running with a synthesized AFU is expected to be correct, though perhaps slightly below the target frequency because *uClk\_usr* frequencies are not infinitely configurable.

## Examples

Two sample AFUs are provided, with both sharing identical RTL and software. Both request a clock crossing for the host channel DMA and MMIO interfaces to *uClk\_usr*. The first, [clock\_freq\_uClk\_310.json](hw/rtl/clock_freq_uClk_310.json) sets the frequency of *uClk\_usr* to 310 MHz. The second, [clock\_freq\_uClk\_auto.json](hw/rtl/clock_freq_uClk_auto.json), sets the frequency of *uClk\_usr* based on the achieved fMAX of place and route.

Set up a simulation build of the fixed frequency version with:

```console
$ afu_sim_setup --source hw/rtl/sources_uClk_310.txt build_sim_u310
$ cd build_sim_u310
$ make
$ make sim
```

or synthesis with:

```console
$ afu_sim_setup --source hw/rtl/sources_uClk_310.txt build_u310
$ cd build_u310
$ $OPAE_PLATFORM_ROOT/bin/afu_synth
```

Build the auto-fMAX version with:

```console
$ afu_sim_setup --source hw/rtl/sources_uClk_auto.txt build_sim_uauto
$ cd build_sim_uauto
$ make
$ make sim
```

or synthesis with:

```console
$ afu_sim_setup --source hw/rtl/sources_uClk_310.txt build_uauto
$ cd build_uauto
$ $OPAE_PLATFORM_ROOT/bin/afu_synth
```

Simulation will show no frequency difference between the two examples since achieved fMAX is meaningless in functional simulation.

In both examples, the host channel memory interfaces (both DMA and MMIO) operate in the *uClk\_usr* domain. The *clk* and *reset\_n* wires in the two interfaces are updated with the new clock.

Any global clock could have been used instead of *uClk\_usr*. To run a design at half the normal speed, bind *afu\_clk* to *plat\_ifc.clocks.pClkDiv2.clk* and *afu\_reset\_n* to *plat\_ifc.clocks.pClkDiv2.reset_n*. The frequency of *uClk\_usr* may still be set in the AFU JSON, despite *uClk\_usr* not being used in the design.