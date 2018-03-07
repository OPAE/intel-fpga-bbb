## Scripts for updating old releases to work with the [Platform Interface Manager](https://github.com/OPAE/opae-sdk/tree/master/platforms)

The Platform Interface Manager adds an abstraction layer on the AFU side of the blue (FIU) / green (AFU) partial reconfiguration interface. The manager matches the interface required by a particular AFU to the wires crossing the blue/green boundary, instantiating shims as necessary. See the [Platform Interface Manager tree](https://github.com/OPAE/opae-sdk/tree/master/platforms) in the OPAE SDK.

To update a particular release, run the install.sh script contained in the subdirectory corresponding to the release. The script only needs to be run once to update a release. The installer takes one argument: the path to the release tree that will be updated.

The installer transforms the release as follows:
* Restructures all releases to a common topology:
  * bin: Scripts for configuring and executing Quartus.
  * hw: Quartus configuration.
* Imports the platform manager RTL and timing constraints into all builds.
* Updates green\_bs to work with the platform manager. On platforms with local memory, the updated green\_bs honors configuration parameters and either passes local memory to the AFU or ties off local memory and passes only CCI-P wires to the AFU.
* Adds improved user clock constraint support. User clock frequencies specified in an AFU's JSON file are loaded automatically by Tcl scripts in Quartus, overriding the default frequencies. All timing analysis uses the JSON frequencies. OPAE automatically sets the requested user clock frequencies when a GBS file is loaded.
