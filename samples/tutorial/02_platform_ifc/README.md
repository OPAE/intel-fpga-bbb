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
any physical platform, independent of the other local device wires may be
available at the AFU's top-level interface.

[02a_ifc_mapping](02a_ifc_mapping) introduces the syntax for requesting
particular device ports. The underlying mechanism that implements the mapping
will be described in greater detail in [Section 4](../04_local_memory).
