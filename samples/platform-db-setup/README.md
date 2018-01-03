## Scripts for updating old releases to work with the [Platform Manager](https://github.com/OPAE/opae-sdk/tree/master/platforms)

The Platform Manager adds an abstraction layer on the AFU side of the blue (FIU) / green (AFU) partial reconfiguration interface. The manager matches the interface required by a particular AFU to the wires crossing the blue/green boundary, instantiating shims as necessary. See the [Platform Manager tree](https://github.com/OPAE/opae-sdk/tree/master/platforms) in the OPAE SDK.

To update a particular release, run the install.sh script contained in the subdirectory corresponding to the release. The script only needs to be run once to update a release. The installer takes one argument: the path to the release tree that will be updated.

The installer transforms the release as follows:
* Restructures all releases to a common topology:
  * bin: Scripts for configuring and executing Quartus.
  * hw: Quartus configuration.
* Imports the platform manager RTL and timing constraints into all builds.
* Updates green\_bs to work with the platform manager. On platforms with local memory, the updated green\_bs honors configuration parameters and either passes local memory to the AFU or ties off local memory and passes only CCI-P wires to the AFU.
* Adds improved user clock constraint support. User clock frequencies specified in an AFU's JSON file are loaded automatically by Tcl scripts in Quartus, overriding the default frequencies. All timing analysis uses the JSON frequencies. OPAE automatically sets the requested user clock frequencies when a GBS file is loaded.

As part of the transformation, a script named bin/afu\_synth\_setup is installed at the top of a release tree. This script is the analog of OPAE's [afu\_sim\_setup](https://github.com/OPAE/opae-sdk/blob/master/ase/scripts/afu_sim_setup). Both scripts expect to invoke [rtl\_src\_config](https://github.com/OPAE/opae-sdk/blob/master/platforms/scripts/rtl_src_config) using an AFU source configuration file that lists all RTL, JSON and timing constraints files. afu\_synth\_setup performs several tasks:
* Construct a tree for building an AFU by copying state from the platform release.
* Populate hw/afu.qsf to load the AFU's sources.
* Construct hw/afu\_json\_info.vh from the AFU's JSON file, using [afu\_json\_mgr](https://github.com/OPAE/opae-sdk/blob/master/tools/packager/afu_json_mgr.py).
* Generate an AFU interface configuration in build/platform/platform\_afu\_top\_config.vh from the AFU's JSON, using [afu\_platform\_config](https://github.com/OPAE/opae-sdk/blob/master/platforms/scripts/afu_platform_config).
