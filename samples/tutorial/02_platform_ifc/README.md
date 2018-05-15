# Platform Interface Manager

The [Platform Interface
Manager's](https://github.com/OPAE/opae-sdk/tree/master/platforms) primary
purpose is to provide an abstraction layer, mapping AFU top-level port
requirements to ports offered by a target physical platform. The first release
to include a PIM database was the PAC with Intel Arria 10 GX FPGA version
1.1. [Scripts to transform earlier
releases](https://github.com/OPAE/intel-fpga-bbb/tree/master/platform-ifc-mgr-compat)
and make them compatible with the PIM are available.

The PIM abstraction layer allows AFUs that connect only to CCI-P to compile on
any physical platform, independent of the other local device wires that may be
available at the AFU's top-level interface.

## Ports

[02a_ifc_mapping](02a_ifc_mapping) introduces the syntax for requesting
particular device ports. The underlying mechanism that implements the mapping
will be described in greater detail in [Section 4](../04_local_memory).

## Clocks

In addition to managing top-level port mapping, the PIM also handles some
common top-level tasks such as clock crossings. AFU designers may specify the
clock that should control incoming interfaces, including both CCI-P and local
memory. For AFUs with simple clocking requirements it is possible to have the
PIM move all devices to common clocks and avoid clock management within the
AFU RTL.

The PIM also manages proper clock constraints for the user-specified clock,
using configuration stored in the AFU JSON. In addition to fixed frequencies,
the user clock can be set to whatever frequency is achieved in a particular
place and route pass, using the same algorithm as OpenCL. This may be
especially useful during development, where achieving timing closure at any
frequency is preferable to long compilations ending in timing failures.

[02b_ccip_clock](02b_ccip_clock) demonstrates CCI-P clocking options. The
equivalent syntax for local memory is covered later, in [Section
4](../04_local_memory).
