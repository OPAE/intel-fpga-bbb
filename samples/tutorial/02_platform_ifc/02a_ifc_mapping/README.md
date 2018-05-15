# Platform Interface Manager Port Mapping

The PIM's primary responsibility is top-level port mapping. The examples here
demonstrate the initial mapping process from AFU interface requests to
physical platform offerings. They are not full AFUs and do not compile.

OPAE ships with two generic physical platforms described in the
[platform_db](https://github.com/OPAE/opae-sdk/tree/master/platforms/platform_db):

- [intg_xeon](https://github.com/OPAE/opae-sdk/blob/master/platforms/platform_db/intg_xeon.json),
  a system supporting only CCI-P with no other devices, and

- [discrete_pcie3](https://github.com/OPAE/opae-sdk/blob/master/platforms/platform_db/discrete_pcie3.json),
  a system that also includes two banks of local memory.

We can experiment with attempts to map various AFU interfaces to these two
systems. There are three sample AFU top-level interfaces in hw/rtl:

- [hw/rtl/sources_ccip_only.txt](hw/rtl/sources_ccip_only.txt) requests only
  CCI-P ports by naming [hw/rtl/ccip_only.json](hw/rtl/ccip_only.json), which
  requests interface class
  [ccip_std_afu](hw/rtl/ccip_only.sv).

- [hw/rtl/sources_ccip_with_local_mem.txt](hw/rtl/sources_ccip_with_local_mem.txt)
  requests CCI-P and local memory ports by naming
  [hw/rtl/ccip_with_local_mem.json](hw/rtl/ccip_with_local_mem.json), which
  requests interface class
  [ccip_std_afu_avalon_mm](hw/rtl/ccip_with_local_mem.sv).

- [hw/rtl/sources_ccip_with_opt_local_mem.txt](hw/rtl/sources_ccip_with_opt_local_mem.txt)
  requests CCI-P and local memory ports by naming
  [hw/rtl/ccip_with_opt_local_mem.json](hw/rtl/ccip_with_opt_local_mem.json),
  which requests the same ccip_std_afu_avalon_mm class as ccip_with_local_mem.
  However, the JSON declares *local memory* optional. The PIM is thus able to
  satisfy the local memory request whether or not it is available. The
  preprocessor variable
  [PLATFORM_PROVIDES_LOCAL_MEMORY](hw/rtl/ccip_with_opt_local_mem.sv)
  indicates whether local memory is actually available. AFUs that can adapt to
  the availability of local memory at compile time can take advantage of this
  optional mapping.

## Experiments

The target platform may be set explicitly on the afu_sim_setup command
line. We can compare the result of choosing *intg_xeon* or *discrete_pcie3*
with the three AFUs.

```console
$ afu_sim_setup --source hw/rtl/sources_ccip_only.txt --platform intg_xeon build_sim -f
```

and

```console
$ afu_sim_setup --source hw/rtl/sources_ccip_only.txt --platform discrete_pcie3 build_sim -f
```

both work because they require only CCI-P. Similarly,

```console
$ afu_sim_setup --source hw/rtl/sources_ccip_with_opt_local_mem.txt --platform intg_xeon build_sim -f
```

and

```console
$ afu_sim_setup --source hw/rtl/sources_ccip_with_opt_local_mem.txt --platform discrete_pcie3 build_sim -f
```

both succeed. The difference is that PLATFORM_PROVIDES_LOCAL_MEMORY is present
in the file build_sim/rtl/platform_afu_top_config.vh only when mapping to
discrete_pcie3. The platform_afu_top_config.vh file is created by
[afu_platform_config](https://github.com/OPAE/opae-sdk/blob/master/platforms/scripts/afu_platform_config),
which is invoked by afu_sim_setup.

Finally, consider ccip_with_local_mem, which maps successfully to
discrete_pcie3 but fails with an error when requesting intg_xeon:

```console
$ afu_sim_setup --source hw/rtl/sources_ccip_with_local_mem.txt --platform intg_xeon build_sim -f
...
Error: ccip_std_afu_avalon_mm needs port local-memory:avalon_mm that intg_xeon doesn't offer
...
```

## Details

A complete, working local memory example is available in [Section
4](../../04_local_memory). Section 4 also describes some PIM implementation
details, including scripts and generated files.
